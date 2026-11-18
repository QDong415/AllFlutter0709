import 'dart:async';

import 'package:all_flutter0709/core/network/http_client.dart';
import 'package:all_flutter0709/features/conversation/data/models/conversation_summary.dart';
import 'package:all_flutter0709/features/conversation/presentation/conversation_controller.dart';
import 'package:all_flutter0709/features/conversation/presentation/widgets/conversation_ai_delete_dialog.dart';
import 'package:all_flutter0709/features/conversation/presentation/widgets/conversation_list_item.dart';
import 'package:all_flutter0709/shared/widgets/app_toast.dart';
import 'package:flutter/material.dart';

/// 会话列表删除：真人只删本地，AI 先确认再清服务端记忆。
abstract final class ConversationDeleteHelper {
  /// 左滑删除入口。AI 取消或接口失败时保留本地会话。
  static Future<void> delete({
    required BuildContext context,
    required ConversationController controller,
    required ConversationSummary summaryModel,
  }) async {
    ConversationListItem.closeOpenSwipe();
    if (!summaryModel.isAi) {
      await controller.deleteConversation(summaryModel.conversationId);
      return;
    }

    final confirmed = await ConversationAiDeleteDialog.show(context);
    if (confirmed != true || !context.mounted) {
      return;
    }

    final navigator = Navigator.of(context, rootNavigator: true);
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

    try {
      await controller.deleteAiConversation(summaryModel.conversationId);
    } catch (error) {
      if (context.mounted) {
        AppToast.show(context, HttpClient.instance.describeError(error));
      }
    } finally {
      if (navigator.mounted) {
        navigator.pop();
      }
    }
  }
}
