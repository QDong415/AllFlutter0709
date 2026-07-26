import 'package:all_flutter0709/core/utils/value_util.dart';
import 'package:all_flutter0709/features/conversation/data/models/conversation_summary.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// 会话列表单行。
class ConversationListItem extends StatelessWidget {
  const ConversationListItem({
    super.key,
    required this.summaryModel,
    required this.onTap,
  });

  final ConversationSummary summaryModel;
  final VoidCallback onTap;

  static const _nameColor = Color(0xFF5B5B5B);
  static const _secondaryColor = Color(0xFF888888);
  static const _pressedColor = Color(0xFFF2F2F2);
  static const _unreadColor = Color(0xFFE64C64);
  static const _itemHeight = 66.0;
  static const _avatarSize = 45.0;

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
        splashColor: _pressedColor,
        highlightColor: _pressedColor,
        child: SizedBox(
          height: _itemHeight,
          child: Row(
            children: [
              SizedBox(
                width: 60,
                height: _itemHeight,
                child: Stack(
                  children: [
                    Positioned(
                      left: 10,
                      top: (_itemHeight - _avatarSize) / 2,
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
                            color: _unreadColor,
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
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _nameColor,
                                fontSize: 16,
                                height: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatConversationTime(
                              summaryModel.latestTimeSeconds,
                            ),
                            style: const TextStyle(
                              color: _secondaryColor,
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
                            color: _secondaryColor,
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
