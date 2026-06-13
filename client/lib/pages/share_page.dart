import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/api_client.dart';
import '../models/file_model.dart';
import '../models/share_model.dart';

class SharePage extends StatefulWidget {
  const SharePage({super.key});

  @override
  State<SharePage> createState() => _SharePageState();
}

class _SharePageState extends State<SharePage> {
  List<ShareModel> _shares = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadShares();
    });
  }

  Future<void> _loadShares() async {
    setState(() => _isLoading = true);
    final result = await ApiClient().loadShareList();
    if (mounted) {
      setState(() {
        _shares = result;
        _isLoading = false;
      });
    }
  }

  Future<void> _showCreateShareDialog() async {
    // 加载文件列表供用户选择
    final files = await ApiClient().loadFileList();
    if (!mounted) return;
    if (files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂无可分享的文件'), backgroundColor: Colors.orange),
      );
      return;
    }

    FileModel? selected = files.first;
    int expireType = 0;
    final pwdCtrl = TextEditingController();
    bool withPwd = false;
    bool submitting = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: const Text('创建分享链接'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<FileModel>(
                      decoration: const InputDecoration(
                        labelText: '选择文件',
                        border: OutlineInputBorder(),
                      ),
                      value: selected,
                      isExpanded: true,
                      items: files.map((f) {
                        return DropdownMenuItem(
                          value: f,
                          child: Text(
                            f.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) setLocal(() => selected = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: '有效期',
                        border: OutlineInputBorder(),
                      ),
                      value: expireType,
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('永久有效')),
                        DropdownMenuItem(value: 1, child: Text('7天')),
                        DropdownMenuItem(value: 2, child: Text('30天')),
                      ],
                      onChanged: (v) {
                        if (v != null) setLocal(() => expireType = v);
                      },
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('启用提取码'),
                      contentPadding: EdgeInsets.zero,
                      value: withPwd,
                      onChanged: (v) => setLocal(() => withPwd = v),
                    ),
                    if (withPwd)
                      TextField(
                        controller: pwdCtrl,
                        decoration: const InputDecoration(
                          labelText: '提取码(留空则自动生成)',
                          border: OutlineInputBorder(),
                          helperText: '只能为字母和数字',
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting ? null : () => Navigator.pop(dialogContext),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: submitting
                      ? null
                      : () async {
                          if (selected == null) return;
                          setLocal(() => submitting = true);
                          final pwd = withPwd ? pwdCtrl.text.trim() : null;
                          final result = await ApiClient().createShare(
                            selected!.id,
                            pwd: (pwd != null && pwd.isNotEmpty) ? pwd : null,
                            expireType: expireType,
                          );
                          if (!dialogContext.mounted) return;
                          Navigator.pop(dialogContext);
                          if (result != null && result['surl'] != null) {
                            if (mounted) {
                              _showShareResult(result['surl']!, pwd);
                              _loadShares();
                            }
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(result?['error'] ?? '创建失败'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  child: submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('创建'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showShareResult(String surl, String? pwd) {
    final link = '${ApiClient().baseUrl}/s/$surl';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('分享创建成功'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('分享链接:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            SelectableText(link),
            if (pwd != null && pwd.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('提取码: $pwd', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: '$link${pwd != null && pwd.isNotEmpty ? ' 提取码:$pwd' : ''}'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已复制到剪贴板'), duration: Duration(seconds: 1)),
              );
            },
            child: const Text('复制全部'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteShare(ShareModel share) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除分享'),
        content: Text('确定要删除分享 "${share.file?.name ?? share.surl}" 吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final ok = await ApiClient().deleteShare(share.surl);
    if (!mounted) return;
    if (ok) {
      setState(() => _shares.removeWhere((s) => s.surl == share.surl));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已删除'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('删除失败'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的分享'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateShareDialog,
            tooltip: '创建分享',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadShares,
            tooltip: '刷新',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _shares.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.share_outlined, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('暂无分享', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      const Text('点击右上角 + 创建分享链接',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadShares,
                  child: ListView.builder(
                    itemCount: _shares.length,
                    itemBuilder: (context, index) {
                      final share = _shares[index];
                      final link = '${ApiClient().baseUrl}/s/${share.surl}';
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.link, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          share.file?.name ?? '/s/${share.surl}',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          link,
                                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy, size: 20),
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: link));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('链接已复制'), duration: Duration(seconds: 1)),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                    onPressed: () => _deleteShare(share),
                                    tooltip: '删除',
                                  ),
                                ],
                              ),
                              if (share.hasPassword)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text('提取码: ${share.pwd}',
                                      style: TextStyle(color: Colors.grey[600])),
                                ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.timer,
                                      size: 16, color: share.isExpired ? Colors.red : Colors.green),
                                  const SizedBox(width: 4),
                                  Text(
                                    share.expireLabel,
                                    style: TextStyle(
                                      color: share.isExpired ? Colors.red : Colors.green,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text('浏览 ${share.viewCount} | 下载 ${share.downloadCount}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                ],
                              ),
                              if (share.addtime != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text('创建于 ${share.addtime}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
