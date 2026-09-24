import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/features/topic/data/models/topic_mention_range_model.dart';
import 'package:all_flutter0709/features/user/data/models/user_base_model.dart';
import 'package:flutter/material.dart';

/// 发布动态输入框：@好友着色、整块删除、输入 `@` 回调。
class TopicMentionEditingController extends TextEditingController {
  TopicMentionEditingController();

  final List<TopicMentionRangeModel> mentionList = <TopicMentionRangeModel>[];

  String _previousText = '';
  bool _isApplying = false;
  VoidCallback? _onAtTyped;

  /// 输入单个 `@` 且不是插入 mention 时回调。
  void setOnAtTyped(VoidCallback? callback) {
    _onAtTyped = callback;
  }

  /// 清空正文和 mention，避免清空时被当成退格整段删除。
  void clearContent() {
    _isApplying = true;
    try {
      mentionList.clear();
      value = const TextEditingValue(text: '');
      _previousText = '';
    } finally {
      _isApplying = false;
    }
  }

  /// 提交给服务端的 `atuserids`（逗号分隔、去重）。
  String findAtUserIds() {
    return mentionList.map((rangeModel) => rangeModel.userId).toSet().join(',');
  }

  /// 把选中好友插入光标处；[byInput] 为 true 时先删掉刚输入的 `@`。
  void insertUser({required UserBaseModel userModel, required bool byInput}) {
    if (userModel.userId.isEmpty) {
      return;
    }
    _isApplying = true;
    try {
      if (byInput) {
        final selectionStart = selection.start;
        if (selectionStart > 0 &&
            selectionStart <= text.length &&
            text.substring(selectionStart - 1, selectionStart) == '@') {
          _deleteRange(selectionStart - 1, selectionStart);
        }
      }

      final showText = '@${userModel.name}';
      final start = selection.isValid
          ? selection.start.clamp(0, text.length)
          : text.length;
      final insertText = '$showText ';
      _shiftMentionsAfter(start, insertText.length);
      value = TextEditingValue(
        text: text.replaceRange(start, start, insertText),
        selection: TextSelection.collapsed(offset: start + insertText.length),
      );
      mentionList.add(
        TopicMentionRangeModel(
          userId: userModel.userId,
          from: start,
          to: start + showText.length,
        ),
      );
      _previousText = text;
    } finally {
      _isApplying = false;
    }
  }

  /// 插入表情等普通文本，并平移后续 mention。
  void insertPlainText(String insertText) {
    _isApplying = true;
    try {
      final start = selection.isValid
          ? selection.start.clamp(0, text.length)
          : text.length;
      final end = selection.isValid
          ? selection.end.clamp(0, text.length)
          : start;
      final safeStart = start <= end ? start : end;
      final safeEnd = start <= end ? end : start;
      if (safeEnd > safeStart) {
        _whenDelText(safeStart, safeEnd, safeStart - safeEnd);
      }
      _shiftMentionsAfter(safeStart, insertText.length);
      value = TextEditingValue(
        text: text.replaceRange(safeStart, safeEnd, insertText),
        selection: TextSelection.collapsed(
          offset: safeStart + insertText.length,
        ),
      );
      _previousText = text;
    } finally {
      _isApplying = false;
    }
  }

  /// 文本变化后同步 mention 范围；检测到单独输入 `@` 时回调。
  void handleTextChanged() {
    if (_isApplying) {
      return;
    }
    final nextText = text;
    final prevText = _previousText;
    if (nextText == prevText) {
      return;
    }

    final delta = nextText.length - prevText.length;
    var start = 0;
    final minLength = nextText.length < prevText.length
        ? nextText.length
        : prevText.length;
    while (start < minLength && nextText[start] == prevText[start]) {
      start++;
    }

    if (delta < 0) {
      final deletedEnd = start - delta;
      final hit = _mentionHitByBackspace(deletedEnd);
      if (hit != null) {
        _deleteWholeMention(
          hit: hit,
          newBreakIndex: start,
          oldDeletedEnd: deletedEnd,
        );
        return;
      }
      _whenDelText(start, deletedEnd, delta);
    } else if (delta > 0) {
      _shiftMentionsAfter(start, delta);
      if (delta == 1 && start < nextText.length && nextText[start] == '@') {
        _onAtTyped?.call();
      }
    }
    _previousText = nextText;
  }

  /// 光标落到 mention 内部时弹到两端。
  void snapSelection() {
    if (_isApplying || !selection.isValid || !selection.isCollapsed) {
      return;
    }
    final offset = selection.baseOffset;
    for (final rangeModel in mentionList) {
      if (rangeModel.containsOffset(offset)) {
        final toEdge = (offset - rangeModel.from) >= (rangeModel.to - offset);
        selection = TextSelection.collapsed(
          offset: toEdge ? rangeModel.to : rangeModel.from,
        );
        return;
      }
    }
  }

  /// 光标在 mention 内部或末尾时退格，对齐 Android `contains2`。
  TopicMentionRangeModel? _mentionHitByBackspace(int cursorBeforeDelete) {
    for (final rangeModel in mentionList) {
      if (rangeModel.from < cursorBeforeDelete &&
          rangeModel.to >= cursorBeforeDelete &&
          cursorBeforeDelete != rangeModel.from) {
        return rangeModel;
      }
    }
    return null;
  }

  /// 退格已经删掉一个字符后，把这段 mention 的剩余文字一并删掉。
  void _deleteWholeMention({
    required TopicMentionRangeModel hit,
    required int newBreakIndex,
    required int oldDeletedEnd,
  }) {
    final tailLength = hit.to - oldDeletedEnd;
    final removeFrom = hit.from.clamp(0, text.length);
    final removeTo = (newBreakIndex + tailLength).clamp(removeFrom, text.length);
    _isApplying = true;
    try {
      mentionList.remove(hit);
      final removedLength = hit.to - hit.from;
      for (final rangeModel in mentionList) {
        if (rangeModel.from >= hit.to) {
          rangeModel.shift(-removedLength);
        }
      }
      value = TextEditingValue(
        text: text.replaceRange(removeFrom, removeTo, ''),
        selection: TextSelection.collapsed(offset: removeFrom),
      );
      _previousText = text;
    } finally {
      _isApplying = false;
    }
  }

  void _whenDelText(int start, int end, int offset) {
    mentionList.removeWhere(
      (rangeModel) => rangeModel.isWrapped(start: start, end: end),
    );
    for (final rangeModel in mentionList) {
      if (rangeModel.from >= end) {
        rangeModel.shift(offset);
      }
    }
  }

  void _shiftMentionsAfter(int start, int offset) {
    for (final rangeModel in mentionList) {
      if (rangeModel.from >= start) {
        rangeModel.shift(offset);
      }
    }
  }

  void _deleteRange(int start, int end) {
    _whenDelText(start, end, start - end);
    value = TextEditingValue(
      text: text.replaceRange(start, end, ''),
      selection: TextSelection.collapsed(offset: start),
    );
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (mentionList.isEmpty) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }

    final sortedList = List<TopicMentionRangeModel>.from(mentionList)
      ..sort((a, b) => a.from.compareTo(b.from));
    final spanList = <InlineSpan>[];
    var cursor = 0;
    for (final rangeModel in sortedList) {
      final from = rangeModel.from.clamp(0, text.length);
      final to = rangeModel.to.clamp(0, text.length);
      if (from < cursor || to <= from) {
        continue;
      }
      if (from > cursor) {
        spanList.add(
          TextSpan(text: text.substring(cursor, from), style: style),
        );
      }
      spanList.add(
        TextSpan(
          text: text.substring(from, to),
          style: (style ?? const TextStyle()).copyWith(color: AppColors.link),
        ),
      );
      cursor = to;
    }
    if (cursor < text.length) {
      spanList.add(TextSpan(text: text.substring(cursor), style: style));
    }
    return TextSpan(style: style, children: spanList);
  }
}
