import 'package:flutter/material.dart';

/// 通用空态 / 错误态占位组件，支持 Icon 或本地图片资源。
class CommonStatePlaceholder extends StatelessWidget {
  const CommonStatePlaceholder({
    super.key,
    this.icon,
    this.imageAsset,
    required this.text,
    this.actionText,
    this.onTap,
  }) : assert(
         icon != null || imageAsset != null,
         'icon 与 imageAsset 至少提供一个',
       );

  final IconData? icon;
  final String? imageAsset;
  final String text;
  final String? actionText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (imageAsset != null)
              Image.asset(
                imageAsset!,
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              )
            else
              Icon(icon, size: 40, color: const Color(0xFFB3B3B8)),
            const SizedBox(height: 12),
            Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF7B7B80),
              ),
            ),
            if (actionText != null && onTap != null) ...[
              const SizedBox(height: 8),
              TextButton(onPressed: onTap, child: Text(actionText!)),
            ],
          ],
        ),
      ),
    );
  }
}
