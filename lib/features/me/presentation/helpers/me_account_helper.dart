import 'package:all_flutter0709/core/account/account.dart';

/// 把 `user/modifyarray` 返回的用户字段合并进当前账号。
AccountModel mergeModifiedAccount(
  AccountModel current,
  Map<String, dynamic> serverJson,
) {
  return AccountModel.fromJson(<String, dynamic>{
    ...current.toJson(),
    ...serverJson,
  });
}

/// 对齐 Android `ValueUtil.findCityIdByAdCode`。
String cityIdFromAdCode(String adCode) {
  if (adCode.isEmpty) {
    return '110000';
  }
  if (adCode.startsWith('11') ||
      adCode.startsWith('12') ||
      adCode.startsWith('31') ||
      adCode.startsWith('50')) {
    return '${adCode.substring(0, 2)}0000';
  }
  if (adCode.length < 4) {
    return adCode;
  }
  return '${adCode.substring(0, 4)}00';
}
