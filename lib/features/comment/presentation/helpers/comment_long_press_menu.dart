import 'package:flutter/material.dart';
import 'package:flutter_show_menu/flutter_show_menu.dart';

/// 评论长按后的操作，对齐 Android 评论列表长按菜单。
enum CommentLongPressAction { copy, delete, report, reply }

/// 评论长按弹层：复制内容、删除或举报、回复。
///
/// 使用 [flutter_show_menu]，菜单贴在评论上沿或下沿并水平居中，不盖住评论本身。
class CommentLongPressMenu {
  const CommentLongPressMenu._();

  static const double _menuWidth = 160;
  static const double _itemHeight = 38;
  static const double _gap = 8;
  static const double _estimatedMenuHeight = _itemHeight * 3 + 8;

  static const TextStyle _itemTextStyle = TextStyle(
    fontSize: 17,
    color: Color(0xFF333333),
  );

  /// 在 [anchorContext] 对应的评论条目旁弹出菜单。
  ///
  /// 评论作者或动态作者看到「删除」，其他人看到「举报」。
  /// 点「删除」返回 [CommentLongPressAction.delete]；点「举报」返回
  /// [CommentLongPressAction.report]。
  static Future<CommentLongPressAction?> show({
    required BuildContext anchorContext,
    required bool canDelete,
  }) {
    final box = anchorContext.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !anchorContext.mounted) {
      return Future<CommentLongPressAction?>.value();
    }

    final topLeft = box.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.sizeOf(anchorContext).height;
    final spaceAbove = topLeft.dy;
    final spaceBelow = screenHeight - topLeft.dy - box.size.height;
    final showBelow =
        spaceBelow >= _estimatedMenuHeight + _gap || spaceBelow >= spaceAbove;

    return showOverlayMenu<CommentLongPressAction>(
      context: anchorContext,
      placement: OverlayMenuPlacement(
        position: showBelow ? MenuPosition.bottom : MenuPosition.top,
        alignment: MenuAlignment.center,
        offset: Offset(0, showBelow ? _gap : -_gap),
      ),
      style: const OverlayMenuStyle(
        backgroundColor: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(4)),
        width: _menuWidth,
        padding: EdgeInsets.symmetric(vertical: 4),
        itemStyle: OverlayMenuItemStyle(
          height: _itemHeight,
          highlightColor: Color(0xFFF2F2F2),
          splashColor: Color(0xFFF2F2F2),
        ),
      ),
      items: [
        const OverlayMenuItem<CommentLongPressAction>(
          value: CommentLongPressAction.copy,
          height: _itemHeight,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('复制内容', style: _itemTextStyle),
          ),
        ),
        OverlayMenuItem<CommentLongPressAction>(
          value: canDelete
              ? CommentLongPressAction.delete
              : CommentLongPressAction.report,
          height: _itemHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(canDelete ? '删除' : '举报', style: _itemTextStyle),
          ),
        ),
        const OverlayMenuItem<CommentLongPressAction>(
          value: CommentLongPressAction.reply,
          height: _itemHeight,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('回复', style: _itemTextStyle),
          ),
        ),
      ],
    );
  }
}
