import 'dart:async';

import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/app/theme/app_dimens.dart';
import 'package:all_flutter0709/features/topic/presentation/widgets/topic_match_user_item.dart';
import 'package:all_flutter0709/features/user/data/models/user_base_model.dart';
import 'package:all_flutter0709/features/user/data/user_repository.dart';
import 'package:all_flutter0709/features/user/presentation/helpers/user_detail_navigation.dart';
import 'package:all_flutter0709/shared/widgets/page_state_view.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';

/// 动态首页「匹配」用户列表，对齐 Android `UserFragment`。
class UserMatchListPage extends StatefulWidget {
  const UserMatchListPage({super.key, required this.gender});

  /// 性别筛选：0 不限 / 1 男 / 2 女。
  final int gender;

  @override
  State<UserMatchListPage> createState() => _UserMatchListPageState();
}

class _UserMatchListPageState extends State<UserMatchListPage>
    with AutomaticKeepAliveClientMixin {
  final UserRepository _userRepository = const UserRepository();
  final List<UserBaseModel> _userModelList = <UserBaseModel>[];

  int _nextPage = 1;
  bool _hasMore = true;
  PageState _pageState = PageState.loading;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    unawaited(_requestList(isRefresh: true));
  }

  @override
  void didUpdateWidget(covariant UserMatchListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gender != widget.gender) {
      unawaited(_requestList(isRefresh: true));
    }
  }

  Future<void> _requestList({required bool isRefresh}) async {
    final page = isRefresh ? 1 : _nextPage;
    try {
      final result = await _userRepository.getUserList(
        page: page,
        gender: widget.gender,
        vip: 1,
      );
      if (!mounted) {
        return;
      }
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
      if (!mounted) {
        return;
      }
      if (_userModelList.isEmpty) {
        setState(() {
          _pageState = PageState.error;
        });
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ColoredBox(
      color: AppColors.bodyBackground,
      child: EasyRefresh.builder(
        header: const ClassicHeader(showMessage: false, showText: false),
        footer: const ClassicFooter(
          showMessage: false,
          showText: false,
          position: IndicatorPosition.locator,
          safeArea: false,
        ),
        triggerAxis: Axis.vertical,
        onRefresh: () => _requestList(isRefresh: true),
        onLoad: _hasMore ? () => _requestList(isRefresh: false) : null,
        childBuilder: (context, physics) {
          return PageStateView(
            state: _pageState,
            emptyText: '暂无匹配用户',
            errorText: '网络异常，请稍后重试',
            successWidget: CustomScrollView(
              physics: physics,
              slivers: [
                SliverList.separated(
                  itemCount: _userModelList.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: AppDimens.dividerThickness,
                    thickness: AppDimens.dividerThickness,
                    color: AppColors.divider,
                  ),
                  itemBuilder: (context, index) {
                    final userModel = _userModelList[index];
                    return TopicMatchUserItem(
                      userModel: userModel,
                      onTap: () {
                        openUserDetailPage(
                          context,
                          userId: userModel.userId,
                          name: userModel.name,
                          avatar: userModel.avatar,
                          userType: userModel.userType,
                        );
                      },
                    );
                  },
                ),
                if (_hasMore) const FooterLocator.sliver(),
                const SliverPadding(
                  padding: EdgeInsets.only(
                    bottom: AppDimens.glassTabBarContentInset,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
