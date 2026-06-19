import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();
  final _loginUsernameController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _regUsernameController = TextEditingController();
  final _regPasswordController = TextEditingController();
  final _regRepasswordController = TextEditingController();
  bool _isLoginLoading = false;
  bool _isRegisterLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // 注册密码一致性实时校验
    _regPasswordController.addListener(_onRegPasswordChanged);
    _regRepasswordController.addListener(_onRegPasswordChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().initServerUrl();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _regPasswordController.removeListener(_onRegPasswordChanged);
    _regRepasswordController.removeListener(_onRegPasswordChanged);
    _loginUsernameController.dispose();
    _loginPasswordController.dispose();
    _regUsernameController.dispose();
    _regPasswordController.dispose();
    _regRepasswordController.dispose();
    super.dispose();
  }

  void _onRegPasswordChanged() {
    // 触发 register form 重新校验
    _registerFormKey.currentState?.validate();
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return '请输入密码';
    if (v.length < 6 || v.length > 20) return '密码长度必须在6-20位之间';
    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(v)) return '密码只能包含字母和数字';
    return null;
  }

  String? _validateRepassword(String? v) {
    if (v == null || v.isEmpty) return '请再次输入密码';
    if (_regPasswordController.text != v) return '两次输入的密码不一致';
    return null;
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() => _isLoginLoading = true);
    final authProvider = context.read<AuthProvider>();
    final username = _loginUsernameController.text.trim();
    final password = _loginPasswordController.text;
    final result = await authProvider.login(username, password);
    setState(() => _isLoginLoading = false);
    final success = result['success'] == true;
    final message = result['message'] ?? (success ? '登录成功' : '登录失败');
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('登录成功'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _handleRegister() async {
    if (!_registerFormKey.currentState!.validate()) return;
    if (_regPasswordController.text != _regRepasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('两次输入的密码不一致'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _isRegisterLoading = true);
    final authProvider = context.read<AuthProvider>();
    final username = _regUsernameController.text.trim();
    final password = _regPasswordController.text;
    final repassword = _regRepasswordController.text;
    final result = await authProvider.register(username, password, repassword);
    setState(() => _isRegisterLoading = false);
    final success = result['success'] == true;
    final message = result['message'] ?? (success ? '注册成功，已自动登录' : '注册失败，请稍后重试');
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('注册成功，已自动登录'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 600;

    return Scaffold(
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: isDesktop ? 400 : double.infinity),
          child: Card(
            margin: isDesktop ? EdgeInsets.zero : const EdgeInsets.all(16),
            elevation: isDesktop ? 8 : 0,
            child: Padding(
              padding: EdgeInsets.all(isDesktop ? 32 : 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud, size: 64, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 8),
                  Text('彩虹网盘', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 24),
                  TabBar(
                    controller: _tabController,
                    tabs: const [Tab(text: '登录'), Tab(text: '注册')],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 280,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildLoginForm(),
                        _buildRegisterForm(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        children: [
          TextFormField(
            controller: _loginUsernameController,
            decoration: const InputDecoration(
              labelText: '用户名',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? '请输入用户名' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _loginPasswordController,
            decoration: const InputDecoration(
              labelText: '密码',
              prefixIcon: Icon(Icons.lock),
              border: OutlineInputBorder(),
            ),
            obscureText: true,
            validator: (v) => v == null || v.isEmpty ? '请输入密码' : null,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isLoginLoading ? null : _handleLogin,
              icon: _isLoginLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.login),
              label: Text(_isLoginLoading ? '登录中...' : '登 录'),
            ),
          ),
          const SizedBox(height: 12),
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return TextButton.icon(
                onPressed: () => _showEditServerUrl(context, authProvider),
                icon: const Icon(Icons.http, size: 16),
                label: Text(
                  '服务器: ${authProvider.serverUrl}',
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          ),
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

  Widget _buildRegisterForm() {
    return Form(
      key: _registerFormKey,
      child: Column(
        children: [
          TextFormField(
            controller: _regUsernameController,
            decoration: const InputDecoration(
              labelText: '用户名',
              prefixIcon: Icon(Icons.person_add),
              border: OutlineInputBorder(),
              helperText: '2-20位字母、数字、下划线或中文',
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? '请输入用户名' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _regPasswordController,
            decoration: const InputDecoration(
              labelText: '密码',
              prefixIcon: Icon(Icons.lock),
              border: OutlineInputBorder(),
              helperText: '6-20位字母或数字',
            ),
            obscureText: true,
            validator: _validatePassword,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _regRepasswordController,
            decoration: const InputDecoration(
              labelText: '确认密码',
              prefixIcon: Icon(Icons.lock_outline),
              border: OutlineInputBorder(),
            ),
            obscureText: true,
            validator: _validateRepassword,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isRegisterLoading ? null : _handleRegister,
              icon: _isRegisterLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.person_add),
              label: Text(_isRegisterLoading ? '注册中...' : '注 册'),
            ),
          ),
        ],
      ),
    );
  }
}
