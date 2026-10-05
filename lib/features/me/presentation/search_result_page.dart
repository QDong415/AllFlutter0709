import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/core/utils/value_util.dart';
import 'package:all_flutter0709/features/topic/presentation/topic_list_base_state.dart';
import 'package:all_flutter0709/features/user/data/models/user_base_model.dart';
import 'package:all_flutter0709/features/user/data/user_repository.dart';
import 'package:all_flutter0709/features/user/presentation/helpers/user_detail_navigation.dart';
import 'package:all_flutter0709/shared/widgets/common_app_bar.dart';
import 'package:all_flutter0709/shared/widgets/page_state_view.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 搜索结果：用户、动态两个 Tab，标题为关键词。
class SearchResultPage extends StatelessWidget {
  const SearchResultPage({super.key, required this.keyword});

  final String keyword;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: CommonAppBar(
          title: keyword,
          leadingWidth: 88,
          leading: InkWell(
            onTap: () => context.pop(),
            child: const Row(
              children: [
                SizedBox(width: 8),
                Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF333333)),
                SizedBox(width: 2),
                Text(
                  '我的',
                  style: TextStyle(fontSize: 16, color: Color(0xFF333333)),
                ),
              ],
            ),
          ),
        ),
        body: Column(
          children: [
            const SizedBox(
              height: 40,
              child: TabBar(
                labelColor: AppColors.link,
                unselectedLabelColor: Color(0xFF333333),
                indicatorColor: AppColors.link,
                indicatorSize: TabBarIndicatorSize.label,
                dividerColor: Color(0xFFE6E6E6),
                labelStyle: TextStyle(fontSize: 16),
                unselectedLabelStyle: TextStyle(fontSize: 16),
                tabs: [
                  Tab(text: '用户'),
                  Tab(text: '动态'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _SearchUserTab(keyword: keyword),
                  _SearchTopicTab(keyword: keyword),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchTopicTab extends StatefulWidget {
  const _SearchTopicTab({required this.keyword});

  final String keyword;

  @override
  State<_SearchTopicTab> createState() => _SearchTopicTabState();
}

class _SearchTopicTabState extends TopicListBaseState<_SearchTopicTab> {
  @override
  bool get useDefaultScaffold => false;

  @override
  String get emptyText => '没有相关动态';

  @override
  Map<String, dynamic>? customParameters() {
    return <String, dynamic>{'keyword': widget.keyword};
  }
}

class _SearchUserTab extends StatefulWidget {
  const _SearchUserTab({required this.keyword});

  final String keyword;

  @override
  State<_SearchUserTab> createState() => _SearchUserTabState();
}

class _SearchUserTabState extends State<_SearchUserTab>
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
    _request(isRefresh: true);
  }

  Future<void> _request({required bool isRefresh}) async {
    final page = isRefresh ? 1 : _nextPage;
    try {
      final result = await _userRepository.getUserList(
        page: page,
        extra: <String, dynamic>{'keyword': widget.keyword},
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
    } catch (_) {
      if (!mounted) return;
      if (_userModelList.isEmpty) setState(() => _pageState = PageState.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return EasyRefresh(
      onRefresh: () => _request(isRefresh: true),
      onLoad: _hasMore ? () => _request(isRefresh: false) : null,
      child: PageStateView(
        state: _pageState,
        emptyText: '没有相关用户',
        successWidget: ListView.separated(
          itemCount: _userModelList.length,
          separatorBuilder: (_, _) => const Divider(
            height: 0.5,
            thickness: 0.5,
            indent: 63,
            color: Color(0xFFE6E6E6),
          ),
          itemBuilder: (context, index) {
            final userModel = _userModelList[index];
            return _SearchUserRow(userModel: userModel);
          },
        ),
      ),
    );
  }
}

/// 搜索用户行：头像、昵称、右箭头。
class _SearchUserRow extends StatelessWidget {
  const _SearchUserRow({required this.userModel});

  final UserBaseModel userModel;

  @override
  Widget build(BuildContext context) {
    final avatarUrl =
        ValueUtil.getQiniuUrlByFileName(userModel.avatar, thumbnail: true) ??
        '';
    return InkWell(
      onTap: () => openUserDetailPage(
        context,
        userId: userModel.userId,
        name: userModel.name,
        avatar: userModel.avatar,
        userType: userModel.userType,
      ),
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            const SizedBox(width: 12),
            ClipOval(
              child: avatarUrl.isEmpty
                  ? Image.asset(
                      'assets/icons/me/user_photo.png',
                      width: 43,
                      height: 43,
                      fit: BoxFit.cover,
                    )
                  : Image.network(
                      avatarUrl,
                      width: 43,
                      height: 43,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Image.asset(
                        'assets/icons/me/user_photo.png',
                        width: 43,
                        height: 43,
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                userModel.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, color: Color(0xFF333333)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Image.asset(
                'assets/icons/me/arrow_right.png',
                width: 16,
                height: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
