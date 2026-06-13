import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';
import 'about_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const _kUploadNotify = 'settings_upload_notify';
  static const _kDownloadNotify = 'settings_download_notify';
  static const _kMaxUploadThreads = 'settings_max_upload_threads';
  static const _kDownloadPath = 'settings_download_path';

  bool _uploadNotify = true;
  bool _downloadNotify = true;
  int _maxUploadThreads = 3;
  String _downloadPath = '';
  LogLevel _logLevel = LogLevel.none;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await AppLogger().init();
    if (!mounted) return;
    setState(() {
      _uploadNotify = prefs.getBool(_kUploadNotify) ?? true;
      _downloadNotify = prefs.getBool(_kDownloadNotify) ?? true;
      _maxUploadThreads = prefs.getInt(_kMaxUploadThreads) ?? 3;
      _downloadPath = prefs.getString(_kDownloadPath) ?? '';
      _logLevel = AppLogger().level;
      _loaded = true;
    });
  }

  Future<void> _setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _setInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  Future<void> _setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<void> _pickDownloadPath() async {
    final controller = TextEditingController(text: _downloadPath);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('下载保存路径'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '本地路径',
            hintText: '留空使用应用默认目录',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (result != null) {
      setState(() => _downloadPath = result);
      await _setString(_kDownloadPath, result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已保存'), duration: Duration(seconds: 1)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.cloud_upload),
            title: const Text('上传完成后通知'),
            trailing: Switch(
              value: _uploadNotify,
              onChanged: (v) async {
                setState(() => _uploadNotify = v);
                await _setBool(_kUploadNotify, v);
              },
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('下载完成后通知'),
            trailing: Switch(
              value: _downloadNotify,
              onChanged: (v) async {
                setState(() => _downloadNotify = v);
                await _setBool(_kDownloadNotify, v);
              },
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('最大上传线程数'),
            subtitle: Text('当前: $_maxUploadThreads'),
            trailing: DropdownButton<int>(
              value: _maxUploadThreads,
              items: const [
                DropdownMenuItem(value: 1, child: Text('1')),
                DropdownMenuItem(value: 2, child: Text('2')),
                DropdownMenuItem(value: 3, child: Text('3')),
                DropdownMenuItem(value: 5, child: Text('5')),
              ],
              onChanged: (v) async {
                if (v == null) return;
                setState(() => _maxUploadThreads = v);
                await _setInt(_kMaxUploadThreads, v);
              },
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.folder),
            title: const Text('下载保存路径'),
            subtitle: Text(
              _downloadPath.isEmpty ? '使用应用默认目录' : _downloadPath,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickDownloadPath,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: const Text('日志等级'),
            subtitle: Text(_logLevel.label),
            trailing: DropdownButton<LogLevel>(
              value: _logLevel,
              items: LogLevel.values.map((level) {
                return DropdownMenuItem(value: level, child: Text(level.label));
              }).toList(),
              onChanged: (v) async {
                if (v == null) return;
                await AppLogger().setLevel(v);
                setState(() => _logLevel = v);
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.folder_open),
            title: const Text('查看日志'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showLogDialog,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('关于'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutPage()));
            },
          ),
        ],
      ),
    );
  }

  void _showLogDialog() async {
    final content = await AppLogger().getLogContent();
    final path = await AppLogger().getLogFilePath();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('应用日志'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (path.isNotEmpty)
                Text('日志路径: $path', style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(
                    content.isEmpty ? '暂无日志' : content,
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await AppLogger().clearLogs();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('清空'),
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: content));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('日志已复制到剪贴板')),
              );
            },
            child: const Text('复制'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}
