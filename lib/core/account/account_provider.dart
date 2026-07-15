import 'package:all_flutter0709/core/account/account.dart';
import 'package:riverpod/riverpod.dart';

final accountProvider = Provider<Account>((ref) {
  return Account.instance;
});
