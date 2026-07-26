import 'package:all_flutter0709/features/topic/presentation/topic_list_base_state.dart';
import 'package:flutter/material.dart';

class TopicPage extends StatefulWidget {
  const TopicPage({super.key});

  @override
  State<TopicPage> createState() => _TopicPageState();
}

class _TopicPageState extends TopicListBaseState<TopicPage>  {

  @override
  Map<String, dynamic>? customParameters() {
    //为了演示，我指定返回评论数 >=2 的动态
    Map<String, dynamic> map = {"commentcount" : 2};
    return map;
  }
}
