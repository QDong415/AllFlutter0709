import 'package:all_flutter0709/app/router/app_routes.dart';
import 'package:all_flutter0709/features/conversation/presentation/conversation_page.dart';
import 'package:all_flutter0709/features/me/presentation/me_page.dart';
import 'package:all_flutter0709/features/topic/presentation/topic_page.dart';
import 'package:all_flutter0709/features/video/presentation/video_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainTabScaffold extends StatelessWidget {
  const MainTabScaffold({super.key, required this.location});

  final String location;

  int get currentIndex {
    for (var i = 0; i < MainTabItem.values.length; i++) {
      if (location.startsWith(MainTabItem.values[i].path)) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final tabs = MainTabItem.values;
    final pages = <Widget>[
      const TopicPage(),
      const VideoPage(),
      const ConversationPage(),
      const MePage(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          context.go(tabs[index].path);
        },
        destinations: tabs
            .map(
              (tab) => NavigationDestination(
                icon: Icon(tab.icon),
                selectedIcon: Icon(tab.selectedIcon),
                label: tab.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

enum MainTabItem {
  topic(
    label: '动态',
    path: AppRoutes.topic,
    icon: Icons.dynamic_feed_outlined,
    selectedIcon: Icons.dynamic_feed,
  ),
  video(
    label: '视频',
    path: AppRoutes.video,
    icon: Icons.ondemand_video_outlined,
    selectedIcon: Icons.ondemand_video,
  ),
  conversation(
    label: '对话',
    path: AppRoutes.conversation,
    icon: Icons.forum_outlined,
    selectedIcon: Icons.forum,
  ),
  me(
    label: '我的',
    path: AppRoutes.me,
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
  );

  const MainTabItem({
    required this.label,
    required this.path,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final String path;
  final IconData icon;
  final IconData selectedIcon;
}
