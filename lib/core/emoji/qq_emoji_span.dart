import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/core/emoji/qq_emoji_catalog.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';

/// 聊天、发动态输入框共用的表情解析器。
final QqEmojiSpanBuilder qqEmojiSpanBuilder = QqEmojiSpanBuilder();

/// 把 `[微笑]` 画成图片；可选把 @好友 区间着成链接色。
class QqEmojiSpanBuilder extends SpecialTextSpanBuilder {
  QqEmojiSpanBuilder({this.mentionRanges});

  /// 输入框里需要着色的 @好友 区间，左闭右开。
  final List<({int from, int to})> Function()? mentionRanges;

  @override
  TextSpan build(
    String data, {
    TextStyle? textStyle,
    SpecialTextGestureTapCallback? onTap,
  }) {
    if (data.isEmpty) {
      return TextSpan(text: '', style: textStyle);
    }
    final spanList = <InlineSpan>[];
    final emojiSize = ((textStyle?.fontSize) ?? 16) * 1.2;
    var index = 0;
    while (index < data.length) {
      final asset = _assetAt(data, index);
      if (asset != null) {
        final token = _tokenAt(data, index)!;
        spanList.add(
          ImageSpan(
            AssetImage(asset),
            imageWidth: emojiSize,
            imageHeight: emojiSize,
            start: index,
            actualText: token,
            margin: const EdgeInsets.symmetric(horizontal: 1),
          ),
        );
        index += token.length;
        continue;
      }
      final mentionEnd = _mentionEndAt(index);
      if (mentionEnd != null &&
          mentionEnd > index &&
          mentionEnd <= data.length) {
        spanList.add(
          TextSpan(
            text: data.substring(index, mentionEnd),
            style: (textStyle ?? const TextStyle()).copyWith(
              color: AppColors.link,
            ),
          ),
        );
        index = mentionEnd;
        continue;
      }
      var next = index + 1;
      while (next < data.length &&
          _assetAt(data, next) == null &&
          _mentionEndAt(next) == null) {
        next++;
      }
      spanList.add(
        TextSpan(text: data.substring(index, next), style: textStyle),
      );
      index = next;
    }
    return TextSpan(style: textStyle, children: spanList);
  }

  @override
  SpecialText? createSpecialText(
    String flag, {
    TextStyle? textStyle,
    SpecialTextGestureTapCallback? onTap,
    required int index,
  }) {
    return null;
  }

  String? _assetAt(String text, int index) {
    final token = _tokenAt(text, index);
    if (token == null) {
      return null;
    }
    return QqEmojiCatalog.assetOf(token);
  }

  String? _tokenAt(String text, int index) {
    if (text.codeUnitAt(index) != 0x5b) {
      return null;
    }
    final close = text.indexOf(']', index + 1);
    if (close < 0 || close - index > 8) {
      return null;
    }
    return text.substring(index, close + 1);
  }

  int? _mentionEndAt(int index) {
    final rangeList = mentionRanges?.call();
    if (rangeList == null) {
      return null;
    }
    for (final range in rangeList) {
      if (range.from == index && range.to > range.from) {
        return range.to;
      }
    }
    return null;
  }
}

/// 只读正文里的表情尺寸，对齐 Android 字号的 1.2 倍。
double qqEmojiSizeOf(TextStyle? style) {
  return ((style?.fontSize) ?? 16) * 1.2;
}

/// 把一段正文拆成普通文字和 QQ 表情图。
List<InlineSpan> buildQqEmojiInlineSpans({
  required String text,
  TextStyle? style,
}) {
  if (text.isEmpty) {
    return const <InlineSpan>[];
  }
  final emojiSize = qqEmojiSizeOf(style);
  final spanList = <InlineSpan>[];
  var index = 0;
  while (index < text.length) {
    final token = _readOnlyTokenAt(text, index);
    final asset = token == null ? null : QqEmojiCatalog.assetOf(token);
    if (token != null && asset != null) {
      spanList.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Image.asset(
            asset,
            width: emojiSize,
            height: emojiSize,
            gaplessPlayback: true,
          ),
        ),
      );
      index += token.length;
      continue;
    }
    var next = index + 1;
    while (next < text.length) {
      final nextToken = _readOnlyTokenAt(text, next);
      if (nextToken != null && QqEmojiCatalog.assetOf(nextToken) != null) {
        break;
      }
      next++;
    }
    spanList.add(TextSpan(text: text.substring(index, next), style: style));
    index = next;
  }
  return spanList;
}

String? _readOnlyTokenAt(String text, int index) {
  if (text.codeUnitAt(index) != 0x5b) {
    return null;
  }
  final close = text.indexOf(']', index + 1);
  if (close < 0 || close - index > 8) {
    return null;
  }
  return text.substring(index, close + 1);
}
