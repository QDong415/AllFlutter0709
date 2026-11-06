import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/features/topic/presentation/helpers/topic_gender.dart';
import 'package:all_flutter0709/shared/widgets/gender_pick_menu.dart';
import 'package:flutter/material.dart';

/// 首页左上角性别筛选：男 / 女 / 不限。
class TopicGenderFilterButton extends StatelessWidget {
  const TopicGenderFilterButton({
    super.key,
    required this.gender,
    required this.onGenderChanged,
  });

  final int gender;
  final ValueChanged<int> onGenderChanged;

  Future<void> _openMenu(BuildContext context) async {
    final selected = await showGenderPickMenu(
      context,
      anchorContext: context,
      currentGender: gender,
      includeUnlimited: true,
    );
    if (selected != null) {
      onGenderChanged(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openMenu(context),
      child: SizedBox(
        width: 52,
        height: 45,
        child: Stack(
          children: [
            const Positioned.fill(
              child: Icon(Icons.tune, color: AppColors.titleText, size: 22),
            ),
            if (gender == TopicGender.male || gender == TopicGender.female)
              Positioned(
                right: 6,
                bottom: 6,
                child: Image.asset(
                  gender == TopicGender.male
                      ? 'assets/icons/user/profile_icon_male_m_normal.png'
                      : 'assets/icons/user/profile_icon_female_m_normal.png',
                  width: 14,
                  height: 14,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
