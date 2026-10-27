import 'package:all_flutter0709/core/config/app_config.dart';
import 'package:all_flutter0709/core/network/app_env.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('没有缓存时使用本地默认 OSS 前缀', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();

    AppConfig.instance.initialize(preferences);

    expect(AppConfig.instance.ossHttp, AppEnv.qiniuBaseUrl);
  });

  test('优先使用缓存并自动补齐末尾斜杠', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'app_config_oss_http': 'https://cdn.example.com',
    });
    final preferences = await SharedPreferences.getInstance();

    AppConfig.instance.initialize(preferences);

    expect(AppConfig.instance.ossHttp, 'https://cdn.example.com/');
  });

  test('忽略无效缓存并使用本地默认值', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'app_config_oss_http': 'not-a-url',
    });
    final preferences = await SharedPreferences.getInstance();

    AppConfig.instance.initialize(preferences);

    expect(AppConfig.instance.ossHttp, AppEnv.qiniuBaseUrl);
  });
}
