import 'dart:math' as math;

import 'package:all_flutter0709/features/topic/data/models/topic_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class TopicPictureGrid extends StatelessWidget {
  const TopicPictureGrid({super.key, required this.pictures});

  final List<TopicPictureModel> pictures;

  static const double _spacing = 6;
  static const double _singleMaxExtent = 220;
  static const double _singleMinExtent = 120;
  static const double _radius = 10;

  @override
  Widget build(BuildContext context) {
    if (pictures.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (pictures.length == 1) {
          return _SinglePictureItem(
            picture: pictures.first,
            maxWidth: constraints.maxWidth,
          );
        }

        final columns = pictures.length == 4 ? 2 : 3;
        final itemWidth =
            (constraints.maxWidth - _spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: _spacing,
          runSpacing: _spacing,
          children: [
            for (final picture in pictures)
              _GridPictureItem(picture: picture, width: itemWidth),
          ],
        );
      },
    );
  }
}

class _SinglePictureItem extends StatelessWidget {
  const _SinglePictureItem({required this.picture, required this.maxWidth});

  final TopicPictureModel picture;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final size = _resolveSize();
    return ClipRRect(
      borderRadius: BorderRadius.circular(TopicPictureGrid._radius),
      child: CachedNetworkImage(
        imageUrl: picture.url,
        width: size.width,
        height: size.height,
        fit: BoxFit.cover,
        placeholder: (_, _) =>
            _PicturePlaceholder(width: size.width, height: size.height),
        errorWidget: (_, _, _) =>
            _PictureError(width: size.width, height: size.height),
      ),
    );
  }

  Size _resolveSize() {
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
}

class _GridPictureItem extends StatelessWidget {
  const _GridPictureItem({required this.picture, required this.width});

  final TopicPictureModel picture;
  final double width;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(TopicPictureGrid._radius),
      child: CachedNetworkImage(
        imageUrl: picture.url,
        width: width,
        height: width,
        fit: BoxFit.cover,
        placeholder: (_, _) => _PicturePlaceholder(width: width, height: width),
        errorWidget: (_, _, _) => _PictureError(width: width, height: width),
      ),
    );
  }
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
