import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../providers/upload_provider.dart';
import '../utils/app_utils.dart';

class UploadPage extends StatelessWidget {
  const UploadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('上传文件'),
        actions: [
          Consumer<UploadProvider>(
            builder: (context, provider, _) {
              final hasCompleted = provider.tasks.any(
                (t) => t.status == UploadStatus.success || t.status == UploadStatus.exists,
              );
              return Row(
                children: [
                  if (hasCompleted)
                    TextButton(
                      onPressed: provider.clearCompleted,
                      child: const Text('清除已完成'),
                    ),
                  if (provider.tasks.isNotEmpty)
                    TextButton(
                      onPressed: () => _confirmClearAll(context, provider),
                      child: const Text('清空'),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: () => _pickFiles(context),
              icon: const Icon(Icons.upload_file),
              label: const Text('选择文件'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Consumer<UploadProvider>(
              builder: (context, provider, _) {
                if (provider.tasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_upload, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('点击上方按钮选择文件上传', style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: provider.tasks.length,
                  itemBuilder: (context, index) {
                    final task = provider.tasks[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: Icon(_getStatusIcon(task.status), color: _getStatusColor(task.status)),
                        title: Text(task.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${AppUtils.formatBytes(task.totalSize)} · ${task.message}'),
                            if (task.status == UploadStatus.uploading || task.status == UploadStatus.checking)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: LinearProgressIndicator(value: task.progress),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              (task.status == UploadStatus.uploading || task.status == UploadStatus.checking)
                                  ? '${(task.progress * 100).toStringAsFixed(0)}%'
                                  : _getStatusText(task.status),
                              style: TextStyle(
                                color: _getStatusColor(task.status),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (task.status == UploadStatus.uploading || task.status == UploadStatus.checking) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.cancel, size: 20),
                                onPressed: () => provider.cancelTask(task.id),
                                tooltip: '取消',
                              ),
                            ] else ...[
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20),
                                onPressed: () => provider.removeTask(task.id),
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
          ),
        ],
      ),
    );
  }

  Future<void> _pickFiles(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null || result.files.isEmpty) return;
    if (!context.mounted) return;
    final provider = context.read<UploadProvider>();
    for (final file in result.files) {
      if (file.path != null && File(file.path!).existsSync()) {
        provider.addFile(file.path!);
      }
    }
  }

  Future<void> _confirmClearAll(BuildContext context, UploadProvider provider) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空上传任务'),
        content: const Text('所有上传任务将被移除,正在上传的会被取消。确定吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('清空'),
          ),
        ],
      ),
    );
    if (ok == true) {
      provider.clearCompleted();
    }
  }

  IconData _getStatusIcon(UploadStatus status) {
    switch (status) {
      case UploadStatus.queued: return Icons.hourglass_empty;
      case UploadStatus.checking: return Icons.search;
      case UploadStatus.uploading: return Icons.cloud_upload;
      case UploadStatus.success: return Icons.check_circle;
      case UploadStatus.failed: return Icons.error;
      case UploadStatus.exists: return Icons.info;
    }
  }

  Color _getStatusColor(UploadStatus status) {
    switch (status) {
      case UploadStatus.queued: return Colors.grey;
      case UploadStatus.checking: return Colors.blue;
      case UploadStatus.uploading: return Colors.blue;
      case UploadStatus.success: return Colors.green;
      case UploadStatus.failed: return Colors.red;
      case UploadStatus.exists: return Colors.orange;
    }
  }

  String _getStatusText(UploadStatus status) {
    switch (status) {
      case UploadStatus.queued: return '等待';
      case UploadStatus.checking: return '检查';
      case UploadStatus.uploading: return '上传';
      case UploadStatus.success: return '成功';
      case UploadStatus.failed: return '失败';
      case UploadStatus.exists: return '已存在';
    }
  }
}
