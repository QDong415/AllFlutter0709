import 'package:all_flutter0709/app/theme/app_dimens.dart';
import 'package:all_flutter0709/app/theme/app_system_ui.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VideoDetailNavBar extends StatelessWidget {
  const VideoDetailNavBar({
    required this.scrollAlpha,
    required this.isLiked,
    required this.avatarUrl,
    required this.onBack,
    required this.onLike,
    required this.onReport,
    super.key,
  });

  /// 0 = 透明导航（白图标），1 = 白底导航（灰图标）
  final double scrollAlpha;
  final bool isLiked;
  final String? avatarUrl;
  final VoidCallback onBack;
  final VoidCallback onLike;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final alpha = scrollAlpha.clamp(0.0, 1.0);
    final overlayStyle = AppSystemUi.overlayStyleWithStatusBarIcons(
      darkIcons: alpha > 0.5,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: SizedBox(
        height: topInset + AppDimens.toolbarHeight,
        child: Stack(
          children: [
            Opacity(
              opacity: 1 - alpha,
              child: _NavContent(
                backgroundColor: Colors.transparent,
                iconColor: Colors.white,
                isLiked: isLiked,
                likedUsesSelectedStyle: true,
                avatarUrl: avatarUrl,
                onBack: onBack,
                onLike: onLike,
                onReport: onReport,
                topInset: topInset,
              ),
            ),
            Opacity(
              opacity: alpha,
              child: _NavContent(
                backgroundColor: Colors.white,
                iconColor: const Color(0xFF555555),
                isLiked: isLiked,
                likedUsesSelectedStyle: true,
                avatarUrl: avatarUrl,
                onBack: onBack,
                onLike: onLike,
                onReport: onReport,
                topInset: topInset,
                showBottomBorder: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavContent extends StatelessWidget {
  const _NavContent({
    required this.backgroundColor,
    required this.iconColor,
    required this.isLiked,
    required this.likedUsesSelectedStyle,
    required this.avatarUrl,
    required this.onBack,
    required this.onLike,
    required this.onReport,
    required this.topInset,
    this.showBottomBorder = false,
  });

  final Color backgroundColor;
  final Color iconColor;
  final bool isLiked;
  final bool likedUsesSelectedStyle;
  final String? avatarUrl;
  final VoidCallback onBack;
  final VoidCallback onLike;
  final VoidCallback onReport;
  final double topInset;
  final bool showBottomBorder;

  @override
  Widget build(BuildContext context) {
    final likedColor = likedUsesSelectedStyle
        ? const Color(0xFFF46533)
        : iconColor;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: showBottomBorder
            ? const Border(
                bottom: BorderSide(color: Color(0xFFECECEC), width: 0.5),
              )
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.only(top: topInset),
        child: SizedBox(
          height: AppDimens.toolbarHeight,
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: iconColor),
              ),
              IconButton(
                onPressed: onLike,
                icon: Icon(
                  isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isLiked ? likedColor : iconColor,
                ),
              ),
              IconButton(
                onPressed: onReport,
                icon: Icon(Icons.report_gmailerrorred_outlined, color: iconColor),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFFE8E8E8),
                  backgroundImage:
                      avatarUrl != null && avatarUrl!.isNotEmpty
                      ? CachedNetworkImageProvider(avatarUrl!)
                      : null,
                  child: avatarUrl == null || avatarUrl!.isEmpty
                      ? Icon(Icons.person, size: 18, color: iconColor)
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
