import 'package:flutter/material.dart';

class MissingVideoPage extends StatelessWidget {
  const MissingVideoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('视频详情')),
      body: const Center(child: Text('缺少视频数据')),
    );
  }
}
