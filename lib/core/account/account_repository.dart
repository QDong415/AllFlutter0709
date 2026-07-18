import 'dart:convert';

import 'package:all_flutter0709/core/account/account.dart';
import 'package:all_flutter0709/core/network/api_response.dart';
import 'package:all_flutter0709/core/network/http_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _currentAccountStorageKey = 'current-account';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences 尚未初始化');
});

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository(
    preferences: ref.watch(sharedPreferencesProvider),
    dio: HttpClient.instance.dio,
  );
});

class AccountRepository {
  const AccountRepository({
    required SharedPreferences preferences,
    required Dio dio,
  }) : _preferences = preferences,
       _dio = dio;

  final SharedPreferences _preferences;
  final Dio _dio;

  AccountModel? restoreAccount() {
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

  Future<AccountModel> login({
    required String mobile,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/user/login',
      data: {'mobile': mobile, 'password': password},
      options: Options(contentType: Headers.formUrlEncodedContentType),
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

    await persistAccount(account);
    await notifyUserOpen();
    return account;
  }

  Future<void> persistAccount(AccountModel account) {
    return _preferences.setString(
      _currentAccountStorageKey,
      jsonEncode(account.toJson()),
    );
  }

  Future<void> clearAccount() {
    return _preferences.remove(_currentAccountStorageKey);
  }

  Future<void> notifyUserOpen() async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/api/user/open',
        data: const <String, dynamic>{},
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
    } catch (_) {
      // 这个接口只用于服务端记录登录设备，失败不阻塞主登录流程。
    }
  }
}
