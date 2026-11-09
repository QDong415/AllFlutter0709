import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// SVIP 头像。`vip == 2` 时在头像外叠性别色皇冠圈。
///
/// 圈图是正方形，皇冠在左上，圆孔偏下。内径约占边长的 273/368，
/// 圆心在 (182.5, 221)。头像按这个比例卡进圆孔，换任何直径都对齐。
class VipHaloAvatar extends StatelessWidget {
  const VipHaloAvatar({
    super.key,
    required this.size,
    this.imageUrl = '',
    this.vip = 0,
    this.gender = 0,
    this.borderWidth = 0,
    this.borderColor = const Color(0xFFF8F8F8),
    this.backgroundColor = const Color(0xFFE8E8E8),
  });

  /// 头像直径，含自身描边。
  final double size;

  /// 头像地址。空地址或下载失败时用本地缺省图。
  final String imageUrl;

  /// 0 普通 / 1 VIP / 2 SVIP。只有 2 画光环。
  final int vip;

  /// 1 男 / 2 女。女用粉圈，其余用蓝圈。
  final int gender;

  /// 头像描边宽度。光环内圈对齐去掉描边后的照片圆。
  final double borderWidth;

  final Color borderColor;
  final Color backgroundColor;

  static const _assetSize = 368.0;
  static const _ringInnerDiameter = 273.0;
  static const _ringCenterX = 182.5;
  static const _ringCenterY = 221.0;

  static const _maleAsset = 'assets/icons/user/avatar_board_m.png';
  static const _femaleAsset = 'assets/icons/user/avatar_board_f.png';

  /// 对齐 Android `R.drawable.user_photo`：头像为空或加载失败时的缺省图。
  static const fallbackAsset = 'assets/icons/user_photo.png';

  /// 是否显示光环。
  static bool showsHalo(int vip) => vip == 2;

  /// 组件边长。无光环时等于头像直径。
  static double layoutExtent({
    required double size,
    required int vip,
    double borderWidth = 0,
  }) {
    if (!showsHalo(vip)) return size;
    return _photoDiameter(size, borderWidth) / _ringInnerDiameter * _assetSize;
  }

  /// 头像和右侧文字的间距。有光环时扣掉圆右侧多出的宽度。
  static double contentGap({
    required double size,
    required int vip,
    required double gap,
    double borderWidth = 0,
  }) {
    if (!showsHalo(vip)) return gap;
    final extent = layoutExtent(size: size, vip: vip, borderWidth: borderWidth);
    final originX = avatarOrigin(
      size: size,
      vip: vip,
      borderWidth: borderWidth,
    ).dx;
    final next = gap - (extent - originX - size);
    if (next < 0) return 0;
    return next;
  }

  /// 头像左上角相对组件左上角的偏移。无光环时为零。
  static Offset avatarOrigin({
    required double size,
    required int vip,
    double borderWidth = 0,
  }) {
    if (!showsHalo(vip)) return Offset.zero;
    final extent = layoutExtent(size: size, vip: vip, borderWidth: borderWidth);
    return Offset(
      extent * _ringCenterX / _assetSize - size / 2,
      extent * _ringCenterY / _assetSize - size / 2,
    );
  }

  static double _photoDiameter(double size, double borderWidth) {
    final photo = size - borderWidth * 2;
    if (photo <= 0) return size;
    return photo;
  }

  @override
  Widget build(BuildContext context) {
    final avatar = _buildAvatar();
    if (!showsHalo(vip)) {
      return SizedBox(width: size, height: size, child: avatar);
    }

    final extent = layoutExtent(size: size, vip: vip, borderWidth: borderWidth);
    final origin = avatarOrigin(size: size, vip: vip, borderWidth: borderWidth);
    return SizedBox(
      width: extent,
      height: extent,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              gender == 2 ? _femaleAsset : _maleAsset,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.medium,
            ),
          ),
          Positioned(
            left: origin.dx,
            top: origin.dy,
            width: size,
            height: size,
            child: avatar,
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
        border: borderWidth > 0
            ? Border.all(color: borderColor, width: borderWidth)
            : null,
      ),
      child: SizedBox.expand(
        child: avatarImage(imageUrl, size: size),
      ),
    );
  }

  /// 头像图。无地址时用圆形灰底+剪影，避免缺省 PNG 在圆裁切里留白边。
  static Widget avatarImage(String imageUrl, {required double size}) {
    final url = imageUrl.trim();
    if (url.isEmpty) {
      return ColoredBox(
        color: const Color(0xFFE9E9E9),
        child: Center(
          child: Icon(
            Icons.person_rounded,
            size: size * 0.52,
            color: Colors.white,
          ),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, _) => _fallbackPlaceholder(size),
      errorWidget: (_, _, _) => _fallbackPlaceholder(size),
    );
  }

  static Widget _fallbackPlaceholder(double size) {
    return ColoredBox(
      color: const Color(0xFFE9E9E9),
      child: Center(
        child: Icon(
          Icons.person_rounded,
          size: size * 0.52,
          color: Colors.white,
        ),
      ),
    );
  }
}
