import 'package:all_flutter0709/core/network/api_response.dart';
import 'package:all_flutter0709/core/network/http_client.dart';
import 'package:all_flutter0709/core/network/page_data.dart';
import 'package:all_flutter0709/features/gift/data/gift_list_errors.dart';
import 'package:all_flutter0709/features/gift/data/gift_model.dart';

/// 礼物目录、送礼、礼物墙和榜单。
class GiftRepository {
  const GiftRepository();

  /// 拉取未下架礼物，按价格从低到高。
  Future<List<GiftModel>> fetchGiftList() async {
    final response = await HttpClient.instance.get(
      '/api/banner/giftlist',
      queryParameters: const <String, dynamic>{'page': '1', 'pagesize': '100'},
    );
    final json = response.data;
    if (json is! Map<String, dynamic>) {
      throw Exception('服务器返回为空');
    }
    final result = ApiResponse<PageData<GiftModel>>.fromJson(
      json,
      (dataJson) => PageData.fromJson(
        dataJson as Map<String, dynamic>,
        (item) => GiftModel.fromJson(item as Map<String, dynamic>),
      ),
    );
    if (!result.success) {
      throw Exception(result.message.isEmpty ? '礼物加载失败' : result.message);
    }
    return result.data?.items ?? const <GiftModel>[];
  }

  /// 当前账号金币。
  Future<int> fetchCoin() async {
    final response = await HttpClient.instance.get('/api/user/countprove');
    final json = response.data;
    if (json is! Map<String, dynamic>) {
      throw Exception('服务器返回为空');
    }
    final result = ApiResponse<int>.fromJson(json, (dataJson) {
      if (dataJson is Map) {
        return _readInt(dataJson['coin']);
      }
      return 0;
    });
    if (!result.success) {
      throw Exception(result.message.isEmpty ? '余额加载失败' : result.message);
    }
    return result.data ?? 0;
  }

  /// 送礼。type：1 动态，4 聊天。成功返回剩余金币。
  Future<int> send({
    required String toUserId,
    required int giftId,
    required int count,
    required int type,
    String feedId = '0',
  }) async {
    final response = await HttpClient.instance.post(
      '/api/gift/send',
      data: <String, dynamic>{
        'to_userid': toUserId,
        'giftid': '$giftId',
        'count': '$count',
        'type': '$type',
        'feedid': feedId,
      },
    );
    final json = response.data;
    if (json is! Map<String, dynamic>) {
      throw Exception('服务器返回为空');
    }
    final result = ApiResponse<int>.fromJson(json, (dataJson) {
      if (dataJson is int) {
        return dataJson;
      }
      if (dataJson is num) {
        return dataJson.toInt();
      }
      return int.tryParse(dataJson?.toString() ?? '') ?? 0;
    });
    if (!result.success) {
      throw Exception(result.message.isEmpty ? '送礼失败' : result.message);
    }
    return result.data ?? 0;
  }

  /// 收到的礼物汇总。至少要传 [toUserId] 或 [feedId]。
  Future<List<ReceivedGift>> fetchReceivedGifts({
    String? toUserId,
    String? feedId,
    int? type,
  }) {
    return _fetchItems(
      '/api/gift/feed_giftlist',
      _giftQuery(toUserId: toUserId, feedId: feedId, type: type),
      ReceivedGift.fromJson,
    );
  }

  /// 送礼流水。
  Future<List<GiftSenderRecord>> fetchSenderList({
    String? toUserId,
    String? feedId,
    int? type,
    int page = 1,
    int pageSize = 20,
  }) {
    return _fetchItems(
      '/api/gift/senderlist',
      _giftQuery(
        toUserId: toUserId,
        feedId: feedId,
        type: type,
        page: page,
        pageSize: pageSize,
      ),
      GiftSenderRecord.fromJson,
    );
  }

  /// 送礼总额前几名。
  Future<List<TopSender>> fetchTopSenders(String toUserId, {int pageSize = 5}) {
    return _fetchItems('/api/gift/top_senderlist', <String, dynamic>{
      'to_userid': toUserId,
      'page': '1',
      'pagesize': '$pageSize',
    }, TopSender.fromJson);
  }

  /// 魅力榜 [charm] 为 true，否则财富榜。duration：1 今日，2 本周，3 总榜。
  Future<RankPageResult> fetchRank({
    required bool charm,
    required int duration,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await HttpClient.instance.get(
      '/api/gift/ranklist',
      queryParameters: <String, dynamic>{
        'charm': charm ? '1' : '0',
        'duration': '$duration',
        'page': '$page',
        'pagesize': '$pageSize',
      },
    );
    final data = _pageMap(response.data, '榜单加载失败');
    final rawItems = data['items'];
    final items = rawItems is List
        ? rawItems
              .whereType<Map>()
              .map((item) => RankUser.fromJson(Map<String, dynamic>.from(item)))
              .toList()
        : <RankUser>[];
    return RankPageResult(items: items, totalPage: _readInt(data['totalpage']));
  }

  /// 当前登录用户在本榜的名次。
  Future<RankSelfResult> fetchRankSelf({
    required bool charm,
    required int duration,
  }) async {
    final response = await HttpClient.instance.get(
      '/api/gift/rankself',
      queryParameters: <String, dynamic>{
        'charm': charm ? '1' : '0',
        'duration': '$duration',
      },
    );
    final json = response.data;
    if (json is! Map<String, dynamic>) {
      throw Exception('服务器返回为空');
    }
    final result = ApiResponse<Map<String, dynamic>>.fromJson(json, (dataJson) {
      if (dataJson is Map<String, dynamic>) {
        return dataJson;
      }
      if (dataJson is Map) {
        return Map<String, dynamic>.from(dataJson);
      }
      return <String, dynamic>{};
    });
    if (!result.success) {
      throw Exception(result.message.isEmpty ? '加载失败' : result.message);
    }
    return RankSelfResult.fromJson(result.data ?? <String, dynamic>{});
  }

  Future<List<T>> _fetchItems<T>(
    String path,
    Map<String, dynamic> query,
    T Function(Map<String, dynamic> json) fromJson,
  ) async {
    final response = await HttpClient.instance.get(
      path,
      queryParameters: query,
    );
    final data = _pageMap(response.data, '加载失败');
    final rawItems = data['items'];
    if (rawItems is! List) {
      return <T>[];
    }
    return rawItems
        .whereType<Map>()
        .map((item) => fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Map<String, dynamic> _pageMap(Object? json, String fallback) {
    if (json is! Map<String, dynamic>) {
      throw Exception('服务器返回为空');
    }
    final result = ApiResponse<Map<String, dynamic>>.fromJson(json, (dataJson) {
      if (dataJson is Map<String, dynamic>) {
        return dataJson;
      }
      if (dataJson is Map) {
        return Map<String, dynamic>.from(dataJson);
      }
      return <String, dynamic>{};
    });
    if (!result.success) {
      final message = result.message.isEmpty ? fallback : result.message;
      if (isGiftListHiddenError(message)) {
        throw GiftListHiddenException();
      }
      throw Exception(message);
    }
    return result.data ?? <String, dynamic>{};
  }

  Map<String, dynamic> _giftQuery({
    String? toUserId,
    String? feedId,
    int? type,
    int? page,
    int? pageSize,
  }) {
    return <String, dynamic>{
      if (toUserId != null && toUserId.isNotEmpty) 'to_userid': toUserId,
      if (feedId != null && feedId.isNotEmpty) 'feedid': feedId,
      if (type != null) 'type': '$type',
      if (page != null) 'page': '$page',
      if (pageSize != null) 'pagesize': '$pageSize',
    };
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
