import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

/// 聊天相册。选中 Live 时，在「预览」和「确认」中间放一个默认不勾的实况圈。
class ChatLivePickerDelegate extends DefaultAssetPickerBuilderDelegate {
  ChatLivePickerDelegate({
    required super.provider,
    required super.initialPermission,
    super.gridCount,
    super.pickerTheme,
    super.textDelegate,
    super.locale,
    super.themeColor,
  });

  /// 确认时是否把 Live 当成带实况的图片发送。
  final ValueNotifier<bool> sendLive = ValueNotifier<bool>(false);

  bool get _showLiveCheck {
    final selected = provider.selectedAssets;
    return selected.length == 1 && selected.first.isLivePhoto;
  }

  @override
  Widget bottomActionBar(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([provider, sendLive]),
      builder: (context, _) {
        if (!_showLiveCheck && sendLive.value) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (sendLive.value) {
              sendLive.value = false;
            }
          });
        }
        final bottomPadding = MediaQuery.paddingOf(context).bottom;
        final children = <Widget>[
          if (isPermissionLimited) accessLimitedBottomTip(context),
          if (hasBottomActions)
            Container(
              height: bottomActionBarHeight + bottomPadding,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
              ).copyWith(bottom: bottomPadding),
              color: theme.bottomAppBarTheme.color?.withValues(
                alpha:
                    (theme.bottomAppBarTheme.color?.a ?? 1) *
                    (isAppleOS(context) ? 0.9 : 1),
              ),
              child: Row(
                children: <Widget>[
                  if (isPreviewEnabled) previewButton(context),
                  if (isPreviewEnabled || !isSingleAssetMode) const Spacer(),
                  if (_showLiveCheck) _liveCheck(context),
                  if (_showLiveCheck &&
                      (isPreviewEnabled || !isSingleAssetMode))
                    const Spacer(),
                  if (isPreviewEnabled || !isSingleAssetMode)
                    confirmButton(context),
                ],
              ),
            ),
        ];
        if (children.isEmpty) {
          return const SizedBox.shrink();
        }
        Widget child = Column(
          mainAxisSize: MainAxisSize.min,
          children: children,
        );
        if (isAppleOS(context)) {
          child = ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: appleOSBlurRadius,
                sigmaY: appleOSBlurRadius,
              ),
              child: child,
            ),
          );
        }
        return child;
      },
    );
  }

  Widget _liveCheck(BuildContext context) {
    final checked = sendLive.value;
    final color = themeColor ?? theme.colorScheme.secondary;
    final labelColor = theme.textTheme.bodyLarge?.color;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        sendLive.value = !sendLive.value;
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: checked ? color : Colors.transparent,
                border: Border.all(
                  color: checked ? color : (labelColor ?? color),
                  width: 1.5,
                ),
              ),
              child: checked
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 6),
            Text('实况', style: TextStyle(color: labelColor, fontSize: 17)),
          ],
        ),
      ),
    );
  }
}
