import 'package:all_flutter0709/features/user/data/user_repository.dart';

/// 关注关系常量。
abstract final class FollowRelation {
  static const int none = 0;
  static const int following = 1;
  static const int fans = 2;
  static const int each = 3;
}

/// 关注按钮文案与样式辅助。
abstract final class UserFollowHelper {
  /// 关系状态对应按钮文案。
  static String labelOf(int followStatus) {
    switch (followStatus) {
      case FollowRelation.following:
        return '已关注';
      case FollowRelation.each:
        return '互关';
      case FollowRelation.fans:
      case FollowRelation.none:
      default:
        return '关注';
    }
  }

  /// 是否为「未关注 / TA 粉我」态（橙色实心按钮）。
  static bool isFollowAction(int followStatus) {
    return followStatus == FollowRelation.none ||
        followStatus == FollowRelation.fans;
  }

  /// 关注按钮左侧图标。
  static String iconAssetOf(int followStatus) {
    switch (followStatus) {
      case FollowRelation.following:
        return 'assets/icons/user/profile_icon_followed_black_m_normal.png';
      case FollowRelation.each:
        return 'assets/icons/user/profile_icon_followeachother_black_m_normal.png';
      case FollowRelation.fans:
      case FollowRelation.none:
      default:
        return 'assets/icons/user/profile_icon_follow_white_s_normal.png';
    }
  }

  /// 发起关注请求，返回最新关系。
  static Future<int> follow({
    required UserRepository repository,
    required String toUserId,
  }) {
    return repository.followUser(toUserId: toUserId);
  }
}
