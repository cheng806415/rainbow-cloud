import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/api_client.dart';
import '../utils/constants.dart';
import '../models/file_model.dart';
import '../models/share_model.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _uploadNotify = true;
  bool _downloadNotify = true;
  int _maxUploadThreads = 3;
  String _downloadPath = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    // Load from SharedPreferences in production
  }

  void _saveSettings() {
    // Save to SharedPreferences in production
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          const ListTile(
            leading: Icon(Icons.account_circle),
            title: Text('账号与安全'),
            trailing: Icon(Icons.chevron_right),
          ),
          const Divider(height: 1),
          const ListTile(
            leading: Icon(Icons.notifications),
            title: Text('通知设置'),
            trailing: Icon(Icons.chevron_right),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.cloud_upload),
            title: const Text('上传完成后通知'),
            trailing: Switch(
              value: _uploadNotify,
              onChanged: (v) => setState(() => _uploadNotify = v),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('下载完成后通知'),
            trailing: Switch(
              value: _downloadNotify,
              onChanged: (v) => setState(() => _downloadNotify = v),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('最大上传线程数'),
            trailing: DropdownButton<int>(
              value: _maxUploadThreads,
              items: const [
                DropdownMenuItem(value: 1, child: Text('1')),
                DropdownMenuItem(value: 2, child: Text('2')),
                DropdownMenuItem(value: 3, child: Text('3')),
                DropdownMenuItem(value: 5, child: Text('5')),
              ],
              onChanged: (v) => setState(() => _maxUploadThreads = v ?? 3),
            ),
          ),
          const Divider(height: 1),
          const ListTile(
            leading: Icon(Icons.storage),
            title: Text('存储管理'),
            trailing: Icon(Icons.chevron_right),
          ),
          const Divider(height: 1),
          const ListTile(
            leading: Icon(Icons.security),
            title: Text('隐私设置'),
            trailing: Icon(Icons.chevron_right),
          ),
          const Divider(height: 1),
          const ListTile(
            leading: Icon(Icons.info),
            title: Text('关于'),
            trailing: Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
