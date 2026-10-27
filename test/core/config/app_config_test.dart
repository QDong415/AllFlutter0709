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
    expect(AppConfig.instance.ossUpload, OssUpload.qiniu);
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

  test('缓存图片上传目标，未知值回退到七牛', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'app_config_oss_upload': OssUpload.aws.value,
    });
    final awsPreferences = await SharedPreferences.getInstance();
    AppConfig.instance.initialize(awsPreferences);
    expect(AppConfig.instance.ossUpload, OssUpload.aws);

    SharedPreferences.setMockInitialValues(<String, Object>{
      'app_config_oss_upload': 9,
    });
    final invalidPreferences = await SharedPreferences.getInstance();
    AppConfig.instance.initialize(invalidPreferences);
    expect(AppConfig.instance.ossUpload, OssUpload.qiniu);
  });
}
