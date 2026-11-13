/// `mission/sign` 成功返回：本次奖励与最新余额。
class MissionSignResult {
  const MissionSignResult({
    required this.earn,
    required this.count,
    required this.coin,
    required this.hasServerPayload,
  });

  /// 本次发放金币。
  final int earn;

  /// 签到后的连续天数（1…7）。
  final int count;

  /// 签到后的金币余额。
  final int coin;

  /// 响应里是否带了 `earn`/`count`/`coin`（旧接口 data 为空时为 false）。
  final bool hasServerPayload;

  factory MissionSignResult.fromJson(Map<String, dynamic> json) {
    final hasServerPayload = json.containsKey('earn') ||
        json.containsKey('count') ||
        json.containsKey('coin');
    return MissionSignResult(
      earn: _readInt(json['earn']),
      count: _readInt(json['count']),
      coin: _readInt(json['coin']),
      hasServerPayload: hasServerPayload,
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
