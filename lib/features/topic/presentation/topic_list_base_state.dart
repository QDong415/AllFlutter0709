import 'package:all_flutter0709/app/router/app_routes.dart';
import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/core/account/account_guard.dart';
import 'package:all_flutter0709/core/network/app_env.dart';
import 'package:all_flutter0709/features/topic/data/models/topic_model.dart';
import 'package:all_flutter0709/features/topic/data/topic_repository.dart';
import 'package:all_flutter0709/features/topic/presentation/widgets/topic_item_widget.dart';
import 'package:all_flutter0709/features/topic/presentation/widgets/topic_share_sheet.dart';
import 'package:all_flutter0709/features/user/presentation/helpers/user_detail_navigation.dart';
import 'package:all_flutter0709/shared/widgets/common_app_bar.dart';
import 'package:all_flutter0709/shared/widgets/page_state_view.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// 动态列表页通用基类：刷新 / 加载更多 / 点赞 / 分享等。
///
/// 子类可通过 [fetchTopicPage]、[buildListHeader]、[buildAppBar] 等钩子定制。
abstract class TopicListBaseState<T extends StatefulWidget> extends State<T>
    implements TopicItemActionListener {
  @protected
  final TopicRepository topicRepository = const TopicRepository();

  final List<TopicModel> _topics = <TopicModel>[];
  final Set<String> _likingTopicIds = <String>{};

  int _nextPage = 1;
  bool _hasMore = true;
  PageState _pageState = PageState.loading;

  @protected
  List<TopicModel> get topics => _topics;

  @protected
  PageState get pageState => _pageState;

  @protected
  bool get hasMore => _hasMore;

  @protected
  String get pageTitle => '动态 Topic';

  @protected
  String get emptyText => '暂无动态';

  @protected
  String get errorText => '网络异常，请稍后重试';

  /// 是否使用默认 Scaffold + AppBar 布局；个人主页等可设为 false 并自行 [build]。
  @protected
  bool get useDefaultScaffold => true;

  @protected
  Future<TopicPageResult> fetchTopicPage(int page) {
    return topicRepository.getTopicList(page: page);
  }

  /// 默认 AppBar；返回 null 表示不展示。
  @protected
  PreferredSizeWidget? buildAppBar() {
    return CommonAppBar(title: pageTitle);
  }

  /// 列表顶部 Header；非 null 时列表改为 CustomScrollView。
  @protected
  Widget? buildListHeader() => null;

  @override
  void initState() {
    super.initState();
    requestList(isRefresh: true);
  }

  @protected
  Future<void> requestList({required bool isRefresh}) async {
    final requestPage = isRefresh ? 1 : _nextPage;

    try {
      final result = await fetchTopicPage(requestPage);
      if (!mounted) return;

      setState(() {
        if (isRefresh) {
          _topics
            ..clear()
            ..addAll(result.items);
          _nextPage = 2;
        } else {
          _topics.addAll(result.items);
          _nextPage++;
        }

        _hasMore = result.hasMore;
        _pageState = _topics.isEmpty ? PageState.empty : PageState.success;
      });
    } catch (e) {
      if (!mounted) return;

      if (_topics.isEmpty) {
        setState(() {
          _pageState = PageState.error;
        });
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  /// 下拉刷新。
  @protected
  Future<void> onRefreshList() async {
    await requestList(isRefresh: true);
  }

  /// 上拉加载更多。
  @protected
  Future<void> onLoadMoreList() async {
    if (!_hasMore) return;
    await requestList(isRefresh: false);
  }

  void _replaceTopic(TopicModel topic) {
    final index = _topics.indexWhere((item) => item.tid == topic.tid);
    if (index == -1) return;
    _topics[index] = topic;
  }

  /// 构建动态列表（可选 physics，便于嵌套滚动）。
  @protected
  Widget buildTopicListView({ScrollPhysics? physics}) {
    final header = buildListHeader();
    if (header == null) {
      return ListView.separated(
        physics: physics,
        itemCount: _topics.length,
        itemBuilder: (context, index) {
          return TopicItemWidget(topicModel: _topics[index], listener: this);
        },
        separatorBuilder: (_, _) => const SizedBox(height: 10),
      );
    }

    return CustomScrollView(
      physics: physics,
      slivers: [
        SliverToBoxAdapter(child: header),
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            if (index.isOdd) {
              return const SizedBox(height: 10);
            }
            final topicIndex = index ~/ 2;
            return TopicItemWidget(
              topicModel: _topics[topicIndex],
              listener: this,
            );
          }, childCount: _topics.isEmpty ? 0 : _topics.length * 2 - 1),
        ),
      ],
    );
  }

  /// 默认列表主体：EasyRefresh + PageStateView。
  @protected
  Widget buildTopicListBody() {
    return EasyRefresh(
      header: const ClassicHeader(showMessage: false, showText: false),
      onRefresh: onRefreshList,
      onLoad: _hasMore ? onLoadMoreList : null,
      child: PageStateView(
        state: _pageState,
        emptyText: emptyText,
        errorText: errorText,
        successWidget: buildTopicListView(),
      ),
    );
  }

  @override
  void onItemTap(TopicModel topic) {
    context.push('${AppRoutes.topic}/detail/${topic.tid}', extra: topic);
  }

  @override
  void onShareTap(TopicModel topic) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return TopicShareSheet(
          onWeChatTap: () => _shareTopic(sheetContext, topic),
        );
      },
    );
  }

  Future<void> _shareTopic(BuildContext sheetContext, TopicModel topic) async {
    Navigator.of(sheetContext).pop();

    final content = topic.content?.trim();
    final shareUrl = '${AppEnv.shareTopicBaseUrl}${topic.tid}';
    final shareText = [
      if (content != null && content.isNotEmpty) content,
      shareUrl,
    ].join('\n');

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: shareText,
          subject: content?.isNotEmpty == true ? content : '分享一条动态',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('分享失败: $e')));
    }
  }

  @override
  void onAvatarTap(TopicModel topic) {
    openUserDetailPage(
      context,
      userId: topic.userId,
      name: topic.userName,
      avatar: topic.avatar,
    );
  }

  @override
  void onCommentTap(TopicModel topic) {
    context.push('${AppRoutes.topic}/detail/${topic.tid}', extra: topic);
  }

  @override
  void onCommentUserTap(
    TopicModel topic,
    TopicCommentModel comment,
    String userId,
    String userName,
    String? avatar,
  ) {
    openUserDetailPage(
      context,
      userId: userId,
      name: userName,
      avatar: avatar,
    );
  }

  @override
  void onMentionTap(TopicModel topic, String mention) {
    if (!context.ensureLoggedIn()) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('点击了 @$mention')));
  }

  @override
  void onHashtagTap(TopicModel topic, String hashtag) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('点击了 $hashtag')));
  }

  @override
  Future<void> onLinkTap(TopicModel topic, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('链接格式不正确')));
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('无法打开链接')));
    }
  }

  @override
  Future<void> onLikeTap(TopicModel topic) async {
    if (!context.ensureLoggedIn()) return;
    if (_likingTopicIds.contains(topic.tid)) return;

    final nextIsLiked = !topic.isLiked;
    final nextLikeCount = nextIsLiked
        ? topic.likeCount + 1
        : (topic.likeCount > 0 ? topic.likeCount - 1 : 0);
    final updatedTopic = topic.copyWith(
      isLiked: nextIsLiked,
      likeCount: nextLikeCount,
    );

    _likingTopicIds.add(topic.tid);
    setState(() {
      _replaceTopic(updatedTopic);
    });

    try {
      await topicRepository.likeTopic(
        tid: topic.tid,
        isLiked: topic.isLiked,
        likeCount: topic.likeCount,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _replaceTopic(topic);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      _likingTopicIds.remove(topic.tid);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!useDefaultScaffold) {
      return buildTopicListBody();
    }

    return Scaffold(
      appBar: buildAppBar(),
      backgroundColor: AppColors.bodyBackground,
      body: buildTopicListBody(),
    );
  }
}
