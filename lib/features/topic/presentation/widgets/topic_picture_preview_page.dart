import 'dart:typed_data';

import 'package:all_flutter0709/app/theme/app_system_ui.dart';
import 'package:all_flutter0709/features/topic/data/models/topic_model.dart';
import 'package:dio/dio.dart';
import 'package:dismissible_page/dismissible_page.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class TopicPicturePreviewPage extends StatefulWidget {
  const TopicPicturePreviewPage({
    super.key,
    required this.pictures,
    required this.initialIndex,
  });

  final List<TopicPictureModel> pictures;
  final int initialIndex;

  @override
  State<TopicPicturePreviewPage> createState() =>
      _TopicPicturePreviewPageState();
}

class _TopicPicturePreviewPageState extends State<TopicPicturePreviewPage> {
  final Dio _dio = Dio();
  late final PageController _pageController;
  late int _currentIndex;
  double _overlayOpacity = 1;

  String _imageUrlOf(TopicPictureModel picture) {
    return picture.originalUrl.isNotEmpty
        ? picture.originalUrl
        : picture.thumbnailUrl;
  }

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

  Future<void> _showImageActions() async {
    await showModalBottomSheet<void>(
      context: context,
      barrierColor: Colors.transparent,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Center(
                  child: Text(
                    '保存图片',
                    style: TextStyle(color: Color(0xFF111111), fontSize: 16),
                  ),
                ),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await _saveCurrentImage();
                },
              ),
              const Divider(height: 1, color: Color(0xFFE5E5E5)),
              ListTile(
                title: const Center(
                  child: Text(
                    '取消',
                    style: TextStyle(color: Color(0xFF666666), fontSize: 16),
                  ),
                ),
                onTap: () => Navigator.of(sheetContext).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveCurrentImage() async {
    final picture = widget.pictures[_currentIndex];
    final imageUrl = _imageUrlOf(picture);
    if (imageUrl.isEmpty) {
      _showMessage('图片地址无效');
      return;
    }

    try {
      final response = await _dio.get<List<int>>(
        imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      final data = response.data;
      if (data == null || data.isEmpty) {
        _showMessage('图片下载失败');
        return;
      }

      await Gal.putImageBytes(
        Uint8List.fromList(data),
        name: _buildImageName(imageUrl),
      );
      _showMessage('已保存到相册');
    } catch (e) {
      _showMessage('保存失败: $e');
    }
  }

  String _buildImageName(String imageUrl) {
    final uri = Uri.tryParse(imageUrl);
    final lastSegment = uri?.pathSegments.isNotEmpty == true
        ? uri!.pathSegments.last
        : null;
    final fileName = (lastSegment == null || lastSegment.isEmpty)
        ? 'topic_${DateTime.now().millisecondsSinceEpoch}.jpg'
        : lastSegment;
    return fileName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
          if (_overlayOpacity == nextOpacity) return;
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
                child: PhotoViewGallery.builder(
                  pageController: _pageController,
                  itemCount: widget.pictures.length,
                  backgroundDecoration: const BoxDecoration(
                    color: Colors.black,
                  ),
                  scrollPhysics: const BouncingScrollPhysics(),
                  onPageChanged: (index) {
                    if (_currentIndex == index) return;
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  builder: (context, index) {
                    final picture = widget.pictures[index];
                    return PhotoViewGalleryPageOptions(
                      imageProvider: NetworkImage(_imageUrlOf(picture)),
                      minScale: PhotoViewComputedScale.contained,
                      initialScale: PhotoViewComputedScale.contained,
                      maxScale: PhotoViewComputedScale.covered * 4,
                      tightMode: true,
                      onTapUp: (context, details, controllerValue) {
                        Navigator.of(context).maybePop();
                      },
                      heroAttributes: PhotoViewHeroAttributes(
                        tag: picture.heroTag,
                      ),
                    );
                  },
                ),
              ),
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onLongPress: _showImageActions,
                  child: const SizedBox.expand(),
                ),
              ),
              Positioned(
                top: MediaQuery.paddingOf(context).top + 8,
                left: 16,
                right: 16,
                child: _PreviewTopBar(
                  opacity: _overlayOpacity,
                  currentIndex: _currentIndex,
                  total: widget.pictures.length,
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

class _PreviewTopBar extends StatelessWidget {
  const _PreviewTopBar({
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
