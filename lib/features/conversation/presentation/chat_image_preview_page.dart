import 'dart:io';

import 'package:all_flutter0709/app/theme/app_system_ui.dart';
import 'package:all_flutter0709/features/conversation/presentation/models/chat_item.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dismissible_page/dismissible_page.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class ChatImagePreviewPage extends StatefulWidget {
  const ChatImagePreviewPage({
    required this.images,
    required this.initialIndex,
    super.key,
  });

  final List<ImageMessage> images;
  final int initialIndex;

  @override
  State<ChatImagePreviewPage> createState() => _ChatImagePreviewPageState();
}

class _ChatImagePreviewPageState extends State<ChatImagePreviewPage> {
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

  ImageProvider<Object> _imageProviderOf(ImageMessage item) {
    if (item.imagePath != null) {
      return FileImage(File(item.imagePath!));
    }
    return CachedNetworkImageProvider(item.imageUrl!);
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
                child: PhotoViewGallery.builder(
                  pageController: _pageController,
                  itemCount: widget.images.length,
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
                    final item = widget.images[index];
                    return PhotoViewGalleryPageOptions(
                      imageProvider: _imageProviderOf(item),
                      minScale: PhotoViewComputedScale.contained,
                      initialScale: PhotoViewComputedScale.contained,
                      maxScale: PhotoViewComputedScale.covered * 4,
                      tightMode: true,
                      onTapUp: (context, details, controllerValue) {
                        Navigator.of(context).maybePop();
                      },
                    );
                  },
                  loadingBuilder: (context, event) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  },
                ),
              ),
              Positioned(
                top: MediaQuery.paddingOf(context).top + 8,
                left: 16,
                right: 16,
                child: _ChatPreviewTopBar(
                  opacity: _overlayOpacity,
                  currentIndex: _currentIndex,
                  total: widget.images.length,
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

class _ChatPreviewTopBar extends StatelessWidget {
  const _ChatPreviewTopBar({
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
