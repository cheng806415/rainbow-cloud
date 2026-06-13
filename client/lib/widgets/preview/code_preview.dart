import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import '../../models/file_model.dart';
import '../../utils/api_client.dart';
import '../../utils/app_logger.dart';
import 'package:dio/dio.dart';

/// 文本/代码预览
/// 支持纯文本与代码高亮,自动识别语言
class CodePreview extends StatefulWidget {
  final FileModel file;
  const CodePreview({super.key, required this.file});

  @override
  State<CodePreview> createState() => _CodePreviewState();
}

class _CodePreviewState extends State<CodePreview> {
  String? _content;
  String? _error;
  bool _isLoading = true;
  bool _isDark = false;

  // 文本/代码文件类型 (没有专属预览器)
  static const Map<String, String> _extToLang = {
    'js': 'javascript', 'mjs': 'javascript', 'cjs': 'javascript',
    'ts': 'typescript', 'jsx': 'javascript', 'tsx': 'typescript',
    'py': 'python', 'rb': 'ruby', 'php': 'php', 'go': 'go',
    'java': 'java', 'kt': 'kotlin', 'swift': 'swift', 'm': 'objectivec',
    'c': 'c', 'h': 'c', 'cpp': 'cpp', 'cc': 'cpp', 'cxx': 'cpp',
    'hpp': 'cpp', 'cs': 'csharp', 'rs': 'rust', 'lua': 'lua',
    'sh': 'bash', 'bash': 'bash', 'zsh': 'bash', 'ps1': 'powershell',
    'sql': 'sql', 'xml': 'xml', 'html': 'xml', 'htm': 'xml',
    'css': 'css', 'scss': 'scss', 'less': 'less', 'sass': 'scss',
    'json': 'json', 'yaml': 'yaml', 'yml': 'yaml', 'toml': 'ini',
    'ini': 'ini', 'cfg': 'ini', 'conf': 'ini',
    'md': 'markdown', 'markdown': 'markdown',
    'dart': 'dart', 'r': 'r', 'matlab': 'matlab', 'pl': 'perl',
  };

  bool get _isCodeFile {
    final ext = (widget.file.type ?? '').toLowerCase();
    return _extToLang.containsKey(ext);
  }

  bool get _isTextFile {
    final ext = (widget.file.type ?? '').toLowerCase();
    return ['txt', 'log', 'csv', 'tsv'].contains(ext);
  }

  String get _language {
    final ext = (widget.file.type ?? '').toLowerCase();
    return _extToLang[ext] ?? 'plaintext';
  }

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    try {
      final url = ApiClient().getFileUrl(widget.file);
      AppLogger().i('CodePreview', '加载 $url');
      // 使用独立的 dio 实例发送请求 (避免消耗业务 CSRF)
      final dio = Dio();
      final response = await dio.get(
        url,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            'Accept': 'text/plain',
            'Referer': ApiClient().baseUrl + '/',
          },
          validateStatus: (s) => true,
        ),
      );
      if (response.statusCode == 200 && response.data is String) {
        // 大于 2MB 的文本/代码,截断显示防止 OOM
        String text = response.data as String;
        const maxChars = 500000; // ~500KB
        bool truncated = false;
        if (text.length > maxChars) {
          text = text.substring(0, maxChars);
          truncated = true;
        }
        if (!mounted) return;
        setState(() {
          _content = text;
          _isLoading = false;
          _error = truncated ? '文件过大,已截断显示前 ${maxChars ~/ 1000} KB' : null;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _error = '加载失败 (${response.statusCode})';
        });
      }
    } catch (e) {
      AppLogger().e('CodePreview', 'load error: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = '加载失败: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_content == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error ?? '无法读取文件内容'),
          ],
        ),
      );
    }

    if (!_isCodeFile && !_isTextFile) {
      // 不支持的格式
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            '暂不支持 ${widget.file.type ?? '此类型'} 文件预览',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildHeader(),
        if (_error != null) _buildWarning(),
        Expanded(
          child: Container(
            color: _isDark ? const Color(0xFF282C34) : Colors.white,
            child: _isCodeFile
                ? _buildCodeView()
                : _buildTextView(),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Icon(_isCodeFile ? Icons.code : Icons.text_snippet, size: 18),
          const SizedBox(width: 8),
          Text(
            _isCodeFile ? _language.toUpperCase() : 'TEXT',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, letterSpacing: 0.5),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(_isDark ? Icons.light_mode : Icons.dark_mode, size: 20),
            onPressed: () => setState(() => _isDark = !_isDark),
            tooltip: '切换主题',
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 20),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: _content ?? ''));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已复制到剪贴板'), duration: Duration(seconds: 1)),
              );
            },
            tooltip: '复制',
          ),
        ],
      ),
    );
  }

  Widget _buildWarning() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: Colors.amber.shade100,
      child: Row(
        children: [
          const Icon(Icons.warning_amber, size: 16, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_error!, style: const TextStyle(fontSize: 12, color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeView() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: HighlightView(
          _content ?? '',
          language: _language,
          theme: _isDark ? atomOneDarkTheme : githubTheme,
          padding: const EdgeInsets.all(12),
          textStyle: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildTextView() {
    final lines = (_content ?? '').split('\n');
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 行号
            Container(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(lines.length, (i) {
                  return Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: _isDark ? Colors.white60 : Colors.black54,
                      height: 1.5,
                    ),
                  );
                }),
              ),
            ),
            Container(
              width: 1,
              color: _isDark ? Colors.white24 : Colors.black12,
            ),
            const SizedBox(width: 12),
            // 文本内容
            Expanded(
              child: SelectableText(
                _content ?? '',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  height: 1.5,
                  color: _isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
