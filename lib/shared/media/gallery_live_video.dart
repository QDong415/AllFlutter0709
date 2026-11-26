import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_player/video_player.dart';

/// 画廊里的 Live 页：循环有声，没有进度条。
///
/// 单击和图片一样，会先等双击判定结束再收回。双击按点击位置放大，手势走
/// [PhotoView.customChild]，和静图同一套。只有 [active] 为 true 时才播放。
class GalleryLiveVideo extends StatefulWidget {
  const GalleryLiveVideo({
    super.key,
    required this.coverImageProvider,
    required this.videoUrl,
    required this.active,
    this.videoPath,
    this.placeholderImageProvider,
    this.heroTag,
    this.scaleController,
    this.onTap,
    this.onLongPress,
  });

  final ImageProvider<Object> coverImageProvider;
  final ImageProvider<Object>? placeholderImageProvider;
  final String videoUrl;

  /// 本地文件优先播放。发送方沙盒里已有短视频时不用等远端。
  final String? videoPath;
  final bool active;
  final String? heroTag;
  final PhotoViewController? scaleController;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  State<GalleryLiveVideo> createState() => _GalleryLiveVideoState();
}

class _GalleryLiveVideoState extends State<GalleryLiveVideo> {
  VideoPlayerController? _controller;
  var _failed = false;
  var _startToken = 0;
  ImageStream? _coverStream;
  ImageStreamListener? _coverListener;
  ImageProvider<Object>? _resolvedCover;
  Size? _coverSize;

  @override
  void initState() {
    super.initState();
    if (widget.active) {
      unawaited(_start());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveCover();
  }

  @override
  void didUpdateWidget(GalleryLiveVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.coverImageProvider != oldWidget.coverImageProvider) {
      _resolveCover();
    }
    if (widget.videoUrl != oldWidget.videoUrl ||
        widget.videoPath != oldWidget.videoPath) {
      unawaited(_start());
      return;
    }
    if (widget.active == oldWidget.active) {
      return;
    }
    if (widget.active) {
      unawaited(_resume());
    } else {
      _pause();
    }
  }

  @override
  void dispose() {
    _startToken++;
    _stopListeningToCover();
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      unawaited(_safeDispose(controller));
    }
    super.dispose();
  }

  void _resolveCover() {
    if (_resolvedCover == widget.coverImageProvider && _coverStream != null) {
      return;
    }
    _stopListeningToCover();
    _resolvedCover = widget.coverImageProvider;
    _coverSize = null;
    final stream = widget.coverImageProvider.resolve(
      createLocalImageConfiguration(context),
    );
    final listener = ImageStreamListener((info, _) {
      final image = info.image;
      final size = Size(image.width.toDouble(), image.height.toDouble());
      if (!mounted || _coverSize == size) {
        return;
      }
      setState(() => _coverSize = size);
    }, onError: (_, _) {});
    _coverStream = stream;
    _coverListener = listener;
    stream.addListener(listener);
  }

  void _stopListeningToCover() {
    final stream = _coverStream;
    final listener = _coverListener;
    if (stream != null && listener != null) {
      stream.removeListener(listener);
    }
    _coverStream = null;
    _coverListener = null;
  }

  Future<void> _safeDispose(VideoPlayerController controller) async {
    try {
      await controller.dispose();
    } catch (_) {}
  }

  Future<void> _start() async {
    final token = ++_startToken;
    final previous = _controller;
    _controller = null;
    if (previous != null) {
      await _safeDispose(previous);
    }
    if (!mounted || token != _startToken) {
      return;
    }

    final path = widget.videoPath?.trim() ?? '';
    final localFile = path.isEmpty ? null : File(path);
    final VideoPlayerController controller;
    if (localFile != null && localFile.existsSync()) {
      controller = VideoPlayerController.file(localFile);
    } else {
      final url = widget.videoUrl.trim();
      if (url.isEmpty) {
        setState(() => _failed = true);
        return;
      }
      controller = VideoPlayerController.networkUrl(Uri.parse(url));
    }
    _controller = controller;
    try {
      await controller.initialize();
      if (!mounted || token != _startToken || _controller != controller) {
        if (_controller == controller) {
          _controller = null;
        }
        await _safeDispose(controller);
        return;
      }
      await controller.setLooping(true);
      if (widget.active) {
        await controller.play();
      }
      if (!widget.active) {
        await controller.pause();
      }
      if (mounted && token == _startToken) {
        setState(() => _failed = false);
      }
    } catch (_) {
      if (_controller == controller) {
        _controller = null;
      }
      await _safeDispose(controller);
      if (mounted && token == _startToken) {
        setState(() => _failed = true);
      }
    }
  }

  Future<void> _resume() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      await _start();
      return;
    }
    if (!widget.active) {
      return;
    }
    await controller.play();
    if (!widget.active) {
      await controller.pause();
      return;
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _pause() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    controller.pause();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final ready =
        controller != null && controller.value.isInitialized && !_failed;
    final coverSize = _coverSize;
    final frameSize =
        coverSize != null && coverSize.width > 0 && coverSize.height > 0
        ? coverSize
        : null;
    final cover = _CoverImage(
      imageProvider: widget.coverImageProvider,
      placeholderImageProvider: widget.placeholderImageProvider,
      heroTag: widget.heroTag,
      fit: BoxFit.fill,
    );
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPress: widget.onLongPress,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (frameSize != null)
            LayoutBuilder(
              builder: (context, constraints) {
                final displayed = _containSize(frameSize, constraints.biggest);
                if (displayed == Size.zero) {
                  return cover;
                }
                final landscape = frameSize.width > frameSize.height;
                return PhotoView.customChild(
                  controller: widget.scaleController,
                  child: _LiveFrame(
                    coverSize: displayed,
                    cover: cover,
                    video: ready
                        ? _FillVideo(
                            controller: controller,
                            frameSize: displayed,
                          )
                        : null,
                  ),
                  childSize: displayed,
                  backgroundDecoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  minScale: PhotoViewComputedScale.contained,
                  initialScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 4,
                  filterQuality: FilterQuality.none,
                  doubleTapScaleMultiplier: _doubleTapMultiplier(
                    landscape: landscape,
                    pixels: frameSize,
                    displayed: displayed,
                  ),
                  scaleStateCycle: _liveScaleCycle,
                  onTapUp: widget.onTap == null
                      ? null
                      : (_, _, _) {
                          widget.onTap!();
                        },
                );
              },
            )
          else
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onTap,
              onDoubleTap: _ignoreDoubleTap,
              child: _CoverImage(
                imageProvider: widget.coverImageProvider,
                placeholderImageProvider: widget.placeholderImageProvider,
                heroTag: widget.heroTag,
                fit: BoxFit.contain,
              ),
            ),
          if (!ready && !_failed && widget.active)
            const IgnorePointer(
              child: Center(
                child: SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _ignoreDoubleTap() {}
}

/// 静图在屏幕上按比例铺开后的矩形。视频拉升到同一块，不按压缩后的比例另算。
Size _containSize(Size source, Size bounds) {
  if (source.width <= 0 ||
      source.height <= 0 ||
      bounds.width <= 0 ||
      bounds.height <= 0 ||
      !bounds.width.isFinite ||
      !bounds.height.isFinite) {
    return Size.zero;
  }
  return applyBoxFit(BoxFit.contain, source, bounds).destination;
}

double _doubleTapMultiplier({
  required bool landscape,
  required Size pixels,
  required Size displayed,
}) {
  if (landscape || displayed.width <= 0) {
    return 2;
  }
  final zoom = pixels.width / displayed.width;
  return zoom > 1.05 ? zoom : 2;
}

PhotoViewScaleState _liveScaleCycle(PhotoViewScaleState actual) {
  return actual == PhotoViewScaleState.initial
      ? PhotoViewScaleState.covering
      : PhotoViewScaleState.initial;
}

class _FillVideo extends StatelessWidget {
  const _FillVideo({required this.controller, required this.frameSize});

  final VideoPlayerController controller;
  final Size frameSize;

  @override
  Widget build(BuildContext context) {
    final raw = controller.value.size;
    var width = raw.width <= 0 ? 1.0 : raw.width;
    var height = raw.height <= 0 ? 1.0 : raw.height;
    if (controller.value.rotationCorrection % 180 != 0) {
      final swapped = width;
      width = height;
      height = swapped;
    }
    final placement = videoPlacement(
      video: Size(width, height),
      frame: frameSize,
    );
    return FittedBox(
      fit: placement.fit,
      alignment: placement.alignment,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: width,
        height: height,
        child: VideoPlayer(controller),
      ),
    );
  }
}

/// 竖向视频常比静图宽一截，多出来的像素在左边，是黑边。
/// 这种时候按静图覆盖并把多余宽度从左边裁掉。横图比例接近，直接拉升铺满。
({BoxFit fit, Alignment alignment}) videoPlacement({
  required Size video,
  required Size frame,
}) {
  final canCompare =
      video.width > 0 &&
      video.height > 0 &&
      frame.width > 0 &&
      frame.height > 0;
  final portraitFrame = frame.height > frame.width;
  final videoWider =
      canCompare &&
      video.width / video.height > frame.width / frame.height + 0.01;
  if (portraitFrame && videoWider) {
    return (fit: BoxFit.cover, alignment: Alignment.centerRight);
  }
  return (fit: BoxFit.fill, alignment: Alignment.center);
}

class _LiveFrame extends StatelessWidget {
  const _LiveFrame({
    required this.coverSize,
    required this.cover,
    required this.video,
  });

  final Size coverSize;
  final Widget cover;
  final Widget? video;

  @override
  Widget build(BuildContext context) {
    final current = video;
    return SizedBox(
      width: coverSize.width,
      height: coverSize.height,
      child: Stack(
        fit: StackFit.expand,
        children: [cover, if (current != null) current],
      ),
    );
  }
}

class _CoverImage extends StatelessWidget {
  const _CoverImage({
    required this.imageProvider,
    required this.placeholderImageProvider,
    required this.heroTag,
    required this.fit,
  });

  final ImageProvider<Object> imageProvider;
  final ImageProvider<Object>? placeholderImageProvider;
  final String? heroTag;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    Widget image = Image(
      image: imageProvider,
      fit: fit,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) {
        final placeholder = placeholderImageProvider;
        if (placeholder == null) {
          return const SizedBox.shrink();
        }
        return Image(image: placeholder, fit: fit);
      },
    );
    final tag = heroTag;
    if (tag != null) {
      image = Hero(tag: tag, child: image);
    }
    return image;
  }
}
