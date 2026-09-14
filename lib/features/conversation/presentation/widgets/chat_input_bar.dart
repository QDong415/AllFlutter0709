import 'package:flutter/material.dart';

/// QInputBarView 资源（来自 QKeyboardEmotionView）。
abstract final class ChatInputAssets {
  static const voice = 'assets/icons/chat/qinput/q_chat_voice.png';
  static const keyboard = 'assets/icons/chat/qinput/q_chat_keyboard.png';
  static const emoji = 'assets/icons/chat/qinput/q_chat_emoji.png';
  static const extend = 'assets/icons/chat/qinput/q_chat_extend.png';
  static const morePic = 'assets/icons/chat/qinput/message_more_pic.png';
  static const recordNormal = 'assets/icons/chat/qinput/q_white_input_btn.png';
  static const recordPressed =
      'assets/icons/chat/qinput/q_white_input_press_btn.png';
}

/// QInputBarViewConfiguration 默认色（浅色）。
abstract final class QInputBarColors {
  /// q_input_gray_bg
  static const barBackground = Color(0xFFF6F6F6);

  /// q_border223
  static const barBorder = Color(0xFFDFDFDF);

  /// q_black_gray
  static const text = Color(0xFF000000);

  /// q_input
  static const textViewBackground = Color(0xFFFFFFFF);

  /// q_input_extend_bg
  static const extendBackground = Color(0xFFF1F1F1);

  /// q_black_white
  static const recordTitle = Color(0xFF000000);
}

/// 对齐 QInputBarView.m 的尺寸常量。
abstract final class QInputBarMetrics {
  static const barMinHeight = 58.0;
  static const textMinHeight = 42.0;
  static const textMaxHeight = 147.0;
  static const horizontalPadding = 6.0;
  static const itemHorizontalSpace = 6.0;
  static const switchButtonSize = 40.0;
  static const textViewHorizontalMargin = 8.0;

  /// 右侧动作位宽度：发送按钮宽，「+」靠右后左侧自然留出原 8 间距。
  static const rightActionWidth = switchButtonSize + 8;

  static double get verticalPadding =>
      (barMinHeight - switchButtonSize) / 2; // 9
}

/// 聊天底部输入栏：对齐 QInputBarView（语音 | 输入 | 表情 | +/发送）。
///
/// 底部安全区与键盘/面板高度由底部容器承接。
class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    super.key,
    required this.isVoiceMode,
    required this.isEmojiPanel,
    required this.isRecording,
    required this.willCancelRecording,
    required this.recordingDurationText,
    required this.controller,
    required this.focusNode,
    required this.readOnly,
    required this.onToggleVoiceMode,
    required this.onToggleEmoji,
    required this.onTogglePanel,
    required this.onInputPointerUp,
    required this.onSendText,
    required this.onVoiceLongPressStart,
    required this.onVoiceLongPressMoveUpdate,
    required this.onVoiceLongPressEnd,
  });

  final bool isVoiceMode;
  final bool isEmojiPanel;
  final bool isRecording;
  final bool willCancelRecording;
  final String recordingDurationText;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool readOnly;
  final VoidCallback onToggleVoiceMode;
  final VoidCallback onToggleEmoji;
  final VoidCallback onTogglePanel;
  final VoidCallback onInputPointerUp;
  final VoidCallback onSendText;
  final GestureLongPressStartCallback onVoiceLongPressStart;
  final GestureLongPressMoveUpdateCallback onVoiceLongPressMoveUpdate;
  final GestureLongPressEndCallback onVoiceLongPressEnd;

  @override
  Widget build(BuildContext context) {
    final hairline = 1 / MediaQuery.devicePixelRatioOf(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: QInputBarColors.barBackground,
        border: Border(
          top: BorderSide(color: QInputBarColors.barBorder, width: hairline),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isRecording)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
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
            padding: EdgeInsets.fromLTRB(
              QInputBarMetrics.horizontalPadding,
              QInputBarMetrics.verticalPadding,
              QInputBarMetrics.horizontalPadding,
              QInputBarMetrics.verticalPadding,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _SwitchIconButton(
                  asset: isVoiceMode
                      ? ChatInputAssets.keyboard
                      : ChatInputAssets.voice,
                  onTap: onToggleVoiceMode,
                ),
                const SizedBox(
                  width: QInputBarMetrics.textViewHorizontalMargin,
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
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
                            readOnly: readOnly,
                            onSendText: onSendText,
                            onInputPointerUp: onInputPointerUp,
                          ),
                  ),
                ),
                const SizedBox(
                  width: QInputBarMetrics.textViewHorizontalMargin,
                ),
                _SwitchIconButton(
                  asset: isEmojiPanel
                      ? ChatInputAssets.keyboard
                      : ChatInputAssets.emoji,
                  onTap: onToggleEmoji,
                  usePointerDown: true,
                ),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, _) {
                    final hasText = value.text.trim().isNotEmpty;
                    final Widget action;
                    if (hasText && !isVoiceMode) {
                      action = _SendTextButton(onTap: onSendText);
                    } else {
                      action = _SwitchIconButton(
                        asset: ChatInputAssets.extend,
                        onTap: onTogglePanel,
                        usePointerDown: true,
                      );
                    }
                    return SizedBox(
                      width: QInputBarMetrics.rightActionWidth,
                      height: QInputBarMetrics.switchButtonSize,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: action,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// “+” 扩展面板内容，背景色对齐 q_input_extend_bg。
class ChatFuncPanel extends StatelessWidget {
  const ChatFuncPanel({super.key, required this.onSendImage});

  final VoidCallback onSendImage;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: QInputBarColors.extendBackground,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
        child: Align(
          alignment: Alignment.topLeft,
          child: _PanelActionButton(
            asset: ChatInputAssets.morePic,
            label: '图片',
            onTap: onSendImage,
          ),
        ),
      ),
    );
  }
}

/// 40×40 切换按钮（语音 / 键盘 / 表情 / +），对齐 UISwitchButtonWidth。
class _SwitchIconButton extends StatelessWidget {
  const _SwitchIconButton({
    this.asset,
    this.icon,
    required this.onTap,
    this.usePointerDown = false,
  }) : assert(asset != null || icon != null);

  final String? asset;
  final IconData? icon;
  final VoidCallback onTap;
  final bool usePointerDown;

  @override
  Widget build(BuildContext context) {
    final child = SizedBox(
      width: QInputBarMetrics.switchButtonSize,
      height: QInputBarMetrics.switchButtonSize,
      child: asset != null
          ? Image.asset(asset!, fit: BoxFit.contain)
          : Icon(icon, size: 28, color: QInputBarColors.text),
    );

    if (usePointerDown) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => onTap(),
        child: child,
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: child,
    );
  }
}

/// 右侧「发送」按钮（有文字时替换「+」，对齐 QInputBarView 的 rightSendButton 切换）。
class _SendTextButton extends StatelessWidget {
  const _SendTextButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: QInputBarMetrics.rightActionWidth,
      height: QInputBarMetrics.switchButtonSize,
      child: Align(
        alignment: Alignment.center,
        child: Material(
          color: const Color(0xFF3478F6),
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(6),
            child: const SizedBox(
              width: 40,
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
      ),
    );
  }
}

/// 「按住说话」条，尺寸对齐输入框 minHeight。
class _VoiceHoldButton extends StatelessWidget {
  const _VoiceHoldButton({
    super.key,
    required this.isRecording,
    required this.willCancelRecording,
    required this.onLongPressStart,
    required this.onLongPressMoveUpdate,
    required this.onLongPressEnd,
  });

  final bool isRecording;
  final bool willCancelRecording;
  final GestureLongPressStartCallback onLongPressStart;
  final GestureLongPressMoveUpdateCallback onLongPressMoveUpdate;
  final GestureLongPressEndCallback onLongPressEnd;

  @override
  Widget build(BuildContext context) {
    final title = willCancelRecording
        ? '松开手指，取消发送'
        : (isRecording ? '松开 结束' : '按住说话');
    final titleColor = willCancelRecording
        ? const Color(0xFFD93025)
        : QInputBarColors.recordTitle;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPressStart: onLongPressStart,
      onLongPressMoveUpdate: onLongPressMoveUpdate,
      onLongPressEnd: onLongPressEnd,
      child: SizedBox(
        height: QInputBarMetrics.textMinHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: willCancelRecording
                ? const Color(0xFFFCE8E6)
                : QInputBarColors.textViewBackground,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: willCancelRecording
                  ? const Color(0xFFD93025)
                  : QInputBarColors.barBorder,
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

/// 多行输入框：对齐 UIInputTextViewMinHeight / MaxHeight、圆角与内边距。
class _TextInputField extends StatelessWidget {
  const _TextInputField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.readOnly,
    required this.onSendText,
    required this.onInputPointerUp,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool readOnly;
  final VoidCallback onSendText;
  final VoidCallback onInputPointerUp;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: QInputBarMetrics.textMinHeight,
        maxHeight: QInputBarMetrics.textMaxHeight,
      ),
      child: Listener(
        onPointerUp: (_) => onInputPointerUp(),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          readOnly: readOnly,
          showCursor: true,
          minLines: 1,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.send,
          onSubmitted: (_) => onSendText(),
          onTapOutside: (_) {},
          style: const TextStyle(
            fontSize: 17.5,
            color: QInputBarColors.text,
            height: 1.25,
          ),
          decoration: InputDecoration(
            hintText: '发消息',
            hintStyle: const TextStyle(
              color: Color(0x59000000),
              fontSize: 17.5,
            ),
            filled: true,
            fillColor: QInputBarColors.textViewBackground,
            isDense: true,
            contentPadding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }
}

class _PanelActionButton extends StatelessWidget {
  const _PanelActionButton({
    required this.asset,
    required this.label,
    required this.onTap,
  });

  final String asset;
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
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Image.asset(
              asset,
              width: 36,
              height: 36,
              fit: BoxFit.contain,
            ),
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
