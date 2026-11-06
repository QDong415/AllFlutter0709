/// `mission/open` 返回的连续签到状态。
class MissionSignOpenModel {
  const MissionSignOpenModel({
    required this.count,
    required this.todaySign,
    required this.signRewardList,
  });

  /// 最近一条 `user_sign.count`（当次签到后的连续天数 1…7）；展示前经 [MissionSignLogic.displayCount]。
  final int count;

  /// 1 表示今天已签。
  final int todaySign;

  /// 第 1…7 天奖励金币，下标 0…6。
  final List<int> signRewardList;

  factory MissionSignOpenModel.fromJson(Map<String, dynamic> json) {
    final rewardList = <int>[];
    for (var day = 1; day <= 7; day++) {
      rewardList.add(_readInt(json['sign_$day']));
    }
    return MissionSignOpenModel(
      count: _readInt(json['count']),
      todaySign: _readInt(json['today_sign']),
      signRewardList: rewardList,
    );
  }

  static int _readInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
