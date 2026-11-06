import 'package:all_flutter0709/features/mission/data/mission_sign_open_model.dart';
import 'package:all_flutter0709/features/mission/presentation/helpers/mission_sign_logic.dart';
import 'package:all_flutter0709/features/mission/presentation/widgets/sign_day_cell.dart';
import 'package:flutter/material.dart';

/// 连续签到弹窗，布局与尺寸对齐 Buddy `SignDialog` + `dialog_sign.xml`。
class SignDialog extends StatelessWidget {
  const SignDialog({
    super.key,
    required this.openModel,
    required this.onSign,
    required this.onClose,
  });

  final MissionSignOpenModel openModel;
  final VoidCallback onSign;
  final VoidCallback onClose;

  static const _signRed = Color(0xFFFE6766);

  /// `sign_bg.png` 为 1080×1588。「每日签到」画在约 y=554–612，奖励格从标题下方开始。
  static const _signBgAspect = 1588 / 1080;
  static const _rewardBlockTopFactor = 0.42;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final rewardTop = width * _signBgAspect * _rewardBlockTopFactor;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(18),
              ),
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: width * _signBgAspect,
                    child: Image.asset(
                      'assets/icons/sign/sign_bg.png',
                      fit: BoxFit.fill,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: rewardTop),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _SignDayRow(
                              openModel: openModel,
                              days: const [1, 2, 3, 4],
                            ),
                            const SizedBox(height: 8),
                            _SignDayRow(
                              openModel: openModel,
                              days: const [5, 6, 7],
                              lastWide: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 26),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(50, 0, 50, 18),
                        child: Material(
                          color: _signRed,
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            onTap: onSign,
                            borderRadius: BorderRadius.circular(20),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 6),
                              child: Center(
                                child: Text(
                                  '签到',
                                  style: TextStyle(
                                    fontSize: 17,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: onClose,
              behavior: HitTestBehavior.opaque,
              child: Image.asset(
                'assets/icons/sign/dialog_center_close_icon.png',
                width: 52,
                height: 52,
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: MediaQuery.paddingOf(context).bottom),
          ],
        ),
      ),
    );
  }
}

class _SignDayRow extends StatelessWidget {
  const _SignDayRow({
    required this.openModel,
    required this.days,
    this.lastWide = false,
  });

  final MissionSignOpenModel openModel;
  final List<int> days;
  final bool lastWide;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < days.length; index++) ...[
          if (index > 0) const SizedBox(width: 8),
          Expanded(
            flex: lastWide && index == days.length - 1 ? 2 : 1,
            child: SignDayCellWidget(
              day: days[index],
              rewardText: _rewardLabel(days[index]),
              signed: MissionSignLogic.isDaySigned(openModel, days[index]),
              isDay7: days[index] == 7,
            ),
          ),
        ],
      ],
    );
  }

  String _rewardLabel(int day) {
    final reward = openModel.signRewardList[day - 1];
    return '+ $reward金';
  }
}
