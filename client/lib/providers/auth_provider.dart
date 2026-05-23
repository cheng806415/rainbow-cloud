import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/api_client.dart';
import '../utils/constants.dart';

class AuthProvider extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  final _apiClient = ApiClient();

  String _serverUrl = AppConstants.defaultServerUrl;
  Timer? _heartbeatTimer;

  String get serverUrl => _serverUrl;
  bool get isLoggedIn => _apiClient.isLoggedIn;
  int get userId => _apiClient.userId;
  Map<String, dynamic> get userInfo => _apiClient.userInfo;

  Future<void> initServerUrl() async {
    final savedUrl = await _storage.read(key: AppConstants.storageKeyServerUrl);
    if (savedUrl != null && savedUrl.isNotEmpty) {
      _serverUrl = savedUrl;
      await _apiClient.init(_serverUrl);
    } else {
      await _apiClient.init(_serverUrl);
    }
  }

  Future<void> setServerUrl(String url) async {
    _serverUrl = url.replaceAll(RegExp(r'/+$'), '');
    await _storage.write(key: AppConstants.storageKeyServerUrl, value: _serverUrl);
    await _apiClient.init(_serverUrl);
    notifyListeners();
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final result = await _apiClient.login(username, password);
    if (result['success'] == true) {
      notifyListeners();
      _startHeartbeat();
    }
    return result;
  }

  Future<Map<String, dynamic>> register(String username, String password, String repassword) async {
    final result = await _apiClient.register(username, password, repassword);
    if (result['success'] == true) {
      notifyListeners();
      _startHeartbeat();
    }
    return result;
  }

  Future<void> checkLoginStatus() async {
    await _apiClient.loadUserInfo();
    notifyListeners();
    if (_apiClient.isLoggedIn) {
      _startHeartbeat();
    }
  }

  Future<void> loadUserInfo() async {
    await _apiClient.loadUserInfo();
    notifyListeners();
  }

  Future<void> logout() async {
    _stopHeartbeat();
    await _apiClient.logout();
    notifyListeners();
  }

  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 60), (timer) async {
      try {
        await _apiClient.loadUserInfo();
      } catch (e) {
        // 心跳失败，可能需要重新登录
      }
    });
  }

  void _stopHeartbeat() {
    if (_heartbeatTimer != null) {
      _heartbeatTimer!.cancel();
      _heartbeatTimer = null;
    }
  }

  @override
  void dispose() {
    _stopHeartbeat();
    super.dispose();
  }

  String get nickname => _apiClient.nickname;
  String get avatar => _apiClient.avatar;
  int get level => _apiClient.level;
  int get storageQuota => _apiClient.storageQuota;
  int get storageUsed => _apiClient.storageUsed;
}
