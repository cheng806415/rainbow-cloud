import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart' as crypto;
import '../utils/api_client.dart';
import '../utils/app_logger.dart';
import '../utils/constants.dart';

enum UploadStatus { queued, checking, uploading, success, failed, exists }

class UploadTask {
  final String id;
  final String name;
  final String path;
  int totalSize = 0;
  int uploadedSize = 0;
  double progress = 0;
  UploadStatus status = UploadStatus.queued;
  String message = '等待中';
  String? hash;
  int? serverFileId;
  int? speedBytesPerSec; // 实时上传速度 (bytes/s)

  UploadTask({
    required this.id,
    required this.name,
    required this.path,
  });
}

class UploadProvider extends ChangeNotifier {
  final List<UploadTask> _tasks = [];
  final Map<String, CancelToken> _cancelTokens = {};
  final Dio _dio = ApiClient().dio;
  final AppLogger _logger = AppLogger();
  int _maxConcurrent = AppConstants.maxConcurrentUploads;
  bool _disposed = false;

  List<UploadTask> get tasks => List.unmodifiable(_tasks);
  int get activeCount => _tasks
      .where((t) =>
          t.status == UploadStatus.uploading ||
          t.status == UploadStatus.checking ||
          t.status == UploadStatus.queued)
      .length;
  int get maxConcurrent => _maxConcurrent;

  set maxConcurrent(int value) {
    _maxConcurrent = value.clamp(1, 10);
  }

  void addFile(String filePath) {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final task = UploadTask(
      id: id,
      name: filePath.split(Platform.pathSeparator).last,
      path: filePath,
    );
    _tasks.insert(0, task);
    _safeNotify();
    _scheduleUpload();
  }

  void removeTask(String id) {
    _cancelTokens[id]?.cancel('用户移除');
    _cancelTokens.remove(id);
    _tasks.removeWhere((t) => t.id == id);
    _safeNotify();
  }

  void clearCompleted() {
    _tasks.removeWhere((t) =>
        t.status == UploadStatus.success ||
        t.status == UploadStatus.failed ||
        t.status == UploadStatus.exists);
    _safeNotify();
  }

  void cancelTask(String id) {
    _cancelTokens[id]?.cancel('用户取消');
  }

  void _scheduleUpload() {
    while (_tasks
            .where((t) =>
                t.status == UploadStatus.uploading ||
                t.status == UploadStatus.checking)
            .length <
        _maxConcurrent) {
      final next = _tasks.firstWhere(
        (t) => t.status == UploadStatus.queued,
        orElse: () => UploadTask(id: '', name: '', path: ''),
      );
      if (next.id.isEmpty) break;
      next.status = UploadStatus.checking;
      next.message = '准备上传...';
      _safeNotify();
      unawaited(_uploadFile(next));
    }
  }

  Future<void> _uploadFile(UploadTask task) async {
    if (task.id.isEmpty) return;
    final file = File(task.path);
    if (!file.existsSync()) {
      _markFailed(task, '文件不存在: ${task.path}');
      return;
    }

    final cancelToken = CancelToken();
    _cancelTokens[task.id] = cancelToken;

    try {
      final bytes = await file.readAsBytes();
      task.totalSize = bytes.length;
      task.message = '计算哈希...';
      _safeNotify();

      final hash = crypto.md5.convert(bytes).toString();
      task.hash = hash;

      // 1) pre_upload
      final preResp = await _dio.post(
        '/ajax.php',
        queryParameters: {'act': 'pre_upload'},
        data: FormData.fromMap({
          'name': task.name,
          'hash': hash,
          'size': task.totalSize,
        }),
        cancelToken: cancelToken,
      );
      final preData = ApiClient().parseResponse(preResp);
      final preCode = (preData['code'] as num?)?.toInt() ?? -1;

      if (preCode == 1) {
        task.status = UploadStatus.exists;
        task.message = preData['msg']?.toString() ?? '秒传成功';
        task.progress = 1.0;
        _safeNotify();
        return;
      }
      if (preCode != 0) {
        _markFailed(task, preData['msg']?.toString() ?? '预上传失败');
        return;
      }

      final chunks = (preData['chunks'] as num?)?.toInt() ?? 1;
      final chunkSize = (preData['chunksize'] as num?)?.toInt() ?? task.totalSize;

      task.status = UploadStatus.uploading;
      _safeNotify();

      // 2) 分片上传
      int? lastSpeedTime;
      int lastUploadedSize = 0;
      for (int i = 0; i < chunks; i++) {
        if (cancelToken.isCancelled) return;
        final start = i * chunkSize;
        final end = (i == chunks - 1) ? bytes.length : (start + chunkSize);
        final partBytes = bytes.sublist(start, end);
        final partLength = partBytes.length;

        final partData = FormData.fromMap({
          'file': MultipartFile.fromBytes(partBytes, filename: '${hash}.part${i + 1}'),
          'chunk': i + 1,
          'hash': hash,
        });

        final partResp = await _dio.post(
          '/ajax.php',
          queryParameters: {'act': 'upload_part'},
          data: partData,
          cancelToken: cancelToken,
          onSendProgress: (sent, total) {
            // onSendProgress 报告的是 HTTP 请求体字节数（含 multipart 开销）
            // 用比例换算为实际文件字节数，避免进度跳变
            final ratio = total > 0 ? sent / total : 0.0;
            final fileBytesSent = (partLength * ratio).toInt();
            final currentUploaded = start + fileBytesSent;
            task.uploadedSize = currentUploaded;
            task.progress = currentUploaded / task.totalSize;
            if (task.progress > 1.0) task.progress = 1.0;

            // 计算上传速度
            final now = DateTime.now().millisecondsSinceEpoch;
            if (lastSpeedTime != null && now - lastSpeedTime >= 500) {
              final deltaSize = currentUploaded - lastUploadedSize;
              final deltaTime = (now - lastSpeedTime) / 1000;
              if (deltaTime > 0) {
                task.speedBytesPerSec = (deltaSize / deltaTime).round();
              }
              lastSpeedTime = now;
              lastUploadedSize = currentUploaded;
            } else if (lastSpeedTime == null) {
              lastSpeedTime = now;
              lastUploadedSize = currentUploaded;
            }

            task.message = '上传分片 ${i + 1}/$chunks';
            _safeNotify();
          },
        );
        final partDataResp = ApiClient().parseResponse(partResp);
        final partCode = (partDataResp['code'] as num?)?.toInt() ?? -1;
        if (partCode == 1) {
          task.serverFileId = (partDataResp['id'] as num?)?.toInt();
          task.message = partDataResp['msg']?.toString() ?? '上传成功';
          break;
        } else if (partCode != 0) {
          _markFailed(task, '分片 ${i + 1} 失败: ${partDataResp['msg']}');
          return;
        }
      }

      task.status = UploadStatus.success;
      task.progress = 1.0;
      task.message = task.message.isEmpty ? '上传成功' : task.message;
      _safeNotify();
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        task.message = '已取消';
        task.status = UploadStatus.queued;
      } else {
        _markFailed(task, '网络错误: ${e.message}');
      }
    } catch (e, stack) {
      _logger.e('UploadProvider', 'upload error: $e\n$stack');
      _markFailed(task, '上传异常: $e');
    } finally {
      _cancelTokens.remove(task.id);
      _safeNotify();
      _scheduleUpload();
    }
  }

  void _markFailed(UploadTask task, String message) {
    task.status = UploadStatus.failed;
    task.message = message;
    _safeNotify();
  }

  void _safeNotify() {
    if (_disposed) return;
    try {
      notifyListeners();
    } catch (_) {}
  }

  @override
  void dispose() {
    _disposed = true;
    for (final token in _cancelTokens.values) {
      token.cancel('Provider disposed');
    }
    _cancelTokens.clear();
    super.dispose();
  }
}
