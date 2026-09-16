import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/core/account/account_guard.dart';
import 'package:all_flutter0709/features/topic/data/models/topic_model.dart';
import 'package:flutter/material.dart';

/// 动态右上角下三角：自己的动态弹出「删除」，别人的弹出「举报」。
class TopicMoreButton extends StatelessWidget {
  const TopicMoreButton({
    super.key,
    required this.topicModel,
    this.onDeleteTap,
    this.onReportTap,
  });

  final TopicModel topicModel;
  final VoidCallback? onDeleteTap;
  final VoidCallback? onReportTap;

  bool _isOwner(BuildContext context) {
    final userId = context.currentUserId;
    return userId.isNotEmpty && userId == topicModel.userId;
  }

  Future<void> _openMenu(BuildContext context) async {
    final button = context.findRenderObject();
    final overlay = Overlay.of(
      context,
      rootOverlay: true,
    ).context.findRenderObject();
    if (button is! RenderBox || overlay is! RenderBox) {
      return;
    }

    final isOwner = _isOwner(context);
    final topLeft = button.localToGlobal(Offset.zero, ancestor: overlay);
    const gap = 8.0;
    final selected = await showMenu<String>(
      context: context,
      useRootNavigator: true,
      color: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      constraints: const BoxConstraints(minWidth: 128, maxWidth: 160),
      position: RelativeRect.fromRect(
        Rect.fromLTWH(
          topLeft.dx,
          topLeft.dy + button.size.height + gap,
          button.size.width,
          0,
        ),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem<String>(
          value: isOwner ? 'delete' : 'report',
          height: 40,
          child: Text(
            isOwner ? '删除' : '举报',
            style: TextStyle(
              fontSize: 17,
              color: isOwner ? AppColors.primary : const Color(0xFF333333),
            ),
          ),
        ),
      ],
    );

    if (!context.mounted || selected == null) {
      return;
    }
    if (selected == 'delete') {
      onDeleteTap?.call();
    } else {
      onReportTap?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openMenu(context),
      child: Padding(
        padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
        child: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade400),
      ),
    );
  }
}
