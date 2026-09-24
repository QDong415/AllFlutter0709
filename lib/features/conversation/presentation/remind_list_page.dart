import 'package:all_flutter0709/app/router/app_routes.dart';
import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/core/account/account_guard.dart';
import 'package:all_flutter0709/core/utils/value_util.dart';
import 'package:all_flutter0709/features/conversation/data/models/remind_model.dart';
import 'package:all_flutter0709/features/conversation/data/remind_repository.dart';
import 'package:all_flutter0709/features/conversation/data/remind_unread_store.dart';
import 'package:all_flutter0709/features/topic/presentation/widgets/topic_content_text.dart';
import 'package:all_flutter0709/features/user/presentation/helpers/user_detail_navigation.dart';
import 'package:all_flutter0709/shared/widgets/common_app_bar.dart';
import 'package:all_flutter0709/shared/widgets/page_state_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 赞、评论、@我 列表，对齐 Android `RemindActivity`。
class RemindListPage extends ConsumerStatefulWidget {
  const RemindListPage({super.key, required this.remindType});

  /// 1 评论，2 赞，3 @我。
  final int remindType;

  @override
  ConsumerState<RemindListPage> createState() => _RemindListPageState();
}

class _RemindListPageState extends ConsumerState<RemindListPage> {
  final RemindRepository _repository = const RemindRepository();
  final List<RemindModel> _remindModelList = <RemindModel>[];

  int _nextPage = 1;
  bool _hasMore = true;
  PageState _pageState = PageState.loading;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _markRead();
      _requestList(isRefresh: true);
    });
  }

  String get _title {
    switch (widget.remindType) {
      case 1:
        return '评论';
      case 2:
        return '赞';
      case 3:
        return '@我';
      default:
        return '提醒';
    }
  }

  RemindKind? get _kind {
    switch (widget.remindType) {
      case 1:
        return RemindKind.comment;
      case 2:
        return RemindKind.praise;
      case 3:
        return RemindKind.at;
      default:
        return null;
    }
  }

  void _markRead() {
    final kind = _kind;
    final userId = context.currentUserId;
    if (kind == null || userId.isEmpty) {
      return;
    }
    ref.read(remindUnreadStoreProvider).readAll(userId: userId, kind: kind);
  }

  Future<void> _requestList({required bool isRefresh}) async {
    final page = isRefresh ? 1 : _nextPage;
    try {
      final result = await _repository.getRemindList(
        remindType: widget.remindType,
        page: page,
      );
      if (!mounted) return;
      setState(() {
        if (isRefresh) {
          _remindModelList
            ..clear()
            ..addAll(result.items);
          _nextPage = 2;
        } else {
          _remindModelList.addAll(result.items);
          _nextPage++;
        }
        _hasMore = result.hasMore;
        _pageState = _remindModelList.isEmpty
            ? PageState.empty
            : PageState.success;
      });
    } catch (error) {
      if (!mounted) return;
      if (_remindModelList.isEmpty) {
        setState(() => _pageState = PageState.error);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bodyBackground,
      appBar: CommonAppBar(title: _title),
      body: EasyRefresh(
        onRefresh: () => _requestList(isRefresh: true),
        onLoad: _hasMore ? () => _requestList(isRefresh: false) : null,
        child: PageStateView(
          state: _pageState,
          emptyText: '暂无提醒',
          successWidget: ListView.separated(
            itemCount: _remindModelList.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final remindModel = _remindModelList[index];
              return _RemindTile(
                remindModel: remindModel,
                onTap: () {
                  final topicId = remindModel.topicId;
                  if (topicId.isEmpty) return;
                  context.push('${AppRoutes.topic}/detail/$topicId');
                },
                onActorTap: () {
                  openUserDetailPage(
                    context,
                    userId: remindModel.actorUserId,
                    name: remindModel.actorName,
                    avatar: remindModel.actorAvatar,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RemindTile extends StatelessWidget {
  const _RemindTile({
    required this.remindModel,
    required this.onTap,
    required this.onActorTap,
  });

  final RemindModel remindModel;
  final VoidCallback onTap;
  final VoidCallback onActorTap;

  @override
  Widget build(BuildContext context) {
    final avatarUrl =
        ValueUtil.getQiniuUrlByFileName(
          remindModel.actorAvatar,
          thumbnail: true,
        ) ??
        '';
    final cover = remindModel.pictures.isNotEmpty
        ? remindModel.pictures.first.thumbnailUrl
        : ValueUtil.getQiniuUrlByFileName(
              remindModel.topicUserAvatar,
              thumbnail: true,
            ) ??
            '';

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 1, thickness: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onActorTap,
                    child: CircleAvatar(
                      radius: 21.5,
                      backgroundColor: const Color(0xFFE8E8E8),
                      backgroundImage: avatarUrl.isNotEmpty
                          ? CachedNetworkImageProvider(avatarUrl)
                          : const AssetImage('assets/icons/user_photo.png')
                                as ImageProvider,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          remindModel.actorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF133465),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          remindModel.displayTime,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF919191),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (remindModel.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: TopicContentText(
                  text: remindModel.content,
                  style: const TextStyle(
                    fontSize: 17,
                    height: 1.25,
                    color: AppColors.titleText,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
              child: ColoredBox(
                color: const Color(0xFFF3F3F3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    cover.isEmpty
                        ? Image.asset(
                            'assets/icons/user_photo.png',
                            width: 76,
                            height: 76,
                            fit: BoxFit.cover,
                          )
                        : CachedNetworkImage(
                            imageUrl: cover,
                            width: 76,
                            height: 76,
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) => Image.asset(
                              'assets/icons/user_photo.png',
                              width: 76,
                              height: 76,
                              fit: BoxFit.cover,
                            ),
                          ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 12, 20, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              remindModel.topicUserName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppColors.titleText,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TopicContentText(
                              text: remindModel.topicContent,
                              maxLines: 2,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.2,
                                color: AppColors.titleText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, thickness: 1, color: AppColors.divider),
          ],
        ),
      ),
    );
  }
}
