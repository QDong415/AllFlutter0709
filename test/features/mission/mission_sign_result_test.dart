import 'package:all_flutter0709/features/mission/data/mission_sign_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromJson 解析 earn/count/coin', () {
    final result = MissionSignResult.fromJson({
      'earn': '2',
      'count': 4,
      'coin': 8,
    });
    expect(result.earn, 2);
    expect(result.count, 4);
    expect(result.coin, 8);
    expect(result.hasServerPayload, isTrue);
  });

  test('空 data 视为无服务端载荷', () {
    final result = MissionSignResult.fromJson(<String, dynamic>{});
    expect(result.earn, 0);
    expect(result.count, 0);
    expect(result.coin, 0);
    expect(result.hasServerPayload, isFalse);
  });
}
