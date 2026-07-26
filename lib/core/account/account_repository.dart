import 'dart:convert';

import 'package:all_flutter0709/core/account/account.dart';
import 'package:all_flutter0709/core/network/api_response.dart';
import 'package:all_flutter0709/core/network/http_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  AccountRepository({required SharedPreferences preferences, required Dio dio})
    : _preferences = preferences,
      _dio = dio;

  static const _currentAccountStorageKey = 'current-account';

  final SharedPreferences _preferences;
  final Dio _dio;

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

    return account;
  }

  /// 发送手机验证码（`POST /api/user/coderequire`）。
  Future<void> requestSmsCode({required String mobile}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/user/coderequire',
      data: {'mobile': mobile},
      options: Options(contentType: Headers.formUrlEncodedContentType),
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
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/user/register',
      data: {
        'mobile': mobile,
        'code': code,
        'name': name,
        'password': password,
        'avatar': avatar,
      },
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
      throw Exception(result.message.isEmpty ? '注册失败' : result.message);
    }

    final account = result.data;
    if (account == null || !account.isValid) {
      throw Exception('注册成功，但用户信息为空');
    }

    return account;
  }

  Future<void> writeAccountToStorage(AccountModel account) {
    return _preferences.setString(
      _currentAccountStorageKey,
      jsonEncode(account.toJson()),
    );
  }

  Future<void> clearAccount() {
    return _preferences.remove(_currentAccountStorageKey);
  }
}
