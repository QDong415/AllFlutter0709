import 'dart:async';

import 'package:all_flutter0709/features/topic/data/topic_repository.dart';
import 'package:flutter/material.dart';

/// 动态 id。
typedef Tid = String;

/// 删除动态的公共入口：请求成功后广播 tid，由各界面自行本地更新。
abstract final class TopicDeleteHelper {
  static const TopicRepository _repository = TopicRepository();

  /// 删除成功后的 tid 广播流。
  static final StreamController<Tid> controller =
      StreamController<Tid>.broadcast();

  /// 弹出 loading 挡住界面并请求删除；成功后再发出 [controller] 事件。
  static Future<void> delete(BuildContext context, Tid tid) async {
    final id = tid.trim();
    if (id.isEmpty) {
      throw Exception('缺少动态id');
    }

    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (dialogContext) {
          return const PopScope(
            canPop: false,
            child: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );

    var success = false;
    try {
      await _repository.deleteTopic(tid: id);
      success = true;
    } finally {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
    if (success) {
      controller.add(id);
    }
  }
}
