import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/file_model.dart';
import '../utils/api_client.dart';
import '../utils/download_manager.dart';
import 'preview_page.dart';

class FileDetailPage extends StatelessWidget {
  final FileModel file;
  const FileDetailPage({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    final canPreview = file.isImage || file.isVideo || file.isAudio || file.isPdf || file.isArchive;
    return Scaffold(
      appBar: AppBar(
        title: const Text('文件详情'),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'copy_hash', child: ListTile(
                leading: Icon(Icons.fingerprint, size: 20), title: Text('复制Hash'), contentPadding: EdgeInsets.zero,
              )),
              const PopupMenuItem(value: 'copy_link', child: ListTile(
                leading: Icon(Icons.link, size: 20), title: Text('复制下载链接'), contentPadding: EdgeInsets.zero,
              )),
            ],
            onSelected: (value) {
              if (value == 'copy_hash') {
                Clipboard.setData(ClipboardData(text: file.hash));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Hash已复制'), duration: Duration(seconds: 1)),
                );
              } else if (value == 'copy_link') {
                final url = ApiClient().getDownloadUrl(file);
                Clipboard.setData(ClipboardData(text: url));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('下载链接已复制'), duration: Duration(seconds: 1)),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFileHeader(context),
            const SizedBox(height: 24),
            _buildInfoSection(context),
            const SizedBox(height: 24),
            _buildActionButtons(context, canPreview),
          ],
        ),
      ),
    );
  }

  Widget _buildFileHeader(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _getFileColor().withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(_getFileIcon(), size: 40, color: _getFileColor()),
          ),
          const SizedBox(height: 12),
          Text(
            file.name,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${file.type?.toUpperCase() ?? '未知'} · ${file.formattedSize}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Card(
      child: Column(
        children: [
          _buildInfoRow(context, Icons.tag, '文件ID', file.id.toString()),
          const Divider(height: 1, indent: 56),
          _buildInfoRow(context, Icons.insert_drive_file, '文件名', file.name),
          const Divider(height: 1, indent: 56),
          _buildInfoRow(context, Icons.extension, '文件类型', file.type?.toUpperCase() ?? '未知'),
          const Divider(height: 1, indent: 56),
          _buildInfoRow(context, Icons.sd_card, '文件大小', file.formattedSize),
          const Divider(height: 1, indent: 56),
          _buildInfoRow(context, Icons.fingerprint, 'Hash', file.hash, copyable: true),
          const Divider(height: 1, indent: 56),
          if (file.addtime != null) ...[
            _buildInfoRow(context, Icons.schedule, '上传时间', file.addtime!),
            const Divider(height: 1, indent: 56),
          ],
          if (file.lasttime != null) ...[
            _buildInfoRow(context, Icons.update, '最后访问', file.lasttime!),
            const Divider(height: 1, indent: 56),
          ],
          _buildInfoRow(context, Icons.visibility, '访问次数', '${file.count} 次'),
          const Divider(height: 1, indent: 56),
          _buildInfoRow(context, Icons.folder, '所属文件夹', file.folderName ?? '根目录'),
          const Divider(height: 1, indent: 56),
          _buildInfoRow(context, Icons.lock, '访问密码', file.pwd ?? '无'),
          const Divider(height: 1, indent: 56),
          _buildInfoRow(context, Icons.visibility_off, '隐藏状态', file.hide ? '已隐藏' : '正常'),
          const Divider(height: 1, indent: 56),
          _buildInfoRow(context, Icons.block, '审核状态', _getBlockText()),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value, {bool copyable = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          ),
          Expanded(
            child: GestureDetector(
              onTap: copyable ? () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已复制'), duration: Duration(seconds: 1)),
                );
              } : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 14,
                        color: copyable ? Theme.of(context).colorScheme.primary : null,
                        decoration: copyable ? TextDecoration.underline : null,
                      ),
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (copyable) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.copy, size: 14, color: Theme.of(context).colorScheme.primary),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool canPreview) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canPreview)
          FilledButton.icon(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => PreviewPage(file: file),
              ));
            },
            icon: const Icon(Icons.visibility),
            label: const Text('预览文件'),
          ),
        if (canPreview) const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {
            final downloadManager = DownloadManager();
            downloadManager.startDownload(file);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('已添加下载任务: ${file.name}')),
            );
          },
          icon: const Icon(Icons.download),
          label: const Text('下载文件'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {
            final url = ApiClient().getDownloadUrl(file);
            Clipboard.setData(ClipboardData(text: url));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('下载链接已复制到剪贴板')),
            );
          },
          icon: const Icon(Icons.link),
          label: const Text('复制下载链接'),
        ),
      ],
    );
  }

  IconData _getFileIcon() {
    if (file.isImage) return Icons.image;
    if (file.isVideo) return Icons.videocam;
    if (file.isAudio) return Icons.audiotrack;
    if (file.isPdf) return Icons.picture_as_pdf;
    if (file.isArchive) return Icons.folder_zip;
    return Icons.insert_drive_file;
  }

  Color _getFileColor() {
    if (file.isImage) return Colors.pink;
    if (file.isVideo) return Colors.purple;
    if (file.isAudio) return Colors.orange;
    if (file.isPdf) return Colors.red;
    if (file.isArchive) return Colors.amber;
    return Colors.blue;
  }

  String _getBlockText() {
    switch (file.block) {
      case 0: return '正常';
      case 1: return '已屏蔽';
      default: return '状态${file.block}';
    }
  }
}
