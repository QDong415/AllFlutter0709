enum AppEnvironment { test, production }

abstract final class AppEnv {
  // 切换环境时，只需要改这里。
  static const AppEnvironment current = AppEnvironment.test;

  static String get apiBaseUrl {
    switch (current) {
      case AppEnvironment.test:
        return 'http://api.itopic.com.cn';
      case AppEnvironment.production:
        return 'http://api.itopic.com.cn';
    }
  }

  static String get qiniuBaseUrl {
    switch (current) {
      case AppEnvironment.test:
        return 'http://qiniu.itopic.com.cn/';
      case AppEnvironment.production:
        return 'http://qiniu.itopic.com.cn/';
    }
  }

  /// CloudFront 图片处理分配，S3 上传后的默认展示前缀。
  static const String cloudFrontBaseUrl =
      'https://d1y2d7egaddq37.cloudfront.net/';

  static String get siteBaseUrl {
    switch (current) {
      case AppEnvironment.test:
        return 'https://api.itopic.com.cn';
      case AppEnvironment.production:
        return 'https://api.itopic.com.cn';
    }
  }

  static String get shareTopicBaseUrl => '$siteBaseUrl/home/topic/detail?tid=';
}
