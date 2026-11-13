/// 金币或魅力值的一条流水。
class WalletLogModel {
  const WalletLogModel({
    required this.id,
    required this.amount,
    required this.remark,
    required this.type,
    required this.createTime,
    required this.displayTime,
  });

  final int id;

  /// 正数增加，负数减少。
  final int amount;
  final String remark;
  final int type;
  final int createTime;
  final String displayTime;

  /// 从 `money_log` 行解析。
  factory WalletLogModel.fromMoneyJson(Map<String, dynamic> json) {
    return WalletLogModel._fromJson(
      json,
      amountKey: 'money_add',
    );
  }

  /// 从 `charm_log` 行解析。
  factory WalletLogModel.fromCharmJson(Map<String, dynamic> json) {
    return WalletLogModel._fromJson(
      json,
      amountKey: 'charm_add',
    );
  }

  factory WalletLogModel._fromJson(
    Map<String, dynamic> json, {
    required String amountKey,
  }) {
    final createTime = _readInt(json['create_time']);
    return WalletLogModel(
      id: _readInt(json['id']),
      amount: _readInt(json[amountKey]),
      remark: '${json['remark'] ?? ''}',
      type: _readInt(json['type']),
      createTime: createTime,
      displayTime: _formatTime(createTime),
    );
  }
}

/// 流水列表分页结果。
class WalletLogPageResult {
  const WalletLogPageResult({
    required this.items,
    required this.hasMore,
  });

  final List<WalletLogModel> items;
  final bool hasMore;
}

int _readInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse('$value') ?? 0;
}

String _formatTime(int timestamp) {
  if (timestamp <= 0) {
    return '--';
  }
  final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${date.year}-$month-$day $hour:$minute';
}
