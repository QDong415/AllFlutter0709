import 'package:all_flutter0709/app/router/app_routes.dart';
import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/app/theme/app_dimens.dart';
import 'package:all_flutter0709/core/account/account_guard.dart';
import 'package:all_flutter0709/core/account/account_provider.dart';
import 'package:all_flutter0709/features/me/presentation/widgets/me_header.dart';
import 'package:all_flutter0709/features/me/presentation/widgets/me_menu_section.dart';
import 'package:all_flutter0709/features/user/data/user_repository.dart';
import 'package:all_flutter0709/features/user/presentation/helpers/user_detail_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 「我的」页，对齐 Android `MineFragment`。
class MePage extends ConsumerStatefulWidget {
  const MePage({super.key});

  @override
  ConsumerState<MePage> createState() => _MePageState();
}

class _MePageState extends ConsumerState<MePage> {
  final UserRepository _userRepository = const UserRepository();
  double _titleOpacity = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshCounts());
  }

  Future<void> _refreshCounts() async {
    final account = ref.read(accountProvider);
    if (account == null) {
      return;
    }
    try {
      final profile = await _userRepository.getUserProfile(
        toUserId: account.userId,
      );
      if (!mounted) {
        return;
      }
      final current = ref.read(accountProvider);
      if (current == null) {
        return;
      }
      await ref
          .read(accountProvider.notifier)
          .setAccount(
            current.copyWith(
              name: profile.name,
              avatar: profile.avatar,
              intro: profile.intro,
              gender: profile.gender,
              age: profile.age,
              cityName: profile.cityName,
              fansCount: profile.fansCount,
              followCount: profile.followCount,
              topicCount: profile.topicCount,
            ),
          );
    } catch (_) {}
  }

  bool _requireLogin() => context.ensureLoggedIn();

  void _open(String path, {Object? extra}) {
    if (!_requireLogin()) {
      return;
    }
    context.push(path, extra: extra);
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(accountProvider);
    final loggedIn = account != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: Stack(
        children: [
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image(
              image: AssetImage('assets/icons/me/mine_header_bg.png'),
              fit: BoxFit.fitWidth,
            ),
          ),
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              final opacity = (notification.metrics.pixels / 80).clamp(
                0.0,
                1.0,
              );
              if ((opacity - _titleOpacity).abs() > 0.02) {
                setState(() => _titleOpacity = opacity);
              }
              return false;
            },
            child: ListView(
              padding: const EdgeInsets.only(
                bottom: AppDimens.glassTabBarContentInset,
              ),
              children: [
                MeHeader(
                  name: loggedIn
                      ? (account.name.isEmpty ? '未填写' : account.name)
                      : '未登录',
                  avatar: account?.avatar ?? '',
                  fansCount: account?.fansCount ?? 0,
                  followCount: account?.followCount ?? 0,
                  onProfileTap: () => _open(AppRoutes.meProfileEdit),
                  onFansTap: () => _open(
                    AppRoutes.meFriendship,
                    extra: const FriendshipArgs(isFansList: true),
                  ),
                  onFollowTap: () => _open(
                    AppRoutes.meFriendship,
                    extra: const FriendshipArgs(isFansList: false),
                  ),
                ),
                MeMenuSection(
                  itemList: [
                    MeMenuItem(
                      iconAsset: 'assets/icons/me/mine_icon_submit.png',
                      title: '我发的动态',
                      onTap: () {
                        if (!_requireLogin()) return;
                        openUserDetailPage(
                          context,
                          userId: account!.userId,
                          name: account.name,
                          avatar: account.avatar,
                          userType: account.userType,
                        );
                      },
                    ),
                    MeMenuItem(
                      iconAsset: 'assets/icons/me/mine_icon_like.png',
                      title: '我赞的动态',
                      onTap: () => _open(
                        AppRoutes.meTopics,
                        extra: const MineTopicArgs(onlyLike: true),
                      ),
                    ),
                    MeMenuItem(
                      iconAsset: 'assets/icons/me/mine_icon_comment.png',
                      title: '我评论的动态',
                      onTap: () => _open(
                        AppRoutes.meTopics,
                        extra: const MineTopicArgs(onlyComment: true),
                      ),
                    ),
                  ],
                ),
                MeMenuSection(
                  itemList: [
                    MeMenuItem(
                      iconAsset: 'assets/icons/me/mine_icon_search.png',
                      title: '找用户动态',
                      onTap: () => context.push(AppRoutes.meSearch),
                    ),
                    MeMenuItem(
                      iconAsset: 'assets/icons/me/mine_icon_near.png',
                      title: '附近的人',
                      onTap: () => context.push(AppRoutes.meNearby),
                    ),
                  ],
                ),
                MeMenuSection(
                  itemList: [
                    MeMenuItem(
                      iconAsset: 'assets/icons/me/mine_icon_setting.png',
                      title: '设置',
                      onTap: () => context.push(AppRoutes.meSettings),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Opacity(
                opacity: _titleOpacity,
                child: Container(
                  color: AppColors.toolbar,
                  padding: EdgeInsets.only(
                    top: MediaQuery.paddingOf(context).top,
                  ),
                  child: const SizedBox(
                    height: AppDimens.toolbarHeight,
                    child: Center(
                      child: Text(
                        '我的',
                        style: TextStyle(
                          fontSize: AppDimens.toolbarTitleSize,
                          color: AppColors.titleText,
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
}

/// 粉丝或关注列表参数。
class FriendshipArgs {
  const FriendshipArgs({required this.isFansList});

  final bool isFansList;
}

/// 我赞过 / 我评论的动态参数。
class MineTopicArgs {
  const MineTopicArgs({this.onlyLike = false, this.onlyComment = false});

  final bool onlyLike;
  final bool onlyComment;
}
