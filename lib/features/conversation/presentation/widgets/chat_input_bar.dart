import 'package:flutter/material.dart';

class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    required this.isVoiceMode,
    required this.isPanelVisible,
    required this.isRecording,
    required this.willCancelRecording,
    required this.recordingDurationText,
    required this.controller,
    required this.focusNode,
    required this.onToggleVoiceMode,
    required this.onTogglePanel,
    required this.onSendText,
    required this.onSendImage,
    required this.onVoiceLongPressStart,
    required this.onVoiceLongPressMoveUpdate,
    required this.onVoiceLongPressEnd,
    super.key,
  });

  final bool isVoiceMode;
  final bool isPanelVisible;
  final bool isRecording;
  final bool willCancelRecording;
  final String recordingDurationText;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onToggleVoiceMode;
  final VoidCallback onTogglePanel;
  final VoidCallback onSendText;
  final VoidCallback onSendImage;
  final GestureLongPressStartCallback onVoiceLongPressStart;
  final GestureLongPressMoveUpdateCallback onVoiceLongPressMoveUpdate;
  final GestureLongPressEndCallback onVoiceLongPressEnd;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFFF7F7F7),
        boxShadow: [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isRecording)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
                child: Text(
                  willCancelRecording
                      ? '松开手指，取消发送'
                      : '手指上滑，取消发送  $recordingDurationText',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: willCancelRecording
                        ? const Color(0xFFD93025)
                        : const Color(0xFF8A8A8A),
                    fontSize: 12,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: onToggleVoiceMode,
                    icon: Icon(
                      isVoiceMode
                          ? Icons.keyboard_alt_outlined
                          : Icons.keyboard_voice_outlined,
                      size: 28,
                      color: const Color(0xFF444444),
                    ),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SizeTransition(
                            sizeFactor: animation,
                            axis: Axis.vertical,
                            child: child,
                          ),
                        );
                      },
                      child: isVoiceMode
                          ? _VoiceHoldButton(
                              key: const ValueKey('voice_button'),
                              isRecording: isRecording,
                              willCancelRecording: willCancelRecording,
                              onLongPressStart: onVoiceLongPressStart,
                              onLongPressMoveUpdate: onVoiceLongPressMoveUpdate,
                              onLongPressEnd: onVoiceLongPressEnd,
                            )
                          : _TextInputField(
                              key: const ValueKey('text_input'),
                              controller: controller,
                              focusNode: focusNode,
                              onSendText: onSendText,
                            ),
                    ),
                  ),
                  IconButton(
                    onPressed: onTogglePanel,
                    icon: Icon(
                      isPanelVisible
                          ? Icons.close_rounded
                          : Icons.add_circle_outline,
                      size: 28,
                      color: const Color(0xFF444444),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              child: isPanelVisible
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F1F1),
                        border: Border(
                          top: BorderSide(color: Color(0xFFE6E6E6)),
                        ),
                      ),
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          _PanelActionButton(
                            icon: Icons.photo_outlined,
                            label: '图片',
                            onTap: onSendImage,
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _VoiceHoldButton extends StatelessWidget {
  const _VoiceHoldButton({
    required this.isRecording,
    required this.willCancelRecording,
    required this.onLongPressStart,
    required this.onLongPressMoveUpdate,
    required this.onLongPressEnd,
    super.key,
  });

  final bool isRecording;
  final bool willCancelRecording;
  final GestureLongPressStartCallback onLongPressStart;
  final GestureLongPressMoveUpdateCallback onLongPressMoveUpdate;
  final GestureLongPressEndCallback onLongPressEnd;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = willCancelRecording
        ? const Color(0xFFFCE8E6)
        : (isRecording ? const Color(0xFFE7E7E7) : Colors.white);
    final borderColor = willCancelRecording
        ? const Color(0xFFD93025)
        : const Color(0xFFD9D9D9);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPressStart: onLongPressStart,
      onLongPressMoveUpdate: onLongPressMoveUpdate,
      onLongPressEnd: onLongPressEnd,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          willCancelRecording ? '松开手指，取消发送' : (isRecording ? '松开 结束' : '按住 说话'),
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: willCancelRecording
                ? const Color(0xFFD93025)
                : const Color(0xFF222222),
          ),
        ),
      ),
    );
  }
}

class _TextInputField extends StatelessWidget {
  const _TextInputField({
    required this.controller,
    required this.focusNode,
    required this.onSendText,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSendText;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textInputAction: TextInputAction.send,
        onSubmitted: (_) => onSendText(),
        decoration: InputDecoration(
          hintText: '发消息',
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide.none,
          ),
          suffixIcon: IconButton(
            onPressed: onSendText,
            icon: const Icon(
              Icons.send_rounded,
              size: 20,
              color: Color(0xFF4CAF50),
            ),
          ),
        ),
      ),
    );
  }
}

class _PanelActionButton extends StatelessWidget {
  const _PanelActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 30, color: const Color(0xFF505050)),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
          ),
        ],
      ),
    );
  }
}
