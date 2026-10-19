import 'dart:convert';
import 'dart:io';

import 'package:all_flutter0709/core/account/account.dart';
import 'package:all_flutter0709/core/account/account_api_exception.dart';
import 'package:all_flutter0709/core/network/api_response.dart';
import 'package:all_flutter0709/core/network/http_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences 尚未初始化');
});

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository(preferences: ref.watch(sharedPreferencesProvider));
});

/// 账号仓库：登录/注册/验证码请求，以及本地账号读写。
class AccountRepository {
  AccountRepository({required SharedPreferences preferences})
    : _preferences = preferences;

  static const _currentAccountStorageKey = 'current-account';

  final SharedPreferences _preferences;

  /// 从本地读取当前账号；无效数据会清除并返回 null。
  AccountModel? readAccountFromStorage() {
    final rawJson = _preferences.getString(_currentAccountStorageKey);
    if (rawJson == null || rawJson.isEmpty) {
      return null;
    }

    try {
      return AccountModel.fromJson(jsonDecode(rawJson) as Map<String, dynamic>);
    } catch (_) {
      _preferences.remove(_currentAccountStorageKey);
      return null;
    }
  }

  /// 账号密码登录（`POST /api/user/login`）。
  Future<AccountModel> login({
    required String mobile,
    required String password,
  }) async {
    final response = await HttpClient.instance.post(
      '/api/user/login',
      data: {'mobile': mobile, 'password': password},
    );

    final json = response.data;
    if (json == null) {
      throw Exception('服务器返回为空');
    }

    final result = ApiResponse<AccountModel>.fromJson(
      json,
      (dataJson) => AccountModel.fromJson(dataJson as Map<String, dynamic>),
    );

    if (!result.success) {
      throw Exception(result.message.isEmpty ? '登录失败' : result.message);
    }

    final account = result.data;
    if (account == null || !account.isValid) {
      throw Exception('登录成功，但用户信息为空');
    }

    return account;
  }

  /// 验证码登录（`POST /api/user/codelogin`）。
  ///
  /// 未注册时抛出 [AccountApiException]，`code` 为 -2。
  Future<AccountModel> loginBySmsCode({
    required String mobile,
    required String code,
  }) async {
    final response = await HttpClient.instance.post(
      '/api/user/codelogin',
      data: {'mobile': mobile, 'code': code},
    );

    final json = response.data;
    if (json == null) {
      throw AccountApiException('服务器返回为空');
    }

    final result = ApiResponse<AccountModel>.fromJson(
      json,
      (dataJson) => AccountModel.fromJson(dataJson as Map<String, dynamic>),
    );

    if (result.code == -2) {
      throw AccountApiException(
        result.message.isEmpty ? '尚未注册' : result.message,
        code: -2,
      );
    }

    if (!result.success) {
      throw AccountApiException(
        result.message.isEmpty ? '验证码登录失败' : result.message,
        code: result.code,
      );
    }

    final account = result.data;
    if (account == null || !account.isValid) {
      throw AccountApiException('登录成功，但用户信息为空');
    }

    return account;
  }

  /// 友盟一键登录（`POST /api/user/ummobile`）。
  ///
  /// `code = 2` 表示未注册，返回手机号和临时验证码，供完善资料。
  Future<CarrierLoginResult> loginByCarrierToken({
    required String token,
    required String verifyId,
  }) async {
    final response = await HttpClient.instance.post(
      '/api/user/ummobile',
      data: {
        'token': token,
        'verifyId': verifyId,
        'os': Platform.isIOS ? 'ios' : 'android',
      },
    );

    final json = response.data;
    if (json == null) {
      throw AccountApiException('服务器返回为空');
    }

    final code = (json['code'] as num?)?.toInt() ?? 0;
    final message = json['message'] as String? ?? '';
    final data = json['data'];

    if (code == 2 && data is Map) {
      return CarrierLoginResult.needProfile(
        mobile: data['mobile']?.toString() ?? '',
        smsCode: data['code']?.toString() ?? '',
      );
    }

    final result = ApiResponse<AccountModel>.fromJson(
      json,
      (dataJson) => AccountModel.fromJson(dataJson as Map<String, dynamic>),
    );
    if (!result.success) {
      throw AccountApiException(
        message.isEmpty ? '一键登录失败' : message,
        code: code,
      );
    }
    final account = result.data;
    if (account == null || !account.isValid) {
      throw AccountApiException('登录成功，但用户信息为空');
    }
    return CarrierLoginResult.account(account);
  }

  /// 发送手机验证码（`POST /api/user/coderequire`）。
  Future<void> requestSmsCode({
    required String mobile,
    String? captchaVerifyParam,
  }) async {
    final data = <String, dynamic>{'mobile': mobile};
    if (captchaVerifyParam != null && captchaVerifyParam.isNotEmpty) {
      data['captchaVerifyParam'] = captchaVerifyParam;
    }
    final response = await HttpClient.instance.post(
      '/api/user/coderequire',
      data: data,
    );

    final json = response.data;
    if (json == null) {
      throw Exception('服务器返回为空');
    }

    final result = ApiResponse<void>.fromJson(json);
    if (!result.success) {
      throw Exception(result.message.isEmpty ? '验证码发送失败' : result.message);
    }
  }

  /// 注册账号（`POST /api/user/register`）。
  Future<AccountModel> register({
    required String mobile,
    required String code,
    required String name,
    required String password,
    String avatar = '',
  }) async {
    final response = await HttpClient.instance.post(
      '/api/user/register',
      data: {
        'mobile': mobile,
        'code': code,
        'name': name,
        'password': password,
        'avatar': avatar,
      },
    );

    final json = response.data;
    if (json == null) {
      throw Exception('服务器返回为空');
    }

    final result = ApiResponse<AccountModel>.fromJson(
      json,
      (dataJson) => AccountModel.fromJson(dataJson as Map<String, dynamic>),
    );

    if (!result.success) {
      throw Exception(result.message.isEmpty ? '注册失败' : result.message);
    }

    final account = result.data;
    if (account == null || !account.isValid) {
      throw Exception('注册成功，但用户信息为空');
    }

    return account;
  }

  /// 将账号写入本地存储。
  Future<void> writeAccountToStorage(AccountModel account) {
    return _preferences.setString(
      _currentAccountStorageKey,
      jsonEncode(account.toJson()),
    );
  }

  /// 清除本地账号。
  Future<void> clearAccount() {
    return _preferences.remove(_currentAccountStorageKey);
  }

  /// 注销当前账号（`POST /api/user/cancel`）。`userid` 由请求拦截器附带。
  Future<void> cancelAccount() async {
    final response = await HttpClient.instance.post('/api/user/cancel');
    final json = response.data;
    if (json == null) {
      throw Exception('服务器返回为空');
    }

    final result = ApiResponse<void>.fromJson(json);
    if (!result.success) {
      throw Exception(result.message.isEmpty ? '注销失败' : result.message);
    }
  }
}

/// 友盟一键登录结果：已注册账号，或未注册时的手机号和临时验证码。
class CarrierLoginResult {
  const CarrierLoginResult.account(this.account)
    : mobile = null,
      smsCode = null;

  const CarrierLoginResult.needProfile({
    required this.mobile,
    required this.smsCode,
  }) : account = null;

  final AccountModel? account;
  final String? mobile;
  final String? smsCode;

  bool get needsProfile => account == null;
}
