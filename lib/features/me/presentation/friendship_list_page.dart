import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/core/account/account_guard.dart';
import 'package:all_flutter0709/features/me/presentation/me_page.dart';
import 'package:all_flutter0709/features/topic/presentation/widgets/topic_match_user_item.dart';
import 'package:all_flutter0709/features/user/data/models/user_base_model.dart';
import 'package:all_flutter0709/features/user/data/user_repository.dart';
import 'package:all_flutter0709/features/user/presentation/helpers/user_detail_navigation.dart';
import 'package:all_flutter0709/shared/widgets/common_app_bar.dart';
import 'package:all_flutter0709/shared/widgets/page_state_view.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';

/// 我的粉丝或我的关注，对齐 Android `FriendShipActivity`。
class FriendshipListPage extends StatefulWidget {
  const FriendshipListPage({super.key, required this.args});

  final FriendshipArgs args;

  @override
  State<FriendshipListPage> createState() => _FriendshipListPageState();
}

class _FriendshipListPageState extends State<FriendshipListPage> {
  final UserRepository _userRepository = const UserRepository();
  final List<UserBaseModel> _userModelList = <UserBaseModel>[];
  int _nextPage = 1;
  bool _hasMore = true;
  PageState _pageState = PageState.loading;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _request(isRefresh: true),
    );
  }

  Future<void> _request({required bool isRefresh}) async {
    final page = isRefresh ? 1 : _nextPage;
    try {
      final result = widget.args.isFansList
          ? await _userRepository.getFansList(
              toUserId: context.currentUserId,
              page: page,
            )
          : await _userRepository.getFollowList(
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bodyBackground,
      appBar: CommonAppBar(title: widget.args.isFansList ? '我的粉丝' : '我的关注'),
      body: EasyRefresh(
        onRefresh: () => _request(isRefresh: true),
        onLoad: _hasMore ? () => _request(isRefresh: false) : null,
        child: PageStateView(
          state: _pageState,
          emptyText: widget.args.isFansList ? '还没有粉丝' : '还没有关注',
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
