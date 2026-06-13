import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/file_model.dart';
import '../../utils/api_client.dart';

/// 文件信息 + 链接管理 + 代码嵌入 (复刻网页版 file.php 的 4 个 Tab)
class FileInfoSheet extends StatefulWidget {
  final FileModel file;
  const FileInfoSheet({super.key, required this.file});

  @override
  State<FileInfoSheet> createState() => _FileInfoSheetState();
}

class _FileInfoSheetState extends State<FileInfoSheet> with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  String get _viewUrl => ApiClient().getFileUrl(widget.file);
  String get _downUrl => ApiClient().getDownloadUrl(widget.file);

  String _getHtmlCode() {
    final viewurl = _viewUrl;
    if (widget.file.isImage) {
      return '<img src="$viewurl" />';
    } else if (widget.file.isAudio) {
      return '<audio src="$viewurl" autoplay="autoplay" loop="loop" preload="auto"></audio>';
    } else if (widget.file.isVideo) {
      return '<video src="$viewurl" controls="" width="100%"></video>';
    } else {
      return '<a href="$viewurl" target="_blank">${widget.file.name}</a>';
    }
  }

  String _getIframeCode() {
    final width = widget.file.isVideo ? 800 : 407;
    final height = widget.file.isVideo ? 500 : 70;
    return '<iframe src="${ApiClient().baseUrl}/player.php?hash=${widget.file.hash}" '
        'width="$width" scrolling="no" frameborder="0" height="$height"></iframe>';
  }

  String _getUbbCode() {
    final viewurl = _viewUrl;
    if (widget.file.isImage) {
      return '[img]$viewurl[/img]';
    } else if (widget.file.isAudio) {
      return '[audio=X]$viewurl[/audio]';
    } else if (widget.file.isVideo) {
      return '[movie=320*180]$viewurl[/movie]';
    } else {
      return '[url=$viewurl]${widget.file.name}[/url]';
    }
  }

  String _getMarkdownCode() {
    final viewurl = _viewUrl;
    if (widget.file.isImage) {
      return '![${widget.file.name}]($viewurl)';
    } else {
      return '[${widget.file.name}]($viewurl)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // 拖动条
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // 标题栏
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline),
                    const SizedBox(width: 8),
                    const Text(
                      '文件信息',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              TabBar(
                controller: _tab,
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Theme.of(context).hintColor,
                tabs: const [
                  Tab(icon: Icon(Icons.link, size: 18), text: '外链'),
                  Tab(icon: Icon(Icons.code, size: 18), text: '代码'),
                  Tab(icon: Icon(Icons.info, size: 18), text: '详情'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tab,
                  children: [
                    _buildLinkTab(scrollController),
                    _buildCodeTab(scrollController),
                    _buildInfoTab(scrollController),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLinkTab(ScrollController ctrl) {
    return ListView(
      controller: ctrl,
      padding: const EdgeInsets.all(16),
      children: [
        if (widget.file.isImage || widget.file.isAudio || widget.file.isVideo || widget.file.isPdf) ...[
          _buildLinkField('预览链接', _viewUrl, canCopy: true),
          const SizedBox(height: 16),
        ],
        _buildLinkField('下载链接', _downUrl, canCopy: true),
      ],
    );
  }

  Widget _buildCodeTab(ScrollController ctrl) {
    final isMedia = widget.file.isImage || widget.file.isAudio || widget.file.isVideo;
    return ListView(
      controller: ctrl,
      padding: const EdgeInsets.all(16),
      children: [
        if (isMedia) ...[
          _buildCodeField('播放器嵌入 (iframe)', _getIframeCode()),
          const SizedBox(height: 16),
        ],
        _buildCodeField('HTML 代码', _getHtmlCode()),
        const SizedBox(height: 16),
        _buildCodeField('UBB 代码', _getUbbCode()),
        const SizedBox(height: 16),
        _buildCodeField('Markdown', _getMarkdownCode()),
      ],
    );
  }

  Widget _buildInfoTab(ScrollController ctrl) {
    final df = DateFormat('yyyy-MM-dd HH:mm:ss');
    DateTime? addTime;
    DateTime? lastTime;
    try {
      if (widget.file.addtime != null) addTime = df.parseLoose(widget.file.addtime!);
      if (widget.file.lasttime != null) lastTime = df.parseLoose(widget.file.lasttime!);
    } catch (_) {}
    return ListView(
      controller: ctrl,
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoRow(Icons.label, '文件名', widget.file.name),
        _buildInfoRow(Icons.category, '文件类型', (widget.file.type ?? '未知').toUpperCase()),
        _buildInfoRow(Icons.straighten, '文件大小', widget.file.formattedSize),
        if (widget.file.addtime != null)
          _buildInfoRow(
            Icons.upload,
            '上传时间',
            addTime != null ? df.format(addTime) : widget.file.addtime!,
          ),
        if (widget.file.lasttime != null)
          _buildInfoRow(
            Icons.access_time,
            '最近访问',
            lastTime != null ? df.format(lastTime) : widget.file.lasttime!,
          ),
        _buildInfoRow(Icons.fingerprint, '文件 Hash', widget.file.hash),
        if (widget.file.sha256 != null)
          _buildInfoRow(Icons.security, 'SHA-256', widget.file.sha256!),
        _buildInfoRow(Icons.visibility, '访问次数', '${widget.file.count}'),
        _buildInfoRow(Icons.folder, '所在文件夹', widget.file.folderName ?? '根目录'),
        if (widget.file.ip != null) _buildInfoRow(Icons.lan, '上传 IP', widget.file.ip!),
      ],
    );
  }

  Widget _buildLinkField(String label, String value, {bool canCopy = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  value,
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonalIcon(
              onPressed: canCopy
                  ? () async {
                      await Clipboard.setData(ClipboardData(text: value));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('已复制到剪贴板'), duration: Duration(seconds: 1)),
                      );
                    }
                  : null,
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('复制'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCodeField(String label, String code) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.copy, size: 16),
              tooltip: '复制代码',
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: code));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已复制到剪贴板'), duration: Duration(seconds: 1)),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F8FA),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: SelectableText(
            code,
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
