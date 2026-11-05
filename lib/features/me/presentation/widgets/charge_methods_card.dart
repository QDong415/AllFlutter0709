import 'package:all_flutter0709/core/utils/value_util.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// 充值方式说明卡片，对齐 Android `charge_ll`。
class ChargeMethodsCard extends StatelessWidget {
  const ChargeMethodsCard({
    super.key,
    required this.secretaryName,
    required this.secretaryAvatar,
    required this.loading,
    required this.onContactTap,
  });

  final String secretaryName;
  final String secretaryAvatar;
  final bool loading;
  final VoidCallback? onContactTap;

  static const _blackGray = Color(0xFF000000);
  static const _textBlack = Color(0xFF5B5B5B);

  @override
  Widget build(BuildContext context) {
    final avatarUrl = ValueUtil.getQiniuUrlByFileName(
      secretaryAvatar,
      limitPx: 128,
    );
    final displayName =
        secretaryName.trim().isEmpty ? '小秘书' : secretaryName.trim();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 20, 14, 24),
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              '充值方式1',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _blackGray,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F3F3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE3E3E3), width: 1),
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
                    style: const TextStyle(fontSize: 16, color: _blackGray),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Material(
                    color: const Color(0xFFFC6F1D),
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
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Text(
              '充值方式2',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _blackGray,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Text(
              '打开微信，关注公众号「秘缘派」，在公众号中完成充值',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: _textBlack),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) {
      return Image.asset(
        'assets/icons/me/user_photo.png',
        fit: BoxFit.cover,
      );
    }
    return CachedNetworkImage(
      imageUrl: avatarUrl,
      fit: BoxFit.cover,
      errorWidget: (_, _, _) => Image.asset(
        'assets/icons/me/user_photo.png',
        fit: BoxFit.cover,
      ),
    );
  }
}
