import 'package:flutter/material.dart';
import '../models/file_model.dart';
import '../utils/api_client.dart';

class RecyclePage extends StatefulWidget {
  const RecyclePage({super.key});

  @override
  State<RecyclePage> createState() => _RecyclePageState();
}

class _RecyclePageState extends State<RecyclePage> {
  final List<FileModel> _deletedFiles = [];
  bool _isLoading = true;
  Set<int> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDeletedFiles();
    });
  }

  void _loadDeletedFiles() {
    setState(() => _isLoading = true);
    // Replace with actual API call
    _deletedFiles.clear();
    _selectedIds.clear();
    setState(() => _isLoading = false);
  }

  Future<void> _restoreFile(FileModel file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('恢复文件'),
        content: Text('确定要恢复 "${file.name}" 吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('恢复')),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final token = await ApiClient().getCsrfToken();
        final response = await ApiClient().post('/ajax.php',
          queryParameters: {'act': 'restoreFile'},
          data: {'csrf_token': token, 'hash': file.hash},
        );
        if (response.data['code'] == 0) {
          _deletedFiles.remove(file);
          if (mounted) {
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('恢复成功'), backgroundColor: Colors.green),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(response.data['msg'] ?? '恢复失败'), backgroundColor: Colors.red),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('网络错误: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _permanentDelete(FileModel file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('彻底删除'),
        content: Text('确定要彻底删除 "${file.name}" 吗？此操作不可恢复！'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('彻底删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final token = await ApiClient().getCsrfToken();
        final response = await ApiClient().post('/ajax.php',
          queryParameters: {'act': 'permanentDelete'},
          data: {'csrf_token': token, 'hash': file.hash},
        );
        if (response.data['code'] == 0) {
          _deletedFiles.remove(file);
          if (mounted) {
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('已彻底删除'), backgroundColor: Colors.green),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(response.data['msg'] ?? '删除失败'), backgroundColor: Colors.red),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('网络错误: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('回收站'),
        actions: [
          if (_deletedFiles.isNotEmpty)
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('清空回收站'),
                    content: const Text('确定要彻底删除所有回收站中的文件吗？此操作不可恢复！'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
                      FilledButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // Implement batch delete
                        },
                        style: FilledButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('清空'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('清空回收站', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _deletedFiles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.delete_outline, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('回收站为空', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('删除的文件将出现在这里',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async => _loadDeletedFiles(),
                  child: ListView.builder(
                    itemCount: _deletedFiles.length,
                    itemBuilder: (context, index) {
                      final file = _deletedFiles[index];
                      final isSelected = _selectedIds.contains(file.id);

                      return ListTile(
                        leading: Icon(_getFileIcon(file), color: _getFileColor(file)),
                        title: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text('${file.formattedSize} · 删除于 ${file.deletedTime ?? ''}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _restoreFile(file),
                              icon: const Icon(Icons.restore, size: 18),
                              label: const Text('恢复'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete_forever, color: Colors.red),
                              onPressed: () => _permanentDelete(file),
                              tooltip: '彻底删除',
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  IconData _getFileIcon(FileModel file) {
    if (file.isImage) return Icons.image;
    if (file.isVideo) return Icons.videocam;
    if (file.isAudio) return Icons.audiotrack;
    if (file.isPdf) return Icons.picture_as_pdf;
    return Icons.insert_drive_file;
  }

  Color _getFileColor(FileModel file) {
    if (file.isImage) return Colors.pink;
    if (file.isVideo) return Colors.purple;
    if (file.isAudio) return Colors.orange;
    if (file.isPdf) return Colors.red;
    return Colors.blue;
  }
}
