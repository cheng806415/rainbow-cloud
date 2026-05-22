import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

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
  String _serverUrlController = '';
  bool _showServerUrl = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _serverUrlController = context.read<AuthProvider>().serverUrl;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginUsernameController.dispose();
    _loginPasswordController.dispose();
    _regUsernameController.dispose();
    _regPasswordController.dispose();
    _regRepasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() => _isLoginLoading = true);
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      _loginUsernameController.text.trim(),
      _loginPasswordController.text,
    );
    setState(() => _isLoginLoading = false);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('登录成功'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pushReplacementNamed('/home');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('用户名或密码错误'), backgroundColor: Colors.red),
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
    final success = await authProvider.register(
      _regUsernameController.text.trim(),
      _regPasswordController.text,
      _regRepasswordController.text,
    );
    setState(() => _isRegisterLoading = false);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('注册成功，已自动登录'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pushReplacementNamed('/home');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('注册失败，请稍后重试'), backgroundColor: Colors.red),
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
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => setState(() => _showServerUrl = !_showServerUrl),
                          icon: const Icon(Icons.settings, size: 18),
                          label: Text(_showServerUrl ? '收起服务器设置' : '服务器设置'),
                        ),
                      ),
                    ],
                  ),
                  if (_showServerUrl) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: _serverUrlController,
                      decoration: const InputDecoration(
                        labelText: '服务器地址',
                        prefixIcon: Icon(Icons.http),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        context.read<AuthProvider>().setServerUrl(value);
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
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
            validator: (v) => v == null || v.isEmpty ? '请输入用户名' : null,
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
            validator: (v) => v == null || v.isEmpty ? '请输入用户名' : null,
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
            validator: (v) => v == null || v.isEmpty ? '请输入密码' : null,
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
            validator: (v) => v == null || v.isEmpty ? '请再次输入密码' : null,
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
