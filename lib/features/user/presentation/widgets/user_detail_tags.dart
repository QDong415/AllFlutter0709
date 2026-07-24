import 'package:all_flutter0709/features/user/data/models/user_profile_model.dart';
import 'package:flutter/material.dart';

/// 个人主页性别 / 年龄 / 城市标签行。
class UserDetailTags extends StatelessWidget {
  const UserDetailTags({super.key, required this.profileModel});

  final UserProfileModel profileModel;

  @override
  Widget build(BuildContext context) {
    if (!profileModel.hasAnyTag) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          if (profileModel.hasGender)
            _TagChip(
              label: profileModel.genderLabel ?? '',
              iconAsset: profileModel.gender == 1
                  ? 'assets/icons/user/profile_icon_male_m_normal.png'
                  : 'assets/icons/user/profile_icon_female_m_normal.png',
              backgroundColor: profileModel.gender == 2
                  ? const Color(0xFFFFE8F0)
                  : const Color(0xFFEEEEEE),
            ),
          if (profileModel.hasAge)
            _TagChip(
              label: '${profileModel.age} 岁',
              backgroundColor: const Color(0xFFEEEEEE),
            ),
          if (profileModel.hasCity)
            _TagChip(
              label: profileModel.cityName,
              backgroundColor: const Color(0xFFEEEEEE),
            ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.backgroundColor,
    this.iconAsset,
  });

  final String label;
  final Color backgroundColor;
  final String? iconAsset;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
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
