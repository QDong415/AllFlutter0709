import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/core/utils/value_util.dart';
import 'package:all_flutter0709/features/conversation/data/models/conversation_summary.dart';
import 'package:all_flutter0709/features/user/presentation/widgets/user_ai_tag.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// 保证同一时间只有一行处于左滑打开状态。
class _SwipeOpenRegistry {
  static _ConversationListItemState? _current;

  static void attach(_ConversationListItemState state) {
    if (_current != null && _current != state) {
      _current!._animateClose();
    }
    _current = state;
  }

  static void detach(_ConversationListItemState state) {
    if (_current == state) {
      _current = null;
    }
  }

  static void closeCurrent() {
    final current = _current;
    if (current == null) {
      return;
    }
    _current = null;
    current._animateClose();
  }
}

/// 会话列表单行，左滑露出红色删除按钮。
class ConversationListItem extends StatefulWidget {
  const ConversationListItem({
    super.key,
    required this.summaryModel,
    required this.onTap,
    required this.onDelete,
  });

  final ConversationSummary summaryModel;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  /// 关闭当前已打开的左滑删除。
  static void closeOpenSwipe() => _SwipeOpenRegistry.closeCurrent();

  static const _nameColor = Color(0xFF5B5B5B);
  static const _secondaryColor = Color(0xFF888888);
  static const _pressedColor = Color(0xFFF2F2F2);
  static const _unreadColor = Color(0xFFE64C64);
  static const _itemHeight = 66.0;
  static const _avatarSize = 45.0;
  static const _deleteActionWidth = 80.0;

  @override
  State<ConversationListItem> createState() => _ConversationListItemState();
}

class _ConversationListItemState extends State<ConversationListItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void didUpdateWidget(ConversationListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.summaryModel.conversationId !=
        widget.summaryModel.conversationId) {
      _controller.value = 0;
      _SwipeOpenRegistry.detach(this);
    }
  }

  @override
  void dispose() {
    _SwipeOpenRegistry.detach(this);
    _controller.dispose();
    super.dispose();
  }

  void _animateClose() {
    _controller.animateTo(0, curve: Curves.easeOutCubic);
  }

  void _close() {
    _animateClose();
    _SwipeOpenRegistry.detach(this);
  }

  void _open() {
    _SwipeOpenRegistry.attach(this);
    _controller.animateTo(1, curve: Curves.easeOutCubic);
  }

  void _onDragStart(DragStartDetails details) {
    _SwipeOpenRegistry.attach(this);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final next =
        (_controller.value -
                details.delta.dx / ConversationListItem._deleteActionWidth)
            .clamp(0.0, 1.0);
    _controller.value = next;
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -300) {
      _open();
    } else if (velocity > 300) {
      _close();
    } else if (_controller.value > 0.5) {
      _open();
    } else {
      _close();
    }
  }

  void _onContentTap() {
    if (_controller.value > 0.01) {
      _close();
      return;
    }
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          height: ConversationListItem._itemHeight,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: ConversationListItem._deleteActionWidth,
                child: Material(
                  color: AppColors.primary,
                  child: InkWell(
                    onTap: widget.onDelete,
                    splashColor: AppColors.primaryPressed,
                    highlightColor: AppColors.primaryPressed,
                    child: const Center(
                      child: Text(
                        '删除',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(
                  -_controller.value * ConversationListItem._deleteActionWidth,
                  0,
                ),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: _onDragStart,
                  onHorizontalDragUpdate: _onDragUpdate,
                  onHorizontalDragEnd: _onDragEnd,
                  child: child,
                ),
              ),
            ],
          ),
        );
      },
      child: _ConversationListTile(
        summaryModel: widget.summaryModel,
        onTap: _onContentTap,
      ),
    );
  }
}

/// 会话列表行内容（头像、名称、摘要、时间）。
class _ConversationListTile extends StatelessWidget {
  const _ConversationListTile({
    required this.summaryModel,
    required this.onTap,
  });

  final ConversationSummary summaryModel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = ValueUtil.getQiniuUrlByFileName(
      summaryModel.avatar,
      thumbnail: true,
    );
    final name = summaryModel.name.isEmpty
        ? '用户${summaryModel.conversationId}'
        : summaryModel.name;
    final unreadText = summaryModel.unreadCount > 99
        ? '99+'
        : '${summaryModel.unreadCount}';

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        splashColor: ConversationListItem._pressedColor,
        highlightColor: ConversationListItem._pressedColor,
        child: SizedBox(
          height: ConversationListItem._itemHeight,
          child: Row(
            children: [
              SizedBox(
                width: 60,
                height: ConversationListItem._itemHeight,
                child: Stack(
                  children: [
                    Positioned(
                      left: 10,
                      top:
                          (ConversationListItem._itemHeight -
                              ConversationListItem._avatarSize) /
                          2,
                      child: _ConversationAvatar(avatarUrl: avatarUrl),
                    ),
                    if (summaryModel.unreadCount > 0)
                      Positioned(
                        top: 4,
                        right: 0,
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 18),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: ConversationListItem._unreadColor,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            unreadText,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              height: 1.2,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 7, right: 7),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: ConversationListItem._nameColor,
                                      fontSize: 16,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                                if (summaryModel.isAi) ...[
                                  const SizedBox(width: 6),
                                  const UserAiTag(compact: true),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatConversationTime(
                              summaryModel.latestTimeSeconds,
                            ),
                            style: const TextStyle(
                              color: ConversationListItem._secondaryColor,
                              fontSize: 13,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4, right: 0),
                        child: Text(
                          summaryModel.latestMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: ConversationListItem._secondaryColor,
                            fontSize: 14,
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 7),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 会话列表头像；禁用 CachedNetworkImage 默认淡入，避免切 Tab 时渐变出现。
class _ConversationAvatar extends StatelessWidget {
  const _ConversationAvatar({required this.avatarUrl});

  final String? avatarUrl;

  static const _placeholderAsset = 'assets/icons/user_photo.png';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ConversationListItem._avatarSize,
      height: ConversationListItem._avatarSize,
      child: avatarUrl == null || avatarUrl!.isEmpty
          ? Image.asset(_placeholderAsset, fit: BoxFit.cover)
          : CachedNetworkImage(
              imageUrl: avatarUrl!,
              fit: BoxFit.cover,
              fadeInDuration: Duration.zero,
              fadeOutDuration: Duration.zero,
              placeholderFadeInDuration: Duration.zero,
              placeholder: (_, _) =>
                  Image.asset(_placeholderAsset, fit: BoxFit.cover),
              errorWidget: (_, _, _) =>
                  Image.asset(_placeholderAsset, fit: BoxFit.cover),
            ),
    );
  }
}

/// 1 天内显示 HH:mm，否则 yyyy-MM-dd。
String _formatConversationTime(int timeSeconds) {
  final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final timeGap = nowSeconds - timeSeconds;
  final dateTime = DateTime.fromMillisecondsSinceEpoch(timeSeconds * 1000);

  if (timeGap > 24 * 60 * 60) {
    final y = dateTime.year.toString().padLeft(4, '0');
    final m = dateTime.month.toString().padLeft(2, '0');
    final d = dateTime.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
