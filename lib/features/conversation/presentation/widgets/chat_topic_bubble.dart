import 'package:all_flutter0709/app/theme/app_palette.dart';
import 'package:all_flutter0709/core/emoji/qq_emoji_span.dart';
import 'package:all_flutter0709/features/conversation/presentation/models/chat_item.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// 聊天里的动态分享卡片：作者 + 正文摘要 + 封面，底部「动态」标识。
class ChatTopicBubble extends StatelessWidget {
  const ChatTopicBubble({
    super.key,
    required this.item,
    this.isSelected = false,
  });

  final TopicMessage item;
  final bool isSelected;

  static const _cardWidth = 228.0;
  static const _coverSize = 56.0;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final card = Container(
      width: _cardWidth,
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _AuthorAvatar(avatarUrl: item.authorAvatarUrl),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item.authorName.isEmpty ? '用户' : item.authorName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: palette.secondaryText,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text.rich(
                        TextSpan(
                          children: buildQqEmojiInlineSpans(
                            text: item.content.isEmpty
                                ? '[图片动态]'
                                : item.content,
                            style: TextStyle(
                              fontSize: 14,
                              color: palette.titleText,
                              height: 1.35,
                            ),
                          ),
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: palette.titleText,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                if (item.pictureUrl.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  _CoverThumb(
                    pictureUrl: item.pictureUrl,
                    hasVideo: item.hasVideo,
                  ),
                ],
              ],
            ),
          ),
          Divider(height: 1, thickness: 0.5, color: palette.divider),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Text(
              '动态',
              style: TextStyle(
                fontSize: 11,
                color: palette.secondaryText,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );

    if (!isSelected) {
      return card;
    }
    return ColorFiltered(
      colorFilter: const ColorFilter.mode(Color(0x33000000), BlendMode.srcATop),
      child: card,
    );
  }
}

class _AuthorAvatar extends StatelessWidget {
  const _AuthorAvatar({required this.avatarUrl});

  final String avatarUrl;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 9,
      backgroundColor: context.palette.pressed,
      backgroundImage: avatarUrl.isNotEmpty
          ? CachedNetworkImageProvider(avatarUrl)
          : null,
    );
  }
}

class _CoverThumb extends StatelessWidget {
  const _CoverThumb({required this.pictureUrl, required this.hasVideo});

  final String pictureUrl;
  final bool hasVideo;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        width: ChatTopicBubble._coverSize,
        height: ChatTopicBubble._coverSize,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: pictureUrl,
              fit: BoxFit.cover,
              placeholderFadeInDuration: Duration.zero,
              fadeInDuration: Duration.zero,
              placeholder: (_, _) => ColoredBox(
                color: context.palette.pressed,
                child: Icon(
                  Icons.image_outlined,
                  size: 22,
                  color: context.palette.secondaryText,
                ),
              ),
              errorWidget: (_, _, _) => ColoredBox(
                color: context.palette.pressed,
                child: Icon(
                  Icons.image_outlined,
                  size: 22,
                  color: context.palette.secondaryText,
                ),
              ),
            ),
            if (hasVideo)
              const Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: EdgeInsets.all(3),
                  child: Icon(
                    Icons.play_circle_fill,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
