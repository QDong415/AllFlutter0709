import 'dart:async';
import 'dart:io';

import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/core/auth/auth_vendor_config.dart';
import 'package:all_flutter0709/core/network/app_env.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';
import 'package:umeng_verify_sdk/umeng_verify_sdk.dart';

/// 友盟一键登录取出的运营商 token。
class OneTapCredential {
  const OneTapCredential({required this.token, required this.verifyId});

  final String token;
  final String verifyId;
}

/// 一键登录授权页的结果。用户取消时 [cancelled] 为 true。
class OneTapLoginResult {
  const OneTapLoginResult._({
    this.credential,
    this.cancelled = false,
    this.message,
  });

  const OneTapLoginResult.success(OneTapCredential credential)
    : this._(credential: credential);

  const OneTapLoginResult.cancelled() : this._(cancelled: true);

  const OneTapLoginResult.failed(String message) : this._(message: message);

  final OneTapCredential? credential;
  final bool cancelled;
  final String? message;

  bool get success => credential != null;
}

/// 拉起友盟智能认证授权页，成功后返回 token 与 verifyId。
class UmengOneTapLogin {
  UmengOneTapLogin._();

  static const MethodChannel _iosAuthChannel = MethodChannel(
    'com.dq.itopic/umeng_auth',
  );
  static bool _prepared = false;
  static Future<void>? _preparing;
  static Completer<OneTapLoginResult>? _pending;

  /// 初始化方案密钥。可重复调用，进行中的那一次会被共用。
  static Future<void> prepare() {
    if (!AuthVendorConfig.oneTapEnabled || _prepared) {
      return Future<void>.value();
    }
    return _preparing ??= _prepare();
  }

  static Future<void> _prepare() async {
    try {
      if (Platform.isIOS) {
        final result = await _iosAuthChannel
            .invokeMapMethod<String, dynamic>('waitUntilPrepared');
        final code =
            (result?['resultCode'] ?? result?['code'])?.toString() ?? '';
        if (code != '600000') {
          throw Exception(result?['msg']?.toString() ?? '友盟认证初始化失败');
        }
      } else if (Platform.isAndroid) {
        UmengVerifySdk.register_android();
        unawaited(
          UmengCommonSdk.initCommon(
            AuthVendorConfig.androidAppKey,
            AuthVendorConfig.iosAppKey,
            'itopic',
          ),
        );
        await UmengVerifySdk.setVerifySDKInfo(
          AuthVendorConfig.androidVerifySecret,
          AuthVendorConfig.iosVerifySecret,
        );
      }
      _prepared = true;
    } catch (error) {
      _preparing = null;
      rethrow;
    }
  }

  /// 拉起授权页。同一时间只允许一次。
  static Future<OneTapLoginResult> start() async {
    if (!AuthVendorConfig.oneTapEnabled) {
      return const OneTapLoginResult.failed('一键登录尚未配置');
    }
    if (_pending != null && !_pending!.isCompleted) {
      return _pending!.future;
    }

    final pending = Completer<OneTapLoginResult>();
    _pending = pending;

    try {
      if (Platform.isAndroid) {
        await Permission.phone.request();
      }
      await prepare();
      if (Platform.isIOS) {
        final accelerate = await UmengVerifySdk.accelerateLoginPageWithTimeout(
          3,
        );
        final accelerateCode = accelerate is Map
            ? (accelerate['resultCode'] ?? accelerate['code'])?.toString() ?? ''
            : '';
        if (accelerateCode != '600000') {
          final message = accelerate is Map
              ? accelerate['msg']?.toString()
              : null;
          _finish(
            OneTapLoginResult.failed(message ?? '一键登录预取号失败'),
          );
          return pending.future;
        }
      }
      _listen();
      UmengVerifySdk.getLoginTokenWithTimeout(5, _uiModel());
    } catch (error) {
      _finish(OneTapLoginResult.failed(error.toString()));
    }

    return pending.future;
  }

  static void _listen() {
    UmengVerifySdk.getLoginTokenCallback((result) {
      _onToken(result);
    });
    UmengVerifySdk.setTokenResultCallback_android((result) {
      _onToken(result);
    });
    UmengVerifySdk.setUIClickCallback_android((result) {
      final code = result['code']?.toString() ?? '';
      if (code == '700000' || code == '700001') {
        _closePage();
        _finish(const OneTapLoginResult.cancelled());
      }
    });
  }

  static void _onToken(Map<dynamic, dynamic> result) {
    final code = (result['code'] ?? result['resultCode'])?.toString() ?? '';
    if (code == '600001' || code.isEmpty) {
      return;
    }
    // 700002 点登录、700003 点协议勾选、700004 点协议文字。这些不是失败。
    // 未勾选时原生授权页会震动协议区，不能当成登录失败把授权页关掉。
    if (code.startsWith('700')) {
      if (code == '700000' || code == '700001') {
        _closePage();
        _finish(const OneTapLoginResult.cancelled());
      }
      return;
    }
    final token = result['token']?.toString() ?? '';
    if (code == '600000' && token.isNotEmpty) {
      unawaited(_completeWithToken(token));
      return;
    }
    _closePage();
    final message = result['msg']?.toString() ?? '一键登录不可用';
    _finish(OneTapLoginResult.failed(message));
  }

  static Future<void> _completeWithToken(String token) async {
    final verifyId = (await UmengVerifySdk.getVerifyId())?.trim() ?? '';
    _closePage();
    if (verifyId.isEmpty) {
      _finish(const OneTapLoginResult.failed('未拿到认证标识'));
      return;
    }
    _finish(
      OneTapLoginResult.success(
        OneTapCredential(token: token, verifyId: verifyId),
      ),
    );
  }

  static void _closePage() {
    if (kIsWeb) {
      return;
    }
    if (Platform.isAndroid) {
      UmengVerifySdk.quitLoginPage_android();
      UmengVerifySdk.hideLoginLoading();
    } else if (Platform.isIOS) {
      unawaited(UmengVerifySdk.cancelLoginVCAnimated(true));
    }
  }

  static void _finish(OneTapLoginResult result) {
    final pending = _pending;
    if (pending == null || pending.isCompleted) {
      return;
    }
    pending.complete(result);
  }

  static UMCustomModel _uiModel() {
    final model = UMCustomModel();
    model.navIsHidden = true;
    model.logoIsHidden = true;
    model.loginBtnText = const <Object>['本机号码一键登录', 0xFFFFFF, 16.0];
    model.loginBtnBgImgs_ios = const <String>[
      'one_tap_login_normal',
      'one_tap_login_disabled',
      'one_tap_login_pressed',
    ];
    model.changeBtnTitle = <Object>[
      '使用手机验证码登录',
      AppColors.titleText.toARGB32() & 0xFFFFFF,
      14.0,
    ];
    // y、宽、高传 0 或负数，原生侧沿用默认纵向位置并把按钮拉满，避免文案被截断。
    model.changeBtnFrame = const <double>[0, -1, 0, 0];
    model.privacyOne = <String>[
      '《用户服务协议》',
      '${AppEnv.apiBaseUrl}/home/article/agreement?agreementid=1',
    ];
    model.privacyTwo = <String>[
      '《用户隐私协议》',
      '${AppEnv.apiBaseUrl}/home/article/agreement?agreementid=2',
    ];
    model.privacyOperatorPreText = '《';
    model.privacyOperatorSufText = '》';
    model.privacyColors = <int>[0xFF8A8A8A, AppColors.link.toARGB32()];
    model.checkBoxIsHidden = false;
    model.checkBoxIsChecked = false;
    return model;
  }
}
