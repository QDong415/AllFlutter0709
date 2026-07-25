/// 注册第一步传给第二步的参数。
class SignupArgs {
  const SignupArgs({
    required this.mobile,
    required this.code,
    required this.password,
  });

  final String mobile;
  final String code;
  final String password;
}
