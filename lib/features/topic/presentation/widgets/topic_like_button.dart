import 'dart:async';

import 'package:flutter/material.dart';

class TopicLikeButton extends StatefulWidget {
  const TopicLikeButton({
    super.key,
    required this.isLiked,
    required this.likeCount,
    this.onTap,
    this.iconSize = 18,
    this.fontSize = 15,
    this.spacing = 4,
    this.mainAxisSize = MainAxisSize.min,
  });

  static const likeIconOffAsset = 'assets/icons/listitem_unpraise.png';
  static const likeIconOnAsset = 'assets/icons/listitem_praise.png';
  static const likedColor = Color(0xFFF46533);

  final bool isLiked;
  final int likeCount;
  final FutureOr<void> Function()? onTap;
  final double iconSize;
  final double fontSize;
  final double spacing;
  final MainAxisSize mainAxisSize;

  @override
  State<TopicLikeButton> createState() => _TopicLikeButtonState();
}

class _TopicLikeButtonState extends State<TopicLikeButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: 1,
          end: 1.4,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 1,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: 1.4,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    final onTap = widget.onTap;
    if (onTap == null || _isAnimating) return;

    _isAnimating = true;
    final result = onTap();
    if (result is Future<void>) {
      unawaited(result);
    }
    await _controller.forward(from: 0);
    if (mounted) {
      _isAnimating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final likeTextColor = widget.isLiked
        ? TopicLikeButton.likedColor
        : Colors.grey;
    final likeAsset = widget.isLiked
        ? TopicLikeButton.likeIconOnAsset
        : TopicLikeButton.likeIconOffAsset;
    final text = widget.likeCount > 0 ? '点赞 ${widget.likeCount}' : '点赞';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        splashColor: const Color(0xFFF5F5F7),
        highlightColor: const Color(0xFFF5F5F7),
        onTap: widget.onTap == null ? null : _handleTap,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: widget.mainAxisSize,
            children: [
              Image.asset(
                likeAsset,
                width: widget.iconSize,
                height: widget.iconSize,
              ),
              SizedBox(width: widget.spacing),
              Text(
                text,
                style: TextStyle(
                  color: likeTextColor,
                  fontSize: widget.fontSize,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
