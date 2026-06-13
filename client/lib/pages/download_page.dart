import 'package:flutter/material.dart';
import '../utils/download_manager.dart';

class DownloadPage extends StatefulWidget {
  const DownloadPage({super.key});

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  final DownloadManager _manager = DownloadManager();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('下载管理'),
        actions: [
          if (_manager.completedTasks.isNotEmpty)
            TextButton(onPressed: _manager.clearCompleted, child: const Text('清除已完成')),
          if (_manager.tasks.isNotEmpty)
            TextButton(
              onPressed: _manager.clearAll,
              child: const Text('清空', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _manager,
        builder: (context, _) {
          if (_manager.tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.download, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('暂无下载任务', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('在文件列表中选择文件下载', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: _manager.tasks.length,
            itemBuilder: (context, index) {
              final task = _manager.tasks[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: Icon(_getStatusIcon(task.status), color: _getStatusColor(task.status)),
                  title: Text(task.file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (task.status == DownloadStatus.downloading)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: LinearProgressIndicator(value: task.progress),
                        ),
                      if (task.error != null)
                        Text(task.error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        task.status == DownloadStatus.downloading
                            ? '${(task.progress * 100).toStringAsFixed(0)}%'
                            : _getStatusText(task.status),
                        style: TextStyle(
                          color: _getStatusColor(task.status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (task.status == DownloadStatus.downloading) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.cancel, size: 20),
                          onPressed: () => _manager.cancelDownload(task.id),
                          tooltip: '取消',
                        ),
                      ] else if (task.status == DownloadStatus.completed) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.folder_open, size: 20),
                          onPressed: () => _manager.openFile(task),
                          tooltip: '打开',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: () => _manager.removeTask(task.id),
                          tooltip: '删除',
                        ),
                      ] else ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.refresh, size: 20),
                          onPressed: () => _manager.startDownload(task.file),
                          tooltip: '重试',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: () => _manager.removeTask(task.id),
                          tooltip: '删除',
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _getStatusIcon(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.queued:
        return Icons.hourglass_empty;
      case DownloadStatus.downloading:
        return Icons.download;
      case DownloadStatus.completed:
        return Icons.check_circle;
      case DownloadStatus.failed:
        return Icons.error;
      case DownloadStatus.cancelled:
        return Icons.cancel;
    }
  }

  Color _getStatusColor(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.queued:
        return Colors.grey;
      case DownloadStatus.downloading:
        return Colors.blue;
      case DownloadStatus.completed:
        return Colors.green;
      case DownloadStatus.failed:
        return Colors.red;
      case DownloadStatus.cancelled:
        return Colors.orange;
    }
  }

  String _getStatusText(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.queued:
        return '等待中';
      case DownloadStatus.downloading:
        return '下载中';
      case DownloadStatus.completed:
        return '已完成';
      case DownloadStatus.failed:
        return '失败';
      case DownloadStatus.cancelled:
        return '已取消';
    }
  }
}
