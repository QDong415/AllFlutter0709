import 'package:all_flutter0709/core/account/account_provider.dart';
import 'package:all_flutter0709/features/mission/data/mission_repository.dart';
import 'package:all_flutter0709/features/mission/data/mission_sign_open_model.dart';
import 'package:all_flutter0709/features/mission/presentation/helpers/mission_sign_logic.dart';
import 'package:all_flutter0709/features/mission/presentation/widgets/sign_dialog.dart';
import 'package:all_flutter0709/features/mission/presentation/widgets/sign_success_dialog.dart';
import 'package:all_flutter0709/shared/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 主 Tab 进入后拉取并展示连续签到弹窗。
class MissionSignFlowHelper {
  MissionSignFlowHelper._();

  /// 已登录且今日未签时弹出签到；失败时静默忽略。
  static Future<void> tryShowDailySign({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    if (!context.mounted) {
      return;
    }
    if (ref.read(accountProvider) == null) {
      return;
    }

    MissionSignOpenModel openModel;
    try {
      openModel = await ref.read(missionRepositoryProvider).fetchSignOpen();
    } catch (_) {
      return;
    }

    if (!context.mounted || openModel.todaySign == 1) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return SignDialog(
          openModel: openModel,
          onClose: () => Navigator.of(dialogContext).pop(),
          onSign: () => _submitSign(
            parentContext: context,
            dialogContext: dialogContext,
            ref: ref,
            openModel: openModel,
          ),
        );
      },
    );
  }

  /// 等服务端签到成功后再关弹窗、同步金币、展示奖励。
  static Future<void> _submitSign({
    required BuildContext parentContext,
    required BuildContext dialogContext,
    required WidgetRef ref,
    required MissionSignOpenModel openModel,
  }) async {
    try {
      final result = await ref.read(missionRepositoryProvider).submitSign();

      // 优先用 sign 返回；旧接口 data 为空时用 open 推算兜底，避免弹 +0。
      final awardCoin = result.hasServerPayload && result.earn > 0
          ? result.earn
          : MissionSignLogic.todayAward(openModel);
      final streakDays = result.hasServerPayload && result.count > 0
          ? result.count
          : MissionSignLogic.streakAfterSign(openModel);

      final account = ref.read(accountProvider);
      if (account != null) {
        final nextCoin = result.hasServerPayload && result.coin > 0
            ? result.coin
            : account.coin + awardCoin;
        await ref.read(accountProvider.notifier).setAccount(
              account.copyWith(coin: nextCoin),
            );
      }

      if (!dialogContext.mounted) {
        return;
      }
      Navigator.of(dialogContext).pop();

      if (!parentContext.mounted) {
        return;
      }
      await showDialog<void>(
        context: parentContext,
        barrierDismissible: false,
        builder: (successContext) {
          return SignSuccessDialog(
            awardCoin: awardCoin,
            streakDays: streakDays,
            onConfirm: () => Navigator.of(successContext).pop(),
          );
        },
      );
    } catch (error) {
      if (dialogContext.mounted) {
        AppToast.show(dialogContext, '$error');
      }
    }
  }
}
