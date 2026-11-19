import 'package:all_flutter0709/features/topic/data/models/topic_model.dart';
import 'package:all_flutter0709/shared/media/gallery_preview_item.dart';
import 'package:all_flutter0709/shared/media/preview_save_source.dart';
import 'package:flutter/material.dart';

/// 将动态配图限制在当前路由内的 Hero 标签。
///
/// 首页、个人主页和动态详情会同时出现同一张图。标签若只按图片地址生成，
/// 返回时二级页的九宫格会飞向首页里并不存在的位置。
String scopedTopicPictureHeroTag(
  BuildContext context,
  TopicPictureModel pictureModel,
) {
  final routeScope = identityHashCode(ModalRoute.of(context));
  return '$routeScope|${pictureModel.heroTag}';
}

/// 将动态配图转为全屏画廊预览项。
///
/// [heroTagFor] 与来源缩略图使用同一标签时，打开大图才播放 Hero。
List<GalleryPreviewItem> topicPictureModelListToGalleryPreviewItemList(
  List<TopicPictureModel> pictureModelList, {
  String Function(TopicPictureModel pictureModel)? heroTagFor,
}) {
  return pictureModelList
      .map(
        (pictureModel) => _toGalleryPreviewItem(
          pictureModel,
          heroTag: heroTagFor?.call(pictureModel) ?? pictureModel.heroTag,
        ),
      )
      .toList(growable: false);
}

GalleryPreviewItem _toGalleryPreviewItem(
  TopicPictureModel pictureModel, {
  required String heroTag,
}) {
  final imageUrl = pictureModel.originalUrl.isNotEmpty
      ? pictureModel.originalUrl
      : pictureModel.thumbnailUrl;
  return GalleryPreviewItem(
    imageProvider: NetworkImage(imageUrl),
    saveSource: PreviewSaveFromUrl(imageUrl),
    heroTag: heroTag,
  );
}
