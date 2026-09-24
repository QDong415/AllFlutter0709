import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/core/account/account_guard.dart';
import 'package:all_flutter0709/features/conversation/data/remind_unread_store.dart';
import 'package:all_flutter0709/features/topic/presentation/widgets/topic_match_user_item.dart';
import 'package:all_flutter0709/features/user/data/models/user_base_model.dart';
import 'package:all_flutter0709/features/user/data/user_repository.dart';
import 'package:all_flutter0709/features/user/presentation/helpers/user_detail_navigation.dart';
import 'package:all_flutter0709/shared/widgets/common_app_bar.dart';
import 'package:all_flutter0709/shared/widgets/page_state_view.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 新粉丝列表，对齐 Android 消息页点「新粉丝」进入的粉丝列表。
class FansListPage extends ConsumerStatefulWidget {
  const FansListPage({super.key});

  @override
  ConsumerState<FansListPage> createState() => _FansListPageState();
}

class _FansListPageState extends ConsumerState<FansListPage> {
  final UserRepository _userRepository = const UserRepository();
  final List<UserBaseModel> _userModelList = <UserBaseModel>[];

  int _nextPage = 1;
  bool _hasMore = true;
  PageState _pageState = PageState.loading;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final userId = context.currentUserId;
      if (userId.isNotEmpty) {
        ref
            .read(remindUnreadStoreProvider)
            .readAll(userId: userId, kind: RemindKind.fans);
      }
      _requestList(isRefresh: true);
    });
  }

  Future<void> _requestList({required bool isRefresh}) async {
    final page = isRefresh ? 1 : _nextPage;
    try {
      final result = await _userRepository.getFansList(
        toUserId: context.currentUserId,
        page: page,
      );
      if (!mounted) return;
      setState(() {
        if (isRefresh) {
          _userModelList
            ..clear()
            ..addAll(result.items);
          _nextPage = 2;
        } else {
          _userModelList.addAll(result.items);
          _nextPage++;
        }
        _hasMore = result.hasMore;
        _pageState = _userModelList.isEmpty
            ? PageState.empty
            : PageState.success;
      });
    } catch (error) {
      if (!mounted) return;
      if (_userModelList.isEmpty) {
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
      appBar: const CommonAppBar(title: '新粉丝'),
      body: EasyRefresh(
        onRefresh: () => _requestList(isRefresh: true),
        onLoad: _hasMore ? () => _requestList(isRefresh: false) : null,
        child: PageStateView(
          state: _pageState,
          emptyText: '还没有新粉丝',
          successWidget: ListView.separated(
            itemCount: _userModelList.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final userModel = _userModelList[index];
              return TopicMatchUserItem(
                userModel: userModel,
                onTap: () => openUserDetailPage(
                  context,
                  userId: userModel.userId,
                  name: userModel.name,
                  avatar: userModel.avatar,
                  userType: userModel.userType,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
