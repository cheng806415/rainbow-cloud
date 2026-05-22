import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'file_list_page.dart';
import 'upload_page.dart';
import 'download_page.dart';
import 'share_page.dart';
import 'recycle_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  bool _showDrawer = false;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const FileListPage(),
      const UploadPage(),
      const DownloadPage(),
      const SharePage(),
      const RecyclePage(),
      const ProfilePage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              extended: true,
              selectedIndex: _currentIndex,
              onDestinationSelected: _onItemTapped,
              leading: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.cloud, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    const Text('彩虹网盘', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.folder_outlined),
                  selectedIcon: Icon(Icons.folder),
                  label: Text('文件'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.upload_outlined),
                  selectedIcon: Icon(Icons.upload),
                  label: Text('上传'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.download_outlined),
                  selectedIcon: Icon(Icons.download),
                  label: Text('下载'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.share_outlined),
                  selectedIcon: Icon(Icons.share),
                  label: Text('分享'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.delete_outline),
                  selectedIcon: Icon(Icons.delete),
                  label: Text('回收站'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.account_circle),
                  label: Text('我的'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: _pages[_currentIndex]),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('彩虹网盘'),
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) => IconButton(
              icon: Icon(
                themeProvider.themeMode == ThemeMode.dark
                    ? Icons.light_mode
                    : Icons.dark_mode,
              ),
              onPressed: () => themeProvider.toggleTheme(),
              tooltip: '切换主题',
            ),
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: '文件',
          ),
          NavigationDestination(
            icon: Icon(Icons.upload_outlined),
            selectedIcon: Icon(Icons.upload),
            label: '上传',
          ),
          NavigationDestination(
            icon: Icon(Icons.download_outlined),
            selectedIcon: Icon(Icons.download),
            label: '下载',
          ),
          NavigationDestination(
            icon: Icon(Icons.share_outlined),
            selectedIcon: Icon(Icons.share),
            label: '分享',
          ),
          NavigationDestination(
            icon: Icon(Icons.delete_outline),
            selectedIcon: Icon(Icons.delete),
            label: '回收站',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
}
