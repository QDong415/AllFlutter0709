abstract final class AppRoutes {
  static const login = '/login';
  static const signup = '/signup';

  static const topic = '/topic';
  static const video = '/video';
  static const conversation = '/conversation';
  static const me = '/me';

  static const homeTabs = <String>[
    topic,
    video,
    conversation,
    me,
  ];
}
