import 'dart:math';

import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/app/theme/app_dimens.dart';
import 'package:all_flutter0709/features/topic/presentation/widgets/topic_match_user_item.dart';
import 'package:all_flutter0709/features/user/data/models/user_base_model.dart';
import 'package:all_flutter0709/features/user/data/user_repository.dart';
import 'package:all_flutter0709/features/user/presentation/helpers/user_detail_navigation.dart';
import 'package:all_flutter0709/shared/widgets/common_app_bar.dart';
import 'package:all_flutter0709/shared/widgets/page_state_view.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:all_flutter0709/shared/widgets/app_toast.dart';

/// 附近的人，对齐 Android `MineNearMemberActivity`。
class NearbyUserPage extends StatefulWidget {
  const NearbyUserPage({super.key});

  @override
  State<NearbyUserPage> createState() => _NearbyUserPageState();
}

class _NearbyUserPageState extends State<NearbyUserPage> {
  final UserRepository _userRepository = const UserRepository();
  final List<UserBaseModel> _userModelList = <UserBaseModel>[];
  int _nextPage = 1;
  bool _hasMore = true;
  PageState _pageState = PageState.loading;
  Position? _position;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _locateAndLoad());
  }

  Future<void> _locateAndLoad() async {
    setState(() => _pageState = PageState.loading);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('需要定位权限才能查看附近的人');
      }
      _position = await Geolocator.getCurrentPosition();
      await _request(isRefresh: true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _pageState = PageState.error);
      AppToast.show(context, '$error');
    }
  }

  Future<void> _request({required bool isRefresh}) async {
    final position = _position;
    if (position == null) {
      await _locateAndLoad();
      return;
    }
    final page = isRefresh ? 1 : _nextPage;
    try {
      final result = await _userRepository.getUserList(
        page: page,
        extra: <String, dynamic>{
          'near': '1',
          'latitude': '${position.latitude}',
          'longitude': '${position.longitude}',
        },
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

  String _distanceText(UserBaseModel userModel) {
    final position = _position;
    if (position == null ||
        userModel.latitude == 0 ||
        userModel.longitude == 0) {
      return userModel.cityName;
    }
    final meters = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      userModel.latitude,
      userModel.longitude,
    );
    if (meters < 1000) {
      return '${max(1, meters.round())}m';
    }
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bodyBackground,
      appBar: const CommonAppBar(title: '附近的人'),
      body: EasyRefresh(
        onRefresh: () => _request(isRefresh: true),
        onLoad: _hasMore ? () => _request(isRefresh: false) : null,
        child: PageStateView(
          state: _pageState,
          emptyText: '附近还没有人',
          errorText: '定位或加载失败，下拉重试',
          successWidget: ListView.separated(
            itemCount: _userModelList.length,
            separatorBuilder: (_, _) => const Divider(
              height: AppDimens.dividerThickness,
              thickness: AppDimens.dividerThickness,
              color: AppColors.divider,
            ),
            itemBuilder: (context, index) {
              final userModel = _userModelList[index];
              return TopicMatchUserItem(
                userModel: userModel,
                distanceText: _distanceText(userModel),
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
