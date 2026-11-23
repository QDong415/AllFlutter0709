import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

/// 一次双击放大，横图覆盖屏幕、其他图片显示原始尺寸，再次双击恢复适应屏。
PhotoViewScaleState appPhotoViewScaleStateCycle(
  PhotoViewScaleState actual, {
  bool isLandscapeImage = false,
}) {
  switch (actual) {
    case PhotoViewScaleState.initial:
      return isLandscapeImage
          ? PhotoViewScaleState.covering
          : PhotoViewScaleState.originalSize;
    case PhotoViewScaleState.covering:
    case PhotoViewScaleState.originalSize:
    case PhotoViewScaleState.zoomedIn:
    case PhotoViewScaleState.zoomedOut:
      return PhotoViewScaleState.initial;
  }
}

/// 支持双指缩放、按双击点放大及缩略图 Loading 底图的图片预览组件。
class AppZoomableImage extends StatefulWidget {
  const AppZoomableImage({
    super.key,
    required this.imageProvider,
    this.placeholderImageProvider,
    this.heroTag,
    this.controller,
    this.maxScale = 4,
    this.onTap,
    this.onLongPress,
  });

  final ImageProvider imageProvider;
  final ImageProvider? placeholderImageProvider;
  final Object? heroTag;
  final PhotoViewController? controller;
  final double maxScale;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  State<AppZoomableImage> createState() => _AppZoomableImageState();
}

class _AppZoomableImageState extends State<AppZoomableImage> {
  ImageStream? _imageStream;
  ImageStreamListener? _imageStreamListener;
  bool _isImageLoaded = false;
  bool _isLandscapeImage = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveImage();
  }

  @override
  void didUpdateWidget(AppZoomableImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageProvider != oldWidget.imageProvider) {
      _resolveImage();
    }
  }

  @override
  void dispose() {
    _stopListeningToImageStream();
    super.dispose();
  }

  void _resolveImage() {
    _stopListeningToImageStream();
    _isImageLoaded = false;
    _isLandscapeImage = false;
    final imageStream = widget.imageProvider.resolve(
      createLocalImageConfiguration(context),
    );
    final imageStreamListener = ImageStreamListener((imageInfo, _) {
      final image = imageInfo.image;
      final isLandscapeImage = image.width > image.height;
      if (mounted &&
          (!_isImageLoaded || _isLandscapeImage != isLandscapeImage)) {
        setState(() {
          _isImageLoaded = true;
          _isLandscapeImage = isLandscapeImage;
        });
      }
    }, onError: (_, _) {});
    _imageStream = imageStream;
    _imageStreamListener = imageStreamListener;
    imageStream.addListener(imageStreamListener);
  }

  void _stopListeningToImageStream() {
    final imageStream = _imageStream;
    final imageStreamListener = _imageStreamListener;
    if (imageStream != null && imageStreamListener != null) {
      imageStream.removeListener(imageStreamListener);
    }
    _imageStream = null;
    _imageStreamListener = null;
  }

  Widget _buildLoading(BuildContext context, ImageChunkEvent? event) {
    final expectedBytes = event?.expectedTotalBytes;
    final loadedBytes = event?.cumulativeBytesLoaded;
    final progress =
        loadedBytes != null && expectedBytes != null && expectedBytes > 0
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
  }

  @override
  Widget build(BuildContext context) {
    final placeholderImageProvider = widget.placeholderImageProvider;
    Widget image = Stack(
      fit: StackFit.expand,
      children: [
        Visibility(
          visible: !_isImageLoaded && placeholderImageProvider != null,
          child: placeholderImageProvider == null
              ? const SizedBox.shrink()
              : Image(
                  image: placeholderImageProvider,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                  filterQuality: FilterQuality.low,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
        ),
        PhotoView(
          controller: widget.controller,
          imageProvider: widget.imageProvider,
          backgroundDecoration: const BoxDecoration(color: Colors.transparent),
          minScale: PhotoViewComputedScale.contained,
          initialScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * widget.maxScale,
          doubleTapScaleMultiplier: _isLandscapeImage ? 2 : null,
          scaleStateCycle: (scaleState) => appPhotoViewScaleStateCycle(
            scaleState,
            isLandscapeImage: _isLandscapeImage,
          ),
          loadingBuilder: _buildLoading,
          errorBuilder: (_, _, _) => const Center(
            child: Icon(Icons.broken_image_outlined, color: Colors.white54),
          ),
          filterQuality: FilterQuality.medium,
          onTapUp: widget.onTap == null
              ? null
              : (_, _, _) {
                  widget.onTap!();
                },
        ),
      ],
    );

    final heroTag = widget.heroTag;
    if (heroTag != null) {
      image = Hero(tag: heroTag, child: image);
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPress: widget.onLongPress,
      child: image,
    );
  }
}
