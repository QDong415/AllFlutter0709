import 'dart:async';

import 'package:all_flutter0709/app/theme/app_shadows.dart';
import 'package:all_flutter0709/core/account/account_guard.dart';
import 'package:all_flutter0709/core/utils/value_util.dart';
import 'package:all_flutter0709/features/conversation/presentation/widgets/chat_input_bar.dart';
import 'package:all_flutter0709/features/topic/presentation/widgets/topic_submit_toolbar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';

/// 评论底部输入栏：头像、表情输入框、表情 / @ / 发送。
class CommentBottomInputBar extends StatelessWidget {
  const CommentBottomInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onCancelReply,
    required this.onSend,
    required this.onToggleEmoji,
    required this.onInputPointerUp,
    required this.emojiSpanBuilder,
    this.onAtTap,
    this.replyHintText,
    this.readOnly = false,
    this.isEmojiPanel = false,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String? replyHintText;
  final VoidCallback onCancelReply;
  final Future<void> Function() onSend;
  final VoidCallback? onAtTap;
  final VoidCallback onToggleEmoji;
  final VoidCallback onInputPointerUp;
  final SpecialTextSpanBuilder emojiSpanBuilder;
  final bool readOnly;
  final bool isEmojiPanel;

  static const double _actionSize = 36;
  static const double _actionGap = 8;

  @override
  Widget build(BuildContext context) {
    final currentAccount = context.currentAccount;
    final avatarUrl =
        ValueUtil.getQiniuUrlByFileName(
          currentAccount?.avatar,
          thumbnail: true,
        ) ??
        '';
    final enabled = currentAccount != null;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: AppShadows.upward,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
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
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7B7B80),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: onCancelReply,
                      child: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: Color(0xFF9B9B9B),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: const Color(0xFFE8E8E8),
                  backgroundImage: avatarUrl.isNotEmpty
                      ? CachedNetworkImageProvider(avatarUrl)
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: enabled ? null : () => context.ensureLoggedIn(),
                    child: AbsorbPointer(
                      absorbing: !enabled,
                      child: Listener(
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
                          style: const TextStyle(fontSize: 16.5, height: 1.25),
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) {
                            unawaited(onSend());
                          },
                          onTapOutside: (_) {},
                          decoration: InputDecoration(
                            hintText: enabled
                                ? (replyHintText ?? '说点什么吧...')
                                : '请先登录后再评论',
                            hintStyle: const TextStyle(
                              fontSize: 16.5,
                              color: Color(0xFFB0B0B0),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF4F5F7),
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
                      isEmojiPanel
                          ? ChatInputAssets.keyboard
                          : ChatInputAssets.emoji,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                if (onAtTap != null) ...[
                  const SizedBox(width: _actionGap),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: enabled
                        ? onAtTap
                        : () => context.ensureLoggedIn(),
                    child: SizedBox(
                      width: _actionSize,
                      height: _actionSize,
                      child: Image.asset(
                        TopicSubmitAssets.at,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
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
