import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/app/theme/app_shadows.dart';
import 'package:all_flutter0709/features/conversation/presentation/conversation_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 主 Tab 壳：底部栏（白底、56、主色选中）。
class MainTabScaffold extends ConsumerWidget {
  const MainTabScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _systemNavStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.tabBarBackground,
    systemNavigationBarDividerColor: AppColors.tabBarBackground,
    systemNavigationBarContrastEnforced: false,
    systemNavigationBarIconBrightness: Brightness.dark,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(conversationControllerProvider);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _systemNavStyle,
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final unreadCount = controller.totalUnreadCount;
            // DecoratedBox 铺满底部安全区，并带上缘轻阴影。
            return DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.tabBarBackground,
                boxShadow: AppShadows.upward,
              ),
              child: SafeArea(
                top: false,
                child: BottomNavigationBar(
                  key: ValueKey('main-tabs-unread-$unreadCount'),
                  currentIndex: navigationShell.currentIndex,
                  backgroundColor: AppColors.tabBarBackground,
                  selectedItemColor: AppColors.primary,
                  unselectedItemColor: AppColors.tabUnselected,
                  type: BottomNavigationBarType.fixed,
                  elevation: 0,
                  selectedFontSize: 12,
                  unselectedFontSize: 12,
                  onTap: (index) {
                    navigationShell.goBranch(
                      index,
                      initialLocation: index == navigationShell.currentIndex,
                    );
                  },
                  items: MainTabItem.values
                      .map(
                        (tab) => BottomNavigationBarItem(
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
                ),
              ),
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

class _TabIcon extends StatelessWidget {
  const _TabIcon({required this.icon, required this.badgeCount});

  final IconData icon;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return Badge.count(
      isLabelVisible: badgeCount > 0,
      count: badgeCount > 99 ? 99 : badgeCount,
      child: Icon(icon, size: 24),
    );
  }
}
