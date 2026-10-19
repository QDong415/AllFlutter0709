import 'dart:async';

import 'package:all_flutter0709/app/app_flags.dart';
import 'package:all_flutter0709/app/router/app_routes.dart';
import 'package:all_flutter0709/core/account/account_api_exception.dart';
import 'package:all_flutter0709/core/account/account_provider.dart';
import 'package:all_flutter0709/core/account/account_repository.dart';
import 'package:all_flutter0709/core/auth/auth_vendor_config.dart';
import 'package:all_flutter0709/core/auth/umeng_one_tap_login.dart';
import 'package:all_flutter0709/features/auth/presentation/models/signup_args.dart';
import 'package:all_flutter0709/features/auth/presentation/widgets/aliyun_captcha_page.dart';
import 'package:all_flutter0709/features/auth/presentation/widgets/sms_login_code_view.dart';
import 'package:all_flutter0709/features/auth/presentation/widgets/sms_login_phone_view.dart';
import 'package:all_flutter0709/shared/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 登录页：默认短信验证码，可切换密码登录。
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

enum _LoginStage { phone, code }

class _LoginPageState extends ConsumerState<LoginPage> {
  final _mobileController = TextEditingController();
  final _codeController = TextEditingController();

  _LoginStage _stage = _LoginStage.phone;
  bool _agreed = false;
  bool _isRequestingCode = false;
  bool _isSubmitting = false;
  bool _isOneTapBusy = false;
  int _countdownSeconds = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    if (AuthVendorConfig.oneTapEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _startOneTap();
        }
      });
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _mobileController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  String get _mobile => _mobileController.text.trim();

  Future<void> _requestSmsCode() async {
    if (_mobile.length != 11) {
      AppToast.show(context, '请输入手机号码');
      return;
    }
    if (!_agreed) {
      AppToast.show(context, '请先同意用户协议和隐私政策');
      return;
    }
    if (_countdownSeconds > 0 || _isRequestingCode) {
      return;
    }

    FocusScope.of(context).unfocus();
    String? captchaVerifyParam;
    if (AuthVendorConfig.captchaEnabled) {
      captchaVerifyParam = await AliyunCaptchaPage.show(context);
      if (!mounted ||
          captchaVerifyParam == null ||
          captchaVerifyParam.isEmpty) {
        return;
      }
    }

    setState(() {
      _isRequestingCode = true;
    });

    try {
      await ref
          .read(accountRepositoryProvider)
          .requestSmsCode(
            mobile: _mobile,
            captchaVerifyParam: captchaVerifyParam,
          );
      if (!mounted) {
        return;
      }
      _codeController.clear();
      _startCountdown();
      setState(() {
        _stage = _LoginStage.code;
      });
      AppToast.show(context, '验证码已发送');
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppToast.show(context, _messageOf(error));
    } finally {
      if (mounted) {
        setState(() {
          _isRequestingCode = false;
        });
      }
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _countdownSeconds = 60;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdownSeconds <= 1) {
        timer.cancel();
        setState(() {
          _countdownSeconds = 0;
        });
        return;
      }
      setState(() {
        _countdownSeconds -= 1;
      });
    });
  }

  Future<void> _loginByCode(String code) async {
    if (_isSubmitting || code.length != 4) {
      return;
    }

    if (AppFlags.testLogin && code == '0000') {
      _codeController.clear();
      context.push(
        AppRoutes.signupPassword,
        extra: SignupArgs(mobile: _mobile, code: code, password: ''),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref
          .read(accountProvider.notifier)
          .loginBySmsCode(mobile: _mobile, code: code);
      if (mounted) {
        context.go(AppRoutes.topic);
      }
    } on AccountApiException catch (error) {
      if (!mounted) {
        return;
      }
      if (error.isUnregistered) {
        _codeController.clear();
        AppToast.show(context, '尚未注册，请完善资料');
        context.push(
          AppRoutes.signupPassword,
          extra: SignupArgs(mobile: _mobile, code: code, password: ''),
        );
        return;
      }
      _codeController.clear();
      AppToast.show(context, error.message);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _codeController.clear();
      AppToast.show(context, _messageOf(error));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _startOneTap() async {
    if (_isOneTapBusy || _stage != _LoginStage.phone) {
      return;
    }
    setState(() {
      _isOneTapBusy = true;
    });
    try {
      final result = await UmengOneTapLogin.start();
      if (!mounted || result.cancelled) {
        return;
      }
      if (!result.success || result.credential == null) {
        AppToast.show(context, result.message ?? '一键登录不可用，请使用短信验证码');
        return;
      }
      final credential = result.credential!;
      final loginResult = await ref
          .read(accountProvider.notifier)
          .loginByCarrierToken(
            token: credential.token,
            verifyId: credential.verifyId,
          );
      if (!mounted) {
        return;
      }
      final account = loginResult.account;
      if (account != null) {
        context.go(AppRoutes.topic);
        return;
      }
      AppToast.show(context, '尚未注册，请完善资料');
      context.push(
        AppRoutes.signupPassword,
        extra: SignupArgs(
          mobile: loginResult.mobile ?? '',
          code: loginResult.smsCode ?? '',
          password: '',
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppToast.show(context, _messageOf(error));
    } finally {
      if (mounted) {
        setState(() {
          _isOneTapBusy = false;
        });
      }
    }
  }

  String _messageOf(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: switch (_stage) {
          _LoginStage.phone => SmsLoginPhoneView(
            mobileController: _mobileController,
            agreed: _agreed,
            countdownSeconds: _countdownSeconds,
            isRequestingCode: _isRequestingCode,
            onAgreedChanged: (value) => setState(() => _agreed = value),
            onRequestCode: _requestSmsCode,
            onPasswordLogin: () => context.push(
              AppRoutes.passwordLogin,
              extra: _mobile,
            ),
          ),
          _LoginStage.code => SmsLoginCodeView(
            mobile: _mobile,
            codeController: _codeController,
            countdownSeconds: _countdownSeconds,
            isRequestingCode: _isRequestingCode,
            isSubmitting: _isSubmitting,
            onBack: () => setState(() => _stage = _LoginStage.phone),
            onResend: _requestSmsCode,
            onCompleted: _loginByCode,
          ),
        },
      ),
    );
  }
}
