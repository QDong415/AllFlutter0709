import 'package:all_flutter0709/features/conversation/presentation/conversation_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MainTabScaffold extends ConsumerWidget {
  const MainTabScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(conversationControllerProvider);
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final unreadCount = controller.totalUnreadCount;
          return NavigationBar(
            maintainBottomViewPadding: true,
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
                    icon: _TabIcon(
                      icon: tab.icon,
                      badgeCount: tab == MainTabItem.conversation
                          ? unreadCount
                          : 0,
                    ),
                    selectedIcon: _TabIcon(
                      icon: tab.selectedIcon,
                      badgeCount: tab == MainTabItem.conversation
                          ? unreadCount
                          : 0,
                    ),
                    label: tab.label,
                  ),
                )
                .toList(),
          );
        },
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
  me(label: '我的', icon: Icons.person_outline, selectedIcon: Icons.person);

  const MainTabItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class _TabIcon extends StatelessWidget {
  const _TabIcon({required this.icon, required this.badgeCount});

  final IconData icon;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return Badge.count(
      isLabelVisible: badgeCount > 0,
      count: badgeCount > 99 ? 99 : badgeCount,
      child: Icon(icon),
    );
  }
}
