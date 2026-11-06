import 'package:all_flutter0709/core/account/account.dart';
import 'package:all_flutter0709/core/config/app_config.dart';
import 'package:all_flutter0709/core/vip/vip_membership.dart';

/// 发话题前是否需要 VIP（对齐 Buddy `TopicRootFragment`）。
bool topicPublishRequiresVip({
  required AccountModel account,
  AppConfig? appConfig,
}) {
  final config = appConfig ?? AppConfig.instance;
  return shouldMaleStyleChatBeLimit(account) && config.allowTopicSubmit == 0;
}

/// 发评论前是否需要 VIP（对齐 Buddy `BaseCommentsActivity`）。
bool topicCommentRequiresVip({
  required AccountModel account,
  AppConfig? appConfig,
}) {
  final config = appConfig ?? AppConfig.instance;
  return shouldMaleStyleChatBeLimit(account) && config.allowTopicComment == 0;
}
