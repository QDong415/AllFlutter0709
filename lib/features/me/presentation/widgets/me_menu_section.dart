import 'package:flutter/material.dart';

/// 「我的」页一组白底菜单，圆角对齐 Android `white_single_round`（4dp）。
class MeMenuSection extends StatelessWidget {
  const MeMenuSection({super.key, required this.itemList});

  final List<MeMenuItem> itemList;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          for (var index = 0; index < itemList.length; index++) ...[
            if (index > 0)
              const Divider(
                height: 0.5,
                thickness: 0.5,
                indent: 18,
                color: Color(0xFFE6E6E6),
              ),
            _MeMenuRow(item: itemList[index]),
          ],
        ],
      ),
    );
  }
}

/// 「我的」菜单项。
class MeMenuItem {
  const MeMenuItem({
    required this.iconAsset,
    required this.title,
    required this.onTap,
  });

  final String iconAsset;
  final String title;
  final VoidCallback onTap;
}

class _MeMenuRow extends StatelessWidget {
  const _MeMenuRow({required this.item});

  final MeMenuItem item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      child: SizedBox(
        height: 50,
        child: Padding(
          padding: const EdgeInsets.only(left: 18),
          child: Row(
            children: [
              Image.asset(item.iconAsset, width: 23, height: 23),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(fontSize: 15, color: Color(0xFF5B5B5B)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Image.asset(
                  'assets/icons/me/arrow_right.png',
                  width: 16,
                  height: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
