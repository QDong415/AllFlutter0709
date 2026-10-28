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
    expect(AppConfig.instance.ossThumbStyle, OssThumbStyle.qiniu);
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

  test('缓存缩略图规则，未知值回退到七牛', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'app_config_oss_thumb_style': OssThumbStyle.aliyun.value,
    });
    final aliyunPreferences = await SharedPreferences.getInstance();
    AppConfig.instance.initialize(aliyunPreferences);
    expect(AppConfig.instance.ossThumbStyle, OssThumbStyle.aliyun);

    SharedPreferences.setMockInitialValues(<String, Object>{
      'app_config_oss_thumb_style': OssThumbStyle.cloudfront.value,
    });
    final cloudfrontPreferences = await SharedPreferences.getInstance();
    AppConfig.instance.initialize(cloudfrontPreferences);
    expect(AppConfig.instance.ossThumbStyle, OssThumbStyle.cloudfront);

    SharedPreferences.setMockInitialValues(<String, Object>{
      'app_config_oss_thumb_style': 9,
    });
    final invalidPreferences = await SharedPreferences.getInstance();
    AppConfig.instance.initialize(invalidPreferences);
    expect(AppConfig.instance.ossThumbStyle, OssThumbStyle.qiniu);
  });

  test('三种缩略图规则按七牛语义拼接查询串', () {
    expect(
      OssThumbStyle.qiniu.query(limitPx: 200, max: false, thumbnail: true),
      '?imageView2/1/w/200/h/200',
    );
    expect(
      OssThumbStyle.qiniu.query(limitPx: 200, max: false, thumbnail: false),
      '?imageView2/2/w/200/h/200',
    );
    expect(
      OssThumbStyle.qiniu.query(limitPx: 200, max: true, thumbnail: false),
      '?imageView2/3/w/200/h/200',
    );
    expect(
      OssThumbStyle.aliyun.query(limitPx: 200, max: false, thumbnail: true),
      '?image_process=crop,w_200,h_200,g_center',
    );
    expect(
      OssThumbStyle.aliyun.query(limitPx: 200, max: false, thumbnail: false),
      '?image_process=resize,l_200',
    );
    expect(
      OssThumbStyle.aliyun.query(limitPx: 200, max: true, thumbnail: false),
      '?image_process=resize,s_200',
    );
    expect(
      OssThumbStyle.cloudfront.query(limitPx: 200, max: false, thumbnail: true),
      '?width=200&height=200&fit=cover',
    );
    expect(
      OssThumbStyle.cloudfront.query(limitPx: 200, max: false, thumbnail: false),
      '?width=200&height=200&fit=inside',
    );
    expect(
      OssThumbStyle.cloudfront.query(limitPx: 200, max: true, thumbnail: false),
      '?width=200&height=200&fit=outside',
    );
  });
}
