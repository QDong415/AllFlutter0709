import 'package:all_flutter0709/core/utils/value_util.dart';
import 'package:all_flutter0709/features/user/data/models/user_profile_model.dart';
import 'package:all_flutter0709/features/user/presentation/widgets/user_detail_action_buttons.dart';
import 'package:all_flutter0709/features/user/presentation/widgets/user_detail_cover.dart';
import 'package:all_flutter0709/features/user/presentation/widgets/user_detail_tags.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// 个人主页资料区：封面 + 头像、粉丝/关注、操作按钮、昵称、简介、标签。
class UserDetailHeader extends StatelessWidget {
  const UserDetailHeader({
    super.key,
    required this.profileModel,
    required this.coverHeight,
    required this.isSelf,
    required this.isFollowLoading,
    required this.onAvatarTap,
    required this.onChatTap,
    required this.onFollowTap,
    required this.onEditTap,
    this.stretchOffset = 0,
  });

  final UserProfileModel profileModel;
  final double coverHeight;
  final double stretchOffset;
  final bool isSelf;
  final bool isFollowLoading;
  final VoidCallback onAvatarTap;
  final VoidCallback onChatTap;
  final VoidCallback onFollowTap;
  final VoidCallback onEditTap;

  static const _headerBg = Color(0xFFF8F8F8);
  static const _avatarSize = 96.0;
  static const _avatarOverlap = 30.0;

  @override
  Widget build(BuildContext context) {
    final avatarUrl =
        ValueUtil.getQiniuUrlByFileName(profileModel.avatar, limitPx: 240) ??
        '';
    final intro = profileModel.intro.trim().isEmpty
        ? '尚未填写个人介绍'
        : profileModel.intro;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: coverHeight + stretchOffset + (112 - _avatarOverlap),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: UserDetailCover(
                  cover: profileModel.cover,
                  height: coverHeight,
                  stretchOffset: stretchOffset,
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 112,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 82,
                      child: ColoredBox(color: _headerBg),
                    ),
                    Positioned(
                      left: 12,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: onAvatarTap,
                        child: Container(
                          width: _avatarSize,
                          height: _avatarSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: _headerBg, width: 4),
                            color: const Color(0xFFE8E8E8),
                          ),
                          child: ClipOval(
                            child: avatarUrl.isEmpty
                                ? Image.asset(
                                    'assets/icons/user_photo.png',
                                    fit: BoxFit.cover,
                                  )
                                : CachedNetworkImage(
                                    imageUrl: avatarUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (_, _) => Image.asset(
                                      'assets/icons/user_photo.png',
                                      fit: BoxFit.cover,
                                    ),
                                    errorWidget: (_, _, _) => Image.asset(
                                      'assets/icons/user_photo.png',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12 + _avatarSize + 24,
                      right: 18,
                      bottom: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${profileModel.followCount}',
                                style: const TextStyle(
                                  fontSize: 21,
                                  color: Color(0xFF222222),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Text(
                                '关注',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF888888),
                                ),
                              ),
                              const SizedBox(width: 23),
                              Text(
                                '${profileModel.fansCount}',
                                style: const TextStyle(
                                  fontSize: 21,
                                  color: Color(0xFF222222),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Text(
                                '粉丝',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF888888),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          UserDetailActionButtons(
                            isSelf: isSelf,
                            followStatus: profileModel.follow,
                            isFollowLoading: isFollowLoading,
                            onChatTap: onChatTap,
                            onFollowTap: onFollowTap,
                            onEditTap: onEditTap,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ColoredBox(
          color: _headerBg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
                child: Text(
                  profileModel.name.isEmpty ? '加载中' : profileModel.name,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Text(
                  intro,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Color(0xFF888888),
                  ),
                ),
              ),
              UserDetailTags(profileModel: profileModel),
            ],
          ),
        ),
      ],
    );
  }
}
