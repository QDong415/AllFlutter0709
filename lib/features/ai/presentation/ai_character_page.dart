import 'dart:async';

import 'package:all_flutter0709/app/router/app_routes.dart';
import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/app/theme/app_dimens.dart';
import 'package:all_flutter0709/core/account/account_guard.dart';
import 'package:all_flutter0709/features/ai/data/ai_character_repository.dart';
import 'package:all_flutter0709/features/ai/data/models/ai_character_model.dart';
import 'package:all_flutter0709/features/ai/presentation/widgets/ai_character_card.dart';
import 'package:all_flutter0709/features/ai/presentation/widgets/ai_character_filter_bar.dart';
import 'package:all_flutter0709/features/ai/presentation/widgets/ai_character_skeleton.dart';
import 'package:all_flutter0709/features/conversation/presentation/helpers/conversation_chat_args.dart';
import 'package:all_flutter0709/features/user/presentation/helpers/user_detail_navigation.dart';
import 'package:all_flutter0709/shared/widgets/app_toast.dart';
import 'package:all_flutter0709/shared/widgets/common_app_bar.dart';
import 'package:all_flutter0709/shared/widgets/page_state_view.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// AI 角色发现页：支持搜索、筛选、分页以及进入主页或聊天。
class AiCharacterPage extends StatefulWidget {
  const AiCharacterPage({super.key});

  @override
  State<AiCharacterPage> createState() => _AiCharacterPageState();
}

class _AiCharacterPageState extends State<AiCharacterPage> {
  final AiCharacterRepository _repository = const AiCharacterRepository();
  final TextEditingController _searchController = TextEditingController();
  final List<AiCharacterModel> _characterModelList = <AiCharacterModel>[];

  AiCharacterFilter _selectedFilter = AiCharacterFilter.female;
  PageState _pageState = PageState.loading;
  Timer? _searchDebounce;
  int _nextPage = 1;
  int _requestSerial = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    unawaited(_requestList(isRefresh: true));
  }

  @override
  void dispose() {
    _requestSerial++;
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _requestList({required bool isRefresh}) async {
    if (!isRefresh && (_isLoadingMore || !_hasMore)) return;
    final requestSerial = isRefresh ? ++_requestSerial : _requestSerial;
    final requestPage = isRefresh ? 1 : _nextPage;
    if (isRefresh) {
      _isLoadingMore = false;
    } else {
      _isLoadingMore = true;
    }

    try {
      final pageResult = await _repository.getCharacterList(
        page: requestPage,
        filter: _selectedFilter,
        keyword: _searchController.text,
      );
      if (!mounted || requestSerial != _requestSerial) return;

      setState(() {
        if (isRefresh) {
          _characterModelList
            ..clear()
            ..addAll(pageResult.characterModelList);
          _nextPage = 2;
        } else {
          _characterModelList.addAll(pageResult.characterModelList);
          _nextPage++;
        }
        _hasMore = pageResult.hasMore;
        _pageState = _characterModelList.isEmpty
            ? PageState.empty
            : PageState.success;
      });
    } catch (error) {
      if (!mounted || requestSerial != _requestSerial) return;
      if (_characterModelList.isEmpty) {
        setState(() => _pageState = PageState.error);
      }
      AppToast.show(context, error.toString());
    } finally {
      if (requestSerial == _requestSerial) {
        _isLoadingMore = false;
      }
    }
  }

  void _onFilterChanged(AiCharacterFilter filter) {
    if (filter == _selectedFilter) return;
    _searchDebounce?.cancel();
    setState(() {
      _selectedFilter = filter;
      _pageState = PageState.loading;
    });
    unawaited(_requestList(isRefresh: true));
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() => _pageState = PageState.loading);
      unawaited(_requestList(isRefresh: true));
    });
  }

  void _openCharacter(AiCharacterModel characterModel) {
    openUserDetailPage(
      context,
      userId: characterModel.userId,
      name: characterModel.name,
      avatar: characterModel.avatarUrl,
      userType: characterModel.userType,
    );
  }

  Future<void> _openChat(AiCharacterModel characterModel) async {
    if (!context.ensureLoggedIn()) return;
    await context.push(
      '${AppRoutes.conversation}/chat/${characterModel.userId}',
      extra: ConversationChatArgs(
        peerName: characterModel.name,
        peerAvatar: characterModel.avatarUrl,
        peerUserType: characterModel.userType,
      ),
    );
  }

  Future<void> _openCreation() async {
    if (!context.ensureLoggedIn()) return;
    final created = await context.push<bool>(
      '${AppRoutes.ai}/${AppRoutes.aiCreate}',
    );
    if (!mounted || created != true) return;
    setState(() {
      _selectedFilter = AiCharacterFilter.female;
      _pageState = PageState.loading;
    });
    await _requestList(isRefresh: true);
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
        10,
        10,
        10,
        AppDimens.glassTabBarContentInset,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.52,
      ),
      itemCount: _characterModelList.length,
      itemBuilder: (context, index) {
        final characterModel = _characterModelList[index];
        return AiCharacterCard(
          characterModel: characterModel,
          onTap: () => _openCharacter(characterModel),
          onChatTap: () => _openChat(characterModel),
        );
      },
    );
  }

  Widget _buildContent() {
    if (_pageState == PageState.loading) {
      return const AiCharacterSkeleton();
    }
    return PageStateView(
      state: _pageState,
      emptyText: '没有找到符合条件的 AI 伙伴',
      errorText: '加载失败，请稍后重试',
      successWidget: _buildGrid(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: 'AI 伙伴'),
      backgroundColor: AppColors.bodyBackground,
      body: Column(
        children: [
          AiCharacterFilterBar(
            selectedFilter: _selectedFilter,
            searchController: _searchController,
            onFilterChanged: _onFilterChanged,
            onSearchChanged: _onSearchChanged,
            onCreateTap: _openCreation,
          ),
          Expanded(
            child: EasyRefresh(
              header: const ClassicHeader(showMessage: false, showText: false),
              onRefresh: () => _requestList(isRefresh: true),
              onLoad: _hasMore ? () => _requestList(isRefresh: false) : null,
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }
}
