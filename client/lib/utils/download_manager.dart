import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import '../models/file_model.dart';
import 'api_client.dart';
import 'app_logger.dart';

enum DownloadStatus { queued, downloading, completed, failed, cancelled }

class DownloadTask {
  final String id;
  final FileModel file;
  final String url;
  String? localPath;
  int totalBytes = 0;
  int receivedBytes = 0;
  double progress = 0;
  DownloadStatus status = DownloadStatus.queued;
  String? error;

  DownloadTask({
    required this.id,
    required this.file,
    required this.url,
  });
}

class DownloadManager extends ChangeNotifier {
  static final DownloadManager _instance = DownloadManager._internal();
  factory DownloadManager() => _instance;
  DownloadManager._internal();

  final List<DownloadTask> _tasks = [];
  final Map<String, CancelToken> _cancelTokens = {};
  final Dio _dio = ApiClient().dio;
  bool _disposed = false;

  List<DownloadTask> get tasks => List.unmodifiable(_tasks);
  List<DownloadTask> get activeTasks =>
      _tasks.where((t) => t.status == DownloadStatus.downloading || t.status == DownloadStatus.queued).toList();
  List<DownloadTask> get completedTasks =>
      _tasks.where((t) => t.status == DownloadStatus.completed).toList();

  Future<void> startDownload(FileModel file) async {
    if (file.hash.isEmpty) {
      AppLogger().e('DownloadManager', '文件缺少 hash,无法下载: ${file.name}');
      return;
    }

    // 防止重复添加
    final existing = _tasks.firstWhere(
      (t) => t.file.hash == file.hash && t.status != DownloadStatus.completed && t.status != DownloadStatus.failed,
      orElse: () => DownloadTask(id: '', file: file, url: ''),
    );
    if (existing.id.isNotEmpty) {
      AppLogger().i('DownloadManager', '任务已在队列中: ${file.name}');
      return;
    }

    final task = DownloadTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      file: file,
      url: ApiClient().getDownloadUrl(file),
    );
    _tasks.insert(0, task);
    _safeNotify();

    try {
      final dir = await _getDownloadDir();
      final filename = '${file.hash}_${_sanitizeFileName(file.name)}';
      final savePath = '${dir.path}/$filename';

      task.status = DownloadStatus.downloading;
      _safeNotify();

      final cancelToken = CancelToken();
      _cancelTokens[task.id] = cancelToken;

      await _dio.download(
        task.url,
        savePath,
        cancelToken: cancelToken,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) => status != null && status < 500,
        ),
        onReceiveProgress: (received, total) {
          task.receivedBytes = received;
          if (total > 0) {
            task.totalBytes = total;
            task.progress = received / total;
          }
          _safeNotify();
        },
      );

      // 校验文件是否真的写到了磁盘
      final savedFile = File(savePath);
      if (savedFile.existsSync() && savedFile.lengthSync() > 0) {
        task.localPath = savePath;
        task.totalBytes = savedFile.lengthSync();
        task.progress = 1.0;
        task.status = DownloadStatus.completed;
        AppLogger().i('DownloadManager', '下载完成: ${file.name} -> $savePath');
      } else {
        task.status = DownloadStatus.failed;
        task.error = '保存文件失败';
        AppLogger().e('DownloadManager', '下载完成但文件不存在或为空: $savePath');
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        task.status = DownloadStatus.cancelled;
        task.error = '已取消';
      } else {
        task.status = DownloadStatus.failed;
        task.error = e.message ?? '下载失败';
        AppLogger().e('DownloadManager', 'Dio error: ${e.message}');
      }
    } catch (e, stack) {
      task.status = DownloadStatus.failed;
      task.error = e.toString();
      AppLogger().e('DownloadManager', 'Download error: $e\n$stack');
    } finally {
      _cancelTokens.remove(task.id);
      _safeNotify();
    }
  }

  void cancelDownload(String taskId) {
    _cancelTokens[taskId]?.cancel('用户取消');
  }

  void removeTask(String taskId) {
    _tasks.removeWhere((t) => t.id == taskId);
    _cancelTokens.remove(taskId);
    _safeNotify();
  }

  void clearCompleted() {
    _tasks.removeWhere((t) => t.status == DownloadStatus.completed);
    _safeNotify();
  }

  void clearFailed() {
    _tasks.removeWhere((t) => t.status == DownloadStatus.failed || t.status == DownloadStatus.cancelled);
    _safeNotify();
  }

  void clearAll() {
    for (final token in _cancelTokens.values) {
      token.cancel('清空任务');
    }
    _cancelTokens.clear();
    _tasks.clear();
    _safeNotify();
  }

  Future<void> openFile(DownloadTask task) async {
    if (task.localPath == null) {
      AppLogger().w('DownloadManager', 'openFile: 本地路径为空: ${task.file.name}');
      return;
    }
    final file = File(task.localPath!);
    if (!file.existsSync()) {
      AppLogger().e('DownloadManager', 'openFile: 文件不存在: ${task.localPath}');
      task.status = DownloadStatus.failed;
      task.error = '文件不存在,可能已被删除';
      _safeNotify();
      return;
    }
    final result = await OpenFile.open(task.localPath!);
    if (result.type != ResultType.done) {
      AppLogger().e('DownloadManager', '打开文件失败: ${result.message}');
    }
  }

  Future<Directory> _getDownloadDir() async {
    // 优先用应用文档目录下的 Downloads 子目录
    try {
      final docs = await getApplicationDocumentsDirectory();
      final downloads = Directory('${docs.path}/Downloads');
      if (!downloads.existsSync()) {
        downloads.createSync(recursive: true);
      }
      return downloads;
    } catch (e) {
      AppLogger().w('DownloadManager', 'getApplicationDocumentsDirectory failed, fallback to /tmp: $e');
      return Directory.systemTemp.createTempSync('downloads_');
    }
  }

  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_');
  }

  void _safeNotify() {
    if (_disposed) return;
    try {
      notifyListeners();
    } catch (e) {
      AppLogger().w('DownloadManager', 'notifyListeners failed: $e');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    for (final token in _cancelTokens.values) {
      token.cancel('Manager disposed');
    }
    _cancelTokens.clear();
    super.dispose();
  }
}
