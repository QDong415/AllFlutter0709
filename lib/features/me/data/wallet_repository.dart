import 'package:all_flutter0709/core/config/app_config.dart';
import 'package:all_flutter0709/core/network/api_response.dart';
import 'package:all_flutter0709/core/network/http_client.dart';
import 'package:all_flutter0709/core/network/page_data.dart';
import 'package:all_flutter0709/core/utils/money_util.dart';
import 'package:all_flutter0709/features/me/data/wallet_log_model.dart';
import 'package:all_flutter0709/features/me/data/wallet_model.dart';

/// 充值说明、会员价格、魅力提现和钱包流水。
class WalletRepository {
  const WalletRepository();

  /// 读取 `user/countprove` 里的 `app_reviewing`。
  Future<bool> fetchAppReviewing() async {
    final data = await _countprove(const <String, String>{});
    return AppConfig.isReviewingValue(data['app_reviewing']);
  }

  /// 金币余额，以及配置里的小秘书账号。
  Future<ChargeGuideModel> fetchChargeGuide() async {
    final data = await _countprove(const <String, String>{'secretary': '1'});
    return ChargeGuideModel.fromJson(data);
  }

  /// 月会员金币价、余额，以及当前 vip 标记。
  Future<VipOfferModel> fetchVipOffer() async {
    final data = await _countprove(const <String, String>{'showprice': '1'});
    return VipOfferModel.fromJson(data);
  }

  /// 用金币购买一个月会员。成功返回最新 coin / vip / vip_time。
  Future<VipOfferModel> buyVipMonth() async {
    final response = await HttpClient.instance.post('/api/user/buyvip');
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
      throw Exception(result.message.isEmpty ? '购买失败' : result.message);
    }
    return VipOfferModel.fromJson(result.data ?? <String, dynamic>{});
  }

  /// 魅力、兑换比例，以及最近一次申请留下的支付宝信息。
  Future<CharmCashModel> fetchCharmCash() async {
    final data = await _countprove(
      const <String, String>{'simple': '1', 'takecash': '1'},
    );
    return CharmCashModel.fromJson(data);
  }

  /// 兑换码兑金币。返回最新余额与提示文案。
  Future<({int coin, String message})> redeemPromoCode(String content) async {
    final response = await HttpClient.instance.post(
      '/api/coin_promo_code/redeem',
      data: <String, dynamic>{
        'content': content,
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
      throw Exception(result.message.isEmpty ? '兑换失败' : result.message);
    }
    final data = result.data ?? <String, dynamic>{};
    final rawCoin = data['coin'];
    final coin = switch (rawCoin) {
      final int value => value,
      final num value => value.toInt(),
      _ => int.tryParse('$rawCoin') ?? 0,
    };
    final message =
        result.message.isEmpty ? '兑换成功' : result.message;
    return (coin: coin, message: message);
  }

  /// 提交魅力提现，参数对齐 Buddy `MineTakeMoneyActivity`。
  Future<void> applyCharmWithdraw({
    required int charm,
    required int cashScale,
    required String account,
    required String realName,
  }) async {
    final reqmoney = MoneyUtil.charmWithdrawReqmoneyCents(charm, cashScale);
    final response = await HttpClient.instance.post(
      '/api/mission/takemoney',
      data: <String, dynamic>{
        'reqcharm': '$charm',
        'reqmoney': '$reqmoney',
        'account': account,
        'realname': realName,
      },
    );
    final json = response.data;
    if (json is! Map<String, dynamic>) {
      throw Exception('服务器返回为空');
    }
    final result = ApiResponse<Object?>.fromJson(json);
    if (!result.success) {
      throw Exception(result.message.isEmpty ? '提交失败' : result.message);
    }
  }

  /// 金币变动流水（`/api/mission/moneylog`）。
  Future<WalletLogPageResult> fetchMoneyLogList({required int page}) {
    return _fetchWalletLogList(
      path: '/api/mission/moneylog',
      page: page,
      fromJson: WalletLogModel.fromMoneyJson,
    );
  }

  /// 魅力值变动流水（`/api/mission/charmlog`）。
  Future<WalletLogPageResult> fetchCharmLogList({required int page}) {
    return _fetchWalletLogList(
      path: '/api/mission/charmlog',
      page: page,
      fromJson: WalletLogModel.fromCharmJson,
    );
  }

  Future<WalletLogPageResult> _fetchWalletLogList({
    required String path,
    required int page,
    required WalletLogModel Function(Map<String, dynamic> json) fromJson,
  }) async {
    final response = await HttpClient.instance.get(
      path,
      queryParameters: <String, dynamic>{
        'page': '$page',
      },
    );
    final json = response.data;
    if (json is! Map<String, dynamic>) {
      throw Exception('服务器返回为空');
    }
    final result = ApiResponse<PageData<WalletLogModel>>.fromJson(
      json,
      (pageJson) => PageData<WalletLogModel>.fromJson(
        pageJson as Map<String, dynamic>,
        (itemJson) => fromJson(itemJson as Map<String, dynamic>),
      ),
    );
    if (!result.success) {
      throw Exception(result.message.isEmpty ? '加载失败' : result.message);
    }
    final pageData = result.data;
    final items = pageData?.items ?? const <WalletLogModel>[];
    final hasMore = (pageData?.totalPage ?? 0) > page;
    return WalletLogPageResult(items: items, hasMore: hasMore);
  }

  Future<Map<String, dynamic>> _countprove(Map<String, String> query) async {
    final response = await HttpClient.instance.get(
      '/api/user/countprove',
      queryParameters: query,
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
    return result.data ?? <String, dynamic>{};
  }
}
