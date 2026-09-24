import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/features/topic/presentation/helpers/topic_gender.dart';
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
    final button = context.findRenderObject();
    final overlay = Overlay.of(
      context,
      rootOverlay: true,
    ).context.findRenderObject();
    if (button is! RenderBox || overlay is! RenderBox) {
      return;
    }

    final topLeft = button.localToGlobal(Offset.zero, ancestor: overlay);
    final selected = await showMenu<int>(
      context: context,
      useRootNavigator: true,
      color: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      constraints: const BoxConstraints(minWidth: 108, maxWidth: 140),
      position: RelativeRect.fromRect(
        Rect.fromLTWH(
          topLeft.dx,
          topLeft.dy + button.size.height,
          button.size.width,
          0,
        ),
        Offset.zero & overlay.size,
      ),
      items: const [
        PopupMenuItem<int>(
          value: TopicGender.male,
          height: 40,
          child: _GenderMenuRow(label: '男', gender: TopicGender.male),
        ),
        PopupMenuItem<int>(
          value: TopicGender.female,
          height: 40,
          child: _GenderMenuRow(label: '女', gender: TopicGender.female),
        ),
        PopupMenuItem<int>(
          value: TopicGender.unlimited,
          height: 40,
          child: _GenderMenuRow(label: '不限', gender: TopicGender.unlimited),
        ),
      ],
    );

    if (selected == null || selected == gender) {
      return;
    }
    onGenderChanged(selected);
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

class _GenderMenuRow extends StatelessWidget {
  const _GenderMenuRow({required this.label, required this.gender});

  final String label;
  final int gender;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 17, color: AppColors.titleText),
        ),
        if (gender != TopicGender.unlimited) ...[
          const SizedBox(width: 8),
          Image.asset(
            gender == TopicGender.male
                ? 'assets/icons/user/profile_icon_male_m_normal.png'
                : 'assets/icons/user/profile_icon_female_m_normal.png',
            width: 18,
            height: 18,
          ),
        ],
      ],
    );
  }
}
