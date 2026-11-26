import 'dart:async';
import 'dart:io';

import 'package:all_flutter0709/app/theme/app_palette.dart';
import 'package:all_flutter0709/app/theme/app_shadows.dart';
import 'package:all_flutter0709/core/account/account_guard.dart';
import 'package:all_flutter0709/features/conversation/presentation/widgets/chat_input_bar.dart';
import 'package:all_flutter0709/features/topic/presentation/widgets/topic_submit_audio_preview.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';

/// 评论底部输入：语音键 + 按住说话 / 文本，右侧 @ / 表情 / 发送。
class CommentBottomInputBar extends StatelessWidget {
  const CommentBottomInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onCancelReply,
    required this.onSend,
    required this.onImageTap,
    required this.onToggleEmoji,
    required this.onInputPointerUp,
    required this.emojiSpanBuilder,
    required this.isVoiceMode,
    required this.onToggleVoiceMode,
    required this.isRecording,
    required this.willCancelRecording,
    required this.onVoicePointerDown,
    required this.onVoicePointerMove,
    required this.onVoicePointerUp,
    required this.onVoicePointerCancel,
    this.replyHintText,
    this.readOnly = false,
    this.isEmojiPanel = false,
    this.pendingAudioFile,
    this.pendingAudioSeconds = 0,
    this.onDeletePendingAudio,
    this.pendingImageFile,
    this.pendingImageIsVideo = false,
    this.onPendingImageTap,
    this.onDeletePendingImage,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String? replyHintText;
  final VoidCallback onCancelReply;
  final Future<void> Function() onSend;
  final VoidCallback onImageTap;
  final VoidCallback onToggleEmoji;
  final VoidCallback onInputPointerUp;
  final SpecialTextSpanBuilder emojiSpanBuilder;
  final bool readOnly;
  final bool isEmojiPanel;
  final bool isVoiceMode;
  final VoidCallback onToggleVoiceMode;
  final bool isRecording;
  final bool willCancelRecording;
  final ValueChanged<Offset> onVoicePointerDown;
  final ValueChanged<Offset> onVoicePointerMove;
  final VoidCallback onVoicePointerUp;
  final VoidCallback onVoicePointerCancel;
  final File? pendingAudioFile;
  final int pendingAudioSeconds;
  final VoidCallback? onDeletePendingAudio;
  final File? pendingImageFile;
  final bool pendingImageIsVideo;
  final VoidCallback? onPendingImageTap;
  final VoidCallback? onDeletePendingImage;

  static const double _actionSize = 36;
  static const double _actionGap = 6;

  @override
  Widget build(BuildContext context) {
    final enabled = context.currentAccount != null;
    final palette = context.palette;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.card,
        boxShadow: AppShadows.upward,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 10, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (replyHintText != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        replyHintText!,
                        style: TextStyle(
                          fontSize: 12,
                          color: palette.secondaryText,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: onCancelReply,
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: palette.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            if (pendingImageFile != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _PendingCommentImagePreview(
                    file: pendingImageFile!,
                    showPlayIcon: pendingImageIsVideo,
                    onTap: onPendingImageTap ?? () {},
                    onDelete: onDeletePendingImage ?? () {},
                  ),
                ),
              ),
            if (pendingAudioFile != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TopicSubmitAudioPreview(
                  file: pendingAudioFile!,
                  durationSeconds: pendingAudioSeconds,
                  onDelete: onDeletePendingAudio ?? () {},
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: enabled
                      ? onToggleVoiceMode
                      : () => context.ensureLoggedIn(),
                  child: SizedBox(
                    width: QInputBarMetrics.switchButtonSize,
                    height: QInputBarMetrics.switchButtonSize,
                    child: Image.asset(
                      context.themedAsset(
                        isVoiceMode
                            ? ChatInputAssets.keyboard
                            : ChatInputAssets.voice,
                        isVoiceMode
                            ? ChatInputAssets.keyboardDark
                            : ChatInputAssets.voiceDark,
                      ),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: isVoiceMode
                      ? _CommentVoiceHoldButton(
                          isRecording: isRecording,
                          willCancelRecording: willCancelRecording,
                          onPointerDown: onVoicePointerDown,
                          onPointerMove: onVoicePointerMove,
                          onPointerUp: onVoicePointerUp,
                          onPointerCancel: onVoicePointerCancel,
                        )
                      : Listener(
                          onPointerUp: (_) => onInputPointerUp(),
                          child: ExtendedTextField(
                            controller: controller,
                            focusNode: focusNode,
                            readOnly: readOnly,
                            showCursor: true,
                            specialTextSpanBuilder: emojiSpanBuilder,
                            minLines: 1,
                            maxLines: 4,
                            enabled: enabled,
                            style: TextStyle(
                              fontSize: 16.5,
                              height: 1.25,
                              color: palette.ink,
                            ),
                            textInputAction: TextInputAction.newline,
                            onTapOutside: (_) {},
                            decoration: InputDecoration(
                              hintText: enabled ? '说点什么吧...' : '请先登录后再评论',
                              hintStyle: TextStyle(
                                fontSize: 16.5,
                                color: palette.secondaryText,
                              ),
                              filled: true,
                              fillColor: palette.inputExtendBackground,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: _actionGap),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: enabled
                      ? onToggleEmoji
                      : () => context.ensureLoggedIn(),
                  child: SizedBox(
                    width: _actionSize,
                    height: _actionSize,
                    child: Image.asset(
                      context.themedAsset(
                        isEmojiPanel
                            ? ChatInputAssets.keyboard
                            : ChatInputAssets.emoji,
                        isEmojiPanel
                            ? ChatInputAssets.keyboardDark
                            : ChatInputAssets.emojiDark,
                      ),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: _actionGap),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: enabled ? onImageTap : () => context.ensureLoggedIn(),
                  child: SizedBox(
                    width: _actionSize,
                    height: _actionSize,
                    child: Image.asset(
                      'assets/icons/topic/comment_photo_black_normal.png',
                      fit: BoxFit.contain,
                      color: palette.ink,
                      colorBlendMode: BlendMode.srcIn,
                    ),
                  ),
                ),
                const SizedBox(width: _actionGap),
                Material(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () {
                      if (!enabled) {
                        context.ensureLoggedIn();
                        return;
                      }
                      unawaited(onSend());
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: const SizedBox(
                      width: 52,
                      height: 32,
                      child: Center(
                        child: Text(
                          '发送',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingCommentImagePreview extends StatelessWidget {
  const _PendingCommentImagePreview({
    required this.file,
    required this.onTap,
    required this.onDelete,
    this.showPlayIcon = false,
  });

  final File file;
  final bool showPlayIcon;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      height: 76,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: onTap,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(file, fit: BoxFit.cover),
              ),
            ),
          ),
          if (showPlayIcon)
            const IgnorePointer(
              child: Center(
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
            ),
          Positioned(
            top: -6,
            right: -6,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onDelete,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Color(0xCC222222),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentVoiceHoldButton extends StatefulWidget {
  const _CommentVoiceHoldButton({
    required this.isRecording,
    required this.willCancelRecording,
    required this.onPointerDown,
    required this.onPointerMove,
    required this.onPointerUp,
    required this.onPointerCancel,
  });

  final bool isRecording;
  final bool willCancelRecording;
  final ValueChanged<Offset> onPointerDown;
  final ValueChanged<Offset> onPointerMove;
  final VoidCallback onPointerUp;
  final VoidCallback onPointerCancel;

  @override
  State<_CommentVoiceHoldButton> createState() =>
      _CommentVoiceHoldButtonState();
}

class _CommentVoiceHoldButtonState extends State<_CommentVoiceHoldButton> {
  int? _pointer;

  @override
  Widget build(BuildContext context) {
    final title = widget.willCancelRecording
        ? '松开手指，取消'
        : (widget.isRecording ? '松开 结束' : '按住说话');
    final titleColor = widget.willCancelRecording
        ? const Color(0xFFD93025)
        : QInputBarColors.recordTitle(context.palette);

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) {
        if (_pointer != null) {
          return;
        }
        _pointer = event.pointer;
        widget.onPointerDown(event.position);
      },
      onPointerMove: (event) {
        if (event.pointer != _pointer) {
          return;
        }
        widget.onPointerMove(event.position);
      },
      onPointerUp: (event) {
        if (event.pointer != _pointer) {
          return;
        }
        _pointer = null;
        widget.onPointerUp();
      },
      onPointerCancel: (event) {
        if (event.pointer != _pointer) {
          return;
        }
        _pointer = null;
        widget.onPointerCancel();
      },
      child: SizedBox(
        height: QInputBarMetrics.textMinHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: widget.willCancelRecording
                ? const Color(0xFFFCE8E6)
                : QInputBarColors.textViewBackground(context.palette),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: widget.willCancelRecording
                  ? const Color(0xFFD93025)
                  : QInputBarColors.barBorder(context.palette),
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: titleColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
