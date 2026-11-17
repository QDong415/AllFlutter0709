import 'package:all_flutter0709/app/theme/app_system_ui.dart';
import 'package:all_flutter0709/shared/media/gallery_preview_item.dart';
import 'package:all_flutter0709/shared/media/image_preview_save_actions.dart';
import 'package:dismissible_page/dismissible_page.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

/// 多图全屏画廊预览：缩放、下滑关闭、长按保存。
class AppImageGalleryPreviewPage extends StatefulWidget {
  const AppImageGalleryPreviewPage({
    super.key,
    required this.itemList,
    required this.initialIndex,
    this.enableSave = true,
  }) : assert(itemList.length > 0),
       assert(initialIndex >= 0 && initialIndex < itemList.length);

  final List<GalleryPreviewItem> itemList;
  final int initialIndex;
  final bool enableSave;

  @override
  State<AppImageGalleryPreviewPage> createState() =>
      _AppImageGalleryPreviewPageState();
}

class _AppImageGalleryPreviewPageState
    extends State<AppImageGalleryPreviewPage> {
  late final PageController _pageController;
  late int _currentIndex;
  double _overlayOpacity = 1;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onLongPressSave() {
    if (!widget.enableSave) {
      return;
    }
    final item = widget.itemList[_currentIndex];
    ImagePreviewSaveActions.showSaveSheet(context, saveSource: item.saveSource);
  }

  @override
  Widget build(BuildContext context) {
    return FullscreenMediaSystemUi(
      child: DismissiblePage(
        direction: DismissiblePageDismissDirection.vertical,
        backgroundColor: Colors.black,
        startingOpacity: 1,
        dragSensitivity: 0.7,
        minRadius: 0,
        maxRadius: 24,
        onDragUpdate: (details) {
          final nextOpacity = details.opacity.clamp(0.0, 1.0);
          if (_overlayOpacity == nextOpacity) {
            return;
          }
          setState(() {
            _overlayOpacity = nextOpacity;
          });
        },
        onDismissed: () => Navigator.of(context).maybePop(),
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onLongPress: widget.enableSave ? _onLongPressSave : null,
                  child: PhotoViewGallery.builder(
                    pageController: _pageController,
                    itemCount: widget.itemList.length,
                    backgroundDecoration: const BoxDecoration(
                      color: Colors.black,
                    ),
                    scrollPhysics: const BouncingScrollPhysics(),
                    onPageChanged: (index) {
                      if (_currentIndex == index) {
                        return;
                      }
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    builder: (context, index) {
                      final item = widget.itemList[index];
                      final heroTag = item.heroTag;
                      final isCurrentPage = index == _currentIndex;
                      return PhotoViewGalleryPageOptions(
                        imageProvider: item.imageProvider,
                        minScale: PhotoViewComputedScale.contained,
                        initialScale: PhotoViewComputedScale.contained,
                        maxScale: PhotoViewComputedScale.covered * 4,
                        tightMode: true,
                        onTapUp: (context, details, controllerValue) {
                          Navigator.of(context).maybePop();
                        },
                        heroAttributes: heroTag == null || !isCurrentPage
                            ? null
                            : PhotoViewHeroAttributes(tag: heroTag),
                      );
                    },
                    loadingBuilder: (context, event) {
                      final expectedBytes = event?.expectedTotalBytes;
                      final loadedBytes = event?.cumulativeBytesLoaded;
                      final progress =
                          loadedBytes != null &&
                              expectedBytes != null &&
                              expectedBytes > 0
                          ? (loadedBytes / expectedBytes).clamp(0.0, 1.0)
                          : null;
                      return Center(
                        child: SizedBox.square(
                          dimension: 24,
                          child: CircularProgressIndicator(
                            value: progress,
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.paddingOf(context).top + 8,
                left: 16,
                right: 16,
                child: _GalleryPreviewTopBar(
                  opacity: _overlayOpacity,
                  currentIndex: _currentIndex,
                  total: widget.itemList.length,
                  onBackTap: () => Navigator.of(context).maybePop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GalleryPreviewTopBar extends StatelessWidget {
  const _GalleryPreviewTopBar({
    required this.opacity,
    required this.currentIndex,
    required this.total,
    required this.onBackTap,
  });

  final double opacity;
  final int currentIndex;
  final int total;
  final VoidCallback onBackTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: opacity,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Row(
        children: [
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: Colors.black45,
              foregroundColor: Colors.white,
            ),
            onPressed: onBackTap,
            icon: const Icon(Icons.arrow_back),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${currentIndex + 1}/$total',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
