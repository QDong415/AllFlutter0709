import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/core/account/account_guard.dart';
import 'package:all_flutter0709/core/utils/value_util.dart';
import 'package:all_flutter0709/features/user/data/models/user_base_model.dart';
import 'package:all_flutter0709/features/user/data/user_repository.dart';
import 'package:all_flutter0709/shared/widgets/common_app_bar.dart';
import 'package:all_flutter0709/shared/widgets/page_state_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 发布动态时选择 @好友，对齐 Android `UserSelectActivity`。
class TopicUserSelectPage extends StatefulWidget {
  const TopicUserSelectPage({super.key});

  @override
  State<TopicUserSelectPage> createState() => _TopicUserSelectPageState();
}

class _TopicUserSelectPageState extends State<TopicUserSelectPage> {
  final UserRepository _userRepository = const UserRepository();
  final TextEditingController _keywordController = TextEditingController();
  final List<UserBaseModel> _userModelList = <UserBaseModel>[];

  int _nextPage = 1;
  bool _hasMore = true;
  PageState _pageState = PageState.loading;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _requestList(isRefresh: true);
    });
  }

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  Future<void> _requestList({required bool isRefresh}) async {
    final page = isRefresh ? 1 : _nextPage;
    try {
      final result = await _userRepository.getFollowList(
        toUserId: context.currentUserId,
        page: page,
        keyword: _keywordController.text.trim(),
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
        setState(() {
          _pageState = PageState.error;
        });
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  void _onSearch() {
    setState(() {
      _pageState = PageState.loading;
    });
    _requestList(isRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bodyBackground,
      appBar: const CommonAppBar(title: '选择好友'),
      body: Column(
        children: [
          ColoredBox(
            color: AppColors.bodyBackground,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _keywordController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _onSearch(),
                      decoration: InputDecoration(
                        hintText: '搜索好友昵称',
                        hintStyle: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF9B9B9B),
                        ),
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.search, size: 18),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 28,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _onSearch,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    child: const Text('确定'),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: EasyRefresh(
              header: const ClassicHeader(showMessage: false, showText: false),
              onRefresh: () => _requestList(isRefresh: true),
              onLoad: _hasMore ? () => _requestList(isRefresh: false) : null,
              child: PageStateView(
                state: _pageState,
                emptyText: '暂无好友',
                errorText: '好友列表加载失败',
                successWidget: ListView.separated(
                  itemCount: _userModelList.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 0.5),
                  itemBuilder: (context, index) {
                    final userModel = _userModelList[index];
                    final avatarUrl =
                        ValueUtil.getQiniuUrlByFileName(
                          userModel.avatar,
                          thumbnail: true,
                        ) ??
                        '';
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFE8E8E8),
                        backgroundImage: avatarUrl.isNotEmpty
                            ? CachedNetworkImageProvider(avatarUrl)
                            : null,
                      ),
                      title: Text(userModel.name),
                      onTap: () => context.pop(userModel),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
