import 'package:all_flutter0709/app/router/app_routes.dart';
import 'package:all_flutter0709/features/video/data/models/video_model.dart';
import 'package:all_flutter0709/features/video/data/video_repository.dart';
import 'package:all_flutter0709/features/video/presentation/widgets/video_item_widget.dart';
import 'package:all_flutter0709/shared/widgets/common_app_bar.dart';
import 'package:all_flutter0709/shared/widgets/page_state_view.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';

class VideoPage extends StatefulWidget {
  const VideoPage({super.key});

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  final VideoRepository _videoRepository = const VideoRepository();
  final List<VideoModel> _videos = <VideoModel>[];

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
      final result = await _videoRepository.getVideoList(page: requestPage);
      if (!mounted) return;

      setState(() {
        if (isRefresh) {
          _videos
            ..clear()
            ..addAll(result.items);
          _nextPage = 2;
        } else {
          _videos.addAll(result.items);
          _nextPage++;
        }

        _hasMore = result.hasMore;
        _pageState = _videos.isEmpty ? PageState.empty : PageState.success;
      });
    } catch (e) {
      if (!mounted) return;

      if (_videos.isEmpty) {
        setState(() {
          _pageState = PageState.error;
        });
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _onRefresh() async {
    await _requestList(isRefresh: true);
  }

  Future<void> _onLoad() async {
    if (!_hasMore) return;
    await _requestList(isRefresh: false);
  }

  void _openDetail(VideoModel video) {
    context.push(
      '${AppRoutes.video}/detail/${video.videoId}',
      extra: video,
    );
  }

  void _showUploadPlaceholder() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('上传功能暂未实现')));
  }

  Widget _buildListView() {
    return MasonryGridView.builder(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 16),
      gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
      ),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      itemCount: _videos.length,
      itemBuilder: (context, index) {
        final video = _videos[index];
        return VideoItemWidget(video: video, onTap: () => _openDetail(video));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: '视频 Video',
        actions: [
          IconButton(
            onPressed: _showUploadPlaceholder,
            icon: const Icon(Icons.add_rounded),
            tooltip: '上传视频',
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF5F5F7),
      body: EasyRefresh(
        header: const ClassicHeader(showMessage: false, showText: false),
        onRefresh: _onRefresh,
        onLoad: _hasMore ? _onLoad : null,
        child: PageStateView(
          state: _pageState,
          emptyText: '尚无视频',
          errorText: '网络异常，请稍后重试',
          successWidget: _buildListView(),
        ),
      ),
    );
  }
}
