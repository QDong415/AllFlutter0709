import 'package:flutter/material.dart';

enum PageState {
  loading,
  empty,
  error,
  success,
}

/// 列表页状态容器：加载中、空数据、网络失败、成功内容。
///
/// 传入 [onRefresh] 时，空数据和失败态会在文案下方展示刷新按钮。
class PageStateView extends StatelessWidget {
  const PageStateView({
    super.key,
    required this.state,
    required this.successWidget,
    this.emptyText,
    this.errorText,
    this.onRefresh,
  });

  final PageState state;
  final Widget successWidget;
  final String? emptyText;
  final String? errorText;

  /// 空数据或加载失败时点击刷新。
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case PageState.loading:
        return const Center(child: CircularProgressIndicator());
      case PageState.empty:
        return _StateHint(
          icon: Icons.inbox_outlined,
          text: emptyText ?? '暂无内容',
          onRefresh: onRefresh,
        );
      case PageState.error:
        return _StateHint(
          icon: Icons.wifi_off_outlined,
          text: errorText ?? '加载失败，请稍后重试',
          onRefresh: onRefresh,
        );
      case PageState.success:
        return successWidget;
    }
  }
}

class _StateHint extends StatelessWidget {
  const _StateHint({
    required this.icon,
    required this.text,
    this.onRefresh,
  });

  final IconData icon;
  final String text;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: Colors.grey.shade500),
          const SizedBox(height: 12),
          Text(
            text,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          if (onRefresh != null) ...[
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRefresh,
              style: FilledButton.styleFrom(
                minimumSize: const Size(96, 36),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              child: const Text('刷新'),
            ),
          ],
        ],
      ),
    );
  }
}
