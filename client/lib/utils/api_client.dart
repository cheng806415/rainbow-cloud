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

    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: AppConstants.requestTimeout),
      receiveTimeout: const Duration(seconds: AppConstants.requestTimeout),
      sendTimeout: const Duration(seconds: 120),
      headers: {
        'Accept': 'application/json',
      },
      validateStatus: (status) => status != null && status < 500,
    ));

    _dio.interceptors.add(CookieManager(_cookieJar));
  }

  Future<String?> getCsrfToken() async {
    try {
      final response = await _dio.get('/ajax.php', queryParameters: {'act': 'get_token'});
      if (response.data['code'] == 0) {
        _csrfToken = response.data['csrf_token'];
        return _csrfToken;
      }
    } catch (e) {
      print('获取CSRF Token失败: $e');
    }
    return null;
  }

  Future<bool> login(String username, String password) async {
    try {
      final response = await _dio.post('/login.php',
        queryParameters: {'act': 'local_login'},
        data: {'username': username, 'password': password},
      );
      if (response.data['code'] == 0) {
        _isLoggedIn = true;
        await getCsrfToken();
        await loadUserInfo();
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<bool> register(String username, String password, String repassword) async {
    try {
      final response = await _dio.post('/login.php',
        queryParameters: {'act': 'local_register'},
        data: {'username': username, 'password': password, 'repassword': repassword},
      );
      if (response.data['code'] == 0) {
        _isLoggedIn = true;
        await getCsrfToken();
        await loadUserInfo();
        return true;
      }
      return false;
    } catch (e) {
      print('Register error: $e');
      return false;
    }
  }

  Future<void> loadUserInfo() async {
    try {
      final response = await _dio.get('/ajax.php', queryParameters: {'act': 'get_user_info'});
      if (response.data['code'] == 0) {
        _userInfo = response.data['data'] ?? {};
        _userId = _userInfo['uid'] ?? 0;
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
      if (response.data['code'] == 0) {
        return (response.data['files'] as List).map((e) => FileModel.fromJson(e)).toList();
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
    ));
    _dio.interceptors.add(CookieManager(_cookieJar));
  }

  Future<Response> get(String path, {Map<String, dynamic>? params}) async {
    return await _dio.get(path, queryParameters: params);
  }

  Future<Response> post(String path, {Map<String, dynamic>? data, Options? options}) async {
    return await _dio.post(path, data: data, options: options);
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
}
