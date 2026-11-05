import 'package:all_flutter0709/core/utils/value_util.dart';

/// 把礼物图片文件名拼成原图地址，前缀跟当前对象存储，不加缩略图参数。
String giftPictureUrl(String picture) {
  return ValueUtil.getOriginalImageUrl(picture) ?? '';
}

/// 礼物目录里的一项。
class GiftModel {
  const GiftModel({
    required this.giftId,
    required this.title,
    required this.picture,
    required this.price,
  });

  final int giftId;
  final String title;
  final String picture;
  final int price;

  /// 礼物图地址。
  String get pictureUrl => giftPictureUrl(picture);

  factory GiftModel.fromJson(Map<String, dynamic> json) {
    return GiftModel(
      giftId: _readInt(json['giftid']),
      title: json['title']?.toString() ?? '',
      picture: json['picture']?.toString() ?? '',
      price: _readInt(json['price']),
    );
  }
}

/// 一次送礼成功的结果。
class GiftSendResult {
  const GiftSendResult({
    required this.giftModel,
    required this.count,
    required this.coin,
  });

  final GiftModel giftModel;
  final int count;
  final int coin;
}

/// 某人收到的一种礼物，按礼物汇总。
class ReceivedGift {
  const ReceivedGift({
    required this.giftId,
    required this.title,
    required this.picture,
    required this.totalCount,
    required this.totalPrice,
  });

  final int giftId;
  final String title;
  final String picture;
  final int totalCount;
  final int totalPrice;

  String get pictureUrl => giftPictureUrl(picture);

  factory ReceivedGift.fromJson(Map<String, dynamic> json) {
    return ReceivedGift(
      giftId: _readInt(json['giftid']),
      title: json['title']?.toString() ?? '',
      picture: json['picture']?.toString() ?? '',
      totalCount: _readInt(json['totalcount']),
      totalPrice: _readInt(json['totalprice']),
    );
  }
}

/// 一条送礼流水。
class GiftSenderRecord {
  const GiftSenderRecord({
    required this.userId,
    required this.name,
    required this.avatar,
    required this.title,
    required this.picture,
    required this.count,
    required this.totalPrice,
  });

  final String userId;
  final String name;
  final String avatar;
  final String title;
  final String picture;
  final int count;
  final int totalPrice;

  String get pictureUrl => giftPictureUrl(picture);

  String? get avatarUrl => ValueUtil.getOriginalImageUrl(avatar);

  factory GiftSenderRecord.fromJson(Map<String, dynamic> json) {
    return GiftSenderRecord(
      userId: json['userid']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      avatar: json['avatar']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      picture: json['picture']?.toString() ?? '',
      count: _readInt(json['count']),
      totalPrice: _readInt(json['totalprice']),
    );
  }
}

/// 给某人送礼总额靠前的人。
class TopSender {
  const TopSender({
    required this.userId,
    required this.name,
    required this.avatar,
    required this.totalPrice,
  });

  final String userId;
  final String name;
  final String avatar;
  final int totalPrice;

  String? get avatarUrl => ValueUtil.getOriginalImageUrl(avatar);

  factory TopSender.fromJson(Map<String, dynamic> json) {
    return TopSender(
      userId: json['userid']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      avatar: json['avatar']?.toString() ?? '',
      totalPrice: _readInt(json['totalprice']),
    );
  }
}

/// 魅力榜或财富榜上的一个人。
class RankUser {
  const RankUser({
    required this.userId,
    required this.name,
    required this.avatar,
    required this.vsend,
    required this.vcharm,
  });

  final String userId;
  final String name;
  final String avatar;
  final int vsend;
  final int vcharm;

  String? get avatarUrl => ValueUtil.getOriginalImageUrl(avatar);

  factory RankUser.fromJson(Map<String, dynamic> json) {
    return RankUser(
      userId: json['userid']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      avatar: json['avatar']?.toString() ?? '',
      vsend: _readInt(json['vsend']),
      vcharm: _readInt(json['vcharm']),
    );
  }
}

/// 榜单一页。
class RankPageResult {
  const RankPageResult({required this.items, required this.totalPage});

  final List<RankUser> items;
  final int totalPage;
}

/// 当前用户在某个榜上的名次。rank=0 表示未上榜。
class RankSelfResult {
  const RankSelfResult({
    required this.rank,
    required this.userId,
    required this.name,
    required this.avatar,
    required this.vcharm,
    required this.vsend,
  });

  final int rank;
  final String userId;
  final String name;
  final String avatar;
  final int vcharm;
  final int vsend;

  String? get avatarUrl => ValueUtil.getOriginalImageUrl(avatar);

  factory RankSelfResult.fromJson(Map<String, dynamic> json) {
    return RankSelfResult(
      rank: _readInt(json['rank']),
      userId: json['userid']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      avatar: json['avatar']?.toString() ?? '',
      vcharm: _readInt(json['vcharm']),
      vsend: _readInt(json['vsend']),
    );
  }
}

int _readInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
