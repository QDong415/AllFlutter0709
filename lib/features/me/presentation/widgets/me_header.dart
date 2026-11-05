import 'package:all_flutter0709/core/utils/value_util.dart';
import 'package:flutter/material.dart';

/// 「我的」页头部：头像压在白卡上，展示昵称、关注、粉丝。
class MeHeader extends StatelessWidget {
  const MeHeader({
    super.key,
    required this.name,
    required this.avatar,
    required this.fansCount,
    required this.followCount,
    required this.onProfileTap,
    required this.onFansTap,
    required this.onFollowTap,
    this.coin = 0,
    this.charm = 0,
    this.showWallet = false,
  });

  final String name;
  final String avatar;
  final int fansCount;
  final int followCount;
  final int coin;
  final int charm;
  final bool showWallet;
  final VoidCallback onProfileTap;
  final VoidCallback onFansTap;
  final VoidCallback onFollowTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl =
        ValueUtil.getQiniuUrlByFileName(avatar, thumbnail: true) ?? '';
    final topInset = MediaQuery.paddingOf(context).top;

    return Padding(
      padding: EdgeInsets.fromLTRB(14, topInset + 36, 14, 0),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 65),
            padding: const EdgeInsets.fromLTRB(16, 70, 16, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              children: [
                InkWell(
                  onTap: onProfileTap,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF5B5B5B),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Image.asset(
                        'assets/icons/me/mine_edit.png',
                        width: 16,
                        height: 15,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 9),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _CountButton(
                      title: '关注',
                      count: followCount,
                      onTap: onFollowTap,
                    ),
                    Container(
                      width: 1,
                      height: 14,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      color: const Color(0xFFE6E6E6),
                    ),
                    _CountButton(
                      title: '粉丝',
                      count: fansCount,
                      onTap: onFansTap,
                    ),
                  ],
                ),
                if (showWallet) ...[
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _WalletChip(
                        iconAsset: 'assets/icons/gift/gift_gold_image.png',
                        label: '金币',
                        value: coin,
                      ),
                      const SizedBox(width: 28),
                      _WalletChip(
                        iconAsset: 'assets/icons/gift/charm_icon.png',
                        label: '魅力',
                        value: charm,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          GestureDetector(
            onTap: onProfileTap,
            child: SizedBox(
              width: 132,
              height: 132,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Image.asset(
                    'assets/icons/me/mine_avatar_bg.png',
                    width: 132,
                    height: 132,
                    fit: BoxFit.contain,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: ClipOval(
                      child: imageUrl.isEmpty
                          ? Image.asset(
                              'assets/icons/me/user_photo.png',
                              width: 114,
                              height: 114,
                              fit: BoxFit.cover,
                            )
                          : Image.network(
                              imageUrl,
                              width: 114,
                              height: 114,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Image.asset(
                                'assets/icons/me/user_photo.png',
                                width: 114,
                                height: 114,
                                fit: BoxFit.cover,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletChip extends StatelessWidget {
  const _WalletChip({
    required this.iconAsset,
    required this.label,
    required this.value,
  });

  final String iconAsset;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          iconAsset,
          width: 18,
          height: 18,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Color(0xFF919191)),
        ),
        const SizedBox(width: 4),
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF5B5B5B),
          ),
        ),
      ],
    );
  }
}

class _CountButton extends StatelessWidget {
  const _CountButton({
    required this.title,
    required this.count,
    required this.onTap,
  });

  final String title;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, color: Color(0xFF919191)),
          ),
          const SizedBox(width: 5),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF5B5B5B),
            ),
          ),
        ],
      ),
    );
  }
}
