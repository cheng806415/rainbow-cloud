import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/file_model.dart';
import '../../utils/api_client.dart';
import '../../utils/app_logger.dart';

/// 通用 WebView 预览组件
/// 用于 macOS 等不支持原生预览插件的平台，
/// 回退到服务器端 view.php 或外部在线预览服务
class WebViewPreview extends StatefulWidget {
  final FileModel file;
  final String? title;

  const WebViewPreview({
    super.key,
    required this.file,
    this.title,
  });

  @override
  State<WebViewPreview> createState() => _WebViewPreviewState();
}

class _WebViewPreviewState extends State<WebViewPreview> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  String _buildViewerUrl() {
    final baseUrl = ApiClient().baseUrl;
    final fileUrl = ApiClient().getFileUrl(widget.file);
    final type = (widget.file.type ?? '').toLowerCase();

    // PDF 使用服务器端 pdfview.php
    if (type == 'pdf') {
      return '$baseUrl/pdfview.php?hash=${widget.file.hash}';
    }

    // Office 文档使用 Microsoft Office Online Viewer
    // 使用 view.php 而非 down.php，因为 Office Online Viewer 无法携带认证 Cookie
    if (['doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'rtf', 'odt', 'ods', 'odp'].contains(type)) {
      final viewUrl = ApiClient().getFileUrl(widget.file);
      return 'https://view.officeapps.live.com/op/view.aspx?src=${Uri.encodeComponent(viewUrl)}';
    }

    // 图片使用服务器端 view.php
    if (widget.file.isImage) {
      return fileUrl;
    }

    // 其他类型回退到服务器端 view.php
    return fileUrl;
  }

  void _initWebView() {
    final url = _buildViewerUrl();
    AppLogger().i('WebViewPreview', 'loading $url for ${widget.file.name}');

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (url) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            AppLogger().w('WebViewPreview', 'web error: ${error.description}');
            if (mounted) {
              setState(() {
                _isLoading = false;
                _error = '无法加载预览 (${error.errorCode})';
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  Future<void> _openInBrowser() async {
    final url = _buildViewerUrl();
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法打开外部浏览器')),
      );
    }
  }

  void _enterFullscreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _WebviewFullscreenPage(
          url: _buildViewerUrl(),
          title: widget.title ?? widget.file.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: _openInBrowser,
                    icon: const Icon(Icons.open_in_browser),
                    label: const Text('在外部浏览器打开'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _error = null;
                        _isLoading = true;
                      });
                      _initWebView();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('重试'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading)
          const Center(child: CircularProgressIndicator()),
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
      ],
    );
  }
}

/// WebView 全屏查看页面
class _WebviewFullscreenPage extends StatefulWidget {
  final String url;
  final String title;

  const _WebviewFullscreenPage({
    required this.url,
    required this.title,
  });

  @override
  State<_WebviewFullscreenPage> createState() => _WebviewFullscreenPageState();
}

class _WebviewFullscreenPageState extends State<_WebviewFullscreenPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (url) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            AppLogger().w('WebViewFullscreen', 'web error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        title: Text(
          widget.title,
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
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
