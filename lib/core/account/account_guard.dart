import 'dart:async';

import 'package:all_flutter0709/app/router/app_routes.dart';
import 'package:all_flutter0709/core/account/account.dart';
import 'package:all_flutter0709/core/account/account_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

extension AccountGuardX on BuildContext {

  //其实就类似一个函数 ProviderContainer providerContainer(){ return ProviderScope.containerOf(this, listen: false); }
  //只是 Dart 用 getter 语法让你写起来像属性。其实是一个 getter，且不保存结果，每次调用currentAccount都会再走一遍providerContainer.read(accountProvider)
  //所以更不会每次创建BuildContext就会触发这些像全局变量的方法
  ProviderContainer get providerContainer =>
      ProviderScope.containerOf(this, listen: false);

  AccountModel? get currentAccount => providerContainer.read(accountProvider);

  String get currentUserId => currentAccount?.userId ?? '';

  bool ensureLoggedIn({bool redirectToLogin = true}) {
    if (currentAccount != null) {
      return true;
    }

    //如果我再写currentAccount，那么他又走了一遍providerContainer.read(accountProvider)

    if (redirectToLogin) {
      unawaited(push(AppRoutes.login));
    }
    return false;
  }
}
