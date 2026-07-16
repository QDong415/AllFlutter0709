import 'package:flutter/material.dart';

enum PageState {
  loading,
  empty,
  error,
  success,
}

class PageStateView extends StatelessWidget {
  const PageStateView({
    required this.state,
    required this.successWidget,
    super.key,
    this.emptyText,
    this.errorText,
  });

  final PageState state;
  final Widget successWidget;
  final String? emptyText;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case PageState.loading:
        return const Center(child: CircularProgressIndicator());
      case PageState.empty:
        return _StateHint(
          icon: Icons.inbox_outlined,
          text: emptyText ?? '暂无内容',
        );
      case PageState.error:
        return _StateHint(
          icon: Icons.wifi_off_outlined,
          text: errorText ?? '加载失败，请稍后重试',
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
  });

  final IconData icon;
  final String text;

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
        ],
      ),
    );
  }
}
