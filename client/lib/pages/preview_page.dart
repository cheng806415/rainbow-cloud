import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../models/file_model.dart';
import '../utils/api_client.dart';
import '../utils/app_logger.dart';

class PreviewPage extends StatefulWidget {
  final FileModel file;
  const PreviewPage({super.key, required this.file});

  @override
  State<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>>? _archiveList;
  Map<String, dynamic>? _archiveInfo;

  @override
  void initState() {
    super.initState();
    if (widget.file.isVideo) {
      _initVideo();
    } else if (widget.file.isArchive) {
      _initArchive();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _initVideo() async {
    try {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(_getFileUrl()),
      );
      await _videoController!.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        showControls: true,
      );
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = '视频加载失败: $e';
      });
    }
  }

  Future<void> _initArchive() async {
    try {
      final data = await ApiClient().getArchiveList(widget.file.hash);
      if (data != null && data['code'] == 0) {
        setState(() {
          _archiveInfo = data;
          _archiveList = (data['list'] as List).cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = data?['msg'] ?? '无法读取压缩包结构';
        });
      }
    } catch (e) {
      AppLogger().e('Preview', 'archive load error: $e');
      setState(() {
        _isLoading = false;
        _error = '读取压缩包结构失败: $e';
      });
    }
  }

  String _getFileUrl() {
    return '${_getBaseUrl()}/view.php/${widget.file.hash}.${widget.file.type ?? ''}';
  }

  String _getDownloadUrl() {
    return '${_getBaseUrl()}/down.php/${widget.file.hash}.${widget.file.type ?? ''}';
  }

  String _getBaseUrl() {
    // We'll get this from context in a real implementation
    return 'https://pan.example.com';
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.file.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('下载链接: ${_getDownloadUrl()}')),
              );
            },
            tooltip: '下载',
          ),
        ],
      ),
      body: _buildPreview(),
    );
  }

  Widget _buildPreview() {
    if (widget.file.isImage) {
      return PhotoView(
        imageProvider: NetworkImage(_getFileUrl()),
        loadingBuilder: (context, event) {
          final total = event?.expectedTotalBytes;
          final loaded = event?.cumulativeBytesLoaded;
          String percentText = '加载中...';
          if (total != null && loaded != null) {
            percentText = '加载中... ${(loaded / total * 100).toStringAsFixed(0)}%';
          }
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(percentText),
              ],
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildErrorView('图片加载失败'),
      );
    }

    if (widget.file.isVideo) {
      if (_isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (_error != null) {
        return _buildErrorView(_error!);
      }
      if (_chewieController != null) {
        return Chewie(controller: _chewieController!);
      }
      return _buildErrorView('视频播放器初始化失败');
    }

    if (widget.file.isAudio) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.audiotrack, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(widget.file.name, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(widget.file.formattedSize),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.play_arrow),
              label: const Text('播放'),
            ),
          ],
        ),
      );
    }

    if (widget.file.isPdf) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.picture_as_pdf, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(widget.file.name),
            const SizedBox(height: 8),
            Text(widget.file.formattedSize),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.open_in_new),
              label: const Text('在浏览器中打开'),
            ),
          ],
        ),
      );
    }

    if (widget.file.isArchive) {
      if (_isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (_error != null) {
        return _buildErrorView(_error!);
      }
      return _buildArchiveView();
    }

    return _buildErrorView('不支持预览该文件格式');
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(message),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.download),
            label: const Text('下载文件'),
          ),
        ],
      ),
    );
  }

  Widget _buildArchiveView() {
    final info = _archiveInfo!;
    final list = _archiveList!;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              Icon(Icons.folder_zip, size: 40, color: Colors.orange[400]),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(info['name'] ?? widget.file.name, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      '${info['archive_type'].toString().toUpperCase()} | '
                      '解压后: ${_formatBytes(info['total_size'] ?? 0)} | '
                      '${info['file_count']} 个文件, ${info['dir_count']} 个文件夹',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              final name = item['name'] as String;
              final isDir = item['is_dir'] == true;
              final size = item['size'] as int? ?? 0;
              final depth = '/'.allMatches(name).length;
              final displayName = name.split('/').last.isNotEmpty
                  ? name.split('/').last
                  : name.split('/').where((s) => s.isNotEmpty).last + '/';
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.only(left: 16.0 + depth * 16.0, right: 16),
                leading: Icon(
                  isDir ? Icons.folder : _getFileIcon(displayName),
                  size: 20,
                  color: isDir ? Colors.orange[400] : Colors.grey[500],
                ),
                title: Text(displayName, style: const TextStyle(fontSize: 13)),
                trailing: isDir
                    ? null
                    : Text(_formatBytes(size), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              );
            },
          ),
        ),
      ],
    );
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
      case 'zip': case 'rar': case '7z': case 'tar': case 'gz':
        return Icons.folder_zip;
      case 'txt': case 'md': case 'log':
        return Icons.text_snippets;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
