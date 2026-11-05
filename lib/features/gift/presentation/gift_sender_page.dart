import 'package:all_flutter0709/app/router/app_routes.dart';
import 'package:all_flutter0709/features/gift/data/gift_list_errors.dart';
import 'package:all_flutter0709/features/gift/data/gift_model.dart';
import 'package:all_flutter0709/features/gift/data/gift_repository.dart';
import 'package:all_flutter0709/features/gift/presentation/widgets/gift_user_avatar.dart';
import 'package:all_flutter0709/features/user/presentation/helpers/user_detail_navigation.dart';
import 'package:all_flutter0709/shared/widgets/common_app_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 打开送礼流水。动态传 [feedId]，个人主页传 [toUserId]。
void openGiftSenderPage(
  BuildContext context, {
  String? toUserId,
  String? feedId,
  int? type,
}) {
  final query = <String, String>{};
  if (toUserId != null && toUserId.trim().isNotEmpty) {
    query['to_userid'] = toUserId.trim();
  }
  if (feedId != null && feedId.trim().isNotEmpty) {
    query['feedid'] = feedId.trim();
  }
  if (type != null) {
    query['type'] = '$type';
  }
  context.push(Uri(path: AppRoutes.giftSenders, queryParameters: query).toString());
}

/// 谁送了什么礼物。
class GiftSenderPage extends StatefulWidget {
  const GiftSenderPage({super.key, this.toUserId, this.feedId, this.type});

  final String? toUserId;
  final String? feedId;
  final int? type;

  @override
  State<GiftSenderPage> createState() => _GiftSenderPageState();
}

class _GiftSenderPageState extends State<GiftSenderPage> {
  final GiftRepository _repository = const GiftRepository();
  final List<GiftSenderRecord> _records = <GiftSenderRecord>[];

  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _errorText;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({required bool reset}) async {
    if (!reset && (_loadingMore || !_hasMore)) {
      return;
    }
    final page = reset ? 1 : _page;
    setState(() {
      if (reset) {
        _loading = true;
        _errorText = null;
      } else {
        _loadingMore = true;
      }
    });
    try {
      final items = await _repository.fetchSenderList(
        toUserId: widget.toUserId,
        feedId: widget.feedId,
        type: widget.type,
        page: page,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        if (reset) {
          _records
            ..clear()
            ..addAll(items);
        } else {
          _records.addAll(items);
        }
        _page = page + 1;
        _hasMore = items.length >= 20;
        _loading = false;
        _loadingMore = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _loadingMore = false;
        if (reset) {
          _errorText = giftErrorMessage(error);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: '送礼的人'),
      backgroundColor: Colors.white,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorText != null && _records.isEmpty) {
      final hidden = isGiftListHiddenError(_errorText!);
      final message = giftErrorMessage(_errorText!);
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, style: const TextStyle(color: Color(0xFF8B8B90))),
            if (!hidden) ...[
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => _load(reset: true),
                child: const Text('重试'),
              ),
            ],
          ],
        ),
      );
    }
    if (_records.isEmpty) {
      return const Center(
        child: Text('还没有人送礼', style: TextStyle(color: Color(0xFF8B8B90))),
      );
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >
            notification.metrics.maxScrollExtent - 240) {
          _load(reset: false);
        }
        return false;
      },
      child: ListView.separated(
        itemCount: _records.length + (_loadingMore ? 1 : 0),
        separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
        itemBuilder: (context, index) {
          if (index >= _records.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final record = _records[index];
          return ListTile(
            onTap: () => openUserDetailPage(
              context,
              userId: record.userId,
              name: record.name,
              avatar: record.avatar,
            ),
            leading: GiftUserAvatar(url: record.avatarUrl, size: 44),
            title: Text(
              record.name.isEmpty ? '用户' : record.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${record.title} x${record.count}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: record.pictureUrl.isEmpty
                ? null
                : CachedNetworkImage(
                    imageUrl: record.pictureUrl,
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                    errorWidget: (_, _, _) => const SizedBox.shrink(),
                  ),
          );
        },
      ),
    );
  }
}
