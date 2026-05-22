import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('关于'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud, size: 80, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text('彩虹网盘', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text('客户端 v1.0.0'),
            const SizedBox(height: 24),
            Text(
              '彩虹外链网盘移动端/桌面端客户端\n支持 Android 和 Windows 平台',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              '基于 Flutter 框架开发',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
