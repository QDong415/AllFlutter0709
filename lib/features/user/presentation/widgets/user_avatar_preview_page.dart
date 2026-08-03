import 'package:all_flutter0709/app/theme/app_system_ui.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dismissible_page/dismissible_page.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

/// 打开头像大图预览。
void openUserAvatarPreview(BuildContext context, {required String imageUrl}) {
  final url = imageUrl.trim();
  if (url.isEmpty) return;

  Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: false,
      pageBuilder: (_, _, _) => UserAvatarPreviewPage(imageUrl: url),
    ),
  );
}

/// 用户头像全屏预览页。
class UserAvatarPreviewPage extends StatelessWidget {
  const UserAvatarPreviewPage({super.key, required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return FullscreenMediaSystemUi(
      child: DismissiblePage(
        direction: DismissiblePageDismissDirection.vertical,
        onDismissed: () => Navigator.of(context).pop(),
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Center(
                child: PhotoView(
                  imageProvider: CachedNetworkImageProvider(imageUrl),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 3,
                  backgroundDecoration: const BoxDecoration(
                    color: Colors.black,
                  ),
                ),
              ),
              SafeArea(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
