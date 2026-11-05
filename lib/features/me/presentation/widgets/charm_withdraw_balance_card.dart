import 'package:all_flutter0709/core/utils/value_util.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// 魅力提现页顶部余额卡片，对齐 Android `activity_mine_takemoney` 的 `money_bg` 区域。
class CharmWithdrawBalanceCard extends StatelessWidget {
  const CharmWithdrawBalanceCard({
    super.key,
    required this.loading,
    required this.yuanLabel,
    required this.scaleHint,
    this.avatarUrl,
  });

  final bool loading;
  final String yuanLabel;
  final String scaleHint;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/icons/me/money_bg.png'),
          fit: BoxFit.fill,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 6, top: 6, bottom: 6),
                child: ClipOval(
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: _avatarImage(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '共可提现：',
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            loading ? '加载中' : yuanLabel,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.normal,
            ),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                loading ? '' : scaleHint,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarImage() {
    final url = avatarUrl?.trim() ?? '';
    if (url.isEmpty) {
      return Image.asset(
        'assets/icons/me/user_photo.png',
        fit: BoxFit.cover,
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      errorWidget: (_, _, _) => Image.asset(
        'assets/icons/me/user_photo.png',
        fit: BoxFit.cover,
      ),
    );
  }
}

/// 按 Android `MineTakeMoneyActivity` 的换算方式格式化为「x元」。
String formatCharmToYuanLabel(int charm, int scale) {
  if (scale <= 0) {
    return '0元';
  }
  final yuan = (charm / scale * 100).round() / 100.0;
  return '$yuan元';
}

/// 头像地址，与 Android 列表头像一致走缩略图。
String? charmWithdrawAvatarUrl(String? avatarFile) {
  return ValueUtil.getQiniuUrlByFileName(avatarFile, limitPx: 96);
}
