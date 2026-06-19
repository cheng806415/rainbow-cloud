import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import '../utils/constants.dart';
import '../utils/app_logger.dart';
import '../utils/auth_storage.dart';
import '../models/file_model.dart';
import '../models/share_model.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  late Dio _dio;
  PersistCookieJar? _cookieJar;
  String _baseUrl = '';
  String? _csrfToken;
  bool _isLoggedIn = false;
  int _userId = 0;
  Map<String, dynamic> _userInfo = {};
  bool _initialized = false;

  Dio get dio => _dio;
  String get baseUrl => _baseUrl;
  String? get csrfToken => _csrfToken;
  bool get isLoggedIn => _isLoggedIn;
  int get userId => _userId;
  Map<String, dynamic> get userInfo => _userInfo;
  String get nickname => _userInfo['nickname'] ?? '用户';
  String get avatar => _userInfo['avatar'] ?? _userInfo['faceimg'] ?? '';
  int get level => _userInfo['level'] ?? 0;
  int get storageQuota => _userInfo['storage_quota'] ?? 1073741824;
  int get storageUsed => _userInfo['storage_used'] ?? 0;
  String get username => _userInfo['username'] ?? '';

  /// 初始化 Dio 与持久化 Cookie 容器
  /// - 必须先 await init() 才能进行网络请求
  /// - 同一进程多次调用是幂等的
  Future<void> init(String baseUrl) async {
    _baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), '');

    // 仅在首次初始化时创建持久化 Cookie 容器
    // 后续重连使用同一份 CookieJar，从而保证用户登录态
    try {
      _cookieJar ??= await AuthStorage.createCookieJar();
    } catch (e) {
      AppLogger().e('ApiClient', 'createCookieJar failed: $e');
    }

    _createDio();
    _initialized = true;
    AppLogger().i('ApiClient', 'init ok, baseUrl=$_baseUrl');
  }

  /// 启动时尝试从本地恢复登录态（先恢复缓存再异步校验）
  /// - 立即恢复 UI：直接用 secure_storage 中的 user_info
  /// - 后台静默校验：调用 getUserInfo，失败则清空
  Future<bool> restoreSession() async {
    if (!_initialized) {
      AppLogger().w('ApiClient', 'restoreSession called before init');
      return false;
    }
    final session = await AuthStorage.loadSession();
    if (session == null) {
      AppLogger().i('ApiClient', 'restoreSession: no local session');
      return false;
    }
    final loginAt = session['loginAt'] as int;
    if (!AuthStorage.isSessionValid(loginAt)) {
      AppLogger().w('ApiClient', 'restoreSession: session expired, clear');
      await AuthStorage.clearSession();
      return false;
    }
    final uid = session['userId'] as int;
    final info = session['userInfo'] as Map<String, dynamic>;
    if (uid <= 0) {
      return false;
    }
    _userId = uid;
    _userInfo = info;
    _isLoggedIn = true;
    AppLogger().i('ApiClient', 'restoreSession: cached uid=$uid, will verify with server');

    // 后台静默校验 token，失败再清空
    unawaited(_verifySessionInBackground());
    return true;
  }

  Future<void> _verifySessionInBackground() async {
    try {
      await loadUserInfo();
      if (!_isLoggedIn || _userId <= 0) {
        AppLogger().w('ApiClient', 'verifySession: server rejected, clearing local state');
        await _clearLocalSession();
      } else {
        // 刷新缓存（昵称/头像/容量等可能已变更）
        await AuthStorage.saveSession(userId: _userId, userInfo: _userInfo);
      }
    } catch (e) {
      AppLogger().w('ApiClient', 'verifySession network error (keep local): $e');
    }
  }

  Future<void> _clearLocalSession() async {
    _isLoggedIn = false;
    _userId = 0;
    _userInfo.clear();
    _csrfToken = null;
    await AuthStorage.clearSession();
    try {
      await _cookieJar?.deleteAll();
    } catch (e) {
      AppLogger().w('ApiClient', 'clear cookies error: $e');
    }
  }

  Future<String?> getCsrfToken() async {
    try {
      final response = await _dio.get('/ajax.php', queryParameters: {'act': 'get_token'});
      AppLogger().d('ApiClient', 'getCsrfToken response: ${response.data}');
      final data = _safeResponse(response);
      if (data['code'] == 0) {
        _csrfToken = data['csrf_token'];
        return _csrfToken;
      }
    } catch (e) {
      AppLogger().e('ApiClient', 'getCsrfToken error: $e');
    }
    return null;
  }

  Future<String?> ensureCsrfToken() async {
    return await getCsrfToken();
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _dio.post('/login.php',
        queryParameters: {'act': 'local_login'},
        data: FormData.fromMap({'username': username, 'password': password}),
      );
      AppLogger().d('ApiClient', 'login response: ${response.data}');
      final data = _safeResponse(response);
      if (data['code'] == 0) {
        _isLoggedIn = true;
        await getCsrfToken();
        await loadUserInfo();
        // 登录成功 -> 持久化会话（Cookie 由 PersistCookieJar 自动落盘，user 信息走 secure storage）
        if (_userId > 0) {
          await AuthStorage.saveSession(userId: _userId, userInfo: _userInfo);
        }
        return {'success': true};
      }
      return {'success': false, 'message': data['msg'] ?? '登录失败'};
    } catch (e) {
      final errMsg = _formatNetworkError(e, 'login');
      AppLogger().e('ApiClient', 'login error: $e');
      return {'success': false, 'message': errMsg};
    }
  }

  Future<Map<String, dynamic>> register(String username, String password, String repassword) async {
    try {
      final response = await _dio.post('/login.php',
        queryParameters: {'act': 'local_register'},
        data: FormData.fromMap({'username': username, 'password': password, 'repassword': repassword}),
      );
      final data = _safeResponse(response);
      if (data['code'] == 0) {
        _isLoggedIn = true;
        await getCsrfToken();
        await loadUserInfo();
        if (_userId > 0) {
          await AuthStorage.saveSession(userId: _userId, userInfo: _userInfo);
        }
        return {'success': true};
      }
      return {'success': false, 'message': data['msg'] ?? '注册失败'};
    } catch (e) {
      final errMsg = _formatNetworkError(e, 'register');
      AppLogger().e('ApiClient', 'register error: $e');
      return {'success': false, 'message': errMsg};
    }
  }

  Future<void> loadUserInfo() async {
    try {
      final response = await _dio.get('/ajax.php', queryParameters: {'act': 'get_user_info'});
      AppLogger().d('ApiClient', 'loadUserInfo response: ${response.data}');
      final data = _safeResponse(response);
      if (data['code'] == 0) {
        _userInfo = Map<String, dynamic>.from(data['data'] ?? {});
        _userId = _toInt(_userInfo['uid']);
        _isLoggedIn = _userId > 0;
      } else {
        _isLoggedIn = false;
      }
    } catch (e) {
      _isLoggedIn = false;
      AppLogger().e('ApiClient', 'loadUserInfo error: $e');
    }
  }

  Future<List<FileModel>> loadFileList({int folderId = 0, String keyword = '', bool showHidden = false}) async {
    try {
      final response = await _dio.get('/ajax.php', queryParameters: {
        'act': 'file_list',
        if (folderId > 0) 'folder_id': folderId,
        if (keyword.isNotEmpty) 'keyword': keyword,
        if (showHidden) 'hide': 1,
      });
      AppLogger().d('ApiClient', 'loadFileList response: ${response.data}');
      final data = _safeResponse(response);
      if (data['code'] == 0) {
        return (data['files'] as List).map((e) => FileModel.fromJson(e)).toList();
      }
    } catch (e) {
      AppLogger().e('ApiClient', 'loadFileList error: $e');
    }
    return [];
  }

  Future<void> logout() async {
    // 通知服务器注销,失败也继续清本地
    try {
      final token = await ensureCsrfToken();
      if (token != null) {
        await _dio.post('/login.php',
          queryParameters: {'act': 'logout'},
          data: FormData.fromMap({'csrf_token': token}),
        ).timeout(const Duration(seconds: 3));
        AppLogger().i('ApiClient', 'server logout ok');
      }
    } catch (e) {
      AppLogger().w('ApiClient', 'server logout failed (continuing local clear): $e');
    }
    // 清理本地会话：内存 + secure storage + 持久化 cookie 文件
    await _clearLocalSession();
    // 重新生成一个全新的 Dio 实例（不复用旧的 _dio，因为它持有旧的 CookieManager）
    _createDio();
  }

  void _createDio() {
    final uri = Uri.parse(_baseUrl);
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: AppConstants.requestTimeout),
      receiveTimeout: const Duration(seconds: AppConstants.requestTimeout),
      sendTimeout: const Duration(seconds: 120),
      headers: {
        'Accept': 'application/json',
        'Referer': _baseUrl + '/',
        'Origin': '${uri.scheme}://${uri.host}',
      },
      validateStatus: (status) => true,
      responseType: ResponseType.plain,
    ));
    if (_cookieJar != null) {
      _dio.interceptors.add(CookieManager(_cookieJar!));
    }
  }

  // ============== 回收站 ==============

  Future<List<FileModel>> loadRecycleList() async {
    try {
      final response = await _dio.get('/ajax.php', queryParameters: {'act': 'recycle_list'});
      final data = _safeResponse(response);
      if (data['code'] == 0 && data['files'] is List) {
        return (data['files'] as List).map((e) => FileModel.fromJson(e)).toList();
      }
    } catch (e) {
      AppLogger().e('ApiClient', 'loadRecycleList error: $e');
    }
    return [];
  }

  Future<bool> restoreFile(String hash) async {
    final token = await ensureCsrfToken();
    final response = await _dio.post('/ajax.php',
      queryParameters: {'act': 'restoreFile'},
      data: FormData.fromMap({'csrf_token': token, 'hash': hash}),
    );
    final data = _safeResponse(response);
    return data['code'] == 0;
  }

  Future<bool> permanentDelete(String hash) async {
    final token = await ensureCsrfToken();
    final response = await _dio.post('/ajax.php',
      queryParameters: {'act': 'permanentDelete'},
      data: FormData.fromMap({'csrf_token': token, 'hash': hash}),
    );
    final data = _safeResponse(response);
    return data['code'] == 0;
  }

  // ============== 分享 ==============

  Future<List<ShareModel>> loadShareList() async {
    try {
      final response = await _dio.get('/ajax.php', queryParameters: {'act': 'share_list'});
      final data = _safeResponse(response);
      if (data['code'] == 0 && data['shares'] is List) {
        return (data['shares'] as List).map((e) => ShareModel.fromJson(_normalizeShareJson(e))).toList();
      }
    } catch (e) {
      AppLogger().e('ApiClient', 'loadShareList error: $e');
    }
    return [];
  }

  Map<String, dynamic> _normalizeShareJson(dynamic raw) {
    final shareData = Map<String, dynamic>.from(raw);
    if (shareData['file'] == null && shareData['file_name'] != null) {
      shareData['file'] = {
        'id': shareData['file_id'] ?? 0,
        'name': shareData['file_name'] ?? '未知文件',
        'size': shareData['file_size'] ?? 0,
        'hash': shareData['file_hash'] ?? '',
        'type': shareData['file_type'] ?? '',
      };
    }
    return shareData;
  }

  Future<Map<String, dynamic>?> createShare(int fileId, {String? pwd, int expireType = 0}) async {
    final token = await ensureCsrfToken();
    if (token == null) return null;
    final response = await _dio.post('/ajax.php',
      queryParameters: {'act': 'create_share'},
      data: FormData.fromMap({
        'csrf_token': token,
        'file_id': fileId,
        'pwd': pwd ?? '',
        'expire_type': expireType,
      }),
    );
    final data = _safeResponse(response);
    if (data['code'] == 0) {
      return {'surl': data['surl'], 'pwd': pwd};
    }
    return {'error': data['msg'] ?? '创建失败'};
  }

  Future<bool> deleteShare(String surl) async {
    final token = await ensureCsrfToken();
    final response = await _dio.post('/ajax.php',
      queryParameters: {'act': 'delete_share'},
      data: FormData.fromMap({'csrf_token': token, 'surl': surl}),
    );
    final data = _safeResponse(response);
    return data['code'] == 0;
  }

  // ============== 用户设置 ==============

  Future<bool> updateNickname(String nickname) async {
    final token = await ensureCsrfToken();
    if (token == null) return false;
    final response = await _dio.post('/ajax.php',
      queryParameters: {'act': 'saveUserSettings'},
      data: FormData.fromMap({'csrf_token': token, 'action': 'nickname', 'nickname': nickname}),
    );
    final data = _safeResponse(response);
    if (data['code'] == 0) {
      _userInfo['nickname'] = nickname;
      return true;
    }
    return false;
  }

  Future<bool> updatePassword(String oldPassword, String newPassword) async {
    final token = await ensureCsrfToken();
    if (token == null) return false;
    final response = await _dio.post('/ajax.php',
      queryParameters: {'act': 'saveUserSettings'},
      data: FormData.fromMap({
        'csrf_token': token,
        'action': 'password',
        'old_password': oldPassword,
        'new_password': newPassword,
      }),
    );
    final data = _safeResponse(response);
    return data['code'] == 0;
  }

  // ============== 通用 GET/POST ==============

  Future<Response> get(String path, {Map<String, dynamic>? params}) async {
    return await _dio.get(path, queryParameters: params);
  }

  Future<Response> post(String path, {Map<String, dynamic>? queryParameters, dynamic data, Options? options}) async {
    return await _dio.post(path, queryParameters: queryParameters, data: data, options: options);
  }

  Future<Response> upload(String path, FormData formData, {ProgressCallback? onSendProgress}) async {
    return await _dio.post(path, data: formData, onSendProgress: onSendProgress);
  }

  Future<Response> download(String url, String savePath, {ProgressCallback? onReceiveProgress}) async {
    return await _dio.download(url, savePath, onReceiveProgress: onReceiveProgress);
  }

  Future<Map<String, dynamic>?> getArchiveList(String hash) async {
    try {
      final response = await _dio.get('/ajax.php', queryParameters: {'act': 'archive_list', 'hash': hash});
      AppLogger().d('ApiClient', 'getArchiveList response: ${response.data}');
      final data = _safeResponse(response);
      if (data['code'] == 0) return data;
    } catch (e) {
      AppLogger().e('ApiClient', 'getArchiveList error: $e');
    }
    return null;
  }

  String getFileUrl(FileModel file) {
    if (file.hash.isEmpty) {
      AppLogger().w('ApiClient', 'getFileUrl: hash 为空,${file.name}');
      return '';
    }
    return '$_baseUrl/view.php/${file.hash}.${file.type ?? ''}';
  }

  String getDownloadUrl(FileModel file) {
    if (file.hash.isEmpty) {
      AppLogger().w('ApiClient', 'getDownloadUrl: hash 为空,${file.name}');
      return '';
    }
    return '$_baseUrl/down.php/${file.hash}.${file.type ?? ''}';
  }

  String getFullUrl(String path) {
    return '$_baseUrl$path';
  }

  Map<String, dynamic> parseResponse(Response response) {
    return _safeResponse(response);
  }

  Map<String, dynamic> _safeResponse(Response response) {
    AppLogger().d('ApiClient', 'response status: ${response.statusCode}, data type: ${response.data.runtimeType}');
    if (response.statusCode != null && response.statusCode! >= 400) {
      if (response.data is Map) {
        final data = Map<String, dynamic>.from(response.data);
        return {'code': -1, 'msg': data['msg'] ?? '服务器错误 (${response.statusCode})'};
      }
      if (response.data is String) {
        final raw = response.data as String;
        AppLogger().w('ApiClient', 'HTTP ${response.statusCode} response: $raw');
        final parsed = _tryParseJson(raw);
        if (parsed != null) return parsed;
        if (raw.contains('<html') || raw.contains('<!DOCTYPE')) {
          return {'code': -1, 'msg': '服务器返回了HTML页面 (HTTP ${response.statusCode})'};
        }
        return {'code': -1, 'msg': '服务器错误 (HTTP ${response.statusCode}): ${raw.substring(0, raw.length > 100 ? 100 : raw.length)}'};
      }
      return {'code': -1, 'msg': '服务器错误 (HTTP ${response.statusCode})'};
    }
    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    if (response.data is Map) {
      return Map<String, dynamic>.from(response.data);
    }
    if (response.data is String) {
      final raw = response.data as String;
      AppLogger().d('ApiClient', 'response raw: $raw');
      try {
        final parsed = _tryParseJson(raw);
        if (parsed != null) return parsed;
      } catch (e) {
        AppLogger().e('ApiClient', 'parse response failed: $e, raw: $raw');
      }
      if (raw.contains('<html') || raw.contains('<!DOCTYPE')) {
        return {'code': -1, 'msg': '服务器返回了HTML页面，可能是登录已过期或请求被拦截'};
      }
    }
    return {'code': -1, 'msg': '服务器返回了非JSON响应'};
  }

  Map<String, dynamic>? _tryParseJson(String str) {
    str = _cleanResponseString(str);
    if (!str.startsWith('{') && !str.startsWith('[')) return null;
    final idx = str.indexOf('{');
    if (idx < 0) return null;
    final sub = str.substring(idx);
    try {
      final parsed = _jsonDecode(sub);
      if (parsed is Map<String, dynamic>) return parsed;
      if (parsed is Map) return Map<String, dynamic>.from(parsed);
    } catch (_) {}
    return null;
  }

  String _cleanResponseString(String str) {
    str = str.trim();
    if (str.isEmpty) return str;
    int start = 0;
    while (start < str.length) {
      final codeUnit = str.codeUnitAt(start);
      if (codeUnit == 0xFEFF || codeUnit <= 0x1F || codeUnit == 0x7F) {
        start++;
      } else {
        break;
      }
    }
    if (start > 0) {
      str = str.substring(start);
    }
    int end = str.length - 1;
    while (end >= 0) {
      final codeUnit = str.codeUnitAt(end);
      if (codeUnit == 0xFEFF || codeUnit <= 0x1F || codeUnit == 0x7F) {
        end--;
      } else {
        break;
      }
    }
    if (end < str.length - 1) {
      str = str.substring(0, end + 1);
    }
    return str;
  }

  dynamic _jsonDecode(String s) {
    return const JsonDecoder().convert(s);
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// 把 Dio 异常转换成用户可读的提示，便于定位问题
  String _formatNetworkError(dynamic e, String action) {
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return '连接超时，请检查网络或服务器地址';
        case DioExceptionType.connectionError:
          return '无法连接到服务器 ($_baseUrl)，请检查地址是否正确';
        case DioExceptionType.badCertificate:
          return '服务器证书校验失败，请检查系统时间或网络环境';
        case DioExceptionType.badResponse:
          return '服务器返回异常 (${e.response?.statusCode})';
        case DioExceptionType.cancel:
          return '请求已取消';
        case DioExceptionType.unknown:
          if (e.message != null && e.message!.contains('Certificate')) {
            return '服务器证书校验失败：${e.message}';
          }
          return '网络错误：${e.message}';
      }
    }
    return '网络错误，请检查服务器地址或网络连接 (${e.runtimeType})';
  }
}
