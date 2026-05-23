import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import '../utils/api_client.dart';
import '../models/share_model.dart';

class SharePage extends StatefulWidget {
  const SharePage({super.key});

  @override
  State<SharePage> createState() => _SharePageState();
}

class _SharePageState extends State<SharePage> {
  final List<ShareModel> _shares = [];
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
    try {
      final response = await ApiClient().get('/ajax.php', params: {'act': 'share_list'});
      if (response.data['code'] == 0) {
        _shares.clear();
        final shares = (response.data['shares'] as List);
        for (final s in shares) {
          final shareData = Map<String, dynamic>.from(s);
          if (shareData['file_name'] != null) {
            shareData['file'] = {
              'id': shareData['file_id'] ?? 0,
              'name': shareData['file_name'] ?? '未知文件',
              'size': shareData['file_size'] ?? 0,
              'hash': shareData['file_hash'] ?? '',
              'type': shareData['file_type'] ?? '',
            };
          }
          _shares.add(ShareModel.fromJson(shareData));
        }
      }
    } catch (e) {
      // ignore
    }
    setState(() => _isLoading = false);
  }

  void _showCreateShareDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('创建分享链接'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: '有效期',
                border: OutlineInputBorder(),
              ),
              value: 0,
              items: const [
                DropdownMenuItem(value: 0, child: Text('永久有效')),
                DropdownMenuItem(value: 1, child: Text('7天')),
                DropdownMenuItem(value: 2, child: Text('30天')),
              ],
              onChanged: (_) {},
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('提取码'),
              value: true,
              onChanged: (_) {},
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('创建')),
        ],
      ),
    );
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
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _shares.length,
                  itemBuilder: (context, index) {
                    final share = _shares[index];
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
                                        '/s/${share.surl}',
                                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy, size: 20),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: '/s/${share.surl}'));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('链接已复制'), duration: Duration(seconds: 1)),
                                    );
                                  },
                                ),
                              ],
                            ),
                            if (share.hasPassword)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text('提取码: ${share.pwd}', style: TextStyle(color: Colors.grey[600])),
                              ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.timer, size: 16, color: share.isExpired ? Colors.red : Colors.green),
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
    );
  }
}
