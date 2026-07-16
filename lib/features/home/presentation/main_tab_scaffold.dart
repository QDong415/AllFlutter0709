import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainTabScaffold extends StatelessWidget {
  const MainTabScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: MainTabItem.values
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
    icon: Icons.dynamic_feed_outlined,
    selectedIcon: Icons.dynamic_feed,
  ),
  video(
    label: '视频',
    icon: Icons.ondemand_video_outlined,
    selectedIcon: Icons.ondemand_video,
  ),
  conversation(
    label: '对话',
    icon: Icons.forum_outlined,
    selectedIcon: Icons.forum,
  ),
  me(
    label: '我的',
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
  );

  const MainTabItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
