import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../models/file_model.dart';
import '../utils/api_client.dart';

class DownloadPage extends StatefulWidget {
  const DownloadPage({super.key});

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class DownloadTask {
  final String name;
  final int size;
  final String url;
  double progress;
  DownloadStatus status;
  String? localPath;
  String? error;

  DownloadTask({
    required this.name,
    required this.size,
    required this.url,
    this.progress = 0,
    this.status = DownloadStatus.waiting,
    this.localPath,
    this.error,
  });
}

enum DownloadStatus { waiting, downloading, success, failed, paused }

class _DownloadPageState extends State<DownloadPage> {
  final List<DownloadTask> _tasks = [];

  Future<void> _startDownload(FileModel file) async {
    final task = DownloadTask(
      name: file.name,
      size: file.size,
      url: ApiClient().getDownloadUrl(file),
    );
    setState(() => _tasks.insert(0, task));
    _downloadFile(task);
  }

  Future<void> _downloadFile(DownloadTask task) async {
    setState(() => task.status = DownloadStatus.downloading);
    try {
      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/${task.name}';

      await ApiClient().download(
        task.url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            setState(() => task.progress = received / total);
          }
        },
      );

      setState(() {
        task.status = DownloadStatus.success;
        task.progress = 1.0;
        task.localPath = savePath;
      });
    } catch (e) {
      setState(() {
        task.status = DownloadStatus.failed;
        task.error = e.toString();
      });
    }
  }

  Future<void> _openFile(DownloadTask task) async {
    if (task.localPath != null) {
      final result = await OpenFile.open(task.localPath);
      if (result.type != ResultType.done) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('无法打开文件: ${result.message}')),
          );
        }
      }
    }
  }

  void _clearCompleted() {
    setState(() {
      _tasks.removeWhere((t) => t.status == DownloadStatus.success);
    });
  }

  void _clearAll() {
    setState(() => _tasks.clear());
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('下载管理'),
        actions: [
          if (_tasks.any((t) => t.status == DownloadStatus.success))
            TextButton(onPressed: _clearCompleted, child: const Text('清除已完成')),
          if (_tasks.isNotEmpty)
            TextButton(onPressed: _clearAll, child: const Text('清空')),
        ],
      ),
      body: _tasks.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.download, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('暂无下载任务', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('在文件列表中选择文件下载',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                final task = _tasks[index];
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
                        if (task.status == DownloadStatus.downloading)
                          LinearProgressIndicator(value: task.progress),
                        if (task.error != null)
                          Text(task.error!,
                              style: const TextStyle(color: Colors.red, fontSize: 12)),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          task.status == DownloadStatus.downloading
                              ? '${(task.progress * 100).toStringAsFixed(1)}%'
                              : _getStatusText(task.status),
                          style: TextStyle(
                            color: _getStatusColor(task.status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (task.status == DownloadStatus.success) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.folder_open),
                            onPressed: () => _openFile(task),
                            tooltip: '打开文件',
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  IconData _getStatusIcon(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.waiting: return Icons.hourglass_empty;
      case DownloadStatus.downloading: return Icons.download;
      case DownloadStatus.success: return Icons.check_circle;
      case DownloadStatus.failed: return Icons.error;
      case DownloadStatus.paused: return Icons.pause_circle;
    }
  }

  Color _getStatusColor(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.waiting: return Colors.grey;
      case DownloadStatus.downloading: return Colors.blue;
      case DownloadStatus.success: return Colors.green;
      case DownloadStatus.failed: return Colors.red;
      case DownloadStatus.paused: return Colors.orange;
    }
  }

  String _getStatusText(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.waiting: return '等待中';
      case DownloadStatus.downloading: return '下载中';
      case DownloadStatus.success: return '已完成';
      case DownloadStatus.failed: return '失败';
      case DownloadStatus.paused: return '已暂停';
    }
  }
}
