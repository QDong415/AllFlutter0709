import 'package:all_flutter0709/features/topic/data/models/topic_model.dart';
import 'package:all_flutter0709/features/topic/data/topic_repository.dart';
import 'package:all_flutter0709/features/topic/presentation/topic_detail_page.dart';
import 'package:all_flutter0709/features/topic/presentation/widgets/topic_item_widget.dart';
import 'package:all_flutter0709/shared/widgets/common_app_bar.dart';
import 'package:all_flutter0709/shared/widgets/page_state_view.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';

class TopicPage extends StatefulWidget {
  const TopicPage({super.key});

  @override
  State<TopicPage> createState() => _TopicPageState();
}

class _TopicPageState extends State<TopicPage> {
  final TopicRepository _topicRepository = const TopicRepository();
  final List<TopicModel> _topics = <TopicModel>[];

  int _nextPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
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
    if (!_hasMore || _isLoadingMore) return;
    _isLoadingMore = true;
    try {
      await _requestList(isRefresh: false);
    } finally {
      _isLoadingMore = false;
    }
  }

  Widget _buildListView() {
    return ListView.separated(
      itemCount: _topics.length,
      itemBuilder: (context, index) {
        return RepaintBoundary(
          child: TopicItemWidget(
            topicModel: _topics[index],
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TopicDetailPage(topic: _topics[index]),
                ),
              );
            },
          ),
        );
      },
      separatorBuilder: (_, _) => const SizedBox(height: 10),
    );
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
