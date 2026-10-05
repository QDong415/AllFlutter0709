import 'package:all_flutter0709/features/me/presentation/me_page.dart';
import 'package:all_flutter0709/features/topic/presentation/topic_list_base_state.dart';
import 'package:flutter/material.dart';

/// 我赞过的 / 我评论的动态，对齐 Android `TopicMineActivity`。
class MineTopicListPage extends StatefulWidget {
  const MineTopicListPage({super.key, required this.args});

  final MineTopicArgs args;

  @override
  State<MineTopicListPage> createState() => _MineTopicListPageState();
}

class _MineTopicListPageState extends TopicListBaseState<MineTopicListPage> {
  @override
  String get pageTitle => widget.args.onlyLike ? '我赞过的' : '我评论的';

  @override
  String get emptyText => widget.args.onlyLike ? '还没有赞过动态' : '还没有评论过动态';

  @override
  Map<String, dynamic>? customParameters() {
    return <String, dynamic>{
      if (widget.args.onlyLike) 'onlylike': '1',
      if (widget.args.onlyComment) 'onlycomment': '1',
    };
  }
}
