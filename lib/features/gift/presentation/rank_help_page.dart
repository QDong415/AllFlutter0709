import 'package:all_flutter0709/shared/widgets/common_app_bar.dart';
import 'package:flutter/material.dart';

/// 榜单规则说明：金币与魅力如何获得。
class RankHelpPage extends StatelessWidget {
  const RankHelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: '规则说明'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: const [
          _Section(
            title: '金币怎么获得',
            body: '每天打开 App 完成签到，即可领取金币。'
                '连续签到天数越高，当天奖励越多；连续满 7 天后会重新从第 1 天计起。'
                '金币可用于在聊天或动态里给他人送礼物。',
          ),
          SizedBox(height: 28),
          _Section(
            title: '魅力怎么获得',
            body: '当你收到别人送的礼物时，会按礼物价值增加相应的魅力值。'
                '礼物单价 × 数量，就是本次增加的魅力。'
                '魅力榜按收到的魅力排序，财富榜按送出礼物消耗的金币排序。',
          ),
        ],
      ),
    );
  }
}

/// 说明区块：标题 + 正文。
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          body,
          style: const TextStyle(
            fontSize: 15,
            height: 1.55,
            color: Color(0xFF666666),
          ),
        ),
      ],
    );
  }
}
