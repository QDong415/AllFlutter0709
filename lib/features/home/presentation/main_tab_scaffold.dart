import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/app/theme/app_system_ui.dart';
import 'package:all_flutter0709/features/conversation/presentation/conversation_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// 主 Tab 壳：底部液态玻璃 TabBar（[GlassTabBar]），内容区由 go_router shell 保活。
class MainTabScaffold extends ConsumerWidget {
  const MainTabScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(conversationControllerProvider);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppSystemUi.overlayStyle,
      child: GlassScaffold(
        backgroundColor: AppColors.bodyBackground,
        statusBarStyle: GlassStatusBarStyle.none,
        extendBody: true,
        // 各 Tab 页自带 Material AppBar，顶部不做 glass edge fade。
        topEdgeFade: false,
        bottomEdgeFade: true,
        body: navigationShell,
        bottomBar: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final unreadCount = controller.totalUnreadCount;
            return GlassTabBar.bottom(
              key: ValueKey('main-tabs-unread-$unreadCount'),
              selectedIndex: navigationShell.currentIndex,
              selectedIconColor: AppColors.primary,
              selectedLabelColor: AppColors.primary,
              unselectedIconColor: AppColors.tabUnselected,
              unselectedLabelColor: AppColors.tabUnselected,
              // iOS 26 默认选中胶囊：深色半透明，而不是品牌主色淡红。
              indicatorColor: const Color(0x1A000000),
              labelFontSize: 12,
              onTabSelected: (index) {
                navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                );
              },
              tabs: MainTabItem.values
                  .map(
                    (tab) => GlassTab(
                      icon: _TabIcon(
                        icon: tab.icon,
                        badgeCount: tab == MainTabItem.conversation
                            ? unreadCount
                            : 0,
                      ),
                      activeIcon: _TabIcon(
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
      ),
    );
  }
}

/// 主 Tab 项：图标映射自 Material Icons，风格接近 QKotlin 矢量 Tab。
enum MainTabItem {
  topic(
    label: '动态',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
  ),
  video(
    label: '视频',
    icon: Icons.videocam_outlined,
    selectedIcon: Icons.videocam,
  ),
  conversation(
    label: '聊天',
    icon: Icons.chat_bubble_outline,
    selectedIcon: Icons.chat_bubble,
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

/// Tab 图标；聊天 Tab 可带未读角标。
class _TabIcon extends StatelessWidget {
  const _TabIcon({required this.icon, required this.badgeCount});

  final IconData icon;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(icon, size: 24);
    if (badgeCount <= 0) {
      return iconWidget;
    }
    return GlassBadge(
      count: badgeCount > 99 ? 99 : badgeCount,
      child: iconWidget,
    );
  }
}
