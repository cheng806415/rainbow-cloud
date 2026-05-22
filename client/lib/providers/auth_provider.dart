import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/api_client.dart';
import '../utils/constants.dart';

class AuthProvider extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  final _apiClient = ApiClient();

  String _serverUrl = AppConstants.defaultServerUrl;

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

  Future<bool> login(String username, String password) async {
    return await _apiClient.login(username, password);
  }

  Future<bool> register(String username, String password, String repassword) async {
    return await _apiClient.register(username, password, repassword);
  }

  Future<void> checkLoginStatus() async {
    await _apiClient.loadUserInfo();
    notifyListeners();
  }

  Future<void> loadUserInfo() async {
    await _apiClient.loadUserInfo();
    notifyListeners();
  }

  Future<void> logout() async {
    await _apiClient.logout();
    notifyListeners();
  }

  String get nickname => _apiClient.nickname;
  String get avatar => _apiClient.avatar;
  int get level => _apiClient.level;
  int get storageQuota => _apiClient.storageQuota;
  int get storageUsed => _apiClient.storageUsed;
}
