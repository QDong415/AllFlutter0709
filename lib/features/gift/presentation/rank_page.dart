import 'dart:async';

import 'package:all_flutter0709/app/router/app_routes.dart';
import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/app/theme/app_dimens.dart';
import 'package:all_flutter0709/features/gift/data/gift_model.dart';
import 'package:all_flutter0709/features/gift/data/gift_repository.dart';
import 'package:all_flutter0709/core/account/account_guard.dart';
import 'package:all_flutter0709/features/gift/presentation/widgets/gift_user_avatar.dart';
import 'package:all_flutter0709/features/gift/presentation/widgets/rank_my_bar.dart';
import 'package:all_flutter0709/features/gift/presentation/widgets/rank_podium.dart'
    show RankPodium, rankDurationSelectedText, rankPageGradient, rankPodiumTopInset;
import 'package:all_flutter0709/features/user/presentation/helpers/user_detail_navigation.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 魅力榜、财富榜。各自有今日、本周、总榜。
class RankPage extends StatefulWidget {
  const RankPage({super.key});

  @override
  State<RankPage> createState() => _RankPageState();
}

class _RankPageState extends State<RankPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFEAEA),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: rankPageGradient),
        child: Column(
          children: [
            SafeArea(
              bottom: false,
              child: SizedBox(
                height: 44,
                child: Row(
                  children: [
                    // 与右侧问号同宽，保证 Tab 仍视觉居中。
                    const SizedBox(width: 44),
                    Expanded(
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        tabAlignment: TabAlignment.center,
                        padding: EdgeInsets.zero,
                        labelPadding:
                            const EdgeInsets.symmetric(horizontal: 10),
                        labelColor: Colors.white,
                        unselectedLabelColor: const Color(0xB3FFFFFF),
                        indicatorColor: Colors.white,
                        indicatorSize: TabBarIndicatorSize.label,
                        indicator: const UnderlineTabIndicator(
                          borderSide:
                              BorderSide(width: 3, color: Colors.white),
                        ),
                        dividerColor: Colors.transparent,
                        dividerHeight: 0,
                        labelStyle: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                        ),
                        tabs: const [
                          Tab(height: 44, text: '魅力榜'),
                          Tab(height: 44, text: '财富榜'),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 44,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        tooltip: '规则说明',
                        onPressed: () => context.push(AppRoutes.rankHelp),
                        icon: const Icon(
                          Icons.help_outline,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _RankBoard(charm: true),
                  _RankBoard(charm: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankBoard extends StatefulWidget {
  const _RankBoard({required this.charm});

  final bool charm;

  @override
  State<_RankBoard> createState() => _RankBoardState();
}

class _RankBoardState extends State<_RankBoard> {
  static const _pageSize = 20;

  final GiftRepository _repository = const GiftRepository();
  final List<RankUser> _users = <RankUser>[];
  final ScrollController _scrollController = ScrollController();

  int _duration = 1;
  int _page = 1;
  int _totalPage = 0;
  int _serial = 0;
  bool _loading = true;
  bool _loadingMore = false;
  String? _errorText;
  RankSelfResult? _myRank;
  bool _myRankLoading = false;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
    unawaited(_loadMyRank());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool get _hasMore => _page <= _totalPage;

  Future<void> _load({required bool reset}) async {
    if (!reset && (_loadingMore || !_hasMore || _loading)) {
      return;
    }
    final page = reset ? 1 : _page;
    final serial = ++_serial;
    setState(() {
      if (reset) {
        _loading = true;
        _errorText = null;
        // 刷新/切换周期时不先清空列表，领奖台始终用旧数据或占位，避免 header 闪没。
      } else {
        _loadingMore = true;
      }
    });
    try {
      final result = await _repository.fetchRank(
        charm: widget.charm,
        duration: _duration,
        page: page,
        pageSize: _pageSize,
      );
      if (!mounted || serial != _serial) {
        return;
      }
      setState(() {
        if (reset) {
          _users
            ..clear()
            ..addAll(result.items);
        } else {
          _users.addAll(result.items);
        }
        _totalPage = result.totalPage;
        _page = page + 1;
        _loading = false;
        _loadingMore = false;
      });
      unawaited(_loadMyRank());
    } catch (error) {
      if (!mounted || serial != _serial) {
        return;
      }
      setState(() {
        _loading = false;
        _loadingMore = false;
        if (reset) {
          _errorText = '$error';
        }
      });
    }
  }

  void _selectDuration(int duration) {
    final changed = _duration != duration;
    setState(() => _duration = duration);
    if (changed) {
      _load(reset: true);
    }
  }

  Future<void> _loadMyRank() async {
    if (context.currentAccount == null) {
      if (mounted) {
        setState(() {
          _myRank = null;
          _myRankLoading = false;
        });
      }
      return;
    }
    setState(() => _myRankLoading = true);
    try {
      final self = await _repository.fetchRankSelf(
        charm: widget.charm,
        duration: _duration,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _myRank = self;
        _myRankLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _myRankLoading = false);
    }
  }

  void _onMyBarTap() {
    final rank = _myRank?.rank ?? 0;
    if (rank <= 0) {
      return;
    }
    if (rank <= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('你当前位列第 $rank 名')),
      );
      return;
    }
    if (!_scrollController.hasClients) {
      return;
    }
    const rowHeight = 68.0;
    final target = 280.0 + (rank - 4) * rowHeight;
    _scrollController.animateTo(
      target.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  Widget _buildMyRankFooter() {
    if (context.currentAccount == null) {
      return const SizedBox.shrink();
    }
    return RankMyBar(
      charm: widget.charm,
      self: _myRank,
      loading: _myRankLoading,
      onTap: _onMyBarTap,
      scrollEmbedded: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    const listBottomPadding = AppDimens.glassTabBarContentInset + 12;

    return Column(
      children: [
        const SizedBox(height: 25),
        Center(
          child: _DurationBar(duration: _duration, onChanged: _selectDuration),
        ),
        Expanded(child: _buildList(listBottomPadding)),
      ],
    );
  }

  /// 对齐 Android header：底座 + 前三名始终占位，无数据时展示「虚位以待」。
  Widget _buildPodiumHeader() {
    final top = _users.take(3).toList();
    return RankPodium(
      charm: widget.charm,
      first: top.isNotEmpty ? top[0] : null,
      second: top.length > 1 ? top[1] : null,
      third: top.length > 2 ? top[2] : null,
    );
  }

  Widget _buildList(double listBottomPadding) {
    return EasyRefresh(
      header: const ClassicHeader(
        showMessage: false,
        showText: false,
        processedDuration: Duration.zero,
        succeededIcon: SizedBox.shrink(),
        failedIcon: SizedBox.shrink(),
        iconTheme: IconThemeData(color: Colors.white),
        progressIndicatorStrokeWidth: 2,
      ),
      onRefresh: () async {
        await _load(reset: true);
        await _loadMyRank();
      },
      child: _buildScrollBody(listBottomPadding),
    );
  }

  Widget _buildScrollBody(double listBottomPadding) {
    final rest = _users.length > 3 ? _users.sublist(3) : const <RankUser>[];
    final initialLoading = _loading && _users.isEmpty;
    final initialError = _errorText != null && _users.isEmpty;
    final emptyBoard = !_loading && _errorText == null && _users.isEmpty;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >
            notification.metrics.maxScrollExtent - 280) {
          _load(reset: false);
        }
        return false;
      },
      child: ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: listBottomPadding),
        children: [
          const SizedBox(height: rankPodiumTopInset),
          _buildPodiumHeader(),
          if (initialLoading)
            const Padding(
              padding: EdgeInsets.only(top: 28, bottom: 32),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (initialError)
            Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 32),
              child: Column(
                children: [
                  const Text(
                    '榜单加载失败',
                    style: TextStyle(color: AppColors.titleText),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => _load(reset: true),
                    child: const Text('重试'),
                  ),
                ],
              ),
            )
          else if (emptyBoard) ...[
            const Padding(
              padding: EdgeInsets.only(top: 24, bottom: 16),
              child: Center(
                child: Text(
                  '暂无更多排名',
                  style: TextStyle(fontSize: 15, color: Color(0xCC333333)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
              child: _RankListSection(child: _buildMyRankFooter()),
            ),
          ] else
            _RankRestList(
              users: rest,
              charm: widget.charm,
              loadingMore: _loadingMore,
              footer: _buildMyRankFooter(),
            ),
        ],
      ),
    );
  }
}

/// 半透明白卡片，与榜单 cell 区域一致。
class _RankListSection extends StatelessWidget {
  const _RankListSection({required this.child});

  final Widget child;

  static BoxDecoration decoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      color: Colors.white.withValues(alpha: 0.5),
      border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1A8B3030),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: decoration(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: child,
      ),
    );
  }
}

/// 第 4 名起：半透明白卡片 + 左右留白；「我的」为独立 section，距最后一 cell 10dp。
class _RankRestList extends StatelessWidget {
  const _RankRestList({
    required this.users,
    required this.charm,
    required this.loadingMore,
    required this.footer,
  });

  final List<RankUser> users;
  final bool charm;
  final bool loadingMore;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    final hasRankCells = users.isNotEmpty || loadingMore;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasRankCells)
            _RankListSection(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < users.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        thickness: 1,
                        indent: 56,
                        endIndent: 16,
                        color: const Color(0x14000000),
                      ),
                    _RankRow(
                      rank: i + 4,
                      user: users[i],
                      score: charm ? users[i].vcharm : users[i].vsend,
                    ),
                  ],
                  if (loadingMore)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          if (hasRankCells) const SizedBox(height: 10),
          _RankListSection(child: footer),
        ],
      ),
    );
  }
}

class _DurationBar extends StatelessWidget {
  const _DurationBar({required this.duration, required this.onChanged});

  final int duration;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.85)),
        color: Colors.white.withValues(alpha: 0.25),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [_chip('今日', 1), _chip('本周', 2), _chip('总榜', 3)],
      ),
    );
  }

  Widget _chip(String label, int value) {
    final selected = duration == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        width: 72,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.horizontal(
            left: value == 1 ? const Radius.circular(7) : Radius.zero,
            right: value == 3 ? const Radius.circular(7) : Radius.zero,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: selected ? rankDurationSelectedText : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.rank, required this.user, required this.score});

  final int rank;
  final RankUser user;
  final int score;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => openUserDetailPage(
        context,
        userId: user.userId,
        name: user.name,
        avatar: user.avatar,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                '$rank',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF666666),
                ),
              ),
            ),
            GiftUserAvatar(url: user.avatarUrl, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                user.name.isEmpty ? '用户' : user.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.titleText,
                ),
              ),
            ),
            Text(
              '$score',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.link,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
