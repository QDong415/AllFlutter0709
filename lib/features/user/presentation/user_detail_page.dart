import 'dart:async';
import 'dart:math' as math;

import 'package:all_flutter0709/app/router/app_routes.dart';
import 'package:all_flutter0709/app/theme/app_dimens.dart';
import 'package:all_flutter0709/core/account/account_guard.dart';
import 'package:all_flutter0709/core/account/account_provider.dart';
import 'package:all_flutter0709/core/utils/value_util.dart';
import 'package:all_flutter0709/features/topic/data/topic_repository.dart';
import 'package:all_flutter0709/features/topic/presentation/topic_list_base_state.dart';
import 'package:all_flutter0709/features/topic/presentation/widgets/topic_item_widget.dart';
import 'package:all_flutter0709/features/conversation/presentation/helpers/conversation_chat_args.dart';
import 'package:all_flutter0709/features/user/data/models/user_profile_model.dart';
import 'package:all_flutter0709/features/user/data/user_repository.dart';
import 'package:all_flutter0709/features/user/presentation/helpers/user_follow_helper.dart';
import 'package:all_flutter0709/features/user/presentation/widgets/user_avatar_preview_page.dart';
import 'package:all_flutter0709/features/user/presentation/widgets/user_detail_header.dart';
import 'package:all_flutter0709/features/user/presentation/widgets/user_detail_nav_bar.dart';
import 'package:all_flutter0709/shared/widgets/page_state_view.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 用户个人主页：资料 Header + 该用户动态列表。
class UserDetailPage extends StatefulWidget {
  const UserDetailPage({
    super.key,
    required this.userId,
    this.initialName,
    this.initialAvatar,
  });

  final String userId;
  final String? initialName;
  final String? initialAvatar;

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends TopicListBaseState<UserDetailPage> {
  final UserRepository _userRepository = const UserRepository();

  late UserProfileModel _profileModel;
  bool _isFollowLoading = false;
  double _collapseProgress = 0;
  double _stretchOffset = 0;

  static const _parallaxHeight = 70.0;

  bool get _isSelf {
    final myId =
        ProviderScope.containerOf(
          context,
        ).read(accountProvider)?.userId.trim() ??
        '';
    return myId.isNotEmpty && myId == widget.userId.trim();
  }

  double _coverHeight(BuildContext context) {
    return MediaQuery.paddingOf(context).top +
        AppDimens.toolbarHeight +
        _parallaxHeight;
  }

  @override
  void initState() {
    super.initState();
    _profileModel = UserProfileModel(
      userId: widget.userId,
      name: widget.initialName?.trim() ?? '',
      avatar: widget.initialAvatar?.trim() ?? '',
      intro: '',
      gender: 0,
      age: 0,
      cover: '',
      cityName: '',
      followCount: 0,
      fansCount: 0,
      topicCount: 0,
      videoCount: 0,
      follow: 0,
    );
    unawaited(_loadProfile());
  }

  @override
  Map<String, dynamic>? customParameters() {
    Map<String, dynamic> map = {"toUserId" : widget.userId};
    return map;
  }

  @override
  String get emptyText => '没发布任何动态';

  @override
  bool get useDefaultScaffold => false;

  Future<void> _loadProfile() async {
    try {
      final profile = await _userRepository.getUserProfile(
        toUserId: widget.userId,
      );
      if (!mounted) return;
      setState(() {
        _profileModel = profile;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _onRefresh() async {
    await Future.wait([_loadProfile(), onRefreshList()]);
  }

  bool _onScrollNotification(ScrollNotification notification) {
    final coverHeight = _coverHeight(context);

    if (notification is OverscrollNotification) {
      // 顶部下拉：放大封面
      if (notification.overscroll < 0 && notification.metrics.pixels <= 0) {
        final nextStretch = (_stretchOffset - notification.overscroll).clamp(
          0.0,
          140.0,
        );
        if ((nextStretch - _stretchOffset).abs() > 0.5) {
          setState(() {
            _stretchOffset = nextStretch;
            _collapseProgress = 0;
          });
        }
        return false;
      }
    }

    if (notification is ScrollEndNotification ||
        notification is ScrollUpdateNotification) {
      final pixels = notification.metrics.pixels;
      if (pixels < 0) {
        final nextStretch = -pixels;
        if ((nextStretch - _stretchOffset).abs() > 0.5 ||
            _collapseProgress != 0) {
          setState(() {
            _stretchOffset = nextStretch;
            _collapseProgress = 0;
          });
        }
        return false;
      }

      final nextProgress = (pixels / math.max(coverHeight, 1)).clamp(0.0, 1.0);
      final shouldResetStretch = _stretchOffset > 0 && pixels >= 0;
      if (shouldResetStretch ||
          (_collapseProgress - nextProgress).abs() > 0.01) {
        setState(() {
          if (shouldResetStretch) {
            _stretchOffset = 0;
          }
          _collapseProgress = nextProgress;
        });
      }
    }
    return false;
  }

  void _onAvatarTap() {
    final url =
        ValueUtil.getOriginalImageUrl(_profileModel.avatar) ??
        ValueUtil.getQiniuUrlByFileName(_profileModel.avatar) ??
        '';
    openUserAvatarPreview(context, imageUrl: url);
  }

  SystemUiOverlayStyle get _systemUiOverlayStyle {
    return userDetailSystemUiOverlayStyle(collapseProgress: _collapseProgress);
  }

  void _applySystemUiOverlayStyle() {
    SystemChrome.setSystemUIOverlayStyle(_systemUiOverlayStyle);
  }

  Future<void> _onChatTap() async {
    if (!context.ensureLoggedIn()) return;
    await context.push(
      '${AppRoutes.conversation}/chat/${widget.userId}',
      extra: ConversationChatArgs(
        peerName: _profileModel.name,
        peerAvatar: _profileModel.avatar,
      ),
    );
    // 从聊天返回时 AnnotatedRegion 不一定会立刻重刷底部指示器，需主动恢复。
    if (!mounted) return;
    _applySystemUiOverlayStyle();
  }

  Future<void> _onFollowTap() async {
    if (!context.ensureLoggedIn()) return;
    if (_isFollowLoading) return;

    setState(() => _isFollowLoading = true);
    try {
      final status = await UserFollowHelper.follow(
        repository: _userRepository,
        toUserId: widget.userId,
      );
      if (!mounted) return;
      setState(() {
        _profileModel = _profileModel.copyWith(follow: status);
        _isFollowLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isFollowLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _onEditTap() {
    // 编辑资料本轮仅占位。
  }

  void _onMoreTap() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('更多功能开发中')));
  }

  Widget _buildScrollBody(ScrollPhysics physics) {
    final coverHeight = _coverHeight(context);

    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: CustomScrollView(
        physics: physics,
        slivers: [
          SliverToBoxAdapter(
            child: UserDetailHeader(
              profileModel: _profileModel,
              coverHeight: coverHeight,
              stretchOffset: _stretchOffset,
              isSelf: _isSelf,
              isFollowLoading: _isFollowLoading,
              onAvatarTap: _onAvatarTap,
              onChatTap: _onChatTap,
              onFollowTap: _onFollowTap,
              onEditTap: _onEditTap,
            ),
          ),
          ..._buildListSlivers(),
        ],
      ),
    );
  }

  List<Widget> _buildListSlivers() {
    switch (pageState) {
      case PageState.loading:
        return [
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          ),
        ];
      case PageState.empty:
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: PageStateView(
              state: PageState.empty,
              emptyText: emptyText,
              successWidget: const SizedBox.shrink(),
            ),
          ),
        ];
      case PageState.error:
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: PageStateView(
              state: PageState.error,
              errorText: errorText,
              successWidget: const SizedBox.shrink(),
            ),
          ),
        ];
      case PageState.success:
        return [
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                if (index.isOdd) {
                  return const SizedBox(height: 10);
                }
                final topicIndex = index ~/ 2;
                return TopicItemWidget(
                  topicModel: topics[topicIndex],
                  listener: this,
                );
              }, childCount: topics.isEmpty ? 0 : topics.length * 2 - 1),
            ),
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _systemUiOverlayStyle,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F8F8),
        body: Stack(
          children: [
            EasyRefresh.builder(
              header: const ClassicHeader(showMessage: false, showText: false),
              onRefresh: _onRefresh,
              onLoad: hasMore ? onLoadMoreList : null,
              childBuilder: (context, physics) => _buildScrollBody(physics),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: UserDetailNavBar(
                progress: _collapseProgress,
                title: _profileModel.name,
                onBack: () => Navigator.of(context).maybePop(),
                onMore: _onMoreTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
