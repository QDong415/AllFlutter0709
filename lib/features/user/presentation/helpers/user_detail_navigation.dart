import 'package:all_flutter0709/app/router/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 打开用户主页时的预填参数（对齐 Android Intent extras）。
class UserDetailArgs {
  const UserDetailArgs({this.name, this.avatar, this.userType});

  final String? name;
  final String? avatar;

  /// 预填账号类型：0 真人 / 1 AI。
  final int? userType;
}

/// 跳转用户个人主页。
void openUserDetailPage(
  BuildContext context, {
  required String userId,
  String? name,
  String? avatar,
  int? userType,
}) {
  final id = userId.trim();
  if (id.isEmpty || id == '0') return;

  context.push(
    '${AppRoutes.user}/$id',
    extra: UserDetailArgs(name: name, avatar: avatar, userType: userType),
  );
}
