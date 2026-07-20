import 'dart:math' as math;

import 'package:all_flutter0709/features/video/data/models/video_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class VideoItemWidget extends StatelessWidget {
  const VideoItemWidget({required this.video, super.key, this.onTap});

  final VideoModel video;
  final VoidCallback? onTap;

  static const double _radius = 12;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: const Color(0xFFE7E7E7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: onTap,
              child: Stack(
                children: [
                  _VideoCover(video: video),
                  if (video.content.isNotEmpty)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(8, 18, 8, 8),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0xB3000000)],
                          ),
                        ),
                        child: Text(
                          video.content,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 13,
                    backgroundColor: const Color(0xFFE5E5E5),
                    backgroundImage: _buildAvatarProvider(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      video.userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider<Object>? _buildAvatarProvider() {
    final avatarUrl = video.avatarUrl;
    if (avatarUrl == null || avatarUrl.isEmpty) {
      return null;
    }
    return CachedNetworkImageProvider(avatarUrl);
  }
}

class _VideoCover extends StatelessWidget {
  const _VideoCover({required this.video});

  final VideoModel video;

  @override
  Widget build(BuildContext context) {
    final aspectRatio = _resolveAspectRatio(video.width, video.height);

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Color(0xFFF4F4F4)),
        child: video.coverUrl?.isNotEmpty == true
            ? _LoggedCoverImage(
                videoId: video.videoId,
                imageUrl: video.coverUrl!,
              )
            : const _CoverFallback(),
      ),
    );
  }

  double _resolveAspectRatio(int width, int height) {
    if (width <= 0 || height <= 0) {
      return 0.72;
    }

    final ratio = width / height;
    return math.max(0.48, math.min(ratio, 1.2));
  }
}

class _LoggedCoverImage extends StatefulWidget {
  const _LoggedCoverImage({required this.videoId, required this.imageUrl});

  final String videoId;
  final String imageUrl;

  @override
  State<_LoggedCoverImage> createState() => _LoggedCoverImageState();
}

class _LoggedCoverImageState extends State<_LoggedCoverImage> {
  @override
  void initState() {
    super.initState();
    _printCoverLog();
  }

  @override
  void didUpdateWidget(covariant _LoggedCoverImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _printCoverLog();
    }
  }

  void _printCoverLog() {
    debugPrint('[VideoCover] videoId=${widget.videoId} url=${widget.imageUrl}');
  }

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: widget.imageUrl,
      fit: BoxFit.cover,
      placeholder: (_, _) => const _CoverPlaceholder(),
      errorWidget: (_, _, _) => const _CoverFallback(),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

class _CoverFallback extends StatelessWidget {
  const _CoverFallback();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(color: Color(0xFFF4F4F4)),
      child: Center(
        child: Icon(
          Icons.play_circle_outline_rounded,
          size: 42,
          color: Color(0xFF999999),
        ),
      ),
    );
  }
}
