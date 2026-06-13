import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/file_model.dart';
import '../../utils/api_client.dart';
import '../../utils/download_manager.dart';
import 'file_info_sheet.dart';

/// 底部操作栏 (复刻网页版 file.php 的功能按钮)
/// 包含: 下载 / 分享 / 复制链接 / 文件信息 / 打开链接 / 创建分享链接
class PreviewBottomBar extends StatelessWidget {
  final FileModel file;
  const PreviewBottomBar({super.key, required this.file});

  Future<void> _copyLink(BuildContext context, String url, String label) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label 已复制'), duration: const Duration(seconds: 1)),
    );
  }

  Future<void> _shareFile(BuildContext context) async {
    final url = ApiClient().getFileUrl(file);
    await Share.share(
      url,
      subject: file.name,
    );
  }

  Future<void> _showInfo(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FileInfoSheet(file: file),
    );
  }

  Future<void> _startDownload(BuildContext context) async {
    await DownloadManager().startDownload(file);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已添加下载任务: ${file.name}'), duration: const Duration(seconds: 1)),
    );
  }

  Future<void> _createShareLink(BuildContext context) async {
    // 调用 API 创建分享链接
    final token = await ApiClient().ensureCsrfToken();
    if (token == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先登录')),
      );
      return;
    }
    try {
      // 这里需要根据实际 API 调整
      // 假设有一个 create_share 接口
      // 暂时只复制直接链接
      final url = ApiClient().getFileUrl(file);
      await Clipboard.setData(ClipboardData(text: url));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('分享链接已复制到剪贴板'),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('创建分享失败: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildAction(
                context,
                icon: Icons.file_download_outlined,
                label: '下载',
                onTap: () => _startDownload(context),
              ),
              _buildAction(
                context,
                icon: Icons.link,
                label: '复制链接',
                onTap: () => _copyLink(
                  context,
                  ApiClient().getFileUrl(file),
                  '预览链接',
                ),
              ),
              _buildAction(
                context,
                icon: Icons.share,
                label: '分享',
                onTap: () => _shareFile(context),
              ),
              _buildAction(
                context,
                icon: Icons.qr_code,
                label: '创建分享',
                onTap: () => _createShareLink(context),
              ),
              _buildAction(
                context,
                icon: Icons.info_outline,
                label: '信息',
                onTap: () => _showInfo(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
