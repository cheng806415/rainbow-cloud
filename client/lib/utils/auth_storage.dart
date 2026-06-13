import 'dart:convert';
import 'dart:io';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'app_logger.dart';

/// 跨平台会话持久化方案：
/// - Cookie 持久化: PersistCookieJar + FileStorage (iOS/Android/Windows 均支持)
/// - 关键登录信息: flutter_secure_storage (iOS Keychain / Android EncryptedSharedPreferences / Windows DPAPI)
class AuthStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    wOptions: WindowsOptions(useBackwardCompatibility: false),
  );

  static const _kUserId = 'auth_user_id';
  static const _kUserInfo = 'auth_user_info';
  static const _kLoginAt = 'auth_login_at';

  /// 获取应用支持目录的 cookie 存储路径（iOS/Android/Windows 通用）
  static Future<String> getCookieDir() async {
    Directory baseDir;
    try {
      baseDir = await getApplicationSupportDirectory();
    } catch (e) {
      baseDir = await getApplicationDocumentsDirectory();
    }
    final dir = Directory('${baseDir.path}/.cookies');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  /// 创建持久化 Cookie 存储
  static Future<PersistCookieJar> createCookieJar() async {
    final dir = await getCookieDir();
    AppLogger().i('AuthStorage', 'Cookie 存储目录: $dir');
    return PersistCookieJar(
      ignoreExpires: false,
      storage: FileStorage(dir),
    );
  }

  static Future<void> saveSession({
    required int userId,
    required Map<String, dynamic> userInfo,
  }) async {
    try {
      await _storage.write(key: _kUserId, value: userId.toString());
      await _storage.write(key: _kUserInfo, value: jsonEncode(userInfo));
      await _storage.write(key: _kLoginAt, value: DateTime.now().millisecondsSinceEpoch.toString());
      AppLogger().i('AuthStorage', 'saveSession ok, uid=$userId');
    } catch (e) {
      AppLogger().e('AuthStorage', 'saveSession error: $e');
    }
  }

  /// 读取上次保存的用户信息（用于启动后立即恢复 UI）
  static Future<Map<String, dynamic>?> loadSession() async {
    try {
      final uidStr = await _storage.read(key: _kUserId);
      final infoStr = await _storage.read(key: _kUserInfo);
      final loginAt = await _storage.read(key: _kLoginAt);
      if (uidStr == null || infoStr == null) {
        return null;
      }
      final userInfo = jsonDecode(infoStr) as Map<String, dynamic>;
      return {
        'userId': int.tryParse(uidStr) ?? 0,
        'userInfo': userInfo,
        'loginAt': int.tryParse(loginAt ?? '0') ?? 0,
      };
    } catch (e) {
      AppLogger().e('AuthStorage', 'loadSession error: $e');
      return null;
    }
  }

  static Future<void> clearSession() async {
    try {
      await _storage.delete(key: _kUserId);
      await _storage.delete(key: _kUserInfo);
      await _storage.delete(key: _kLoginAt);
      AppLogger().i('AuthStorage', 'clearSession ok');
    } catch (e) {
      AppLogger().e('AuthStorage', 'clearSession error: $e');
    }
  }

  /// 检查会话是否在有效期内（默认 30 天，与后端 cookie 一致）
  static bool isSessionValid(int loginAtMs, {int maxAgeDays = 30}) {
    if (loginAtMs <= 0) return false;
    final age = DateTime.now().millisecondsSinceEpoch - loginAtMs;
    return age < maxAgeDays * 24 * 60 * 60 * 1000;
  }
}
