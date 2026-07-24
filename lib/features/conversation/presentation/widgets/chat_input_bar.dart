import 'package:flutter/material.dart';

/// QInputBarView 资源（来自 QKeyboardEmotionView，不含表情按钮）。
abstract final class ChatInputAssets {
  static const voice = 'assets/icons/chat/qinput/q_chat_voice.png';
  static const keyboard = 'assets/icons/chat/qinput/q_chat_keyboard.png';
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

  static double get verticalPadding =>
      (barMinHeight - switchButtonSize) / 2; // 9
}

/// 聊天底部输入栏：对齐 QInputBarView（无表情按钮）。
///
/// 扩展面板由页面底部 Func 占位区承接。
class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    super.key,
    required this.isVoiceMode,
    required this.isRecording,
    required this.willCancelRecording,
    required this.recordingDurationText,
    required this.controller,
    required this.focusNode,
    required this.applyBottomSafeArea,
    required this.onToggleVoiceMode,
    required this.onTogglePanel,
    required this.onSendText,
    required this.onVoiceLongPressStart,
    required this.onVoiceLongPressMoveUpdate,
    required this.onVoiceLongPressEnd,
  });

  final bool isVoiceMode;
  final bool isRecording;
  final bool willCancelRecording;
  final String recordingDurationText;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool applyBottomSafeArea;
  final VoidCallback onToggleVoiceMode;
  final VoidCallback onTogglePanel;
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
      child: SafeArea(
        top: false,
        bottom: applyBottomSafeArea,
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
                  const SizedBox(width: QInputBarMetrics.textViewHorizontalMargin),
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
                              onSendText: onSendText,
                            ),
                    ),
                  ),
                  const SizedBox(width: QInputBarMetrics.textViewHorizontalMargin),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller,
                    builder: (context, value, _) {
                      final hasText = value.text.trim().isNotEmpty;
                      // 对齐 QInputBarView：有文字显示发送，空内容显示「+」。
                      if (hasText && !isVoiceMode) {
                        return _SendTextButton(onTap: onSendText);
                      }
                      return _SwitchIconButton(
                        asset: ChatInputAssets.extend,
                        onTap: onTogglePanel,
                        usePointerDown: true,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
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

/// 40×40 切换按钮（语音 / 键盘 / +），对齐 UISwitchButtonWidth。
class _SwitchIconButton extends StatelessWidget {
  const _SwitchIconButton({
    required this.asset,
    required this.onTap,
    this.usePointerDown = false,
  });

  final String asset;
  final VoidCallback onTap;
  final bool usePointerDown;

  @override
  Widget build(BuildContext context) {
    final child = SizedBox(
      width: QInputBarMetrics.switchButtonSize,
      height: QInputBarMetrics.switchButtonSize,
      child: Image.asset(asset, fit: BoxFit.contain),
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
      width: QInputBarMetrics.switchButtonSize + 8,
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
    required this.onSendText,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSendText;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: QInputBarMetrics.textMinHeight,
        maxHeight: QInputBarMetrics.textMaxHeight,
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
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
