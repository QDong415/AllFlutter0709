import 'package:all_flutter0709/app/theme/app_dimens.dart';
import 'package:flutter/material.dart';

/// AI 角色列表首次加载骨架屏。
class AiCharacterSkeleton extends StatelessWidget {
  const AiCharacterSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
        10,
        10,
        10,
        AppDimens.glassTabBarContentInset,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.52,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(child: ColoredBox(color: Color(0xFFE5E5E5))),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _line(width: 82, height: 14),
                    const SizedBox(height: 8),
                    _line(width: double.infinity, height: 10),
                    const SizedBox(height: 6),
                    _line(width: 104, height: 10),
                    const SizedBox(height: 8),
                    _line(width: double.infinity, height: 32),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _line({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E5E5),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
