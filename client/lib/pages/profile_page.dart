import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'login_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDesktop = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () => themeProvider.toggleTheme(),
            tooltip: '切换主题',
          ),
        ],
      ),
      body: isDesktop
          ? SingleChildScrollView(
              child: Center(
                child: SizedBox(
                  width: 600,
                  child: _buildContent(context, authProvider),
                ),
              ),
            )
          : SingleChildScrollView(
              child: _buildContent(context, authProvider),
            ),
    );
  }

  Widget _buildContent(BuildContext context, AuthProvider authProvider) {
    return Column(
      children: [
        _buildHeader(context, authProvider),
        const Divider(),
        _buildStorageCard(context, authProvider),
        const SizedBox(height: 16),
        _buildMenuList(context, authProvider),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, AuthProvider authProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white.withOpacity(0.3),
            child: authProvider.avatar.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      '${authProvider.serverUrl}/${authProvider.avatar}',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 40, color: Colors.white),
                    ),
                  )
                : const Icon(Icons.person, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            authProvider.nickname,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              authProvider.level > 0 ? '高级用户' : '普通用户',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageCard(BuildContext context, AuthProvider authProvider) {
    final used = authProvider.storageUsed;
    final quota = authProvider.storageQuota;
    final percent = quota > 0 ? (used / quota * 100).clamp(0.0, 100.0) : 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.storage),
                const SizedBox(width: 8),
                Text('存储空间', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: percent / 100,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatBytes(used)),
                Text(_formatBytes(quota)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuList(BuildContext context, AuthProvider authProvider) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          _buildMenuItem(
            context,
            icon: Icons.account_circle,
            title: '修改昵称',
            onTap: () => _showEditNickname(context, authProvider),
          ),
          if (authProvider.userInfo['username'] != null)
            _buildMenuItem(
              context,
              icon: Icons.lock,
              title: '修改密码',
              onTap: () => _showChangePassword(context, authProvider),
            ),
          _buildMenuItem(
            context,
            icon: Icons.http,
            title: '服务器地址',
            subtitle: authProvider.serverUrl,
            onTap: () => _showEditServerUrl(context, authProvider),
          ),
          _buildMenuItem(
            context,
            icon: Icons.info,
            title: '关于',
            subtitle: '彩虹网盘客户端 v1.0.0',
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('退出登录', style: TextStyle(color: Colors.red)),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('确认退出'),
                  content: const Text('确定要退出登录吗？'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
                    FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('退出')),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                await authProvider.logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis) : null,
      trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
      onTap: onTap,
    );
  }

  void _showEditNickname(BuildContext context, AuthProvider authProvider) {
    final controller = TextEditingController(text: authProvider.nickname);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改昵称'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: '昵称', border: OutlineInputBorder()),
          maxLength: 20,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('昵称修改成功')),
              );
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showChangePassword(BuildContext context, AuthProvider authProvider) {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改密码'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldCtrl,
              decoration: const InputDecoration(labelText: '当前密码', border: OutlineInputBorder()),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newCtrl,
              decoration: const InputDecoration(labelText: '新密码', border: OutlineInputBorder()),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('确认')),
        ],
      ),
    );
  }

  void _showEditServerUrl(BuildContext context, AuthProvider authProvider) {
    final controller = TextEditingController(text: authProvider.serverUrl);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置服务器地址'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '服务器地址',
            hintText: 'https://pan.example.com',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
            onPressed: () async {
              await authProvider.setServerUrl(controller.text.trim());
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
