import 'package:all_flutter0709/core/account/account_provider.dart';
import 'package:all_flutter0709/features/mission/data/mission_repository.dart';
import 'package:all_flutter0709/features/mission/data/mission_sign_open_model.dart';
import 'package:all_flutter0709/features/mission/presentation/helpers/mission_sign_logic.dart';
import 'package:all_flutter0709/features/mission/presentation/widgets/sign_dialog.dart';
import 'package:all_flutter0709/features/mission/presentation/widgets/sign_success_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 主 Tab 进入后拉取并展示连续签到弹窗，流程对齐 Buddy MainActivity。
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
          onSign: () {
            Navigator.of(dialogContext).pop();
            _onSignTapped(
              context: context,
              ref: ref,
              openModel: openModel,
            );
          },
        );
      },
    );
  }

  static void _onSignTapped({
    required BuildContext context,
    required WidgetRef ref,
    required MissionSignOpenModel openModel,
  }) {
    final award = MissionSignLogic.todayAward(openModel);
    final streakDays = MissionSignLogic.streakAfterSign(openModel);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (successContext) {
        return SignSuccessDialog(
          awardCoin: award,
          streakDays: streakDays,
          onConfirm: () => Navigator.of(successContext).pop(),
        );
      },
    );

    final account = ref.read(accountProvider);
    if (account != null) {
      ref.read(accountProvider.notifier).setAccount(
            account.copyWith(coin: account.coin + award),
          );
    }

    ref.read(missionRepositoryProvider).submitSign().catchError((_) {});
  }
}
