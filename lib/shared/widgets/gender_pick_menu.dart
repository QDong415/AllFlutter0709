import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/features/topic/presentation/helpers/topic_gender.dart';
import 'package:flutter/material.dart';

/// 性别选项行，对齐动态首页左上角筛选弹层样式。
class GenderPickMenuRow extends StatelessWidget {
  const GenderPickMenuRow({super.key, required this.label, required this.gender});

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

/// 性别菜单相对锚点的水平对齐方式。
enum GenderPickMenuAlign {
  /// 菜单左缘与锚点左缘对齐（动态首页筛选）。
  start,

  /// 菜单右缘与锚点右缘对齐（资料编辑等整行锚点）。
  end,
}

/// 弹出性别选择菜单。样式与动态首页左上角筛选一致；默认仅男/女。
Future<int?> showGenderPickMenu(
  BuildContext context, {
  required BuildContext anchorContext,
  required int currentGender,
  bool includeUnlimited = false,
  GenderPickMenuAlign align = GenderPickMenuAlign.start,
}) async {
  final button = anchorContext.findRenderObject();
  final overlay = Overlay.of(
    context,
    rootOverlay: true,
  ).context.findRenderObject();
  if (button is! RenderBox || overlay is! RenderBox) {
    return null;
  }

  const menuMinWidth = 108.0;
  const edgePadding = 8.0;

  final topLeft = button.localToGlobal(Offset.zero, ancestor: overlay);
  var menuLeft = topLeft.dx;
  if (align == GenderPickMenuAlign.end) {
    menuLeft = topLeft.dx + button.size.width - menuMinWidth;
  }
  menuLeft = menuLeft.clamp(
    edgePadding,
    overlay.size.width - menuMinWidth - edgePadding,
  );

  final selected = await showMenu<int>(
    context: context,
    useRootNavigator: true,
    color: Colors.white,
    elevation: 8,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    constraints: const BoxConstraints(minWidth: 108, maxWidth: 140),
    position: RelativeRect.fromRect(
      Rect.fromLTWH(
        menuLeft,
        topLeft.dy + button.size.height,
        button.size.width,
        0,
      ),
      Offset.zero & overlay.size,
    ),
    items: [
      const PopupMenuItem<int>(
        value: TopicGender.male,
        height: 40,
        child: GenderPickMenuRow(label: '男', gender: TopicGender.male),
      ),
      const PopupMenuItem<int>(
        value: TopicGender.female,
        height: 40,
        child: GenderPickMenuRow(label: '女', gender: TopicGender.female),
      ),
      if (includeUnlimited)
        const PopupMenuItem<int>(
          value: TopicGender.unlimited,
          height: 40,
          child: GenderPickMenuRow(label: '不限', gender: TopicGender.unlimited),
        ),
    ],
  );

  if (selected == null || selected == currentGender) {
    return null;
  }
  return selected;
}
