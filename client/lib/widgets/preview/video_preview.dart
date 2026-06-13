import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../models/file_model.dart';
import '../../utils/api_client.dart';
import '../../utils/app_logger.dart';

/// 视频预览
/// - 全屏切换
/// - 倍速切换 (0.5x-2x)
/// - 自动播放
/// - 错误处理
class VideoPreview extends StatefulWidget {
  final FileModel file;
  const VideoPreview({super.key, required this.file});

  @override
  State<VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<VideoPreview> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _error;
  double _speed = 1.0;

  static const List<double> _speedOptions = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      final url = ApiClient().getFileUrl(widget.file);
      AppLogger().i('VideoPreview', 'load $url');
      _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
      await _videoController!.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        showControls: true,
        allowFullScreen: true,
        allowMuting: true,
        allowPlaybackSpeedChanging: false, // 我们用自定义
        progressIndicatorDelay: const Duration(milliseconds: 200),
        materialProgressColors: ChewieProgressColors(
          playedColor: Theme.of(context).colorScheme.primary,
          handleColor: Theme.of(context).colorScheme.primary,
          bufferedColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          backgroundColor: Colors.grey.shade700,
        ),
      );
      _videoController!.addListener(_onVideoState);
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      AppLogger().e('VideoPreview', 'init error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = '视频加载失败: $e';
        });
      }
    }
  }

  void _onVideoState() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _videoController?.removeListener(_onVideoState);
    _videoController?.dispose();
    _chewieController?.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('视频加载中...'),
            const SizedBox(height: 8),
            Text(
              widget.file.formattedSize,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(_error!, textAlign: TextAlign.center),
            ),
          ],
        ),
      );
    }
    if (_chewieController == null) {
      return const Center(child: Text('播放器初始化失败'));
    }
    return Stack(
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: Chewie(controller: _chewieController!),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Material(
            color: Colors.black54,
            shape: const CircleBorder(),
            child: PopupMenuButton<double>(
              tooltip: '倍速',
              icon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  '${_speed}x',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              onSelected: (s) async {
                await _videoController?.setPlaybackSpeed(s);
                if (mounted) setState(() => _speed = s);
              },
              itemBuilder: (context) => _speedOptions
                  .map((s) => PopupMenuItem(
                        value: s,
                        child: Row(
                          children: [
                            if (s == _speed) const Icon(Icons.check, size: 16) else const SizedBox(width: 16),
                            const SizedBox(width: 8),
                            Text('${s}x'),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}
