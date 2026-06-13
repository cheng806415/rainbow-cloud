import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/file_model.dart';
import '../utils/api_client.dart';
import '../utils/file_preview_resolver.dart';
import '../widgets/preview/image_preview.dart';
import '../widgets/preview/video_preview.dart';
import '../widgets/preview/audio_preview.dart';
import '../widgets/preview/pdf_preview.dart';
import '../widgets/preview/office_preview.dart';
import '../widgets/preview/code_preview.dart';
import '../widgets/preview/archive_preview.dart';
import '../widgets/preview/file_info_sheet.dart';
import '../widgets/preview/preview_bottom_bar.dart';

/// 统一预览入口
/// - 单文件模式: PreviewPage(file: file)
/// - 画廊模式 (多文件滑动, 主要用于图片): PreviewPage(files: list, initialIndex: i)
///
/// 界面与交互对齐网页版 file.php:
/// - 顶部导航: 文件名 + 操作按钮
/// - 中部: 各类文件专属预览器
/// - 底部: 操作栏 (下载/复制链接/分享/创建分享/信息)
class PreviewPage extends StatelessWidget {
  final FileModel file;
  final List<FileModel>? files;
  final int initialIndex;

  const PreviewPage({
    super.key,
    required this.file,
    this.files,
    this.initialIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    // 画廊模式 (主要针对多张图片)
    if (files != null && files!.length > 1) {
      // 过滤出图片文件
      final imageFiles = files!.where((f) => f.isImage).toList();
      if (imageFiles.length > 1) {
        // 找到当前 file 在 imageFiles 中的位置
        int idx = imageFiles.indexWhere((f) => f.hash == file.hash);
        if (idx < 0) idx = 0;
        return ImagePreview(
          files: imageFiles,
          initialIndex: idx,
        );
      }
    }

    // 单文件模式
    return _SingleFilePreview(file: file);
  }
}

class _SingleFilePreview extends StatelessWidget {
  final FileModel file;
  const _SingleFilePreview({required this.file});

  @override
  Widget build(BuildContext context) {
    final type = FilePreviewResolver.resolve(file);

    // 图片走专门的画廊组件
    if (type == PreviewType.image) {
      return ImagePreview(files: [file], initialIndex: 0);
    }

    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(type),
      bottomNavigationBar: PreviewBottomBar(file: file),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            file.name,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${(file.type ?? 'file').toUpperCase()} | ${file.formattedSize}',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => FileInfoSheet(file: file),
            );
          },
          tooltip: '文件信息',
        ),
        PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'browser') _openInBrowser(context);
            if (v == 'copy') _copyLink(context);
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'copy',
              child: Row(
                children: [Icon(Icons.copy, size: 18), SizedBox(width: 8), Text('复制链接')],
              ),
            ),
            PopupMenuItem(
              value: 'browser',
              child: Row(
                children: [Icon(Icons.open_in_browser, size: 18), SizedBox(width: 8), Text('浏览器打开')],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBody(PreviewType type) {
    switch (type) {
      case PreviewType.image:
        return const SizedBox.shrink(); // 已在外层处理
      case PreviewType.video:
        return VideoPreview(file: file);
      case PreviewType.audio:
        return AudioPreview(file: file);
      case PreviewType.pdf:
        return PdfPreview(file: file);
      case PreviewType.office:
        return OfficePreview(file: file);
      case PreviewType.code:
      case PreviewType.text:
        return CodePreview(file: file);
      case PreviewType.archive:
        return ArchivePreview(file: file);
      case PreviewType.unknown:
        return _UnsupportedView(file: file);
    }
  }

  void _openInBrowser(BuildContext context) async {
    final url = ApiClient().getFileUrl(file);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('链接: $url'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: '复制',
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: url));
          },
        ),
      ),
    );
  }

  void _copyLink(BuildContext context) async {
    final url = ApiClient().getFileUrl(file);
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('链接已复制'), duration: Duration(seconds: 1)),
    );
  }
}

class _UnsupportedView extends StatelessWidget {
  final FileModel file;
  const _UnsupportedView({required this.file});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_iconForType(file), size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              file.name,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '暂不支持 ${(file.type ?? '此类型').toUpperCase()} 文件在线预览',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download),
                  label: const Text('下载到本地'),
                ),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.open_in_browser),
                  label: const Text('复制链接'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForType(FileModel file) {
    final ext = (file.type ?? '').toLowerCase();
    if (file.isImage) return Icons.image;
    if (file.isVideo) return Icons.videocam;
    if (file.isAudio) return Icons.audiotrack;
    if (file.isPdf) return Icons.picture_as_pdf;
    if (['doc', 'docx', 'wps', 'rtf'].contains(ext)) return Icons.description;
    if (['xls', 'xlsx'].contains(ext)) return Icons.table_chart;
    if (['ppt', 'pptx'].contains(ext)) return Icons.slideshow;
    if (['zip', 'rar', '7z', 'tar', 'gz'].contains(ext)) return Icons.folder_zip;
    if (['txt', 'md', 'log'].contains(ext)) return Icons.text_snippet;
    return Icons.insert_drive_file;
  }
}
