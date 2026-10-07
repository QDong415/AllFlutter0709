import 'package:all_flutter0709/core/emoji/qq_emoji_catalog.dart';
import 'package:all_flutter0709/features/conversation/presentation/widgets/chat_input_bar.dart';
import 'package:flutter/material.dart';

/// QQ 表情面板：点选后把 `[微笑]` 这类文本插入输入框。
class ChatEmojiPanel extends StatelessWidget {
  const ChatEmojiPanel({
    super.key,
    required this.height,
    required this.onEmojiTap,
    required this.onDelete,
  });

  final double height;
  final ValueChanged<String> onEmojiTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = 12 + MediaQuery.paddingOf(context).bottom;
    return ColoredBox(
      color: QInputBarColors.extendBackground,
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: Stack(
          children: [
            GridView.builder(
              padding: EdgeInsets.fromLTRB(8, 8, 8, bottomPadding + 44),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
              ),
              itemCount: QqEmojiCatalog.entries.length,
              itemBuilder: (context, index) {
                final entry = QqEmojiCatalog.entries[index];
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onEmojiTap(entry.code),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Image.asset(entry.asset, gaplessPlayback: true),
                  ),
                );
              },
            ),
            Positioned(
              right: 10,
              bottom: bottomPadding,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onDelete,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Image.asset(
                      QqEmojiCatalog.deleteAsset,
                      width: 28,
                      height: 28,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
