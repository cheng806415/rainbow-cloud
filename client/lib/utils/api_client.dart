import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import '../utils/constants.dart';
import '../models/file_model.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  late Dio _dio;
  late CookieJar _cookieJar;
  String _baseUrl = '';
  String? _csrfToken;
  bool _isLoggedIn = false;
  int _userId = 0;
  Map<String, dynamic> _userInfo = {};

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

  Future<void> init(String baseUrl) async {
    _baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), '');
    _cookieJar = CookieJar();

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
    ));

    _dio.interceptors.add(CookieManager(_cookieJar));
  }

  Future<String?> getCsrfToken() async {
    try {
      final response = await _dio.get('/ajax.php', queryParameters: {'act': 'get_token'});
      final data = _safeResponse(response);
      if (data['code'] == 0) {
        _csrfToken = data['csrf_token'];
        return _csrfToken;
      }
    } catch (e) {
      print('获取CSRF Token失败: $e');
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
      final data = _safeResponse(response);
      if (data['code'] == 0) {
        _isLoggedIn = true;
        await getCsrfToken();
        await loadUserInfo();
        return {'success': true};
      }
      return {'success': false, 'message': data['msg'] ?? '登录失败'};
    } catch (e) {
      print('Login error: $e');
      return {'success': false, 'message': '网络错误，请检查服务器地址或网络连接'};
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
        return {'success': true};
      }
      return {'success': false, 'message': data['msg'] ?? '注册失败'};
    } catch (e) {
      print('Register error: $e');
      return {'success': false, 'message': '网络错误，请检查服务器地址或网络连接'};
    }
  }

  Future<void> loadUserInfo() async {
    try {
      final response = await _dio.get('/ajax.php', queryParameters: {'act': 'get_user_info'});
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
      print('loadUserInfo error: $e');
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
      final data = _safeResponse(response);
      if (data['code'] == 0) {
        return (data['files'] as List).map((e) => FileModel.fromJson(e)).toList();
      }
    } catch (e) {
      print('loadFileList error: $e');
    }
    return [];
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _userId = 0;
    _userInfo.clear();
    _cookieJar = CookieJar();
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: AppConstants.requestTimeout),
      receiveTimeout: const Duration(seconds: AppConstants.requestTimeout),
      validateStatus: (status) => true,
    ));
    _dio.interceptors.add(CookieManager(_cookieJar));
  }

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

  String getFileUrl(FileModel file) {
    return '$_baseUrl/view.php/${file.hash}.${file.type ?? ''}';
  }

  String getDownloadUrl(FileModel file) {
    return '$_baseUrl/down.php/${file.hash}.${file.type ?? ''}';
  }

  String getFullUrl(String path) {
    return '$_baseUrl$path';
  }

  Map<String, dynamic> _safeResponse(Response response) {
    if (response.statusCode != null && response.statusCode! >= 400) {
      if (response.data is Map) {
        final data = Map<String, dynamic>.from(response.data);
        return {'code': -1, 'msg': data['msg'] ?? '服务器错误 (${response.statusCode})'};
      }
      if (response.data is String) {
        final parsed = _tryParseJson(response.data as String);
        if (parsed != null) return parsed;
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
      try {
        final parsed = _tryParseJson(response.data as String);
        if (parsed != null) return parsed;
      } catch (_) {}
    }
    return {'code': -1, 'msg': '服务器返回了非JSON响应'};
  }

  Map<String, dynamic>? _tryParseJson(String str) {
    str = str.trim();
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

  dynamic _jsonDecode(String s) {
    return const JsonDecoder().convert(s);
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
