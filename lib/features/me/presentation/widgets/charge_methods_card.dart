import 'package:all_flutter0709/app/theme/app_palette.dart';
import 'package:all_flutter0709/core/utils/value_util.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 充值方式说明卡片，对齐 Android `charge_ll`，并增加兑换码方式 3。
class ChargeMethodsCard extends StatelessWidget {
  const ChargeMethodsCard({
    super.key,
    required this.secretaryName,
    required this.secretaryAvatar,
    required this.way2Text,
    required this.promoCodeController,
    required this.loading,
    required this.redeeming,
    required this.onContactTap,
    required this.onRedeemTap,
  });

  final String secretaryName;
  final String secretaryAvatar;

  /// 「充值方式2」说明，来自服务端 `pay_way2`。
  final String way2Text;

  /// 「充值方式3」兑换码输入。
  final TextEditingController promoCodeController;
  final bool loading;
  final bool redeeming;
  final VoidCallback? onContactTap;
  final VoidCallback? onRedeemTap;

  static const _orange = Color(0xFFFC6F1D);

  @override
  Widget build(BuildContext context) {
    final avatarUrl = ValueUtil.getQiniuUrlByFileName(
      secretaryAvatar,
      limitPx: 128,
    );
    final palette = context.palette;
    final displayName = secretaryName.trim().isEmpty
        ? '小秘书'
        : secretaryName.trim();
    final titleStyle = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: palette.ink,
    );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 20, 14, 24),
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 18),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              '充值方式1',
              textAlign: TextAlign.center,
              style: titleStyle,
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: palette.pressed,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: palette.divider, width: 1),
            ),
            child: Row(
              children: [
                const SizedBox(width: 20),
                ClipOval(
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: _avatar(avatarUrl),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    displayName,
                    style: TextStyle(fontSize: 16, color: palette.ink),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Material(
                    color: _orange,
                    borderRadius: BorderRadius.circular(4),
                    child: InkWell(
                      onTap: loading ? null : onContactTap,
                      borderRadius: BorderRadius.circular(4),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        child: Text(
                          '去联系',
                          style: TextStyle(color: Colors.white, fontSize: 15),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Text(
              '充值方式2',
              textAlign: TextAlign.center,
              style: titleStyle,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Text(
              way2Text,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: palette.bodyText),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Text(
              '充值方式3',
              textAlign: TextAlign.center,
              style: titleStyle,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: TextField(
              controller: promoCodeController,
              enabled: !loading && !redeeming,
              maxLines: 1,
              textInputAction: TextInputAction.done,
              keyboardType: TextInputType.visiblePassword,
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'[\r\n]')),
                LengthLimitingTextInputFormatter(32),
              ],
              style: TextStyle(fontSize: 15, color: palette.ink),
              cursorColor: palette.ink,
              decoration: InputDecoration(
                hintText: '兑换码',
                hintStyle: TextStyle(
                  color: palette.secondaryText,
                  fontSize: 15,
                ),
                filled: true,
                fillColor: palette.inputExtendBackground,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: palette.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: palette.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _orange),
                ),
              ),
              onSubmitted: (_) {
                if (!loading && !redeeming) {
                  onRedeemTap?.call();
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
            child: SizedBox(
              width: double.infinity,
              child: Material(
                color: _orange,
                borderRadius: BorderRadius.circular(4),
                child: InkWell(
                  onTap: (loading || redeeming) ? null : onRedeemTap,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Text(
                        redeeming ? '兑换中…' : '确认',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) {
      return Image.asset('assets/icons/me/user_photo.png', fit: BoxFit.cover);
    }
    return CachedNetworkImage(
      imageUrl: avatarUrl,
      fit: BoxFit.cover,
      errorWidget: (_, _, _) =>
          Image.asset('assets/icons/me/user_photo.png', fit: BoxFit.cover),
    );
  }
}
