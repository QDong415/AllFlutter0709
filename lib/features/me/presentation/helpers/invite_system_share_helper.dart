import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

/// 调系统分享。移动端微信不认纯文字，需以链接 [uri] 分享。
Future<void> shareInviteToSystem({
  required String link,
  required String shareText,
  required String inviteTitle,
}) async {
  final uri = Uri.tryParse(link);
  if (uri == null) {
    await SharePlus.instance.share(ShareParams(text: shareText));
    return;
  }

  final isMobile = !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  if (isMobile) {
    await SharePlus.instance.share(
      ShareParams(
        uri: uri,
        title: inviteTitle,
        subject: inviteTitle,
      ),
    );
    return;
  }

  await SharePlus.instance.share(ShareParams(text: shareText));
}