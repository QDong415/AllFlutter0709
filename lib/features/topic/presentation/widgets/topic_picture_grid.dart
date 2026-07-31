import 'dart:math' as math;

import 'package:all_flutter0709/features/topic/data/models/topic_model.dart';
import 'package:all_flutter0709/features/topic/presentation/widgets/topic_picture_preview_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// 动态图片九宫格；单图尺寸算法可供视频封面复用。
class TopicPictureGrid extends StatelessWidget {
  const TopicPictureGrid({super.key, required this.pictures});

  final List<TopicPictureModel> pictures;

  static const double _spacing = 6;
  static const double singleMaxExtent = 220;
  static const double singleMinExtent = 120;
  static const double radius = 8;

  /// 计算单张图片（或视频封面）展示尺寸，与列表单图逻辑一致。
  static Size resolveSinglePictureSize({
    required int? width,
    required int? height,
    required double maxWidth,
  }) {
    final limitedMax = math.min(maxWidth, singleMaxExtent);
    final pictureWidth = width ?? 0;
    final pictureHeight = height ?? 0;

    if (pictureWidth <= 0 || pictureHeight <= 0) {
      return Size(limitedMax, limitedMax);
    }

    if (pictureWidth >= pictureHeight) {
      final resolvedWidth = limitedMax;
      final resolvedHeight = math.max(
        singleMinExtent,
        resolvedWidth * pictureHeight / pictureWidth,
      );
      return Size(resolvedWidth, resolvedHeight);
    }

    final resolvedHeight = limitedMax;
    final resolvedWidth = math.max(
      singleMinExtent,
      resolvedHeight * pictureWidth / pictureHeight,
    );
    return Size(resolvedWidth, resolvedHeight);
  }

  @override
  Widget build(BuildContext context) {
    if (pictures.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (pictures.length == 1) {
          final picture = pictures.first;
          final size = resolveSinglePictureSize(
            width: picture.width,
            height: picture.height,
            maxWidth: constraints.maxWidth,
          );
          return _SinglePictureItem(
            index: 0,
            pictures: pictures,
            picture: picture,
            size: size,
          );
        }

        final tripleGridItemWidth = (constraints.maxWidth - _spacing * 2) / 3;
        final isFourGrid = pictures.length == 4;
        final itemWidth = tripleGridItemWidth;
        final gridWidth = isFourGrid
            ? itemWidth * 2 + _spacing
            : constraints.maxWidth;

        return SizedBox(
          width: gridWidth,
          child: Wrap(
            spacing: _spacing,
            runSpacing: _spacing,
            children: [
              for (var i = 0; i < pictures.length; i++)
                _GridPictureItem(
                  index: i,
                  pictures: pictures,
                  picture: pictures[i],
                  width: itemWidth,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SinglePictureItem extends StatelessWidget {
  const _SinglePictureItem({
    required this.index,
    required this.pictures,
    required this.picture,
    required this.size,
  });

  final int index;
  final List<TopicPictureModel> pictures;
  final TopicPictureModel picture;
  final Size size;

  @override
  Widget build(BuildContext context) {
    return _PictureTile(
      picture: picture,
      width: size.width,
      height: size.height,
      onTap: () => _openPreview(context, pictures, index),
    );
  }
}

class _GridPictureItem extends StatelessWidget {
  const _GridPictureItem({
    required this.index,
    required this.pictures,
    required this.picture,
    required this.width,
  });

  final int index;
  final List<TopicPictureModel> pictures;
  final TopicPictureModel picture;
  final double width;

  @override
  Widget build(BuildContext context) {
    return _PictureTile(
      picture: picture,
      width: width,
      height: width,
      onTap: () => _openPreview(context, pictures, index),
    );
  }
}

class _PictureTile extends StatelessWidget {
  const _PictureTile({
    required this.picture,
    required this.width,
    required this.height,
    required this.onTap,
  });

  final TopicPictureModel picture;
  final double width;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: picture.heroTag,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(TopicPictureGrid.radius),
          child: CachedNetworkImage(
            imageUrl: picture.thumbnailUrl,
            width: width,
            height: height,
            fit: BoxFit.cover,
            placeholder: (_, _) =>
                _PicturePlaceholder(width: width, height: height),
            errorWidget: (_, _, _) =>
                _PictureError(width: width, height: height),
          ),
        ),
      ),
    );
  }
}

void _openPreview(
  BuildContext context,
  List<TopicPictureModel> pictures,
  int initialIndex,
) {
  // 打开大图前清掉输入焦点，避免关闭预览时系统把焦点还给评论框并弹出键盘。
  FocusManager.instance.primaryFocus?.unfocus();

  Navigator.of(context, rootNavigator: true)
      .push(
    PageRouteBuilder<void>(
      opaque: false,
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, animation, secondaryAnimation) {
        return TopicPicturePreviewPage(
          pictures: pictures,
          initialIndex: initialIndex,
        );
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fade = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        final scale = Tween<double>(begin: 0.96, end: 1.0).animate(fade);
        return FadeTransition(
          opacity: fade,
          child: ScaleTransition(scale: scale, child: child),
        );
      },
    ),
  )
      .whenComplete(() {
    // pop 后 Flutter 可能恢复先前焦点，下一帧再清一次。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusManager.instance.primaryFocus?.unfocus();
    });
  });
}

class _PicturePlaceholder extends StatelessWidget {
  const _PicturePlaceholder({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFF0F0F0),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

class _PictureError extends StatelessWidget {
  const _PictureError({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFF0F0F0),
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
    );
  }
}
