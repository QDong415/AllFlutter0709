import 'dart:math' as math;

import 'package:all_flutter0709/features/topic/data/models/topic_model.dart';
import 'package:all_flutter0709/features/topic/presentation/widgets/topic_picture_preview_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class TopicPictureGrid extends StatelessWidget {
  const TopicPictureGrid({super.key, required this.pictures});

  final List<TopicPictureModel> pictures;

  static const double _spacing = 6;
  static const double _singleMaxExtent = 220;
  static const double _singleMinExtent = 120;
  static const double _radius = 8;

  @override
  Widget build(BuildContext context) {
    if (pictures.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (pictures.length == 1) {
          final size = _resolveSinglePictureSize(
            picture: pictures.first,
            maxWidth: constraints.maxWidth,
          );
          return _SinglePictureItem(
            index: 0,
            pictures: pictures,
            picture: pictures.first,
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
          borderRadius: BorderRadius.circular(TopicPictureGrid._radius),
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

Size _resolveSinglePictureSize({
  required TopicPictureModel picture,
  required double maxWidth,
}) {
  final limitedMax = math.min(maxWidth, TopicPictureGrid._singleMaxExtent);
  final pictureWidth = picture.width ?? 0;
  final pictureHeight = picture.height ?? 0;

  if (pictureWidth <= 0 || pictureHeight <= 0) {
    return Size(limitedMax, limitedMax);
  }

  if (pictureWidth >= pictureHeight) {
    final width = limitedMax;
    final height = math.max(
      TopicPictureGrid._singleMinExtent,
      width * pictureHeight / pictureWidth,
    );
    return Size(width, height);
  }

  final height = limitedMax;
  final width = math.max(
    TopicPictureGrid._singleMinExtent,
    height * pictureWidth / pictureHeight,
  );
  return Size(width, height);
}

void _openPreview(
  BuildContext context,
  List<TopicPictureModel> pictures,
  int initialIndex,
) {
  Navigator.of(context, rootNavigator: true).push(
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
  );
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
