import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import '../utils/api_client.dart';
import '../utils/app_logger.dart';
import '../providers/auth_provider.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  final List<UploadTask> _uploadTasks = [];
  bool _isUploading = false;

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null || result.files.isEmpty) return;

    for (final file in result.files) {
      if (file.path != null) {
        final uploadTask = UploadTask(
          name: file.name,
          path: file.path!,
          size: file.size,
        );
        setState(() => _uploadTasks.add(uploadTask));
        _uploadFile(uploadTask);
      }
    }
  }

  Future<void> _uploadFile(UploadTask task) async {
    setState(() => task.status = UploadStatus.preparing);
    final apiClient = ApiClient();

    try {
      final csrfToken = await apiClient.ensureCsrfToken();
      if (csrfToken == null) {
        setState(() {
          task.status = UploadStatus.failed;
          task.message = '获取CSRF Token失败，请重新登录';
        });
        return;
      }

      final file = File(task.path);
      final bytes = await file.readAsBytes();
      final md5Hash = md5.convert(bytes).toString();
      final fileSize = bytes.length;
      AppLogger().i('Upload', 'start upload: ${task.name}, size: $fileSize, hash: $md5Hash');

      setState(() => task.status = UploadStatus.checking);

      final preResponse = await apiClient.post('/ajax.php',
        queryParameters: {'act': 'pre_upload'},
        data: FormData.fromMap({
          'csrf_token': csrfToken,
          'name': task.name,
          'hash': md5Hash,
          'size': fileSize,
          'show': 1,
          'ispwd': 0,
        }),
      );
      AppLogger().d('Upload', 'pre_upload response: ${preResponse.data}');

      final preData = _safeResponse(preResponse);
      if (preData['code'] == 1) {
        setState(() {
          task.status = UploadStatus.exists;
          task.message = '文件已存在';
        });
        return;
      }

      if (preData['code'] != 0) {
        setState(() {
          task.status = UploadStatus.failed;
          task.message = preData['msg']?.toString() ?? '上传预检失败';
        });
        return;
      }

      final chunks = _toInt(preData['chunks'] ?? 1);
      final chunkSize = _toInt(preData['chunksize'] ?? fileSize);

      setState(() => task.status = UploadStatus.uploading);

      if (chunks == 1) {
        final formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(task.path, filename: task.name),
          'chunk': 0,
          'hash': md5Hash,
        });

        final uploadResponse = await apiClient.dio.post('/ajax.php',
          queryParameters: {'act': 'upload_part'},
          data: formData,
          onSendProgress: (sent, total) {
            setState(() => task.progress = sent / total);
          },
        );
        AppLogger().d('Upload', 'upload_part response: ${uploadResponse.data}');
        final uploadData = _safeResponse(uploadResponse);
        if (uploadData['code'] == 1) {
          AppLogger().i('Upload', 'upload success: ${task.name}');
          setState(() {
            task.status = UploadStatus.success;
            task.progress = 1.0;
            task.message = uploadData['msg']?.toString() ?? '上传成功';
          });
        } else {
          AppLogger().e('Upload', 'upload failed: ${task.name}, msg: ${uploadData['msg']}');
          setState(() {
            task.status = UploadStatus.failed;
            task.message = uploadData['msg']?.toString() ?? '上传失败';
          });
        }
      } else {
        Response? lastResponse;
        for (int i = 0; i < chunks; i++) {
          final int start = i * chunkSize;
          final int end = (i + 1) * chunkSize > fileSize ? fileSize : (i + 1) * chunkSize;
          final chunkData = bytes.sublist(start, end);

          final chunkFile = File('${task.path}.part$i');
          await chunkFile.writeAsBytes(chunkData);

          final formData = FormData.fromMap({
            'file': await MultipartFile.fromFile(chunkFile.path, filename: 'part$i'),
            'chunk': i + 1,
            'hash': md5Hash,
          });

          lastResponse = await apiClient.dio.post('/ajax.php',
            queryParameters: {'act': 'upload_part'},
            data: formData,
            onSendProgress: (sent, total) {
              setState(() => task.progress = (i + sent / total) / chunks);
            },
          );
          AppLogger().d('Upload', 'chunk ${i + 1}/$chunks response: ${lastResponse.data}');

          await chunkFile.delete();
        }

        if (lastResponse != null) {
          final uploadData = _safeResponse(lastResponse);
          if (uploadData['code'] == 1) {
            AppLogger().i('Upload', 'multipart upload success: ${task.name}');
            setState(() {
              task.status = UploadStatus.success;
              task.progress = 1.0;
              task.message = uploadData['msg']?.toString() ?? '上传成功';
            });
          } else {
            AppLogger().e('Upload', 'multipart upload failed: ${task.name}, msg: ${uploadData['msg']}');
            setState(() {
              task.status = UploadStatus.failed;
              task.message = uploadData['msg']?.toString() ?? '上传失败';
            });
          }
        }
      }
    } catch (e, stackTrace) {
      AppLogger().e('Upload', 'upload exception: $e\n$stackTrace');
      setState(() {
        task.status = UploadStatus.failed;
        task.message = '上传失败: $e';
      });
    }
  }

  void _clearCompleted() {
    setState(() {
      _uploadTasks.removeWhere((t) =>
          t.status == UploadStatus.success || t.status == UploadStatus.exists);
    });
  }

  void _clearAll() {
    setState(() => _uploadTasks.clear());
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('上传文件'),
        actions: [
          if (_uploadTasks.any((t) => t.status == UploadStatus.success || t.status == UploadStatus.exists))
            TextButton(onPressed: _clearCompleted, child: const Text('清除已完成')),
          if (_uploadTasks.isNotEmpty)
            TextButton(onPressed: _clearAll, child: const Text('清空')),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: _pickFiles,
              icon: const Icon(Icons.upload_file),
              label: const Text('选择文件'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: _uploadTasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_upload, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('点击上方按钮选择文件上传',
                            style: Theme.of(context).textTheme.titleMedium),
                        if (isDesktop) const SizedBox(height: 8),
                        if (isDesktop)
                          Text('也可以拖拽文件到此处（Windows 端）',
                              style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _uploadTasks.length,
                    itemBuilder: (context, index) {
                      final task = _uploadTasks[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: Icon(
                            _getStatusIcon(task.status),
                            color: _getStatusColor(task.status),
                          ),
                          title: Text(task.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${_formatBytes(task.size)} ${task.message ?? ''}'),
                              if (task.status == UploadStatus.uploading)
                                LinearProgressIndicator(value: task.progress),
                            ],
                          ),
                          trailing: Text(
                            task.status == UploadStatus.uploading
                                ? '${(task.progress * 100).toStringAsFixed(1)}%'
                                : _getStatusText(task.status),
                            style: TextStyle(
                              color: _getStatusColor(task.status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(UploadStatus status) {
    switch (status) {
      case UploadStatus.preparing: return Icons.hourglass_empty;
      case UploadStatus.checking: return Icons.search;
      case UploadStatus.uploading: return Icons.cloud_upload;
      case UploadStatus.success: return Icons.check_circle;
      case UploadStatus.failed: return Icons.error;
      case UploadStatus.exists: return Icons.info;
    }
  }

  Color _getStatusColor(UploadStatus status) {
    switch (status) {
      case UploadStatus.preparing: return Colors.grey;
      case UploadStatus.checking: return Colors.blue;
      case UploadStatus.uploading: return Colors.blue;
      case UploadStatus.success: return Colors.green;
      case UploadStatus.failed: return Colors.red;
      case UploadStatus.exists: return Colors.orange;
    }
  }

  String _getStatusText(UploadStatus status) {
    switch (status) {
      case UploadStatus.preparing: return '准备中';
      case UploadStatus.checking: return '检查中';
      case UploadStatus.uploading: return '上传中';
      case UploadStatus.success: return '成功';
      case UploadStatus.failed: return '失败';
      case UploadStatus.exists: return '已存在';
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  Map<String, dynamic> _safeResponse(Response response) {
    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    if (response.data is Map) {
      return Map<String, dynamic>.from(response.data);
    }
    if (response.data is String) {
      var str = (response.data as String).trim();
      str = _cleanControlChars(str);
      final idx = str.indexOf('{');
      if (idx >= 0) {
        try {
          final parsed = const JsonDecoder().convert(str.substring(idx));
          if (parsed is Map) return Map<String, dynamic>.from(parsed);
        } catch (_) {}
      }
    }
    return {'code': -1, 'msg': '服务器返回了非JSON响应'};
  }

  String _cleanControlChars(String str) {
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
    if (start > 0) str = str.substring(start);
    int end = str.length - 1;
    while (end >= 0) {
      final codeUnit = str.codeUnitAt(end);
      if (codeUnit == 0xFEFF || codeUnit <= 0x1F || codeUnit == 0x7F) {
        end--;
      } else {
        break;
      }
    }
    if (end < str.length - 1) str = str.substring(0, end + 1);
    return str;
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

enum UploadStatus { preparing, checking, uploading, success, failed, exists }

class UploadTask {
  final String name;
  final String path;
  final int size;
  UploadStatus status;
  double progress;
  String? message;

  UploadTask({
    required this.name,
    required this.path,
    required this.size,
    this.status = UploadStatus.preparing,
    this.progress = 0,
    this.message,
  });
}
