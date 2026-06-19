import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import '../../models/file_model.dart';
import '../../utils/api_client.dart';
import '../../utils/app_logger.dart';

/// PDF 预览
/// - 自动下载缓存 (避免重复下载)
/// - 支持分页/缩放/跳转
/// - 支持全屏查看
class PdfPreview extends StatefulWidget {
  final FileModel file;
  const PdfPreview({super.key, required this.file});

  @override
  State<PdfPreview> createState() => _PdfPreviewState();
}

class _PdfPreviewState extends State<PdfPreview> {
  String? _localPath;
  int _totalPages = 0;
  int _currentPage = 0;
  bool _isReady = false;
  String? _error;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _downloadPdf();
  }

  Future<void> _downloadPdf() async {
    try {
      final url = ApiClient().getFileUrl(widget.file);
      AppLogger().i('PdfPreview', 'downloading $url');

      final cacheDir = await getTemporaryDirectory();
      final file = File('${cacheDir.path}/${widget.file.hash}.pdf');

      if (await file.exists() && await file.length() > 0) {
        AppLogger().i('PdfPreview', 'using cache: ${file.path}');
        if (!mounted) return;
        setState(() {
          _localPath = file.path;
          _isReady = true;
        });
        return;
      }

      final dio = Dio();
      await dio.download(
        url,
        file.path,
        options: Options(
          headers: {
            'Referer': ApiClient().baseUrl + '/',
          },
        ),
        onReceiveProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() => _progress = received / total);
          }
        },
      );
      if (!mounted) return;
      setState(() {
        _localPath = file.path;
        _isReady = true;
      });
    } catch (e) {
      AppLogger().e('PdfPreview', 'download error: $e');
      if (mounted) setState(() => _error = 'PDF 下载失败: $e');
    }
  }

  void _enterFullscreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _PdfFullscreenPage(
          filePath: _localPath!,
          fileName: widget.file.name,
          initialPage: _currentPage,
          totalPages: _totalPages,
        ),
      ),
    );
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
    if (!_isReady || _localPath == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('PDF 加载中... ${(_progress * 100).toStringAsFixed(0)}%'),
          ],
        ),
      );
    }
    return Stack(
      children: [
        PDFView(
          filePath: _localPath,
          enableSwipe: true,
          swipeHorizontal: false,
          autoSpacing: true,
          pageFling: true,
          pageSnap: true,
          fitPolicy: FitPolicy.BOTH,
          preventLinkNavigation: false,
          onRender: (pages) {
            if (!mounted) return;
            setState(() {
              _totalPages = pages ?? 0;
              _currentPage = 1;
            });
          },
          onError: (error) {
            if (!mounted) return;
            setState(() => _error = 'PDF 渲染失败: $error');
          },
          onPageError: (page, error) {
            AppLogger().w('PdfPreview', 'page $page error: $error');
          },
          onPageChanged: (page, total) {
            if (!mounted) return;
            setState(() {
              _currentPage = (page ?? 0) + 1;
              _totalPages = total ?? _totalPages;
            });
          },
        ),
        // 全屏按钮
        Positioned(
          top: 8,
          right: 8,
          child: Material(
            color: Colors.white70,
            shape: const CircleBorder(),
            child: IconButton(
              icon: const Icon(Icons.fullscreen, size: 22),
              tooltip: '全屏查看',
              onPressed: _enterFullscreen,
            ),
          ),
        ),
        if (_totalPages > 0)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_currentPage / $_totalPages',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// PDF 全屏查看页面
class _PdfFullscreenPage extends StatefulWidget {
  final String filePath;
  final String fileName;
  final int initialPage;
  final int totalPages;

  const _PdfFullscreenPage({
    required this.filePath,
    required this.fileName,
    required this.initialPage,
    required this.totalPages,
  });

  @override
  State<_PdfFullscreenPage> createState() => _PdfFullscreenPageState();
}

class _PdfFullscreenPageState extends State<_PdfFullscreenPage> {
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        title: Text(
          widget.fileName,
          style: const TextStyle(fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.fullscreen_exit),
            tooltip: '退出全屏',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: PDFView(
        filePath: widget.filePath,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: true,
        pageFling: true,
        pageSnap: true,
        fitPolicy: FitPolicy.BOTH,
        preventLinkNavigation: false,
        defaultPage: widget.initialPage - 1,
        onRender: (pages) {
          if (!mounted) return;
          setState(() {});
        },
        onPageChanged: (page, total) {
          if (!mounted) return;
          setState(() => _currentPage = (page ?? 0) + 1);
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(color: Colors.black87),
        child: Center(
          child: Text(
            '$_currentPage / ${widget.totalPages}',
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
      ),
    );
  }
}
