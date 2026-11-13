import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/core/account/account_guard.dart';
import 'package:all_flutter0709/core/account/account_provider.dart';
import 'package:all_flutter0709/core/utils/value_util.dart';
import 'package:all_flutter0709/features/conversation/data/conversation_repository.dart';
import 'package:all_flutter0709/features/conversation/data/models/conversation_summary.dart';
import 'package:all_flutter0709/features/user/data/models/user_base_model.dart';
import 'package:all_flutter0709/features/user/data/user_repository.dart';
import 'package:all_flutter0709/shared/widgets/app_toast.dart';
import 'package:all_flutter0709/shared/widgets/common_app_bar.dart';
import 'package:all_flutter0709/shared/widgets/page_state_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 列表数据来源：本地会话优先，空则关注列表兜底。
enum _UserSelectSource { local, follow }

/// 发布动态 / 评论时选择 @好友，对齐 Android `UserSelectActivity`。
class TopicUserSelectPage extends ConsumerStatefulWidget {
  const TopicUserSelectPage({super.key});

  @override
  ConsumerState<TopicUserSelectPage> createState() =>
      _TopicUserSelectPageState();
}

class _TopicUserSelectPageState extends ConsumerState<TopicUserSelectPage> {
  final UserRepository _userRepository = const UserRepository();
  final TextEditingController _keywordController = TextEditingController();

  /// 当前数据源全量缓存（会话或已加载的关注页），供本地即时搜索。
  final List<UserBaseModel> _sourceUserModelList = <UserBaseModel>[];

  /// 按昵称过滤后的展示列表。
  final List<UserBaseModel> _userModelList = <UserBaseModel>[];

  _UserSelectSource _source = _UserSelectSource.local;
  int _nextPage = 1;
  bool _hasMore = false;
  PageState _pageState = PageState.loading;

  @override
  void initState() {
    super.initState();
    _keywordController.addListener(_onKeywordChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _requestList(isRefresh: true);
    });
  }

  @override
  void dispose() {
    _keywordController.removeListener(_onKeywordChanged);
    _keywordController.dispose();
    super.dispose();
  }

  void _onKeywordChanged() {
    if (_pageState == PageState.loading || _pageState == PageState.error) {
      return;
    }
    _applyKeywordFilter();
  }

  Future<void> _requestList({required bool isRefresh}) async {
    try {
      if (isRefresh) {
        final localList = await _loadLocalUserModelList();
        if (!mounted) return;
        if (localList.isNotEmpty) {
          _replaceSourceList(
            source: _UserSelectSource.local,
            userModelList: localList,
            hasMore: false,
            nextPage: 1,
          );
          return;
        }
        await _loadFollowList(isRefresh: true);
        return;
      }

      if (_source == _UserSelectSource.follow) {
        await _loadFollowList(isRefresh: false);
      }
    } catch (error) {
      if (!mounted) return;
      if (_sourceUserModelList.isEmpty) {
        setState(() {
          _pageState = PageState.error;
        });
      }
      AppToast.show(context, error.toString());
    }
  }

  /// 从本地会话表取真人用户；无会话或全是 AI 时返回空列表。
  Future<List<UserBaseModel>> _loadLocalUserModelList() async {
    final account = ref.read(accountProvider);
    if (account == null) {
      return const <UserBaseModel>[];
    }
    final conversationList = await ref
        .read(conversationRepositoryProvider)
        .getConversationList(account.userId);
    return conversationList
        .where((summaryModel) => !summaryModel.isAi)
        .map(_fromConversationSummary)
        .where((userModel) => userModel.userId.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> _loadFollowList({required bool isRefresh}) async {
    final page = isRefresh ? 1 : _nextPage;
    final result = await _userRepository.getFollowList(
      toUserId: context.currentUserId,
      page: page,
      keyword: '',
    );
    if (!mounted) return;

    final mappedList = result.items
        .where((userModel) => !userModel.isAi && userModel.userId.isNotEmpty)
        .toList(growable: false);

    if (isRefresh) {
      _replaceSourceList(
        source: _UserSelectSource.follow,
        userModelList: mappedList,
        hasMore: result.hasMore,
        nextPage: 2,
      );
      return;
    }

    setState(() {
      _source = _UserSelectSource.follow;
      _sourceUserModelList.addAll(mappedList);
      _nextPage++;
      _hasMore = result.hasMore;
      _syncDisplayList();
    });
  }

  void _replaceSourceList({
    required _UserSelectSource source,
    required List<UserBaseModel> userModelList,
    required bool hasMore,
    required int nextPage,
  }) {
    setState(() {
      _source = source;
      _sourceUserModelList
        ..clear()
        ..addAll(userModelList);
      _hasMore = hasMore;
      _nextPage = nextPage;
      _syncDisplayList();
    });
  }

  void _applyKeywordFilter() {
    setState(_syncDisplayList);
  }

  void _syncDisplayList() {
    final filteredList = _filterByKeyword(
      _sourceUserModelList,
      _keywordController.text.trim(),
    );
    _userModelList
      ..clear()
      ..addAll(filteredList);
    _pageState = _userModelList.isEmpty ? PageState.empty : PageState.success;
  }

  List<UserBaseModel> _filterByKeyword(
    List<UserBaseModel> sourceList,
    String keyword,
  ) {
    if (keyword.isEmpty) {
      return List<UserBaseModel>.from(sourceList);
    }
    return sourceList
        .where((userModel) => userModel.name.contains(keyword))
        .toList(growable: false);
  }

  UserBaseModel _fromConversationSummary(ConversationSummary summaryModel) {
    final userId = summaryModel.otherUserId.isNotEmpty
        ? summaryModel.otherUserId
        : summaryModel.conversationId;
    return UserBaseModel(
      userId: userId,
      name: summaryModel.name,
      avatar: summaryModel.avatar,
      userType: summaryModel.userType,
    );
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
              child: TextField(
                controller: _keywordController,
                textInputAction: TextInputAction.search,
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
