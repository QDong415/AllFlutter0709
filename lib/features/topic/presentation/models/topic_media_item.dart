import 'package:all_flutter0709/features/topic/data/models/topic_model.dart';

/// 动态预览媒体类型。
enum TopicMediaType { image, video }

/// 动态放大预览中的单条媒体（图片或视频）。
class TopicMediaItem {
  const TopicMediaItem._({
    required this.type,
    required this.heroTag,
    this.imageUrl = '',
    this.thumbnailUrl = '',
    this.videoUrl = '',
  });

  /// 由图片构造预览项。
  factory TopicMediaItem.image(TopicPictureModel picture) {
    final imageUrl = picture.originalUrl.isNotEmpty
        ? picture.originalUrl
        : picture.thumbnailUrl;
    return TopicMediaItem._(
      type: TopicMediaType.image,
      heroTag: picture.heroTag,
      imageUrl: imageUrl,
      thumbnailUrl: picture.thumbnailUrl,
    );
  }

  /// 由视频地址构造预览项；[coverPicture] 用于封面与 Hero。
  factory TopicMediaItem.video({
    required String videoUrl,
    TopicPictureModel? coverPicture,
  }) {
    final cover = coverPicture;
    final heroTag = cover != null
        ? 'video|${cover.heroTag}|$videoUrl'
        : 'video|$videoUrl';
    return TopicMediaItem._(
      type: TopicMediaType.video,
      heroTag: heroTag,
      videoUrl: videoUrl.trim(),
      thumbnailUrl: cover?.thumbnailUrl ?? '',
      imageUrl: cover?.originalUrl.isNotEmpty == true
          ? cover!.originalUrl
          : (cover?.thumbnailUrl ?? ''),
    );
  }

  final TopicMediaType type;
  final String heroTag;
  final String imageUrl;
  final String thumbnailUrl;
  final String videoUrl;

  /// 是否为视频项。
  bool get isVideo => type == TopicMediaType.video;

  /// 是否为图片项。
  bool get isImage => type == TopicMediaType.image;
}

/// 从动态模型构建「视频 + 图片」混合预览列表。
List<TopicMediaItem> buildTopicMediaItems(TopicModel topicModel) {
  final items = <TopicMediaItem>[];
  final videoUrl = topicModel.videoUrl?.trim() ?? '';
  if (videoUrl.isNotEmpty) {
    items.add(
      TopicMediaItem.video(
        videoUrl: videoUrl,
        coverPicture: topicModel.pictures.isNotEmpty
            ? topicModel.pictures.first
            : null,
      ),
    );
  }
  for (final picture in topicModel.pictures) {
    items.add(TopicMediaItem.image(picture));
  }
  return items;
}

/// 仅由图片列表构建预览项（纯图九宫格）。
List<TopicMediaItem> buildTopicImageMediaItems(
  List<TopicPictureModel> pictures,
) {
  return pictures.map(TopicMediaItem.image).toList(growable: false);
}
