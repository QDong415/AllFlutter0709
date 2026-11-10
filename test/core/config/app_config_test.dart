import 'package:all_flutter0709/core/config/app_config.dart';
import 'package:all_flutter0709/core/network/app_env.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('没有缓存时使用本地默认存储前缀', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();

    AppConfig.instance.initialize(preferences);

    expect(AppConfig.instance.cloudStorageHttp, AppEnv.cloudFrontBaseUrl);
    expect(AppConfig.instance.cloudStorageVideoHttp, AppEnv.s3VideoBaseUrl);
    expect(AppConfig.instance.cloudStorage, CloudStorage.s3);
    expect(
      AppConfig.instance.cloudStorageThumbStyle,
      CloudStorageThumbStyle.cloudfront,
    );
    expect(
      AppConfig.instance.imageUploadMaxMemoryMb,
      AppConfig.defaultImageUploadMaxMemoryMb,
    );
  });

  test('发图上限跟缓存，0 表示不压缩', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'app_config_image_upload_max_memory': 0,
    });
    final unlimited = await SharedPreferences.getInstance();
    AppConfig.instance.initialize(unlimited);
    expect(AppConfig.instance.imageUploadMaxMemoryMb, 0);

    SharedPreferences.setMockInitialValues(<String, Object>{
      'app_config_image_upload_max_memory': 8,
    });
    final limited = await SharedPreferences.getInstance();
    AppConfig.instance.initialize(limited);
    expect(AppConfig.instance.imageUploadMaxMemoryMb, 8);
  });

  test('优先使用缓存并自动补齐末尾斜杠', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'app_config_cloud_storage_http': 'https://cdn.example.com',
    });
    final preferences = await SharedPreferences.getInstance();

    AppConfig.instance.initialize(preferences);

    expect(AppConfig.instance.cloudStorageHttp, 'https://cdn.example.com/');
  });

  test('视频播放前缀读 oss_video_http 缓存', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'app_config_cloud_storage_video_http': 'http://s3.itopic.com.cn',
    });
    final preferences = await SharedPreferences.getInstance();

    AppConfig.instance.initialize(preferences);

    expect(AppConfig.instance.cloudStorageVideoHttp, 'http://s3.itopic.com.cn/');
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

    expect(AppConfig.instance.cloudStorageHttp, AppEnv.cloudFrontBaseUrl);
  });

  test('缓存上传目标，未知值回退到 S3', () async {
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
    expect(AppConfig.instance.cloudStorage, CloudStorage.s3);
  });

  test('缓存缩略图规则，未知值回退到 CloudFront', () async {
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
      CloudStorageThumbStyle.cloudfront,
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

  test('审核开关缺省为否，写入本地并可恢复', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    AppConfig.instance.initialize(preferences);
    expect(AppConfig.instance.appReviewing, isFalse);

    expect(AppConfig.isReviewingValue(null), isFalse);
    expect(AppConfig.isReviewingValue(false), isFalse);
    expect(AppConfig.isReviewingValue(0), isFalse);
    expect(AppConfig.isReviewingValue('0'), isFalse);
    expect(AppConfig.isReviewingValue(true), isTrue);
    expect(AppConfig.isReviewingValue(1), isTrue);
    expect(AppConfig.isReviewingValue('1'), isTrue);
    expect(AppConfig.isReviewingValue('true'), isTrue);

    AppConfig.instance.setAppReviewing(true);
    expect(AppConfig.instance.appReviewing, isTrue);
    expect(preferences.getBool('app_config_app_reviewing'), isTrue);

    // 再次 initialize 应从 SharedPreferences 恢复
    AppConfig.instance.initialize(preferences);
    expect(AppConfig.instance.appReviewing, isTrue);
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
