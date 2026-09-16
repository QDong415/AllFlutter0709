import 'package:all_flutter0709/features/topic/data/models/topic_submit_media_model.dart';
import 'package:flutter/material.dart';

/// 发布页九宫格：已选媒体 + 添加按钮，一行最多 3 张。
class TopicSubmitMediaGrid extends StatelessWidget {
  const TopicSubmitMediaGrid({
    super.key,
    required this.mediaList,
    required this.canAddMore,
    required this.onAddTap,
    required this.onItemTap,
    required this.onDeleteTap,
  });

  final List<TopicSubmitMediaModel> mediaList;
  final bool canAddMore;
  final VoidCallback onAddTap;
  final ValueChanged<int> onItemTap;
  final ValueChanged<int> onDeleteTap;

  static const int _crossAxisCount = 3;
  static const double _itemSize = 80;
  static const double _deleteOffset = 5;
  static const double _spacing = 8;

  static double get _tileSize => _itemSize + _deleteOffset;

  @override
  Widget build(BuildContext context) {
    final itemCount = mediaList.length + (canAddMore ? 1 : 0);
    if (itemCount <= 0) {
      return const SizedBox.shrink();
    }
    final rowCount = (itemCount / _crossAxisCount).ceil();
    final gridWidth =
        _crossAxisCount * _tileSize + (_crossAxisCount - 1) * _spacing;
    final gridHeight = rowCount * _tileSize + (rowCount - 1) * _spacing;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 5, 8, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: gridWidth,
          height: gridHeight,
          child: GridView.builder(
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: itemCount,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _crossAxisCount,
              mainAxisSpacing: _spacing,
              crossAxisSpacing: _spacing,
            ),
            itemBuilder: (context, index) {
              if (index < mediaList.length) {
                return _MediaTile(
                  mediaModel: mediaList[index],
                  onTap: () => onItemTap(index),
                  onDelete: () => onDeleteTap(index),
                );
              }
              return _AddTile(onTap: onAddTap);
            },
          ),
        ),
      ),
    );
  }
}

class _MediaTile extends StatelessWidget {
  const _MediaTile({
    required this.mediaModel,
    required this.onTap,
    required this.onDelete,
  });

  final TopicSubmitMediaModel mediaModel;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 0,
          bottom: 0,
          child: GestureDetector(
            onTap: onTap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: TopicSubmitMediaGrid._itemSize,
                height: TopicSubmitMediaGrid._itemSize,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(mediaModel.file, fit: BoxFit.cover),
                    if (mediaModel.isVideo)
                      const ColoredBox(
                        color: Color(0x33000000),
                        child: Icon(
                          Icons.play_circle_fill,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    if (mediaModel.isVideo)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: ColoredBox(
                          color: const Color(0x99000000),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            child: Text(
                              mediaModel.durationLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          child: GestureDetector(
            onTap: onDelete,
            child: const CircleAvatar(
              radius: 10,
              backgroundColor: Color(0xCC333333),
              child: Icon(Icons.close, size: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomLeft,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: TopicSubmitMediaGrid._itemSize,
          height: TopicSubmitMediaGrid._itemSize,
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F2),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: const Icon(Icons.add, size: 36, color: Color(0xFFB0B0B0)),
        ),
      ),
    );
  }
}
