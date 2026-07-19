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
