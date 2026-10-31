import 'package:all_flutter0709/core/config/app_config.dart';
import 'package:all_flutter0709/core/network/app_env.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('没有缓存时使用本地默认存储前缀', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();

    AppConfig.instance.initialize(preferences);

    expect(AppConfig.instance.cloudStorageHttp, AppEnv.qiniuBaseUrl);
    expect(AppConfig.instance.cloudStorage, CloudStorage.qiniu);
    expect(AppConfig.instance.cloudStorageThumbStyle, CloudStorageThumbStyle.qiniu);
  });

  test('优先使用缓存并自动补齐末尾斜杠', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'app_config_cloud_storage_http': 'https://cdn.example.com',
    });
    final preferences = await SharedPreferences.getInstance();

    AppConfig.instance.initialize(preferences);

    expect(AppConfig.instance.cloudStorageHttp, 'https://cdn.example.com/');
  });

  test('兼容旧缓存键 oss_http', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'app_config_oss_http': 'https://cdn.example.com',
    });
    final preferences = await SharedPreferences.getInstance();

    AppConfig.instance.initialize(preferences);

    expect(AppConfig.instance.cloudStorageHttp, 'https://cdn.example.com/');
  });

  test('忽略无效缓存并使用本地默认值', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'app_config_cloud_storage_http': 'not-a-url',
    });
    final preferences = await SharedPreferences.getInstance();

    AppConfig.instance.initialize(preferences);

    expect(AppConfig.instance.cloudStorageHttp, AppEnv.qiniuBaseUrl);
  });

  test('缓存上传目标，未知值回退到七牛', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'app_config_cloud_storage': CloudStorage.s3.value,
    });
    final s3Preferences = await SharedPreferences.getInstance();
    AppConfig.instance.initialize(s3Preferences);
    expect(AppConfig.instance.cloudStorage, CloudStorage.s3);

    SharedPreferences.setMockInitialValues(<String, Object>{
      'app_config_cloud_storage': 9,
    });
    final invalidPreferences = await SharedPreferences.getInstance();
    AppConfig.instance.initialize(invalidPreferences);
    expect(AppConfig.instance.cloudStorage, CloudStorage.qiniu);
  });

  test('缓存缩略图规则，未知值回退到七牛', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'app_config_cloud_storage_thumb_style': CloudStorageThumbStyle.aliyun.value,
    });
    final aliyunPreferences = await SharedPreferences.getInstance();
    AppConfig.instance.initialize(aliyunPreferences);
    expect(
      AppConfig.instance.cloudStorageThumbStyle,
      CloudStorageThumbStyle.aliyun,
    );

    SharedPreferences.setMockInitialValues(<String, Object>{
      'app_config_cloud_storage_thumb_style':
          CloudStorageThumbStyle.cloudfront.value,
    });
    final cloudfrontPreferences = await SharedPreferences.getInstance();
    AppConfig.instance.initialize(cloudfrontPreferences);
    expect(
      AppConfig.instance.cloudStorageThumbStyle,
      CloudStorageThumbStyle.cloudfront,
    );

    SharedPreferences.setMockInitialValues(<String, Object>{
      'app_config_cloud_storage_thumb_style': 9,
    });
    final invalidPreferences = await SharedPreferences.getInstance();
    AppConfig.instance.initialize(invalidPreferences);
    expect(
      AppConfig.instance.cloudStorageThumbStyle,
      CloudStorageThumbStyle.qiniu,
    );
  });

  test('使用服务端 oss_http、上传目标和缩略图规则', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'app_config_cloud_storage_http': 'https://d1y2d7egaddq37.cloudfront.net',
      'app_config_cloud_storage': CloudStorage.s3.value,
      'app_config_cloud_storage_thumb_style':
          CloudStorageThumbStyle.cloudfront.value,
    });
    final preferences = await SharedPreferences.getInstance();
    AppConfig.instance.initialize(preferences);

    expect(AppConfig.instance.cloudStorage, CloudStorage.s3);
    expect(
      AppConfig.instance.cloudStorageHttp,
      'https://d1y2d7egaddq37.cloudfront.net/',
    );
    expect(
      AppConfig.instance.cloudStorageThumbStyle,
      CloudStorageThumbStyle.cloudfront,
    );
  });

  test('忽略本地上传目标覆盖，跟服务端缓存', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'app_config_cloud_storage_http': 'http://qiniu.itopic.com.cn/',
      'app_config_cloud_storage': CloudStorage.qiniu.value,
      'app_config_cloud_storage_thumb_style': CloudStorageThumbStyle.qiniu.value,
      'app_config_cloud_storage_override': CloudStorage.s3.value,
    });
    final preferences = await SharedPreferences.getInstance();
    AppConfig.instance.initialize(preferences);

    expect(AppConfig.instance.cloudStorage, CloudStorage.qiniu);
    expect(AppConfig.instance.cloudStorageHttp, 'http://qiniu.itopic.com.cn/');
    expect(
      AppConfig.instance.cloudStorageThumbStyle,
      CloudStorageThumbStyle.qiniu,
    );
  });

  test('三种缩略图规则按七牛语义拼接查询串', () {
    expect(
      CloudStorageThumbStyle.qiniu.query(
        limitPx: 200,
        max: false,
        thumbnail: true,
      ),
      '?imageView2/1/w/200/h/200',
    );
    expect(
      CloudStorageThumbStyle.qiniu.query(
        limitPx: 200,
        max: false,
        thumbnail: false,
      ),
      '?imageView2/2/w/200/h/200',
    );
    expect(
      CloudStorageThumbStyle.qiniu.query(
        limitPx: 200,
        max: true,
        thumbnail: false,
      ),
      '?imageView2/3/w/200/h/200',
    );
    expect(
      CloudStorageThumbStyle.aliyun.query(
        limitPx: 200,
        max: false,
        thumbnail: true,
      ),
      '?image_process=crop,w_200,h_200,g_center',
    );
    expect(
      CloudStorageThumbStyle.aliyun.query(
        limitPx: 200,
        max: false,
        thumbnail: false,
      ),
      '?image_process=resize,l_200',
    );
    expect(
      CloudStorageThumbStyle.aliyun.query(
        limitPx: 200,
        max: true,
        thumbnail: false,
      ),
      '?image_process=resize,s_200',
    );
    expect(
      CloudStorageThumbStyle.cloudfront.query(
        limitPx: 200,
        max: false,
        thumbnail: true,
      ),
      '?width=200&height=200&fit=cover',
    );
    expect(
      CloudStorageThumbStyle.cloudfront.query(
        limitPx: 200,
        max: false,
        thumbnail: false,
      ),
      '?width=200&height=200&fit=inside',
    );
    expect(
      CloudStorageThumbStyle.cloudfront.query(
        limitPx: 200,
        max: true,
        thumbnail: false,
      ),
      '?width=200&height=200&fit=outside',
    );
  });
}
