import 'package:all_flutter0709/app/theme/app_palette.dart';
import 'package:flutter/material.dart';

/// 别人主页右上角菜单的选项。
enum UserDetailMoreAction {
  /// 给对方设置备注。
  remark,

  /// 拉入黑名单。
  block,

  /// 举报。
  report,
}

/// 在更多按钮下方弹出「拉入黑名单 / 举报」，对齐 Android 个人主页更多菜单。
Future<UserDetailMoreAction?> showUserDetailMoreMenu(
  BuildContext anchorContext,
) async {
  final button = anchorContext.findRenderObject();
  final overlay = Overlay.of(
    anchorContext,
    rootOverlay: true,
  ).context.findRenderObject();
  if (button is! RenderBox ||
      !button.hasSize ||
      overlay is! RenderBox ||
      !overlay.hasSize) {
    return null;
  }

  final topLeft = button.localToGlobal(Offset.zero, ancestor: overlay);
  final palette = anchorContext.palette;
  final itemStyle = TextStyle(fontSize: 17, color: palette.titleText);
  return showMenu<UserDetailMoreAction>(
    context: anchorContext,
    useRootNavigator: true,
    color: palette.card,
    elevation: 8,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    constraints: const BoxConstraints(minWidth: 160, maxWidth: 160),
    position: RelativeRect.fromRect(
      Rect.fromLTWH(
        topLeft.dx,
        topLeft.dy + button.size.height,
        button.size.width,
        0,
      ),
      Offset.zero & overlay.size,
    ),
    items: [
      PopupMenuItem<UserDetailMoreAction>(
        value: UserDetailMoreAction.remark,
        height: 44,
        child: Text('设置备注', style: itemStyle),
      ),
      PopupMenuItem<UserDetailMoreAction>(
        value: UserDetailMoreAction.block,
        height: 44,
        child: Text('拉入黑名单', style: itemStyle),
      ),
      PopupMenuItem<UserDetailMoreAction>(
        value: UserDetailMoreAction.report,
        height: 44,
        child: Text('举报', style: itemStyle),
      ),
    ],
  );
}
