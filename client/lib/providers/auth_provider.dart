import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/api_client.dart';
import '../utils/app_logger.dart';
import '../utils/auth_storage.dart';
import '../utils/constants.dart';

class AuthProvider extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  final _apiClient = ApiClient();
  final _appLogger = AppLogger();

  String _serverUrl = AppConstants.defaultServerUrl;
  Timer? _heartbeatTimer;
  bool _disposed = false;

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
    // 切换服务器 -> 旧会话失效，强制清空本地登录态
    // 否则不同 server 的 cookie 会混在同一个 CookieJar 里导致校验失败
    await _apiClient.logout();
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
    // 1) 先尝试从本地恢复登录态（cache + PersistCookieJar 落盘 cookie）
    //    这一步会立即把 UI 切到已登录状态，后台再静默校验
    final restored = await _apiClient.restoreSession();
    if (restored) {
      AppLogger().i('AuthProvider', 'checkLoginStatus: restored from local');
      notifyListeners();
      _startHeartbeat();
      return;
    }
    // 2) 本地无会话 -> 调用一次 getUserInfo 兜底（可能服务器 session 还在但本地缓存被清）
    await _apiClient.loadUserInfo();
    notifyListeners();
    if (_apiClient.isLoggedIn) {
      // 服务器仍认这个会话 -> 立即把缓存补回 secure storage
      await AuthStorage.saveSession(
        userId: _apiClient.userId,
        userInfo: _apiClient.userInfo,
      );
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
        if (!_disposed) notifyListeners();
      } catch (e) {
        _appLogger.w('AuthProvider', 'heartbeat error: $e');
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
    _disposed = true;
    _stopHeartbeat();
    super.dispose();
  }

  String get nickname => _apiClient.nickname;
  String get avatar => _apiClient.avatar;
  int get level => _apiClient.level;
  int get storageQuota => _apiClient.storageQuota;
  int get storageUsed => _apiClient.storageUsed;
}
