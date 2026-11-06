import 'package:all_flutter0709/features/mission/data/mission_sign_open_model.dart';
import 'package:all_flutter0709/features/mission/presentation/helpers/mission_sign_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  MissionSignOpenModel model({required int count, List<int>? rewards}) {
    return MissionSignOpenModel(
      count: count,
      todaySign: 0,
      signRewardList: rewards ?? const [1, 1, 1, 2, 2, 3, 5],
    );
  }

  test('displayCount 满 7 天归零', () {
    expect(MissionSignLogic.displayCount(model(count: 7)), 0);
    expect(MissionSignLogic.displayCount(model(count: 3)), 3);
  });

  test('todayAward 取下一天奖励', () {
    final openModel = model(count: 2);
    expect(MissionSignLogic.todayAward(openModel), 1);
    expect(MissionSignLogic.todayAward(model(count: 4)), 2);
  });

  test('isDaySigned 对齐 Buddy 已签格', () {
    final openModel = model(count: 3);
    expect(MissionSignLogic.isDaySigned(openModel, 1), isTrue);
    expect(MissionSignLogic.isDaySigned(openModel, 3), isTrue);
    expect(MissionSignLogic.isDaySigned(openModel, 4), isFalse);
  });
}
