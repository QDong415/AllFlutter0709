import 'package:flutter/material.dart';

class CommonStatePlaceholder extends StatelessWidget {
  const CommonStatePlaceholder({
    required this.icon,
    required this.text,
    super.key,
    this.actionText,
    this.onTap,
  });

  final IconData icon;
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
