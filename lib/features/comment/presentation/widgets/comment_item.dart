import 'dart:async';
import 'dart:io';

import 'package:all_flutter0709/app/theme/app_palette.dart';
import 'package:all_flutter0709/features/comment/data/models/comment_display_model.dart';
import 'package:all_flutter0709/features/comment/presentation/widgets/comment_feed_audio_bar.dart';
import 'package:all_flutter0709/features/comment/data/models/comment_model.dart';
import 'package:all_flutter0709/core/utils/value_util.dart';
import 'package:all_flutter0709/features/topic/data/models/topic_model.dart';
import 'package:all_flutter0709/features/topic/presentation/helpers/topic_gallery_preview_mapper.dart';
import 'package:all_flutter0709/features/topic/presentation/widgets/topic_video_preview_page.dart';
import 'package:all_flutter0709/features/topic/presentation/widgets/topic_content_text.dart';
import 'package:all_flutter0709/features/topic/presentation/widgets/topic_like_button.dart';
import 'package:all_flutter0709/features/user/presentation/helpers/user_detail_navigation.dart';
import 'package:all_flutter0709/features/user/presentation/widgets/user_ai_tag.dart';
import 'package:all_flutter0709/features/user/presentation/widgets/vip_halo_avatar.dart';
import 'package:all_flutter0709/shared/media/gallery_preview_item.dart';
import 'package:all_flutter0709/shared/media/live_badge.dart';
import 'package:all_flutter0709/shared/media/open_image_gallery_preview.dart';
import 'package:all_flutter0709/shared/media/preview_save_source.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class CommentItem extends StatelessWidget {
  const CommentItem({
    required this.comment,
    required this.isChild,
    required this.authorUserId,
    required this.displayType,
    required this.onTap,
    required this.onLikeTap,
    super.key,
    this.onAvatarTap,
    this.onLongPress,
    this.textFontSize = 15,
  });

  final CommentModel comment;
  final bool isChild;
  final String authorUserId;
  final CommentDisplayType displayType;
  final VoidCallback onTap;
  final VoidCallback onLikeTap;
  final VoidCallback? onAvatarTap;

  /// 按住约 0.8 秒后回调，参数是这条评论自己的 context，用来定位弹层。
  final void Function(BuildContext anchorContext)? onLongPress;

  /// 昵称和正文共用的字号。动态评论用 16，视频评论保持 15。
  final double textFontSize;

  @override
  Widget build(BuildContext context) {
    final nameColor = context.palette.brightness == Brightness.dark
        ? context.palette.nameText
        : const Color(0xFF133465);
    final avatarUrl = comment.avatar ?? '';
    final isAuthor = authorUserId.isNotEmpty && authorUserId == comment.userId;
    final avatarTopInset = isChild
        ? 0.0
        : VipHaloAvatar.avatarOrigin(
            size: _CommentTree.parentAvatarSize,
            vip: comment.vip,
            borderWidth: _CommentTree.parentAvatarBorder,
          ).dy;

    return Builder(
      builder: (itemContext) {
        return _CommentPressSurface(
          onTap: onTap,
          onLongPress: onLongPress == null
              ? null
              : () => onLongPress!(itemContext),
          child: Padding(
            padding: EdgeInsets.only(top: isChild ? 0 : 8),
            child: Column(
              children: [
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _CommentTree(
                        isChild: isChild,
                        displayType: displayType,
                        avatarUrl: avatarUrl,
                        onAvatarTap: onAvatarTap,
                        vip: comment.vip,
                        gender: comment.gender,
                      ),
                      SizedBox(
                        width: isChild
                            ? 10
                            : VipHaloAvatar.contentGap(
                                size: _CommentTree.parentAvatarSize,
                                vip: comment.vip,
                                gap: 10,
                                borderWidth: _CommentTree.parentAvatarBorder,
                              ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: (isChild ? 12 : 10) + avatarTopInset,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      comment.userName.isEmpty
                                          ? '匿名用户'
                                          : comment.userName,
                                      style: TextStyle(
                                        fontSize: textFontSize,
                                        fontWeight: FontWeight.w500,
                                        color: nameColor,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (comment.isAi) ...[
                                    const SizedBox(width: 6),
                                    const UserAiTag(compact: true),
                                  ],
                                  if (isAuthor) ...[
                                    const SizedBox(width: 6),
                                    const _AuthorBadge(),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 3),
                              _CommentRichText(
                                comment: comment,
                                fontSize: textFontSize,
                              ),
                              if (comment.hasAudio) ...[
                                const SizedBox(height: 6),
                                _CommentCellPointerShield(
                                  child: CommentFeedAudioBar(comment: comment),
                                ),
                              ],
                              if (comment.localImageFile != null) ...[
                                const SizedBox(height: 5),
                                _CommentCellPointerShield(
                                  child: _LocalCommentImage(
                                    file: comment.localImageFile!,
                                  ),
                                ),
                              ] else if (comment.pictures.isNotEmpty) ...[
                                const SizedBox(height: 5),
                                _CommentCellPointerShield(
                                  child: _NetworkCommentImages(
                                    pictures: comment.pictures,
                                  ),
                                ),
                              ],
                              if (comment.isPending) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '发送中...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: context.palette.secondaryText,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                          top: (isChild ? 12 : 10) + avatarTopInset,
                        ),
                        child: _CommentCellPointerShield(
                          child: _CommentLikeColumn(
                            comment: comment,
                            onTap: onLikeTap,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (showCommentSeparator(displayType))
                  Padding(
                    padding: EdgeInsets.only(left: isChild ? 85 : 61, top: 8),
                    child: Divider(
                      height: 0.6,
                      thickness: 0.6,
                      color: context.palette.divider,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 评论按下时把白底换成 Android `white_press_drawable`（#F2F2F2）。
class _CommentPressSurface extends StatefulWidget {
  const _CommentPressSurface({
    required this.onTap,
    required this.child,
    this.onLongPress,
  });

  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Widget child;

  @override
  State<_CommentPressSurface> createState() => _CommentPressSurfaceState();
}

class _CommentPressSurfaceState extends State<_CommentPressSurface> {
  static const Duration _longPressDuration = Duration(milliseconds: 800);

  bool _pressed = false;
  bool _ignorePressFromChild = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() {
      _pressed = value;
    });
  }

  /// 子区域（语音、点赞等）接管 pointer 时不改变整格底色。
  void ignorePressFromChild() {
    _ignorePressFromChild = true;
    _setPressed(false);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) {
        if (_ignorePressFromChild) {
          _ignorePressFromChild = false;
          return;
        }
        _setPressed(true);
      },
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: RawGestureDetector(
        behavior: HitTestBehavior.opaque,
        gestures: widget.onLongPress == null
            ? const <Type, GestureRecognizerFactory>{}
            : <Type, GestureRecognizerFactory>{
                LongPressGestureRecognizer:
                    GestureRecognizerFactoryWithHandlers<
                      LongPressGestureRecognizer
                    >(
                      () => LongPressGestureRecognizer(
                        duration: _longPressDuration,
                      ),
                      (instance) {
                        instance.onLongPress = () {
                          Feedback.forLongPress(context);
                          widget.onLongPress?.call();
                        };
                      },
                    ),
              },
        child: Material(
          color: _pressed ? context.palette.pressed : context.palette.card,
          child: InkWell(
            onTap: widget.onTap,
            splashFactory: NoSplash.splashFactory,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// 包在语音、点赞等子控件外，避免整格跟着变 pressed 底色。
class _CommentCellPointerShield extends StatelessWidget {
  const _CommentCellPointerShield({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) {
        context
            .findAncestorStateOfType<_CommentPressSurfaceState>()
            ?.ignorePressFromChild();
      },
      child: child,
    );
  }
}

class _CommentTree extends StatelessWidget {
  const _CommentTree({
    required this.isChild,
    required this.displayType,
    required this.avatarUrl,
    this.onAvatarTap,
    this.vip = 0,
    this.gender = 0,
  });

  static const parentAvatarSize = 36.0;
  static const parentAvatarBorder = 0.6;

  final bool isChild;
  final CommentDisplayType displayType;
  final String avatarUrl;
  final VoidCallback? onAvatarTap;
  final int vip;
  final int gender;

  @override
  Widget build(BuildContext context) {
    if (!isChild) {
      final extent = VipHaloAvatar.layoutExtent(
        size: parentAvatarSize,
        vip: vip,
        borderWidth: parentAvatarBorder,
      );
      final origin = VipHaloAvatar.avatarOrigin(
        size: parentAvatarSize,
        vip: vip,
        borderWidth: parentAvatarBorder,
      );
      // 头像中心保持在原来 40 宽列的中线，竖线才接得上子回复。
      final left = 12 + 20 - (origin.dx + parentAvatarSize / 2);
      return Padding(
        padding: EdgeInsets.only(left: left, top: 10),
        child: SizedBox(
          width: extent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _CommentCellPointerShield(
                child: GestureDetector(
                  onTap: onAvatarTap,
                  behavior: HitTestBehavior.opaque,
                  child: VipHaloAvatar(
                    size: parentAvatarSize,
                    vip: vip,
                    gender: gender,
                    borderWidth: parentAvatarBorder,
                    borderColor: context.palette.divider,
                    imageUrl: avatarUrl,
                  ),
                ),
              ),
              if (displayType == CommentDisplayType.fatherCommentContainsChild)
                Expanded(
                  child: Center(
                    child: Container(
                      width: 0.6,
                      color: context.palette.divider,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: SizedBox(
        width: 64,
        child: Stack(
          children: [
            Positioned(
              left: 19.7,
              top: 0,
              bottom: displayType == CommentDisplayType.childCommentMiddle
                  ? 0
                  : null,
              child: Container(
                width: 0.6,
                height: displayType == CommentDisplayType.childCommentMiddle
                    ? null
                    : 24,
                color: context.palette.divider,
              ),
            ),
            Positioned(
              left: 20,
              top: 24,
              child: Container(
                width: 20,
                height: 0.6,
                color: context.palette.divider,
              ),
            ),
            Positioned(
              left: 40,
              top: 10,
              child: _CommentCellPointerShield(
                child: GestureDetector(
                  onTap: onAvatarTap,
                  behavior: HitTestBehavior.opaque,
                  child: _CommentAvatar(size: 24, avatarUrl: avatarUrl),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentAvatar extends StatelessWidget {
  const _CommentAvatar({required this.size, required this.avatarUrl});

  final double size;
  final String avatarUrl;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Container(
        width: size,
        height: size,
        color: context.palette.pressed,
        foregroundDecoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: context.palette.divider, width: 0.6),
        ),
        child: VipHaloAvatar.avatarImage(avatarUrl, size: size),
      ),
    );
  }
}

class _CommentRichText extends StatefulWidget {
  const _CommentRichText({required this.comment, required this.fontSize});

  final CommentModel comment;
  final double fontSize;

  @override
  State<_CommentRichText> createState() => _CommentRichTextState();
}

class _CommentRichTextState extends State<_CommentRichText> {
  final List<TapGestureRecognizer> _recognizers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _CommentRichText oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  @override
  Widget build(BuildContext context) {
    final comment = widget.comment;
    final palette = context.palette;
    final nameColor = palette.brightness == Brightness.dark
        ? palette.nameText
        : const Color(0xFF133465);
    final baseStyle = TextStyle(
      fontSize: widget.fontSize,
      height: 1.45,
      color: palette.titleText,
    );
    final mentionStyle = baseStyle.copyWith(color: const Color(0xFF3399FF));
    final replyNameStyle = baseStyle.copyWith(color: nameColor);
    final timeStyle = TextStyle(
      fontSize: 12,
      height: 1.45,
      color: palette.secondaryText,
    );
    final content = comment.content;
    final timeText = _formatCommentTimeText(comment.createTime);
    final contentSpans = buildTopicContentSpans(
      text: content,
      highlightStyle: mentionStyle,
      baseStyle: baseStyle,
      recognizers: _recognizers,
      onMentionTap: (name) => openUserDetailByName(context, name: name),
    );

    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          if (comment.hasReplyTarget) ...[
            const TextSpan(text: '回复 '),
            TextSpan(text: comment.toUserName, style: replyNameStyle),
            const TextSpan(text: '：'),
          ],
          ...contentSpans,
          if (timeText.isNotEmpty) ...[
            const TextSpan(text: ' '),
            TextSpan(text: timeText, style: timeStyle),
          ],
        ],
      ),
    );
  }
}

class _AuthorBadge extends StatelessWidget {
  const _AuthorBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFEAA55E), width: 0.6),
        borderRadius: BorderRadius.circular(3),
      ),
      child: const Text(
        '作者',
        style: TextStyle(fontSize: 10, color: Color(0xFFEAA55E), height: 1.1),
      ),
    );
  }
}

class _LocalCommentImage extends StatelessWidget {
  const _LocalCommentImage({required this.file});

  final File file;

  static const double _extent = 90;
  static const double _radius = 8;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openPreview(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: Image.file(
          file,
          width: _extent,
          height: _extent,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  void _openPreview(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();
    final imageProvider = FileImage(file);
    openImageGalleryPreview(
      context,
      itemList: [
        GalleryImagePreviewItem(
          imageProvider: imageProvider,
          placeholderImageProvider: imageProvider,
          saveSource: PreviewSaveFromLocalPath(file.path),
        ),
      ],
      initialIndex: 0,
    );
  }
}

class _NetworkCommentImages extends StatelessWidget {
  const _NetworkCommentImages({required this.pictures});

  final List<TopicPictureModel> pictures;

  static const double _extent = 90;
  static const double _spacing = 6;
  static const double _radius = 8;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: _spacing,
      runSpacing: _spacing,
      children: [
        for (var index = 0; index < pictures.length; index++)
          GestureDetector(
            onTap: () => _openPreview(context, index),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_radius),
              child: SizedBox(
                width: _extent,
                height: _extent,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: pictures[index].thumbnailUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => Container(
                        width: _extent,
                        height: _extent,
                        color: context.palette.pressed,
                      ),
                      errorWidget: (_, _, _) => Container(
                        width: _extent,
                        height: _extent,
                        color: context.palette.pressed,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: context.palette.secondaryText,
                        ),
                      ),
                    ),
                    if (pictures[index].isVideoClip) ...[
                      const Center(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color(0x66000000),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0x66000000),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            child: Text(
                              _formatCommentVideoDuration(
                                pictures[index].videoDurationSeconds,
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ] else if (pictures[index].hasLive)
                      const Positioned(left: 4, bottom: 4, child: LiveBadge()),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _openPreview(BuildContext context, int initialIndex) {
    FocusManager.instance.primaryFocus?.unfocus();
    final picture = pictures[initialIndex];
    if (picture.isVideoClip) {
      final videoUrl =
          ValueUtil.getVideoUrlByFileName(picture.videoFileName) ?? '';
      unawaited(
        TopicVideoPreviewPage.open(context: context, videoUrl: videoUrl),
      );
      return;
    }
    openImageGalleryPreview(
      context,
      itemList: topicPictureModelListToGalleryPreviewItemList(pictures),
      initialIndex: initialIndex,
    );
  }
}

class _CommentLikeColumn extends StatelessWidget {
  const _CommentLikeColumn({required this.comment, required this.onTap});

  final CommentModel comment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final asset = comment.isLiked
        ? TopicLikeButton.likeIconOnAsset
        : TopicLikeButton.likeIconOffAsset;
    final textColor = comment.isLiked
        ? TopicLikeButton.likedColor
        : context.palette.secondaryText;
    final countText = comment.likeCount > 0 ? '${comment.likeCount}' : '';

    return SizedBox(
      width: 36,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.only(top: 2, right: 2),
          child: Column(
            children: [
              Image.asset(
                asset,
                width: 18,
                height: 18,
                color: comment.isLiked ? null : context.palette.secondaryText,
              ),
              if (countText.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  countText,
                  style: TextStyle(fontSize: 14, color: textColor, height: 1),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 今天显示 HH:mm，其他日期显示 yyyy-MM-dd。
String _formatCommentVideoDuration(int seconds) {
  final safe = seconds < 0 ? 0 : seconds;
  final minutes = (safe ~/ 60).toString().padLeft(2, '0');
  final remain = (safe % 60).toString().padLeft(2, '0');
  return '$minutes:$remain';
}

String _formatCommentTimeText(int timestamp) {
  if (timestamp <= 0) return '--';
  final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  final now = DateTime.now();
  final isToday =
      date.year == now.year && date.month == now.month && date.day == now.day;
  if (isToday) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
