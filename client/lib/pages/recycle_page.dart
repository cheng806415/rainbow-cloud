import 'package:flutter/material.dart';
import '../models/file_model.dart';
import '../utils/api_client.dart';

class RecyclePage extends StatefulWidget {
  const RecyclePage({super.key});

  @override
  State<RecyclePage> createState() => _RecyclePageState();
}

class _RecyclePageState extends State<RecyclePage> {
  List<FileModel> _deletedFiles = [];
  bool _isLoading = true;
  String? _error;
  bool _isBatchOperating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDeletedFiles();
    });
  }

  Future<void> _loadDeletedFiles() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final files = await ApiClient().loadRecycleList();
      if (!mounted) return;
      setState(() {
        _deletedFiles = files;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = '加载失败: $e';
      });
    }
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
    if (confirmed != true) return;

    final ok = await ApiClient().restoreFile(file.hash);
    if (!mounted) return;
    if (ok) {
      setState(() => _deletedFiles.removeWhere((f) => f.hash == file.hash));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('恢复成功'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('恢复失败'), backgroundColor: Colors.red),
      );
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
    if (confirmed != true) return;

    final ok = await ApiClient().permanentDelete(file.hash);
    if (!mounted) return;
    if (ok) {
      setState(() => _deletedFiles.removeWhere((f) => f.hash == file.hash));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已彻底删除'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('删除失败'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空回收站'),
        content: const Text('确定要彻底删除回收站中所有文件吗？此操作不可恢复！'),
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
    if (confirmed != true) return;
    if (_deletedFiles.isEmpty) return;

    setState(() => _isBatchOperating = true);

    int success = 0;
    int failed = 0;
    final errors = <String>[];
    for (final file in List.of(_deletedFiles)) {
      final ok = await ApiClient().permanentDelete(file.hash);
      if (ok) {
        success++;
        if (mounted) {
          setState(() => _deletedFiles.removeWhere((f) => f.hash == file.hash));
        }
      } else {
        failed++;
        errors.add(file.name);
      }
    }

    if (!mounted) return;
    setState(() => _isBatchOperating = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(failed == 0
            ? '已清空,共删除 $success 个文件'
            : '完成:成功 $success,失败 $failed${errors.isNotEmpty ? '\n失败: ${errors.take(3).join(", ")}${errors.length > 3 ? "..." : ""}' : ''}'),
        backgroundColor: failed == 0 ? Colors.green : Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('回收站'),
        actions: [
          if (_deletedFiles.isNotEmpty && !_isBatchOperating)
            TextButton(
              onPressed: _clearAll,
              child: const Text('清空回收站', style: TextStyle(color: Colors.red)),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadDeletedFiles,
            tooltip: '刷新',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isBatchOperating
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('正在清理...'),
                    ],
                  ),
                )
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                          const SizedBox(height: 16),
                          Text(_error!),
                          const SizedBox(height: 16),
                          FilledButton(onPressed: _loadDeletedFiles, child: const Text('重试')),
                        ],
                      ),
                    )
                  : _deletedFiles.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.delete_outline, size: 80, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text('回收站为空', style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 8),
                              const Text('删除的文件将出现在这里',
                                  style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadDeletedFiles,
                          child: ListView.builder(
                            itemCount: _deletedFiles.length,
                            itemBuilder: (context, index) {
                              final file = _deletedFiles[index];
                              return ListTile(
                                leading: Icon(_getFileIcon(file), color: _getFileColor(file)),
                                title: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                                subtitle: Text(
                                  '${file.formattedSize} · 删除于 ${file.deletedTime ?? ''}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
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
