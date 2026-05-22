import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../models/file_model.dart';

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

  @override
  void initState() {
    super.initState();
    if (widget.file.isVideo) {
      _initVideo();
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
        loadingBuilder: (context, event) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('加载中... ${(event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 1) * 100).toStringAsFixed(0)}%'),
            ],
          ),
        ),
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
}
