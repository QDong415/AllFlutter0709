import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/features/gift/data/gift_model.dart';
import 'package:all_flutter0709/features/gift/presentation/widgets/gift_user_avatar.dart';
import 'package:all_flutter0709/features/user/presentation/helpers/user_detail_navigation.dart';
import 'package:flutter/material.dart';

/// 设计稿基准宽度（对齐 Android 330dp）。
const _kDesignWidth = 330.0;

const _kPedestalHeight = 111.0;

const _kRank1FrameHeight = 92.0;
const _kRank2FrameHeight = 84.0;

const _kHaloToNameGap = 25.0;
const _kNameToScoreGap = 4.0;

/// 昵称+分数落在台面上的高度（越大台子越靠上）。
const _kLabelsOnPedestal = 64.0;

/// 底座整体上移（距 Stack 底边）。
const _kPedestalLift = 10.0;

const _kCrownOverflow = 12.0;
const _kLayoutSlack = 8.0;

/// 第 2 / 3 名列整体相对第 1 名再下沉一点（对齐较矮的台面）。
const _kRank2FrameExtraDrop = 6.0;
const _kRank3FrameExtraDrop = 13.0;

/// 仅头环+头像微调（不影响昵称/分数）。
const _kRank1FrameExtraLift = 3.0;
const _kRank3FrameOnlyExtraDrop = 6.0;

const _kPedestalTopLeft = 16 / 231 * _kPedestalHeight;
const _kPedestalTopRight = 13 / 231 * _kPedestalHeight;

/// 领奖台（蓝框区域）与上方「今日/本周/总榜」的间距（ListView header 使用）。
const rankPodiumTopInset = 0.0;

double _columnTextBlockHeight(double scale) {
  return scale * (22 + _kNameToScoreGap + 16);
}

double _columnHeight(int rank, double scale) {
  final frameH = scale * (rank == 1 ? _kRank1FrameHeight : _kRank2FrameHeight);
  return frameH + scale * _kHaloToNameGap + _columnTextBlockHeight(scale);
}

double _stackHeight(double scale) {
  final pedestal = scale * _kPedestalHeight;
  final column = _columnHeight(1, scale);
  final overlap = scale * _kLabelsOnPedestal;
  return pedestal +
      column -
      overlap +
      scale *
          (_kCrownOverflow +
              _kLayoutSlack +
              _kPedestalLift +
              _kRank3FrameExtraDrop +
              _kRank3FrameOnlyExtraDrop +
              _kRank1FrameExtraLift);
}

/// 榜单前三名领奖台（作为 ListView header 使用）。
class RankPodium extends StatelessWidget {
  const RankPodium({
    super.key,
    required this.charm,
    required this.first,
    required this.second,
    required this.third,
  });

  final bool charm;
  final RankUser? first;
  final RankUser? second;
  final RankUser? third;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final scale = ((maxW - 24).clamp(280.0, _kDesignWidth)) / _kDesignWidth;
        double s(double v) => v * scale;

        final pedestalH = s(_kPedestalHeight);
        final columnBottom = pedestalH - s(_kLabelsOnPedestal);

        return Center(
          child: SizedBox(
            width: s(_kDesignWidth),
            height: _stackHeight(scale),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: s(_kPedestalLift),
                  height: pedestalH,
                  child: Image.asset(
                    'assets/icons/rank/rank_bottom_theme.png',
                    fit: BoxFit.fill,
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: columnBottom,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(top: s(_kPedestalTopLeft)),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Transform.translate(
                              offset: Offset(0, s(_kRank2FrameExtraDrop)),
                              child: _PodiumColumn(
                                user: second,
                                rank: 2,
                                charm: charm,
                                scale: scale,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: _PodiumColumn(
                            user: first,
                            rank: 1,
                            charm: charm,
                            scale: scale,
                            frameVerticalOffset: -_kRank1FrameExtraLift,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(top: s(_kPedestalTopRight)),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Transform.translate(
                              offset: Offset(0, s(_kRank3FrameExtraDrop)),
                              child: _PodiumColumn(
                                user: third,
                                rank: 3,
                                charm: charm,
                                scale: scale,
                                frameVerticalOffset: _kRank3FrameOnlyExtraDrop,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  const _PodiumColumn({
    required this.user,
    required this.rank,
    required this.charm,
    required this.scale,
    this.frameVerticalOffset = 0,
  });

  final RankUser? user;
  final int rank;
  final bool charm;
  final double scale;
  final double frameVerticalOffset;

  @override
  Widget build(BuildContext context) {
    final spec = _PodiumFrameSpec.forRank(rank, scale);
    final name = user == null || user!.name.isEmpty ? '虚位以待' : user!.name;
    // 始终占位分数行，避免空榜时列高变矮、头像相对台面下移。
    final score = user == null
        ? '0'
        : '${charm ? user!.vcharm : user!.vsend}';
    final nameSize = (rank == 1 ? 15.0 : 14.0) * scale;
    final scoreSize = 13.0 * scale;

    return GestureDetector(
      onTap: user == null
          ? null
          : () => openUserDetailPage(
              context,
              userId: user!.userId,
              name: user!.name,
              avatar: user!.avatar,
            ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Transform.translate(
            offset: Offset(0, frameVerticalOffset * scale),
            child: SizedBox(
              width: spec.frameWidth,
              height: spec.frameHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: spec.avatarTop,
                    left: (spec.frameWidth - spec.avatarSize) / 2,
                    child: GiftUserAvatar(
                      url: user?.avatarUrl,
                      size: spec.avatarSize,
                    ),
                  ),
                  Positioned.fill(
                    child: Image.asset(
                      spec.frameAsset,
                      fit: BoxFit.contain,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: _kHaloToNameGap * scale),
          Container(
            constraints: BoxConstraints(maxWidth: 100 * scale),
            padding: EdgeInsets.symmetric(
              horizontal: 10 * scale,
              vertical: 2 * scale,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFE85554),
              borderRadius: BorderRadius.circular(16 * scale),
            ),
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: nameSize,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(height: _kNameToScoreGap * scale),
          Text(
            score,
            style: TextStyle(
              color: Colors.white,
              fontSize: scoreSize,
              fontWeight: FontWeight.w700,
              shadows: const [
                Shadow(
                  color: Color(0x88000000),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumFrameSpec {
  const _PodiumFrameSpec({
    required this.frameWidth,
    required this.frameHeight,
    required this.avatarSize,
    required this.avatarTop,
    required this.frameAsset,
  });

  final double frameWidth;
  final double frameHeight;
  final double avatarSize;
  final double avatarTop;
  final String frameAsset;

  static _PodiumFrameSpec forRank(int rank, double scale) {
    double s(double v) => v * scale;
    switch (rank) {
      case 1:
        return _PodiumFrameSpec(
          frameWidth: s(66),
          frameHeight: s(92),
          avatarSize: s(62),
          avatarTop: s(25),
          frameAsset: 'assets/icons/rank/gift_sender_top1.png',
        );
      case 2:
        return _PodiumFrameSpec(
          frameWidth: s(58),
          frameHeight: s(84),
          avatarSize: s(56),
          avatarTop: s(22),
          frameAsset: 'assets/icons/rank/gift_sender_top2.png',
        );
      default:
        return _PodiumFrameSpec(
          frameWidth: s(58),
          frameHeight: s(84),
          avatarSize: s(56),
          avatarTop: s(22),
          frameAsset: 'assets/icons/rank/gift_sender_top3.png',
        );
    }
  }
}

const rankPageGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFFFF7A79),
    Color(0xFFFFB1B0),
    Color(0xFFFFEAEA),
  ],
  stops: [0.0, 0.45, 1.0],
);

const rankDurationSelectedText = AppColors.primary;
