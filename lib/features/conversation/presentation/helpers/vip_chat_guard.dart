import 'package:all_flutter0709/app/router/app_routes.dart';
import 'package:all_flutter0709/core/account/account.dart';
import 'package:all_flutter0709/core/config/app_config.dart';
import 'package:all_flutter0709/shared/widgets/app_toast.dart';
import 'package:all_flutter0709/core/vip/vip_chat_limit_exception.dart';
import 'package:all_flutter0709/core/vip/vip_chat_send_policy.dart';
import 'package:all_flutter0709/shared/widgets/vip_required_dialog.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 聊天页选图等发送前门禁（条数/女对女在入库后由 [VipChatSendPolicy] 判定）。
class VipChatGuard {
  const VipChatGuard({required AppConfig appConfig}) : _appConfig = appConfig;

  final AppConfig _appConfig;

  VipChatSendEvaluation beforePickImage(AccountModel account) {
    return VipChatSendPolicy.beforePickImage(
      account: account,
      config: _appConfig,
    );
  }
}

/// 选图前等场景：`allowServerSend==false` 时 toast / 弹 VIP。
Future<bool> applyVipSendEvaluation(
  BuildContext context,
  VipChatSendEvaluation evaluation,
) async {
  if (evaluation.allowServerSend) {
    return true;
  }
  final toast = evaluation.tipMessage;
  if (toast != null && toast.isNotEmpty && context.mounted) {
    AppToast.show(context, toast);
  }
  if (evaluation.promptOpenVip && context.mounted) {
    await showVipRequiredDialog(context);
  }
  return false;
}

Future<void> handleVipChatLimitException(
  BuildContext context,
  VipChatLimitException exception,
) async {
  if (!context.mounted) {
    return;
  }
  if (exception.message.isNotEmpty) {
    AppToast.show(context, exception.message);
  }
}

/// 弹窗引导开通 VIP（对齐 Buddy `showVipAlertView`）。
Future<void> showVipRequiredDialog(BuildContext context) async {
  final open = await VipRequiredDialog.show(context);
  if (open == true && context.mounted) {
    await context.push(AppRoutes.meVip);
  }
}
