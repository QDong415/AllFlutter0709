/// 用户身份类型：0 真人，1 AI。
abstract final class UserType {
  static const int human = 0;
  static const int ai = 1;

  /// 从接口字段解析 `user_type`。
  static int parse(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? human;
  }

  /// 是否为 AI 账号。
  static bool isAi(int userType) => userType == ai;
}
