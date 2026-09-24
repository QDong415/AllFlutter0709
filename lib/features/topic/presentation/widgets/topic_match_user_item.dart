import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/core/utils/value_util.dart';
import 'package:all_flutter0709/features/user/data/models/user_base_model.dart';
import 'package:all_flutter0709/features/user/presentation/widgets/user_ai_tag.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// 匹配 Tab 用户行，对齐 Android `listitem_expert`。
class TopicMatchUserItem extends StatelessWidget {
  const TopicMatchUserItem({
    super.key,
    required this.userModel,
    required this.onTap,
  });

  final UserBaseModel userModel;
  final VoidCallback onTap;

  Color get _nameColor {
    if (userModel.vip == 2) {
      return const Color(0xFFED3C21);
    }
    if (userModel.vip == 1) {
      return const Color(0xFFFBC058);
    }
    return AppColors.titleText;
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl =
        ValueUtil.getQiniuUrlByFileName(userModel.avatar, thumbnail: true) ??
        '';
    final openTimeText = ValueUtil.getTimeStringFromNow(userModel.openTime);
    final genderLabel = userModel.genderLabel;

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 16, 8, 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 33,
                backgroundColor: const Color(0xFFE8E8E8),
                backgroundImage: avatarUrl.isNotEmpty
                    ? CachedNetworkImageProvider(avatarUrl)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            userModel.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              color: _nameColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (userModel.vip == 1 || userModel.vip == 2) ...[
                          const SizedBox(width: 6),
                          Text(
                            userModel.vip == 2 ? 'SVIP' : 'VIP',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _nameColor,
                            ),
                          ),
                        ],
                        if (userModel.isAi) ...[
                          const SizedBox(width: 6),
                          const UserAiTag(compact: true),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (genderLabel != null)
                          _TagChip(
                            label: genderLabel,
                            iconAsset: userModel.gender == 1
                                ? 'assets/icons/user/profile_icon_male_m_normal.png'
                                : 'assets/icons/user/profile_icon_female_m_normal.png',
                          ),
                        if (userModel.age > 0)
                          _TagChip(label: '${userModel.age}岁'),
                        if (userModel.cityName.trim().isNotEmpty)
                          _TagChip(label: userModel.cityName),
                      ],
                    ),
                    if (openTimeText.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        '$openTimeText 在线',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF999999),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, this.iconAsset});

  final String label;
  final String? iconAsset;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconAsset != null) ...[
            Image.asset(iconAsset!, width: 12, height: 12),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF666666),
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
