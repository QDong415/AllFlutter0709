import 'package:flutter/material.dart';

/// 个人主页简介下方的系统禁言标签。
class UserDetailBanLabel extends StatelessWidget {
  const UserDetailBanLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECEC),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          height: 1.2,
          fontWeight: FontWeight.w600,
          color: Color(0xFFE02020),
        ),
      ),
    );
  }
}
