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

  /// 友盟一键登录并落登录态。未注册时不写本地账号，把结果交回页面。
  Future<CarrierLoginResult> loginByCarrierToken({
    required String token,
    required String verifyId,
  }) async {
    final result = await _repository.loginByCarrierToken(
      token: token,
      verifyId: verifyId,
    );
    final account = result.account;
    if (account != null) {
      await _repository.writeAccountToStorage(account);
      HttpClient.instance.updateUserId(account.userId);
      state = account;
    }
    return result;
  }

  /// 验证码登录并落登录态。未注册时原样抛出，由页面去完善资料。
  Future<void> loginBySmsCode({
    required String mobile,
    required String code,
  }) async {
    final account = await _repository.loginBySmsCode(
      mobile: mobile,
      code: code,
    );
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

  /// 注销账号并清除本地登录态。服务端成功后才清本地，失败时保持登录。
  Future<void> cancelAccount() async {
    if (state == null) {
      throw Exception('请先登录');
    }
    await _repository.cancelAccount();
    await _repository.clearAccount();
    HttpClient.instance.updateUserId(null);
    state = null;
  }
}
