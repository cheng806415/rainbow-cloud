import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/api_client.dart';
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
        const SizedBox(height: 16),
        _buildUserInfoCard(context, authProvider),
        const SizedBox(height: 16),
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
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white.withValues(alpha: 0.3),
            child: authProvider.avatar.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      _resolveAvatarUrl(authProvider.avatar),
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
              color: Colors.white.withValues(alpha: 0.3),
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

  Widget _buildUserInfoCard(BuildContext context, AuthProvider authProvider) {
    final userInfo = authProvider.userInfo;
    final isDesktop = MediaQuery.of(context).size.width > 600;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: isDesktop ? 0 : 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline),
                const SizedBox(width: 8),
                Text('账号信息', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(context, '用户名', userInfo['username'] ?? '未知'),
            _buildInfoRow(context, '用户 ID', (userInfo['uid'] ?? 0).toString()),
            _buildInfoRow(context, '用户组', authProvider.level > 0 ? '高级用户' : '普通用户'),
            if (userInfo['addtime'] != null)
              _buildInfoRow(context, '注册时间', userInfo['addtime'].toString()),
            if (userInfo['lasttime'] != null)
              _buildInfoRow(context, '上次登录', userInfo['lasttime'].toString()),
            if (userInfo['allow_view'] != null)
              _buildInfoRow(context, '在线预览', (userInfo['allow_view'] ?? 1) == 1 ? '已启用' : '已禁用'),
            if (userInfo['allow_search'] != null)
              _buildInfoRow(context, '搜索功能', (userInfo['allow_search'] ?? 1) == 1 ? '已启用' : '已禁用'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageCard(BuildContext context, AuthProvider authProvider) {
    final used = authProvider.storageUsed;
    final quota = authProvider.storageQuota;
    final percent = quota > 0 ? (used / quota).clamp(0.0, 1.0) : 0.0;

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
              value: percent,
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
    bool submitting = false;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocal) => AlertDialog(
            title: const Text('修改昵称'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: '昵称', border: OutlineInputBorder()),
              maxLength: 20,
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
                        final name = controller.text.trim();
                        if (name.isEmpty) return;
                        setLocal(() => submitting = true);
                        final ok = await ApiClient().updateNickname(name);
                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        if (!context.mounted) return;
                        if (ok) {
                          await authProvider.loadUserInfo();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('昵称修改成功'), backgroundColor: Colors.green),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('昵称修改失败'), backgroundColor: Colors.red),
                          );
                        }
                      },
                child: submitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('保存'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showChangePassword(BuildContext context, AuthProvider authProvider) {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    bool submitting = false;
    String? errorText;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocal) => AlertDialog(
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
                  decoration: const InputDecoration(
                    labelText: '新密码(6-20位字母或数字)',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                if (errorText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(errorText!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ),
              ],
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
                        final oldPwd = oldCtrl.text;
                        final newPwd = newCtrl.text;
                        if (oldPwd.isEmpty || newPwd.isEmpty) {
                          setLocal(() => errorText = '请填写完整');
                          return;
                        }
                        if (newPwd.length < 6 || newPwd.length > 20) {
                          setLocal(() => errorText = '新密码长度必须在6-20位之间');
                          return;
                        }
                        if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(newPwd)) {
                          setLocal(() => errorText = '新密码只能包含字母和数字');
                          return;
                        }
                        setLocal(() {
                          submitting = true;
                          errorText = null;
                        });
                        final ok = await ApiClient().updatePassword(oldPwd, newPwd);
                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(ok ? '密码修改成功' : '密码修改失败,请检查当前密码是否正确'),
                            backgroundColor: ok ? Colors.green : Colors.red,
                          ),
                        );
                      },
                child: submitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('确认'),
              ),
            ],
          ),
        );
      },
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

  String _resolveAvatarUrl(String avatar) {
    if (avatar.isEmpty) return '';
    if (avatar.startsWith('http://') || avatar.startsWith('https://')) {
      return avatar;
    }
    final base = ApiClient().baseUrl;
    if (avatar.startsWith('./')) {
      return '$base/${avatar.substring(2)}';
    }
    if (avatar.startsWith('/')) {
      return '$base$avatar';
    }
    return '$base/$avatar';
  }
}
