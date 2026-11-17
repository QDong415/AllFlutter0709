import 'package:all_flutter0709/features/topic/data/models/topic_model.dart';
import 'package:all_flutter0709/shared/media/gallery_preview_item.dart';
import 'package:all_flutter0709/shared/media/preview_save_source.dart';
import 'package:flutter/material.dart';

/// 将动态配图转为全屏画廊预览项。
List<GalleryPreviewItem> topicPictureModelListToGalleryPreviewItemList(
  List<TopicPictureModel> pictureModelList,
) {
  return pictureModelList
      .map((pictureModel) => _toGalleryPreviewItem(pictureModel))
      .toList(growable: false);
}

GalleryPreviewItem _toGalleryPreviewItem(TopicPictureModel pictureModel) {
  final imageUrl = pictureModel.originalUrl.isNotEmpty
      ? pictureModel.originalUrl
      : pictureModel.thumbnailUrl;
  return GalleryPreviewItem(
    imageProvider: NetworkImage(imageUrl),
    saveSource: PreviewSaveFromUrl(imageUrl),
    heroTag: pictureModel.heroTag,
  );
}
