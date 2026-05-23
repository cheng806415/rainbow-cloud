import 'package:flutter/material.dart';
import '../utils/download_manager.dart';

class DownloadPage extends StatefulWidget {
  const DownloadPage({super.key});

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  final DownloadManager _downloadManager = DownloadManager();

  @override
  void initState() {
    super.initState();
    _downloadManager.addListener(_onDownloadUpdate);
  }

  @override
  void dispose() {
    _downloadManager.removeListener(_onDownloadUpdate);
    super.dispose();
  }

  void _onDownloadUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _openFile(DownloadTask task) async {
    await _downloadManager.openFile(task);
  }

  void _clearCompleted() {
    _downloadManager.clearCompleted();
  }

  void _clearAll() {
    _downloadManager.clearAll();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('下载管理'),
        actions: [
          if (_downloadManager.tasks.any((t) => t.status == DownloadStatus.success))
            TextButton(onPressed: _clearCompleted, child: const Text('清除已完成')),
          if (_downloadManager.tasks.isNotEmpty)
            TextButton(onPressed: _clearAll, child: const Text('清空')),
        ],
      ),
      body: _downloadManager.tasks.isEmpty
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
              itemCount: _downloadManager.tasks.length,
              itemBuilder: (context, index) {
                final task = _downloadManager.tasks[index];
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
      case DownloadStatus.waiting:
        return Icons.hourglass_empty;
      case DownloadStatus.downloading:
        return Icons.download;
      case DownloadStatus.success:
        return Icons.check_circle;
      case DownloadStatus.failed:
        return Icons.error;
      case DownloadStatus.paused:
        return Icons.pause_circle;
    }
  }

  Color _getStatusColor(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.waiting:
        return Colors.grey;
      case DownloadStatus.downloading:
        return Colors.blue;
      case DownloadStatus.success:
        return Colors.green;
      case DownloadStatus.failed:
        return Colors.red;
      case DownloadStatus.paused:
        return Colors.orange;
    }
  }

  String _getStatusText(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.waiting:
        return '等待中';
      case DownloadStatus.downloading:
        return '下载中';
      case DownloadStatus.success:
        return '已完成';
      case DownloadStatus.failed:
        return '失败';
      case DownloadStatus.paused:
        return '已暂停';
    }
  }
}
