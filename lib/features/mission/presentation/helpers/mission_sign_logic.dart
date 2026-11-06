import 'package:all_flutter0709/features/mission/data/mission_sign_open_model.dart';

/// 连续签到天数与奖励计算，对齐 Buddy [SignDialog]。
class MissionSignLogic {
  MissionSignLogic._();

  /// 弹窗展示用的已签天数（0…6）。
  static int displayCount(MissionSignOpenModel model) {
    return model.count >= 7 ? 0 : model.count;
  }

  /// 今日签到将领取的金币。
  static int todayAward(MissionSignOpenModel model) {
    final streak = displayCount(model);
    final dayIndex = streak;
    if (dayIndex < 0 || dayIndex >= model.signRewardList.length) {
      return 1;
    }
    return model.signRewardList[dayIndex];
  }

  /// 签到成功文案里的连续天数。
  static int streakAfterSign(MissionSignOpenModel model) {
    return displayCount(model) + 1;
  }

  /// 第 [day] 天（1…7）是否已签。
  static bool isDaySigned(MissionSignOpenModel model, int day) {
    return day - 1 < displayCount(model);
  }
}
