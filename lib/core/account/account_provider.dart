import 'package:all_flutter0709/core/account/account.dart';
import 'package:all_flutter0709/core/account/account_repository.dart';
import 'package:all_flutter0709/core/network/http_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final accountProvider = NotifierProvider<AccountNotifier, AccountModel?>(
  AccountNotifier.new,
);

class AccountNotifier extends Notifier<AccountModel?> {
  AccountRepository get _repository => ref.read(accountRepositoryProvider);

  @override
  AccountModel? build() {
    final account = _repository.readAccountFromStorage();
    HttpClient.instance.updateUserId(account?.userId);
    return account;
  }

  bool get isLogin => state != null;

  Future<void> login({required String mobile, required String password}) async {
    final account = await _repository.login(mobile: mobile, password: password);
    await _repository.writeAccountToStorage(account);
    HttpClient.instance.updateUserId(account.userId);
    state = account;
  }

  /// 注册并落登录态。
  Future<void> register({
    required String mobile,
    required String code,
    required String name,
    required String password,
    String avatar = '',
  }) async {
    final account = await _repository.register(
      mobile: mobile,
      code: code,
      name: name,
      password: password,
      avatar: avatar,
    );
    await _repository.writeAccountToStorage(account);
    HttpClient.instance.updateUserId(account.userId);
    state = account;
  }

  Future<void> setAccount(AccountModel account) async {
    await _repository.writeAccountToStorage(account);
    HttpClient.instance.updateUserId(account.userId);
    state = account;
  }

  Future<void> updateName(String name) async {
    final current = state;
    if (current == null) {
      return;
    }

    final next = current.copyWith(name: name);
    await _repository.writeAccountToStorage(next);
    state = next;
  }

  Future<void> updateAvatar(String avatar) async {
    final current = state;
    if (current == null) {
      return;
    }

    final next = current.copyWith(avatar: avatar);
    await _repository.writeAccountToStorage(next);
    state = next;
  }

  Future<void> logout() async {
    await _repository.clearAccount();
    HttpClient.instance.updateUserId(null);
    state = null;
  }
}
