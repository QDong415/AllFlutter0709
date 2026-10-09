import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/features/topic/presentation/widgets/topic_match_user_item.dart';
import 'package:all_flutter0709/features/user/data/models/user_base_model.dart';
import 'package:all_flutter0709/features/user/data/user_repository.dart';
import 'package:all_flutter0709/shared/widgets/common_app_bar.dart';
import 'package:all_flutter0709/shared/widgets/page_state_view.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:all_flutter0709/shared/widgets/app_toast.dart';

/// 黑名单，点击后确认移出。
class BlacklistPage extends StatefulWidget {
  const BlacklistPage({super.key});

  @override
  State<BlacklistPage> createState() => _BlacklistPageState();
}

class _BlacklistPageState extends State<BlacklistPage> {
  final UserRepository _userRepository = const UserRepository();
  final List<UserBaseModel> _userModelList = <UserBaseModel>[];
  int _nextPage = 1;
  bool _hasMore = true;
  PageState _pageState = PageState.loading;

  @override
  void initState() {
    super.initState();
    _request(isRefresh: true);
  }

  Future<void> _request({required bool isRefresh}) async {
    final page = isRefresh ? 1 : _nextPage;
    try {
      final result = await _userRepository.getUserList(
        page: page,
        extra: const <String, dynamic>{'block': '1'},
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
      if (_userModelList.isEmpty) setState(() => _pageState = PageState.error);
      AppToast.show(context, '$error');
    }
  }

  Future<void> _unblock(UserBaseModel userModel) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('移除黑名单'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('好'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _userRepository.unblockUser(toUserId: userModel.userId);
      if (!mounted) return;
      setState(() {
        _userModelList.removeWhere((item) => item.userId == userModel.userId);
        if (_userModelList.isEmpty) _pageState = PageState.empty;
      });
    } catch (error) {
      if (mounted) {
        AppToast.show(context, '$error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bodyBackground,
      appBar: const CommonAppBar(title: '黑名单'),
      body: EasyRefresh(
        onRefresh: () => _request(isRefresh: true),
        onLoad: _hasMore ? () => _request(isRefresh: false) : null,
        child: PageStateView(
          state: _pageState,
          emptyText: '黑名单是空的',
          successWidget: ListView.separated(
            itemCount: _userModelList.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final userModel = _userModelList[index];
              return TopicMatchUserItem(
                userModel: userModel,
                onTap: () => _unblock(userModel),
              );
            },
          ),
        ),
      ),
    );
  }
}
