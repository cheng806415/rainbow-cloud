import 'package:flutter/material.dart';
import '../../models/file_model.dart';
import '../../utils/api_client.dart';
import '../../utils/app_logger.dart';

/// 压缩包预览 (结构浏览)
class ArchivePreview extends StatefulWidget {
  final FileModel file;
  const ArchivePreview({super.key, required this.file});

  @override
  State<ArchivePreview> createState() => _ArchivePreviewState();
}

class _ArchivePreviewState extends State<ArchivePreview> {
  Map<String, dynamic>? _info;
  List<Map<String, dynamic>>? _list;
  bool _isLoading = true;
  String? _error;
  String? _expandingPath;
  Map<String, List<Map<String, dynamic>>> _childCache = {};

  @override
  void initState() {
    super.initState();
    _loadRoot();
  }

  Future<void> _loadRoot() async {
    try {
      final data = await ApiClient().getArchiveList(widget.file.hash);
      if (!mounted) return;
      if (data != null && data['code'] == 0) {
        setState(() {
          _info = data;
          _list = (data['list'] as List).cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = data?['msg'] ?? '无法读取压缩包结构';
        });
      }
    } catch (e) {
      AppLogger().e('ArchivePreview', 'load error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = '读取失败: $e';
        });
      }
    }
  }

  Future<void> _loadChild(String path) async {
    if (_childCache.containsKey(path)) return;
    try {
      final response = await ApiClient().dio.get(
        '/ajax.php',
        queryParameters: {'act': 'archive_list', 'hash': widget.file.hash, 'path': path},
      );
      final data = ApiClient().parseResponse(response);
      if (data['code'] == 0) {
        _childCache[path] = (data['list'] as List).cast<Map<String, dynamic>>();
        if (mounted) setState(() {});
      }
    } catch (e) {
      AppLogger().e('ArchivePreview', 'load child $path error: $e');
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  IconData _getFileIcon(String name) {
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    switch (ext) {
      case 'png': case 'jpg': case 'jpeg': case 'gif': case 'bmp': case 'webp': case 'svg':
        return Icons.image;
      case 'mp3': case 'wav': case 'ogg': case 'flac': case 'aac':
        return Icons.audiotrack;
      case 'mp4': case 'avi': case 'mkv': case 'mov': case 'webm':
        return Icons.videocam;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc': case 'docx':
        return Icons.description;
      case 'xls': case 'xlsx':
        return Icons.table_chart;
      case 'txt': case 'md': case 'log':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _displayName(String name) {
    final parts = name.split('/').where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return name;
    return parts.last;
  }

  int _depth(String name) {
    return '/'.allMatches(name).length;
  }

  Widget _buildItem(Map<String, dynamic> item) {
    final name = item['name'] as String;
    final isDir = item['is_dir'] == true;
    final size = (item['size'] as num?)?.toInt() ?? 0;
    final displayName = _displayName(name);
    final depth = _depth(name);
    final expanded = _expandingPath == name;

    return Column(
      children: [
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.only(left: 16.0 + depth * 16.0, right: 16),
          leading: Icon(
            isDir
                ? (expanded ? Icons.folder_open : Icons.folder)
                : _getFileIcon(displayName),
            size: 20,
            color: isDir ? Colors.amber.shade700 : Colors.grey.shade600,
          ),
          title: Text(displayName, style: const TextStyle(fontSize: 13)),
          trailing: isDir
              ? null
              : Text(_formatBytes(size), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          onTap: isDir
              ? () async {
                  if (expanded) {
                    setState(() => _expandingPath = null);
                  } else {
                    setState(() => _expandingPath = name);
                    await _loadChild(name);
                  }
                }
              : null,
        ),
        if (isDir && expanded && _childCache.containsKey(name))
          ...(_childCache[name] ?? [])
              .map((child) => _buildItem(child))
              .toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!),
          ],
        ),
      );
    }
    final list = _list ?? [];
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              Icon(Icons.folder_zip, size: 40, color: Colors.orange.shade400),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _info?['name'] ?? widget.file.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(_info?['archive_type'] ?? 'zip').toString().toUpperCase()} | '
                      '解压后: ${_formatBytes((_info?['total_size'] as num?)?.toInt() ?? 0)} | '
                      '${_info?['file_count'] ?? 0} 文件, ${_info?['dir_count'] ?? 0} 文件夹',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? const Center(child: Text('压缩包为空'))
              : ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, index) => _buildItem(list[index]),
                ),
        ),
      ],
    );
  }
}
