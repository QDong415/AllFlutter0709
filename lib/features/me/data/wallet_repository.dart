import 'package:all_flutter0709/core/network/api_response.dart';
import 'package:all_flutter0709/core/network/http_client.dart';
import 'package:all_flutter0709/features/me/data/wallet_model.dart';

/// 充值说明、会员价格和魅力提现。
class WalletRepository {
  const WalletRepository();

  /// 金币余额，以及配置里的小秘书账号。
  Future<ChargeGuideModel> fetchChargeGuide() async {
    final data = await _countprove(const <String, String>{'secretary': '1'});
    return ChargeGuideModel.fromJson(data);
  }

  /// 月 / 季 / 年价格，以及当前 vip 标记。
  Future<VipOfferModel> fetchVipOffer() async {
    final data = await _countprove(const <String, String>{'showprice': '1'});
    return VipOfferModel.fromJson(data);
  }

  /// 魅力、兑换比例，以及最近一次申请留下的支付宝信息。
  Future<CharmCashModel> fetchCharmCash() async {
    final data = await _countprove(
      const <String, String>{'simple': '1', 'takecash': '1'},
    );
    return CharmCashModel.fromJson(data);
  }

  /// 提交魅力提现。金额由服务端按比例重算。
  Future<void> applyCharmWithdraw({
    required int charm,
    required String account,
    required String realName,
  }) async {
    final response = await HttpClient.instance.post(
      '/api/mission/takemoney',
      data: <String, dynamic>{
        'reqcharm': '$charm',
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
