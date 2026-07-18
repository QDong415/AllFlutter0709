import 'package:all_flutter0709/app/router/app_routes.dart';
import 'package:all_flutter0709/features/topic/data/models/topic_model.dart';
import 'package:all_flutter0709/features/topic/data/topic_repository.dart';
import 'package:all_flutter0709/features/topic/presentation/widgets/topic_item_widget.dart';
import 'package:all_flutter0709/shared/widgets/common_app_bar.dart';
import 'package:all_flutter0709/shared/widgets/page_state_view.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

abstract class TopicListBaseState<T extends StatefulWidget> extends State<T> implements TopicItemActionListener {

  final TopicRepository _topicRepository = const TopicRepository();
  final List<TopicModel> _topics = <TopicModel>[];
  final Set<String> _likingTopicIds = <String>{};

  int _nextPage = 1;
  bool _hasMore = true;
  PageState _pageState = PageState.loading;

  @override
  void initState() {
    super.initState();
    _requestList(isRefresh: true);
  }

  Future<void> _requestList({required bool isRefresh}) async {
    final requestPage = isRefresh ? 1 : _nextPage;

    try {
      final result = await _topicRepository.getTopicList(page: requestPage);
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _onRefresh() async {
    await _requestList(isRefresh: true);
  }

  Future<void> _onLoad() async {
    if (!_hasMore) return;
    await _requestList(isRefresh: false);
  }

  void _replaceTopic(TopicModel topic) {
    final index = _topics.indexWhere((item) => item.tid == topic.tid);
    if (index == -1) return;
    _topics[index] = topic;
  }

  Widget _buildListView() {
    return ListView.separated(
      itemCount: _topics.length,
      itemBuilder: (context, index) {
        return TopicItemWidget(
          topicModel: _topics[index],
          listener: this,
        );
      },
      separatorBuilder: (_, _) => const SizedBox(height: 10),
    );
  }

  @override
  void onItemTap(TopicModel topic) {
    context.push('${AppRoutes.topic}/detail/${topic.tid}', extra: topic);
  }

  @override
  void onShareTap(TopicModel topic) {}

  @override
  void onAvatarTap(TopicModel topic) {}

  @override
  void onCommentTap(TopicModel topic) {}

  @override
  Future<void> onLikeTap(TopicModel topic) async {
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
      await _topicRepository.likeTopic(
        tid: topic.tid,
        isLiked: topic.isLiked,
        likeCount: topic.likeCount,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _replaceTopic(topic);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      _likingTopicIds.remove(topic.tid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: '动态 Topic'),
      backgroundColor: const Color(0xFFF5F5F7),
      body: EasyRefresh(
        header: const ClassicHeader(showMessage: false, showText: false),
        onRefresh: _onRefresh,
        onLoad: _hasMore ? _onLoad : null,
        child: PageStateView(
          state: _pageState,
          emptyText: '暂无动态',
          errorText: '网络异常，请稍后重试',
          successWidget: _buildListView(),
        ),
      ),
    );
  }
}