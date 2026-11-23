/// 客户端内置的个人主页封面。
///
/// [picture] 写入 `user.cover`。主页看到这个 key 就读 [asset]，不再请求网络。
class ProfileCoverPreset {
  const ProfileCoverPreset({required this.picture, required this.asset});

  /// 写入 `user.cover` 的文件名。
  final String picture;

  /// 打进安装包的封面图。
  final String asset;
}

/// 内置封面目录。相册自选的封面不在这里，主页改为走网络。
///
/// [assetMap] 的 key 就是 `user.cover`。命中则读包内图；没有再请求服务器。
/// 第一张是未设置封面时的默认图。同名文件也在 S3 上，给没有这张包内图的客户端兜底。
abstract final class ProfileCoverCatalog {
  static const defaultAsset =
      'assets/icons/user/covers/cover-preset-default.jpg';

  /// 更换封面页展示顺序。
  static const presetList = <ProfileCoverPreset>[
    ProfileCoverPreset(
      picture: 'cover-preset-default.jpg',
      asset: defaultAsset,
    ),
    ProfileCoverPreset(
      picture: 'cover-preset-car.jpg',
      asset: 'assets/icons/user/covers/cover-preset-car.jpg',
    ),
    ProfileCoverPreset(
      picture: 'cover-preset-book.jpg',
      asset: 'assets/icons/user/covers/cover-preset-book.jpg',
    ),
    ProfileCoverPreset(
      picture: 'cover-preset-radio.jpg',
      asset: 'assets/icons/user/covers/cover-preset-radio.jpg',
    ),
    ProfileCoverPreset(
      picture: 'cover-preset-poi.jpg',
      asset: 'assets/icons/user/covers/cover-preset-poi.jpg',
    ),
    ProfileCoverPreset(
      picture: 'cover-preset-music.jpg',
      asset: 'assets/icons/user/covers/cover-preset-music.jpg',
    ),
    ProfileCoverPreset(
      picture: 'cover-preset-game.jpg',
      asset: 'assets/icons/user/covers/cover-preset-game.jpg',
    ),
    ProfileCoverPreset(
      picture: 'cover-preset-tv.jpg',
      asset: 'assets/icons/user/covers/cover-preset-tv.jpg',
    ),
    ProfileCoverPreset(
      picture: 'cover-preset-movie.jpg',
      asset: 'assets/icons/user/covers/cover-preset-movie.jpg',
    ),
  ];

  /// `user.cover` -> 包内图。
  static final assetMap = <String, String>{
    for (final preset in presetList) preset.picture: preset.asset,
  };

  /// Buddy 早期内置封面 key，现网已无有效图片；本客户端按默认封面展示，不请求服务器。
  static bool isLegacyCoverKey(String? cover) {
    final value = cover?.trim() ?? '';
    if (value.isEmpty) {
      return false;
    }
    final name = value.contains('/')
        ? value.substring(value.lastIndexOf('/') + 1)
        : value;
    return name.startsWith('image-20200815-');
  }

  /// 封面 key 命中内置图时返回本地资源路径。空封面与废弃 key 返回默认图。
  static String? assetFor(String? cover) {
    final value = cover?.trim() ?? '';
    if (value.isEmpty || isLegacyCoverKey(value)) {
      return defaultAsset;
    }
    final direct = assetMap[value];
    if (direct != null) {
      return direct;
    }
    final slash = value.lastIndexOf('/');
    if (slash >= 0 && slash < value.length - 1) {
      return assetMap[value.substring(slash + 1)];
    }
    return null;
  }
}
