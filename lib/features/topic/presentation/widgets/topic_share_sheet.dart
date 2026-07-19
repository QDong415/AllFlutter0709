import 'package:flutter/material.dart';

class TopicShareSheet extends StatelessWidget {
  const TopicShareSheet({super.key, this.onWeChatTap});

  static const weChatLogoAsset = 'assets/icons/logo_wechat.png';

  final VoidCallback? onWeChatTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        color: const Color(0xFFEDEDED),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(height: 3, color: const Color(0xFFF46533)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ShareAction(
                    iconAsset: weChatLogoAsset,
                    label: '微信好友',
                    onTap: onWeChatTap,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFF46533),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    '取消',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareAction extends StatelessWidget {
  const _ShareAction({
    required this.iconAsset,
    required this.label,
    this.onTap,
  });

  final String iconAsset;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(iconAsset, width: 56, height: 56),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(color: Color(0xFF333333), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
