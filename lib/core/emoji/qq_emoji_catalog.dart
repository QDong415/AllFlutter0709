import 'package:flutter/services.dart';

/// 一条 QQ 表情：发送文本是 [code]，展示用本地图。
class QqEmojiEntry {
  const QqEmojiEntry({required this.code, required this.asset});

  /// 写入正文的文本，例如 `[微笑]`。
  final String code;

  /// 对应的本地图片。
  final String asset;
}

/// Buddy `EmojiconHandler.sQQFaceMap` 的表情表，顺序与 Android 面板一致。
abstract final class QqEmojiCatalog {
  static const deleteAsset = 'assets/emoji/qq/icon_del.png';

  static const entries = <QqEmojiEntry>[
    QqEmojiEntry(code: '[微笑]', asset: 'assets/emoji/qq/expression_1.png'),
    QqEmojiEntry(code: '[撇嘴]', asset: 'assets/emoji/qq/expression_2.png'),
    QqEmojiEntry(code: '[色]', asset: 'assets/emoji/qq/expression_3.png'),
    QqEmojiEntry(code: '[发呆]', asset: 'assets/emoji/qq/expression_4.png'),
    QqEmojiEntry(code: '[得意]', asset: 'assets/emoji/qq/expression_5.png'),
    QqEmojiEntry(code: '[流泪]', asset: 'assets/emoji/qq/expression_6.png'),
    QqEmojiEntry(code: '[害羞]', asset: 'assets/emoji/qq/expression_7.png'),
    QqEmojiEntry(code: '[闭嘴]', asset: 'assets/emoji/qq/expression_8.png'),
    QqEmojiEntry(code: '[睡]', asset: 'assets/emoji/qq/expression_9.png'),
    QqEmojiEntry(code: '[大哭]', asset: 'assets/emoji/qq/expression_10.png'),
    QqEmojiEntry(code: '[尴尬]', asset: 'assets/emoji/qq/expression_11.png'),
    QqEmojiEntry(code: '[发怒]', asset: 'assets/emoji/qq/expression_12.png'),
    QqEmojiEntry(code: '[调皮]', asset: 'assets/emoji/qq/expression_13.png'),
    QqEmojiEntry(code: '[呲牙]', asset: 'assets/emoji/qq/expression_14.png'),
    QqEmojiEntry(code: '[惊讶]', asset: 'assets/emoji/qq/expression_15.png'),
    QqEmojiEntry(code: '[难过]', asset: 'assets/emoji/qq/expression_16.png'),
    QqEmojiEntry(code: '[酷]', asset: 'assets/emoji/qq/expression_17.png'),
    QqEmojiEntry(code: '[冷汗]', asset: 'assets/emoji/qq/expression_18.png'),
    QqEmojiEntry(code: '[抓狂]', asset: 'assets/emoji/qq/expression_19.png'),
    QqEmojiEntry(code: '[吐]', asset: 'assets/emoji/qq/expression_20.png'),
    QqEmojiEntry(code: '[嘿哈]', asset: 'assets/emoji/qq/expression_101.png'),
    QqEmojiEntry(code: '[奸笑]', asset: 'assets/emoji/qq/expression_102.png'),
    QqEmojiEntry(code: '[捂脸]', asset: 'assets/emoji/qq/expression_103.png'),
    QqEmojiEntry(code: '[机智]', asset: 'assets/emoji/qq/expression_104.png'),
    QqEmojiEntry(code: '[皱眉]', asset: 'assets/emoji/qq/expression_105.png'),
    QqEmojiEntry(code: '[耶]', asset: 'assets/emoji/qq/expression_106.png'),
    QqEmojiEntry(code: '[红包]', asset: 'assets/emoji/qq/expression_107.png'),
    QqEmojiEntry(code: '[蜡烛]', asset: 'assets/emoji/qq/expression_108.png'),
    QqEmojiEntry(code: '[小鸡]', asset: 'assets/emoji/qq/expression_109.png'),
    QqEmojiEntry(code: '[旺柴]', asset: 'assets/emoji/qq/expression_110.png'),
    QqEmojiEntry(code: '[吃瓜]', asset: 'assets/emoji/qq/watermelon.png'),
    QqEmojiEntry(code: '[加油]', asset: 'assets/emoji/qq/addoil.png'),
    QqEmojiEntry(code: '[汗]', asset: 'assets/emoji/qq/sweat.png'),
    QqEmojiEntry(code: '[天啊]', asset: 'assets/emoji/qq/shocked.png'),
    QqEmojiEntry(code: '[Emm]', asset: 'assets/emoji/qq/cold.png'),
    QqEmojiEntry(code: '[社会]', asset: 'assets/emoji/qq/social.png'),
    QqEmojiEntry(code: '[好的]', asset: 'assets/emoji/qq/noprob.png'),
    QqEmojiEntry(code: '[打脸]', asset: 'assets/emoji/qq/slap.png'),
    QqEmojiEntry(code: '[翻白眼]', asset: 'assets/emoji/qq/boring.png'),
    QqEmojiEntry(code: '[666]', asset: 'assets/emoji/qq/sixsixsix.png'),
    QqEmojiEntry(code: '[我看看]', asset: 'assets/emoji/qq/letmesee.png'),
    QqEmojiEntry(code: '[叹气]', asset: 'assets/emoji/qq/sigh.png'),
    QqEmojiEntry(code: '[苦涩]', asset: 'assets/emoji/qq/hurt.png'),
    QqEmojiEntry(code: '[裂开]', asset: 'assets/emoji/qq/broken.png'),
    QqEmojiEntry(code: '[偷笑]', asset: 'assets/emoji/qq/expression_21.png'),
    QqEmojiEntry(code: '[白眼]', asset: 'assets/emoji/qq/expression_23.png'),
    QqEmojiEntry(code: '[傲慢]', asset: 'assets/emoji/qq/expression_24.png'),
    QqEmojiEntry(code: '[饥饿]', asset: 'assets/emoji/qq/expression_25.png'),
    QqEmojiEntry(code: '[困]', asset: 'assets/emoji/qq/expression_26.png'),
    QqEmojiEntry(code: '[惊恐]', asset: 'assets/emoji/qq/expression_27.png'),
    QqEmojiEntry(code: '[流汗]', asset: 'assets/emoji/qq/expression_28.png'),
    QqEmojiEntry(code: '[憨笑]', asset: 'assets/emoji/qq/expression_29.png'),
    QqEmojiEntry(code: '[悠闲]', asset: 'assets/emoji/qq/expression_30.png'),
    QqEmojiEntry(code: '[奋斗]', asset: 'assets/emoji/qq/expression_31.png'),
    QqEmojiEntry(code: '[咒骂]', asset: 'assets/emoji/qq/expression_32.png'),
    QqEmojiEntry(code: '[疑问]', asset: 'assets/emoji/qq/expression_33.png'),
    QqEmojiEntry(code: '[嘘]', asset: 'assets/emoji/qq/expression_34.png'),
    QqEmojiEntry(code: '[晕]', asset: 'assets/emoji/qq/expression_35.png'),
    QqEmojiEntry(code: '[疯了]', asset: 'assets/emoji/qq/expression_36.png'),
    QqEmojiEntry(code: '[衰]', asset: 'assets/emoji/qq/expression_37.png'),
    QqEmojiEntry(code: '[骷髅]', asset: 'assets/emoji/qq/expression_38.png'),
    QqEmojiEntry(code: '[敲打]', asset: 'assets/emoji/qq/expression_39.png'),
    QqEmojiEntry(code: '[再见]', asset: 'assets/emoji/qq/expression_40.png'),
    QqEmojiEntry(code: '[擦汗]', asset: 'assets/emoji/qq/expression_41.png'),
    QqEmojiEntry(code: '[抠鼻]', asset: 'assets/emoji/qq/expression_42.png'),
    QqEmojiEntry(code: '[鼓掌]', asset: 'assets/emoji/qq/expression_43.png'),
    QqEmojiEntry(code: '[坏笑]', asset: 'assets/emoji/qq/expression_45.png'),
    QqEmojiEntry(code: '[糗大了]', asset: 'assets/emoji/qq/expression_44.png'),
    QqEmojiEntry(code: '[左哼哼]', asset: 'assets/emoji/qq/expression_46.png'),
    QqEmojiEntry(code: '[右哼哼]', asset: 'assets/emoji/qq/expression_47.png'),
    QqEmojiEntry(code: '[哈欠]', asset: 'assets/emoji/qq/expression_48.png'),
    QqEmojiEntry(code: '[鄙视]', asset: 'assets/emoji/qq/expression_49.png'),
    QqEmojiEntry(code: '[委屈]', asset: 'assets/emoji/qq/expression_50.png'),
    QqEmojiEntry(code: '[快哭了]', asset: 'assets/emoji/qq/expression_51.png'),
    QqEmojiEntry(code: '[阴险]', asset: 'assets/emoji/qq/expression_52.png'),
    QqEmojiEntry(code: '[亲亲]', asset: 'assets/emoji/qq/expression_53.png'),
    QqEmojiEntry(code: '[吓]', asset: 'assets/emoji/qq/expression_54.png'),
    QqEmojiEntry(code: '[可怜]', asset: 'assets/emoji/qq/expression_55.png'),
    QqEmojiEntry(code: '[菜刀]', asset: 'assets/emoji/qq/expression_56.png'),
    QqEmojiEntry(code: '[西瓜]', asset: 'assets/emoji/qq/expression_57.png'),
    QqEmojiEntry(code: '[啤酒]', asset: 'assets/emoji/qq/expression_58.png'),
    QqEmojiEntry(code: '[篮球]', asset: 'assets/emoji/qq/expression_59.png'),
    QqEmojiEntry(code: '[乒乓]', asset: 'assets/emoji/qq/expression_60.png'),
    QqEmojiEntry(code: '[咖啡]', asset: 'assets/emoji/qq/expression_61.png'),
    QqEmojiEntry(code: '[饭]', asset: 'assets/emoji/qq/expression_62.png'),
    QqEmojiEntry(code: '[猪头]', asset: 'assets/emoji/qq/expression_63.png'),
    QqEmojiEntry(code: '[玫瑰]', asset: 'assets/emoji/qq/expression_64.png'),
    QqEmojiEntry(code: '[凋谢]', asset: 'assets/emoji/qq/expression_65.png'),
    QqEmojiEntry(code: '[嘴唇]', asset: 'assets/emoji/qq/expression_66.png'),
    QqEmojiEntry(code: '[爱心]', asset: 'assets/emoji/qq/expression_67.png'),
    QqEmojiEntry(code: '[心碎]', asset: 'assets/emoji/qq/expression_68.png'),
    QqEmojiEntry(code: '[蛋糕]', asset: 'assets/emoji/qq/expression_69.png'),
    QqEmojiEntry(code: '[闪电]', asset: 'assets/emoji/qq/expression_70.png'),
    QqEmojiEntry(code: '[炸弹]', asset: 'assets/emoji/qq/expression_71.png'),
    QqEmojiEntry(code: '[刀]', asset: 'assets/emoji/qq/expression_72.png'),
    QqEmojiEntry(code: '[足球]', asset: 'assets/emoji/qq/expression_73.png'),
    QqEmojiEntry(code: '[瓢虫]', asset: 'assets/emoji/qq/expression_74.png'),
    QqEmojiEntry(code: '[便便]', asset: 'assets/emoji/qq/expression_75.png'),
    QqEmojiEntry(code: '[月亮]', asset: 'assets/emoji/qq/expression_76.png'),
    QqEmojiEntry(code: '[太阳]', asset: 'assets/emoji/qq/expression_77.png'),
    QqEmojiEntry(code: '[礼物]', asset: 'assets/emoji/qq/expression_78.png'),
    QqEmojiEntry(code: '[拥抱]', asset: 'assets/emoji/qq/expression_79.png'),
    QqEmojiEntry(code: '[强]', asset: 'assets/emoji/qq/expression_80.png'),
    QqEmojiEntry(code: '[弱]', asset: 'assets/emoji/qq/expression_81.png'),
    QqEmojiEntry(code: '[握手]', asset: 'assets/emoji/qq/expression_82.png'),
    QqEmojiEntry(code: '[胜利]', asset: 'assets/emoji/qq/expression_83.png'),
    QqEmojiEntry(code: '[抱拳]', asset: 'assets/emoji/qq/expression_84.png'),
    QqEmojiEntry(code: '[勾引]', asset: 'assets/emoji/qq/expression_85.png'),
    QqEmojiEntry(code: '[拳头]', asset: 'assets/emoji/qq/expression_86.png'),
    QqEmojiEntry(code: '[差劲]', asset: 'assets/emoji/qq/expression_87.png'),
    QqEmojiEntry(code: '[爱你]', asset: 'assets/emoji/qq/expression_88.png'),
    QqEmojiEntry(code: '[NO]', asset: 'assets/emoji/qq/expression_89.png'),
    QqEmojiEntry(code: '[OK]', asset: 'assets/emoji/qq/expression_90.png'),
    QqEmojiEntry(code: '[爱情]', asset: 'assets/emoji/qq/expression_91.png'),
  ];

  static final Map<String, String> _assetByCode = <String, String>{
    for (final entry in entries) entry.code: entry.asset,
  };

  /// 文本码对应的图片；未知码返回 null。
  static String? assetOf(String code) => _assetByCode[code];
}

/// 把光标前的 QQ 表情整段删掉；否则删一个字符。
abstract final class QqEmojiEditing {
  /// 面板删除键 / 退格：光标紧挨在表情码后面时，一次删掉整个 `[微笑]`。
  static TextEditingValue deleteBackward(TextEditingValue value) {
    final text = value.text;
    if (text.isEmpty) {
      return value;
    }
    if (!value.selection.isValid) {
      return _replace(text, _deleteRange(text, text.length, text.length));
    }
    var start = value.selection.start;
    var end = value.selection.end;
    if (start > end) {
      final swap = start;
      start = end;
      end = swap;
    }
    start = start.clamp(0, text.length);
    end = end.clamp(0, text.length);
    return _replace(text, _deleteRange(text, start, end));
  }

  static ({int start, int end}) _deleteRange(String text, int start, int end) {
    if (start != end) {
      return (start: start, end: end);
    }
    if (end <= 0) {
      return (start: 0, end: 0);
    }
    final tokenStart = _tokenStartBefore(text, end);
    return (start: tokenStart ?? end - 1, end: end);
  }

  static TextEditingValue _replace(String text, ({int start, int end}) range) {
    if (range.start == range.end) {
      return TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: range.start),
      );
    }
    return TextEditingValue(
      text: text.replaceRange(range.start, range.end, ''),
      selection: TextSelection.collapsed(offset: range.start),
    );
  }

  /// 光标前若正好是一条已知表情码，返回该码起点。
  static int? _tokenStartBefore(String text, int cursor) {
    final from = cursor > 8 ? cursor - 8 : 0;
    for (var index = from; index < cursor; index++) {
      if (text.codeUnitAt(index) != 0x5b) {
        continue;
      }
      final token = text.substring(index, cursor);
      if (QqEmojiCatalog.assetOf(token) != null) {
        return index;
      }
    }
    return null;
  }
}
