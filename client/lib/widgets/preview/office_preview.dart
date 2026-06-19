import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/file_model.dart';
import '../../utils/api_client.dart';
import '../../utils/app_logger.dart';

/// Office 文档预览
/// 使用 Microsoft Office Online Viewer (与网页版一致)
/// https://view.officeapps.live.com/op/view.aspx?src=<url>
class OfficePreview extends StatefulWidget {
  final FileModel file;
  const OfficePreview({super.key, required this.file});

  @override
  State<OfficePreview> createState() => _OfficePreviewState();
}

class _OfficePreviewState extends State<OfficePreview> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    // 使用 view.php 而非 down.php，因为 Office Online Viewer 无法携带认证 Cookie
    final viewUrl = ApiClient().getFileUrl(widget.file);
    final encoded = Uri.encodeComponent(viewUrl);
    final viewerUrl = 'https://view.officeapps.live.com/op/view.aspx?src=$encoded';
    AppLogger().i('OfficePreview', 'loading $viewerUrl');

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 10; SM-G973F) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
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
            AppLogger().w('OfficePreview', 'web error: ${error.description}');
            if (mounted) {
              setState(() {
                _isLoading = false;
                _error = '无法加载在线预览 (${error.errorCode})';
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(viewerUrl));
  }

  Future<void> _openInBrowser() async {
    final viewUrl = ApiClient().getFileUrl(widget.file);
    final encoded = Uri.encodeComponent(viewUrl);
    final viewerUrl = 'https://view.officeapps.live.com/op/view.aspx?src=$encoded';
    if (await canLaunchUrl(Uri.parse(viewerUrl))) {
      await launchUrl(Uri.parse(viewerUrl), mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法打开外部浏览器')),
      );
    }
  }

  void _enterFullscreen() {
    final viewUrl = ApiClient().getFileUrl(widget.file);
    final encoded = Uri.encodeComponent(viewUrl);
    final viewerUrl = 'https://view.officeapps.live.com/op/view.aspx?src=$encoded';
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _OfficeFullscreenPage(
          viewerUrl: viewerUrl,
          title: widget.file.name,
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
        Positioned(
          top: 8,
          right: 8,
          child: Material(
            color: Colors.white70,
            shape: const CircleBorder(),
            child: IconButton(
              icon: const Icon(Icons.open_in_browser, size: 20),
              tooltip: '在外部浏览器打开',
              onPressed: _openInBrowser,
            ),
          ),
        ),
      ],
    );
  }
}
