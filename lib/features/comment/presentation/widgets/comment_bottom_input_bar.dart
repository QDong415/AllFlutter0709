import 'dart:async';

import 'package:all_flutter0709/core/account/account_guard.dart';
import 'package:all_flutter0709/core/utils/value_util.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class CommentBottomInputBar extends StatelessWidget {
  const CommentBottomInputBar({
    required this.controller,
    required this.focusNode,
    required this.onCancelReply,
    required this.onSend,
    super.key,
    this.replyHintText,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String? replyHintText;
  final VoidCallback onCancelReply;
  final Future<void> Function() onSend;

  @override
  Widget build(BuildContext context) {
    final currentAccount = context.currentAccount;
    final avatarUrl = ValueUtil.getQiniuUrlByFileName(
          currentAccount?.avatar,
          thumbnail: true,
        ) ??
        '';
    final enabled = currentAccount != null;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (replyHintText != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          replyHintText!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF7B7B80),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: onCancelReply,
                        child: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Color(0xFF9B9B9B),
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFFE8E8E8),
                    backgroundImage: avatarUrl.isNotEmpty
                        ? CachedNetworkImageProvider(avatarUrl)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: enabled
                          ? null
                          : () => context.ensureLoggedIn(),
                      child: AbsorbPointer(
                        absorbing: !enabled,
                        child: TextField(
                          controller: controller,
                          focusNode: focusNode,
                          minLines: 1,
                          maxLines: 4,
                          enabled: enabled,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) {
                            unawaited(onSend());
                          },
                          decoration: InputDecoration(
                            hintText: enabled
                                ? (replyHintText ?? '说点什么吧...')
                                : '请先登录后再评论',
                            filled: true,
                            fillColor: const Color(0xFFF4F5F7),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: () {
                      if (!enabled) {
                        context.ensureLoggedIn();
                        return;
                      }
                      unawaited(onSend());
                    },
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('发送'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
