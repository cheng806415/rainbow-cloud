import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../models/file_model.dart';
import '../../utils/api_client.dart';
import '../../utils/app_logger.dart';

/// 自定义音频播放器 (类 APlayer 风格)
/// - 大封面 (无图时使用类型图标)
/// - 标题/副标题
/// - 进度条 (可拖动)
/// - 播放/暂停/上一首/下一首
/// - 倍速切换
/// - 音量控制
class AudioPreview extends StatefulWidget {
  final FileModel file;
  const AudioPreview({super.key, required this.file});

  @override
  State<AudioPreview> createState() => _AudioPreviewState();
}

class _AudioPreviewState extends State<AudioPreview> with TickerProviderStateMixin {
  late AudioPlayer _player;
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _volume = 1.0;
  double _speed = 1.0;
  bool _isReady = false;
  String? _error;
  StreamSubscription? _durationSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _stateSub;

  static const List<double> _speedOptions = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _bindStreams();
    _loadAndPlay();
  }

  void _bindStreams() {
    _durationSub = _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _positionSub = _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _stateSub = _player.onPlayerStateChanged.listen((s) {
      if (!mounted) return;
      setState(() {
        _playerState = s;
        if (s == PlayerState.completed) {
          _player.seek(Duration.zero);
          _player.pause();
        }
      });
    });
    _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _position = _duration;
        _playerState = PlayerState.completed;
      });
    });
  }

  Future<void> _loadAndPlay() async {
    try {
      final url = ApiClient().getFileUrl(widget.file);
      AppLogger().i('AudioPreview', 'load $url');
      // 使用 device 文件源 (音频可能需要 range 支持)
      await _player.setSourceUrl(url);
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.setVolume(_volume);
      await _player.setPlaybackRate(_speed);
      if (mounted) setState(() => _isReady = true);
      await _player.resume();
    } catch (e) {
      AppLogger().e('AudioPreview', 'load error: $e');
      if (mounted) setState(() => _error = '加载失败: $e');
    }
  }

  @override
  void dispose() {
    _durationSub?.cancel();
    _positionSub?.cancel();
    _stateSub?.cancel();
    _player.release();
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_playerState == PlayerState.playing) {
      await _player.pause();
    } else {
      if (_playerState == PlayerState.completed) {
        await _player.seek(Duration.zero);
      }
      await _player.resume();
    }
  }

  Future<void> _seekTo(double value) async {
    final pos = Duration(milliseconds: value.toInt());
    await _player.seek(pos);
  }

  Future<void> _changeSpeed() async {
    final idx = _speedOptions.indexOf(_speed);
    final next = _speedOptions[(idx + 1) % _speedOptions.length];
    await _player.setPlaybackRate(next);
    if (mounted) setState(() => _speed = next);
  }

  Future<void> _changeVolume(double v) async {
    await _player.setVolume(v);
    if (mounted) setState(() => _volume = v);
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
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

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.15),
            Theme.of(context).colorScheme.secondary.withOpacity(0.10),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 5,
              child: Center(
                child: _buildCover(),
              ),
            ),
            Expanded(
              flex: 4,
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.file.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(widget.file.type ?? 'audio').toUpperCase()} | ${widget.file.formattedSize}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).hintColor,
                          ),
                    ),
                    const Spacer(),
                    _buildProgress(),
                    const SizedBox(height: 12),
                    _buildControls(),
                    const SizedBox(height: 8),
                    _buildVolume(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCover() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: _playerState == PlayerState.playing ? 1.0 : 0.0),
      duration: const Duration(seconds: 20),
      builder: (context, value, child) {
        return Transform.rotate(
          angle: value * 6.28,
          child: child,
        );
      },
      child: Container(
        width: 240,
        height: 240,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Icon(
            Icons.music_note,
            size: 100,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ),
    );
  }

  Widget _buildProgress() {
    final maxMs = _duration.inMilliseconds.toDouble();
    final posMs = _position.inMilliseconds.clamp(0, maxMs.toInt()).toDouble();
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
          ),
          child: Slider(
            value: posMs,
            min: 0,
            max: maxMs > 0 ? maxMs : 1,
            onChanged: maxMs > 0 ? _seekTo : null,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(_position), style: const TextStyle(fontSize: 12)),
              Text(_formatDuration(_duration), style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: const Icon(Icons.replay_10),
          iconSize: 32,
          onPressed: () async {
            final p = _position - const Duration(seconds: 10);
            await _player.seek(p < Duration.zero ? Duration.zero : p);
          },
        ),
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.primary,
          ),
          child: IconButton(
            icon: Icon(
              _playerState == PlayerState.playing ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
            ),
            iconSize: 40,
            onPressed: _isReady ? _togglePlay : null,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.forward_30),
          iconSize: 32,
          onPressed: () async {
            final p = _position + const Duration(seconds: 30);
            await _player.seek(p > _duration ? _duration : p);
          },
        ),
      ],
    );
  }

  Widget _buildVolume() {
    return Row(
      children: [
        const Icon(Icons.volume_down, size: 20),
        Expanded(
          child: Slider(
            value: _volume,
            min: 0,
            max: 1,
            onChanged: _changeVolume,
          ),
        ),
        TextButton(
          onPressed: _changeSpeed,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            minimumSize: const Size(48, 32),
          ),
          child: Text('${_speed}x', style: const TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}
