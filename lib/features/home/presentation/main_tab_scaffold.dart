import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/app/theme/app_system_ui.dart';
import 'package:all_flutter0709/features/conversation/presentation/conversation_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// 底栏玻璃配方：与 package 内 `kBottomBarGlassDefaults` 相同，但关掉色差。
const _kMainTabBarGlassSettings = LiquidGlassSettings(
  thickness: 30,
  blur: 3,
  chromaticAberration: 0,
  lightIntensity: 0.6,
  refractiveIndex: 1.59,
  saturation: 0.7,
  ambientStrength: 1,
  lightAngle: GlassDefaults.lightAngle,
  glassColor: Color(0x3DFFFFFF),
);

/// 与 [GlassTabBar.bottom] 默认一致，便于叠字对齐。
const _kTabBarHeight = 64.0;
const _kTabBarHorizontalPadding = 20.0;
const _kTabBarVerticalPadding = 20.0;
const _kTabIconSize = 24.0;
const _kTabIconLabelSpacing = 4.0;
const _kTabLabelFontSize = 12.0;
const _kTabLabelLineHeight = 14.0;

/// 主 Tab 壳：底部液态玻璃 TabBar（[GlassTabBar]），内容区由 go_router shell 保活。
///
/// 汉字标签叠在玻璃层之上绘制，避免 shader 在胶囊底沿折射文字产生淡黄色散线。
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
            final selectedIndex = navigationShell.currentIndex;
            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                GlassTabBar.bottom(
                  key: ValueKey('main-tabs-unread-$unreadCount'),
                  selectedIndex: selectedIndex,
                  selectedIconColor: AppColors.primary,
                  unselectedIconColor: AppColors.tabUnselected,
                  indicatorColor: const Color(0x1A000000),
                  settings: _kMainTabBarGlassSettings,
                  indicatorSettings: const LiquidGlassSettings(
                    thickness: 20,
                    refractiveIndex: 1.10,
                    lightIntensity: GlassDefaults.lightIntensity,
                    chromaticAberration: 0,
                    lightAngle: GlassDefaults.lightAngle,
                    blur: 0,
                  ),
                  barHeight: _kTabBarHeight,
                  horizontalPadding: _kTabBarHorizontalPadding,
                  verticalPadding: _kTabBarVerticalPadding,
                  iconSize: _kTabIconSize,
                  iconLabelSpacing: _kTabIconLabelSpacing,
                  onTabSelected: (index) {
                    navigationShell.goBranch(
                      index,
                      initialLocation: index == selectedIndex,
                    );
                  },
                  tabs: MainTabItem.values
                      .map(
                        (tab) => GlassTab(
                          icon: _TabGlyph(
                            icon: tab.icon,
                            badgeCount: tab == MainTabItem.conversation
                                ? unreadCount
                                : 0,
                          ),
                          activeIcon: _TabGlyph(
                            icon: tab.selectedIcon,
                            badgeCount: tab == MainTabItem.conversation
                                ? unreadCount
                                : 0,
                          ),
                        ),
                      )
                      .toList(),
                ),
                Positioned(
                  left: _kTabBarHorizontalPadding,
                  right: _kTabBarHorizontalPadding,
                  bottom: _kTabBarVerticalPadding,
                  height: _kTabBarHeight,
                  child: IgnorePointer(
                    child: Row(
                      children: [
                        for (var index = 0;
                            index < MainTabItem.values.length;
                            index++)
                          Expanded(
                            child: _TabLabelOverlay(
                              label: MainTabItem.values[index].label,
                              selected: index == selectedIndex,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
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

/// 玻璃内只放图标，并预留下方标签高度，保证与叠层文字对齐。
class _TabGlyph extends StatelessWidget {
  const _TabGlyph({required this.icon, required this.badgeCount});

  final IconData icon;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(icon, size: _kTabIconSize);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (badgeCount > 0)
          Badge.count(
            isLabelVisible: true,
            count: badgeCount > 99 ? 99 : badgeCount,
            child: iconWidget,
          )
        else
          iconWidget,
        const SizedBox(height: _kTabIconLabelSpacing + _kTabLabelLineHeight),
      ],
    );
  }
}

/// 叠在玻璃之上的 Tab 文案，不参与 shader 折射。
class _TabLabelOverlay extends StatelessWidget {
  const _TabLabelOverlay({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: _kTabIconSize + _kTabIconLabelSpacing),
        Text(
          label,
          maxLines: 1,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: _kTabLabelFontSize,
            height: _kTabLabelLineHeight / _kTabLabelFontSize,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? AppColors.primary : AppColors.tabUnselected,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }
}
