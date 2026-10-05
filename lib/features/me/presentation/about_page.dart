import 'package:all_flutter0709/shared/widgets/common_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// 关于我们，对齐 Android `AboutUsActivity`。
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: '关于我们'),
      body: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          final version = snapshot.data?.version ?? '';
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                '秘缘',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text('版本号：$version', textAlign: TextAlign.center),
              const SizedBox(height: 24),
              const Text('联系邮箱：2911088438@qq.com'),
              const SizedBox(height: 8),
              const Text('QQ：2911088438'),
            ],
          );
        },
      ),
    );
  }
}
