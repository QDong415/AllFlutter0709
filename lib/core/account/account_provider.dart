import 'package:all_flutter0709/core/account/account.dart';
import 'package:all_flutter0709/core/account/account_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final accountProvider = NotifierProvider<AccountNotifier, AccountModel?>(
  AccountNotifier.new,
);

class AccountNotifier extends Notifier<AccountModel?> {
  AccountRepository get _repository => ref.read(accountRepositoryProvider);

  @override
  AccountModel? build() {
    return _repository.restoreAccount();
  }

  bool get isLogin => state != null;

  Future<void> login({required String mobile, required String password}) async {
    final account = await _repository.login(mobile: mobile, password: password);
    state = account;
  }

  Future<void> setAccount(AccountModel account) async {
    await _repository.persistAccount(account);
    state = account;
  }

  Future<void> updateName(String name) async {
    final current = state;
    if (current == null) {
      return;
    }

    final next = current.copyWith(name: name);
    await _repository.persistAccount(next);
    state = next;
  }

  Future<void> updateAvatar(String avatar) async {
    final current = state;
    if (current == null) {
      return;
    }

    final next = current.copyWith(avatar: avatar);
    await _repository.persistAccount(next);
    state = next;
  }

  Future<void> logout() async {
    await _repository.clearAccount();
    state = null;
  }
}
