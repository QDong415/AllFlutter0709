import 'package:all_flutter0709/app/router/app_routes.dart';
import 'package:all_flutter0709/features/user/data/user_repository.dart';
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

/// 去掉 @ 前缀后的昵称。
String mentionNameOf(String mention) {
  final text = mention.trim();
  if (text.startsWith('@')) {
    return text.substring(1).trim();
  }
  return text;
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

/// 按昵称打开个人主页，对齐 Android 点击 @提及。
Future<void> openUserDetailByName(
  BuildContext context, {
  required String name,
}) async {
  final trimmedName = mentionNameOf(name);
  if (trimmedName.isEmpty) {
    return;
  }

  try {
    final profileModel = await const UserRepository().getUserProfile(
      toName: trimmedName,
    );
    if (!context.mounted) {
      return;
    }
    openUserDetailPage(
      context,
      userId: profileModel.userId,
      name: profileModel.name,
      avatar: profileModel.avatar,
      userType: profileModel.userType,
    );
  } catch (error) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error.toString())));
  }
}
