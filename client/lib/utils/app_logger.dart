import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LogLevel {
  none(0),
  error(1),
  warning(2),
  info(3),
  debug(4),
  verbose(5);

  final int value;
  const LogLevel(this.value);

  static LogLevel fromValue(int value) {
    return LogLevel.values.firstWhere(
      (e) => e.value == value,
      orElse: () => LogLevel.none,
    );
  }

  String get label {
    switch (this) {
      case LogLevel.none:
        return '关闭';
      case LogLevel.error:
        return '错误';
      case LogLevel.warning:
        return '警告';
      case LogLevel.info:
        return '信息';
      case LogLevel.debug:
        return '调试';
      case LogLevel.verbose:
        return '详细';
    }
  }
}

class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();

  static const String _prefsKey = 'app_log_level';
  LogLevel _level = LogLevel.none;
  File? _logFile;
  bool _initialized = false;

  LogLevel get level => _level;

  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_prefsKey) ?? 0;
    _level = LogLevel.fromValue(saved);
    await _initLogFile();
    _initialized = true;
  }

  Future<void> _initLogFile() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final logDir = Directory('${dir.path}/logs');
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }
      final now = DateTime.now();
      final fileName =
          'app_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.log';
      _logFile = File('${logDir.path}/$fileName');
    } catch (e) {
      print('[Logger] init log file failed: $e');
    }
  }

  Future<void> setLevel(LogLevel level) async {
    _level = level;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKey, level.value);
    i('Logger', 'Log level changed to ${level.label}');
  }

  void _log(LogLevel level, String tag, String message) {
    if (_level.value < level.value) return;
    final now = DateTime.now();
    final timeStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}.${now.millisecond.toString().padLeft(3, '0')}';
    final line = '[$timeStr] [${level.name.toUpperCase()}] [$tag] $message';
    print(line);
    _writeToFile(line);
  }

  void _writeToFile(String line) {
    if (_logFile == null) return;
    try {
      _logFile!.writeAsStringSync('$line\n', mode: FileMode.append);
    } catch (e) {
      print('[Logger] write file failed: $e');
    }
  }

  void v(String tag, String message) => _log(LogLevel.verbose, tag, message);
  void d(String tag, String message) => _log(LogLevel.debug, tag, message);
  void i(String tag, String message) => _log(LogLevel.info, tag, message);
  void w(String tag, String message) => _log(LogLevel.warning, tag, message);
  void e(String tag, String message) => _log(LogLevel.error, tag, message);

  Future<String> getLogContent() async {
    if (_logFile == null || !await _logFile!.exists()) return '';
    try {
      return await _logFile!.readAsString();
    } catch (e) {
      return '读取日志失败: $e';
    }
  }

  Future<String> getLogFilePath() async {
    return _logFile?.path ?? '';
  }

  Future<void> clearLogs() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final logDir = Directory('${dir.path}/logs');
      if (await logDir.exists()) {
        final files = await logDir.list().toList();
        for (final file in files) {
          if (file is File) {
            await file.delete();
          }
        }
      }
    } catch (err) {
      _log(LogLevel.error, 'Logger', 'clear logs failed: $err');
    }
  }
}
