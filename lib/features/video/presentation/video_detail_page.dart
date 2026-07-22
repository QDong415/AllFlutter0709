import 'dart:async';

import 'package:all_flutter0709/core/account/account_guard.dart';
import 'package:all_flutter0709/features/comment/data/comment_repository.dart';
import 'package:all_flutter0709/features/comment/presentation/widgets/comment_section.dart';
import 'package:all_flutter0709/features/video/data/models/video_model.dart';
import 'package:all_flutter0709/features/video/data/video_repository.dart';
import 'package:all_flutter0709/features/video/presentation/widgets/video_detail_info_header.dart';
import 'package:all_flutter0709/features/video/presentation/widgets/video_detail_nav_bar.dart';
import 'package:all_flutter0709/features/video/presentation/widgets/video_detail_player.dart';
import 'package:flutter/material.dart';

class VideoDetailPage extends StatefulWidget {
  const VideoDetailPage({required this.video, super.key});

  final VideoModel video;

  @override
  State<VideoDetailPage> createState() => _VideoDetailPageState();
}

class _VideoDetailPageState extends State<VideoDetailPage> {
  final VideoRepository _videoRepository = const VideoRepository();

  late VideoModel _video;
  bool _isLiking = false;
  double _navAlpha = 0;

  @override
  void initState() {
    super.initState();
    _video = widget.video;
  }

  double _playerHeight(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    if (_video.width > 0 && _video.height > 0) {
      return (_video.height * screenWidth) / _video.width;
    }
    return screenWidth * 9 / 16;
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;

    final playerHeight = _playerHeight(context);
    final navHeight =
        MediaQuery.paddingOf(context).top + kToolbarHeight;
    final offsetYByHeader =
        notification.metrics.pixels - playerHeight + navHeight;

    final double nextAlpha;
    if (offsetYByHeader < -navHeight) {
      nextAlpha = 0;
    } else if (offsetYByHeader > 0) {
      nextAlpha = 1;
    } else {
      nextAlpha = 1 - (-offsetYByHeader) / navHeight;
    }

    if ((nextAlpha - _navAlpha).abs() > 0.01) {
      setState(() {
        _navAlpha = nextAlpha.clamp(0.0, 1.0);
      });
    }
    return false;
  }

  Future<void> _toggleLike({required bool onlyWhenNotLiked}) async {
    if (_isLiking) return;
    if (onlyWhenNotLiked && _video.isLiked) return;
    if (!context.ensureLoggedIn()) return;

    final previous = _video;
    final nextIsLiked = !previous.isLiked;
    final nextLikeCount = nextIsLiked
        ? previous.likeCount + 1
        : (previous.likeCount > 0 ? previous.likeCount - 1 : 0);

    setState(() {
      _video = previous.copyWith(
        isLiked: nextIsLiked,
        likeCount: nextLikeCount,
      );
      _isLiking = true;
    });

    try {
      await _videoRepository.likeVideo(
        videoId: previous.videoId,
        isLiked: previous.isLiked,
        likeCount: previous.likeCount,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _video = previous;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLiking = false;
        });
      }
    }
  }

  void _onReport() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('举报功能暂未实现')));
  }

  @override
  Widget build(BuildContext context) {
    final playerHeight = _playerHeight(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: _onScrollNotification,
            child: CommentSection(
              targetId: _video.videoId,
              targetType: CommentTargetType.video,
              initialCommentCount: _video.commentCount,
              authorUserId: _video.userId,
              enablePullRefresh: false,
              listPadding: const EdgeInsets.only(bottom: 24),
              onCommentCountChanged: (count) {
                if (!mounted) return;
                setState(() {
                  _video = _video.copyWith(commentCount: count);
                });
              },
              header: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  VideoDetailPlayer(
                    videoUrl: _video.videoUrl,
                    coverUrl: _video.coverUrl,
                    height: playerHeight,
                    onDoubleTap: () {
                      unawaited(_toggleLike(onlyWhenNotLiked: true));
                    },
                  ),
                  VideoDetailInfoHeader(video: _video),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: VideoDetailNavBar(
              scrollAlpha: _navAlpha,
              isLiked: _video.isLiked,
              avatarUrl: _video.avatarUrl,
              onBack: () => Navigator.of(context).maybePop(),
              onLike: () {
                unawaited(_toggleLike(onlyWhenNotLiked: false));
              },
              onReport: _onReport,
            ),
          ),
        ],
      ),
    );
  }
}
