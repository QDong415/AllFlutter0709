import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:all_flutter0709/core/cloud_storage/cloud_storage_service.dart';
import 'package:all_flutter0709/core/cloud_storage/cloud_storage_upload_result.dart';
import 'package:all_flutter0709/core/config/app_config.dart';
import 'package:all_flutter0709/core/qiniu/qiniu_upload_service.dart';
import 'package:all_flutter0709/features/topic/data/models/topic_submit_media_model.dart';
import 'package:all_flutter0709/features/topic/data/topic_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:qiniu_flutter_sdk/qiniu_flutter_sdk.dart';
import 'package:video_player/video_player.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

/// 发布动态全局控制器。
final topicPublishControllerProvider = Provider<TopicPublishController>((ref) {
  final controller = TopicPublishController(
    cloudStorageService: ref.watch(cloudStorageServiceProvider),
    topicRepository: const TopicRepository(),
  );
  ref.onDispose(controller.dispose);
  return controller;
});

/// 发布流程阶段。
enum TopicPublishPhase { idle, uploading, failed }

/// 对齐 Android `HomeManager`：提交页立刻关闭，列表顶栏展示上传 / 失败重试。
class TopicPublishController extends ChangeNotifier {
  TopicPublishController({
    required CloudStorageService cloudStorageService,
    required TopicRepository topicRepository,
  }) : _cloudStorageService = cloudStorageService,
       _topicRepository = topicRepository;

  /// 媒体全部传完后的进度上限；`/topic/submit` 成功才到 1。
  static const Duration _successHideDelay = Duration(milliseconds: 400);

  final CloudStorageService _cloudStorageService;
  final TopicRepository _topicRepository;
  final Random _random = Random();
  final _TopicUploadProgress _uploadProgress = _TopicUploadProgress();
  final List<PutController> _putControllerList = <PutController>[];
  final List<CancelToken> _s3CancelTokens = <CancelToken>[];

  TopicPublishPhase _phase = TopicPublishPhase.idle;
  double _progress = 0;
  String _statusText = '';
  File? _coverFile;
  bool _coverIsVideo = false;
  AssetEntity? _coverAsset;
  bool _shouldRefreshList = false;
  bool _cancelled = false;
  bool _disposed = false;
  Map<String, dynamic>? _lastParamsMap;
  List<TopicSubmitMediaModel>? _lastMediaList;

  TopicPublishPhase get phase => _phase;

  /// 0~1，上传阶段最高 [_TopicUploadProgress.progressCap]。
  double get progress => _progress;

  String get statusText => _statusText;

  File? get coverFile => _coverFile;

  bool get coverIsVideo => _coverIsVideo;

  /// 上传条封面用的相册资源。
  AssetEntity? get coverAsset => _coverAsset;

  bool get isVisible => _phase != TopicPublishPhase.idle;

  bool get isBusy => _phase == TopicPublishPhase.uploading;

  bool get isFailed => _phase == TopicPublishPhase.failed;

  bool get canRetry => isFailed;

  bool get shouldRefreshList => _shouldRefreshList;

  /// 开始发布；调用方应随即关闭提交页。
  Future<void> publish({
    required String content,
    required String atUserIds,
    required List<TopicSubmitMediaModel> mediaList,
  }) async {
    late final List<TopicSubmitMediaModel> persistedList;
    try {
      persistedList = _persistMediaSync(mediaList);
    } catch (error) {
      _phase = TopicPublishPhase.failed;
      _statusText = _formatError(error);
      _notify();
      return;
    }
    final paramsMap = _buildSubmitParams(
      content: content,
      atUserIds: atUserIds,
    );
    _lastParamsMap = Map<String, dynamic>.from(paramsMap);
    _lastMediaList = persistedList;
    await _runPublish(paramsMap, persistedList);
  }

  /// 失败后按上次文案 / 媒体重试（会重新上传）。
  Future<bool> retry() async {
    if (!canRetry) {
      return false;
    }
    final paramsMap = _lastParamsMap;
    final mediaList = _lastMediaList;
    if (paramsMap == null) {
      hide();
      return false;
    }
    await _runPublish(
      Map<String, dynamic>.from(paramsMap),
      mediaList == null
          ? const <TopicSubmitMediaModel>[]
          : List<TopicSubmitMediaModel>.from(mediaList),
    );
    return true;
  }

  void cancel() {
    _cancelled = true;
    _uploadProgress.stop();
    _cancelUploads();
    hide();
  }

  void markListRefreshed() {
    _shouldRefreshList = false;
  }

  void hide() {
    _uploadProgress.stop();
    _phase = TopicPublishPhase.idle;
    _progress = 0;
    _statusText = '';
    _coverFile = null;
    _coverIsVideo = false;
    _coverAsset = null;
    _notify();
  }

  Future<void> _runPublish(
    Map<String, dynamic> paramsMap,
    List<TopicSubmitMediaModel> mediaList,
  ) async {
    _cancelled = false;
    _cancelUploads();
    _phase = TopicPublishPhase.uploading;
    _progress = 0;
    _statusText = mediaList.isEmpty ? '正在发布' : '正在上传';
    _coverFile = mediaList.isEmpty ? null : mediaList.first.file;
    _coverIsVideo = mediaList.isNotEmpty && mediaList.first.isVideo;
    _coverAsset = mediaList.isEmpty ? null : mediaList.first.asset;
    _shouldRefreshList = false;
    _notify();

    try {
      if (mediaList.isNotEmpty && mediaList.first.isVideo) {
        await _uploadVideo(paramsMap, mediaList.first);
      } else if (mediaList.isNotEmpty) {
        await _uploadImages(paramsMap, mediaList);
      }
      if (_cancelled) {
        return;
      }
      if (mediaList.isNotEmpty && !_hasUploadedMedia(paramsMap)) {
        throw Exception('媒体上传未完成，已取消发布');
      }

      _uploadProgress.stop();
      _statusText = '正在发布';
      _progress = _progress < _TopicUploadProgress.progressCap
          ? _TopicUploadProgress.progressCap
          : _progress;
      _notify();

      final topicId = await _topicRepository.submitTopic(params: paramsMap);
      if (_cancelled) {
        return;
      }
      debugPrint('[TopicPublish] 发布成功 tid=$topicId');

      _lastParamsMap = null;
      _lastMediaList = null;
      _progress = 1;
      _statusText = '上传成功';
      _shouldRefreshList = true;
      _notify();
      await Future<void>.delayed(_successHideDelay);
      if (_cancelled || _disposed) {
        return;
      }
      hide();
    } catch (error, stackTrace) {
      debugPrint('[TopicPublish] 发布失败: $error');
      debugPrint('$stackTrace');
      _uploadProgress.stop();
      if (error is CloudStorageUploadCancelled || _cancelled || _disposed) {
        return;
      }
      _phase = TopicPublishPhase.failed;
      _statusText = _formatError(error);
      _notify();
    }
  }

  Future<void> _uploadVideo(
    Map<String, dynamic> paramsMap,
    TopicSubmitMediaModel mediaModel,
  ) async {
    debugPrint('[TopicPublish] 开始上传视频 ${mediaModel.file.path}');
    final useS3 = AppConfig.instance.cloudStorage == CloudStorage.s3;
    String? token;
    if (!useS3) {
      token = await _cloudStorageService.fetchQiniuUploadToken(
        api: QiniuUploadService.topicVideoTokenApi,
        queryParameters: const <String, dynamic>{
          'callback': 'videotopiccompress',
        },
      );
      if (_cancelled) {
        return;
      }
    }

    final result = await _uploadInSlot(
      file: mediaModel.file,
      token: token,
      keyIndex: 0,
      slotIndex: 0,
      slotTotal: 1,
    );
    if (_cancelled) {
      return;
    }

    var rawWidth = result.widthText;
    var rawHeight = result.heightText;
    if (useS3 || !result.hasSize) {
      final localSize = await _readVideoSize(mediaModel.file);
      if (localSize != null) {
        rawWidth = '${localSize.$1}';
        rawHeight = '${localSize.$2}';
      }
    }
    final rotate = result.rawData['rotate']?.toString() ?? '';
    final isRotate = !useS3 && (rotate == '90' || rotate == '270');
    paramsMap['videourl'] = result.key;
    paramsMap['width'] = isRotate ? rawHeight : rawWidth;
    paramsMap['height'] = isRotate ? rawWidth : rawHeight;
    paramsMap.remove('photoarray');
    debugPrint(
      '[TopicPublish] 视频上传完成 key=${result.key} '
      'w=${paramsMap['width']} h=${paramsMap['height']}',
    );
  }

  Future<void> _uploadImages(
    Map<String, dynamic> paramsMap,
    List<TopicSubmitMediaModel> mediaList,
  ) async {
    debugPrint('[TopicPublish] 开始上传图片 count=${mediaList.length}');
    String? token;
    if (AppConfig.instance.cloudStorage != CloudStorage.s3) {
      token = await _cloudStorageService.fetchQiniuUploadToken();
      if (_cancelled) {
        return;
      }
    }

    try {
      final photoJsonList = <Map<String, String>>[];
      for (var index = 0; index < mediaList.length; index++) {
        if (_cancelled) {
          return;
        }
        final mediaModel = mediaList[index];
        final result = await _uploadInSlot(
          file: mediaModel.file,
          token: token,
          keyIndex: index,
          slotIndex: index,
          slotTotal: mediaList.length,
        );
        if (_cancelled) {
          return;
        }

        (int, int)? fallbackSize;
        if (!result.hasSize) {
          fallbackSize = await _readImageSize(mediaModel.file);
        }
        photoJsonList.add(result.toTopicPhotoJson(fallbackSize: fallbackSize));
      }
      paramsMap['photoarray'] = jsonEncode(photoJsonList);
      paramsMap.remove('videourl');
      debugPrint(
        '[TopicPublish] 图片上传完成 count=${photoJsonList.length} '
        'photoarray=${paramsMap['photoarray']}',
      );
    } catch (_) {
      _uploadProgress.stop();
      _cancelUploads();
      rethrow;
    }
  }

  Future<CloudStorageUploadResult> _uploadInSlot({
    required File file,
    String? token,
    required int keyIndex,
    required int slotIndex,
    required int slotTotal,
  }) async {
    final fileLength = file.lengthSync();
    if (fileLength <= 0) {
      throw Exception('上传文件无效: ${file.path}');
    }
    _uploadProgress.startSlot(
      index: slotIndex,
      total: slotTotal,
      fileBytes: fileLength,
      onProgress: _onSlotProgress,
    );
    try {
      final result = await _uploadSingle(
        file: file,
        token: token,
        keyIndex: keyIndex,
      );
      _uploadProgress.finishSlot(onProgress: _onSlotProgress);
      return result;
    } catch (_) {
      _uploadProgress.stop();
      rethrow;
    }
  }

  void _onSlotProgress(double value) {
    if (_cancelled || _disposed) {
      return;
    }
    if (value + 0.0001 < _progress) {
      return;
    }
    _progress = value;
    _notify();
  }

  Map<String, dynamic> _buildSubmitParams({
    required String content,
    required String atUserIds,
  }) {
    return <String, dynamic>{
      'content': content,
      if (AppConfig.instance.cloudStorage != CloudStorage.s3)
        'callback': 'videotopiccompress',
      if (atUserIds.isNotEmpty) 'atuserids': atUserIds,
    };
  }

  bool _hasUploadedMedia(Map<String, dynamic> paramsMap) {
    return !_isBlank(paramsMap['photoarray']) || !_isBlank(paramsMap['videourl']);
  }

  bool _isBlank(Object? value) {
    return value == null || value.toString().trim().isEmpty;
  }

  String _formatError(Object error) {
    return error.toString().replaceFirst(RegExp(r'^Exception: '), '');
  }

  Future<CloudStorageUploadResult> _uploadSingle({
    required File file,
    String? token,
    required int keyIndex,
  }) {
    final useS3 = AppConfig.instance.cloudStorage == CloudStorage.s3;
    PutController? putController;
    CancelToken? cancelToken;
    if (useS3) {
      cancelToken = CancelToken();
      _s3CancelTokens.add(cancelToken);
    } else {
      putController = PutController();
      _putControllerList.add(putController);
    }
    return _cloudStorageService.uploadFileResult(
      file: file,
      key: _buildObjectKey(file.path, keyIndex),
      token: token,
      putController: putController,
      cancelToken: cancelToken,
      onProgress: useS3
          ? (percent) =>
                _uploadProgress.updateFilePercent(percent, _onSlotProgress)
          : null,
    );
  }

  void _cancelUploads() {
    for (final controller in _putControllerList) {
      controller.cancel();
    }
    _putControllerList.clear();
    for (final token in _s3CancelTokens) {
      if (!token.isCancelled) {
        token.cancel('cancelled');
      }
    }
    _s3CancelTokens.clear();
  }

  /// 提交页马上关闭，先把相册临时文件拷到本地，避免上传时路径失效。
  List<TopicSubmitMediaModel> _persistMediaSync(
    List<TopicSubmitMediaModel> mediaList,
  ) {
    if (mediaList.isEmpty) {
      return const <TopicSubmitMediaModel>[];
    }
    final dir = Directory(
      '${Directory.systemTemp.path}/topic_upload_${DateTime.now().millisecondsSinceEpoch}',
    );
    dir.createSync(recursive: true);
    return [
      for (var i = 0; i < mediaList.length; i++)
        _copyMediaSync(dir: dir, index: i, mediaModel: mediaList[i]),
    ];
  }

  TopicSubmitMediaModel _copyMediaSync({
    required Directory dir,
    required int index,
    required TopicSubmitMediaModel mediaModel,
  }) {
    final source = mediaModel.file;
    if (!source.existsSync() || source.lengthSync() <= 0) {
      throw Exception('选择的文件无效，请重新选择');
    }
    var ext = p.extension(source.path);
    if (ext.isEmpty) {
      ext = mediaModel.isVideo ? '.mp4' : '.jpg';
    }
    final dest = File('${dir.path}/$index$ext');
    source.copySync(dest.path);
    debugPrint(
      '[TopicPublish] 已缓存文件 ${source.path} -> ${dest.path} '
      'size=${dest.lengthSync()}',
    );
    return TopicSubmitMediaModel(
      file: dest,
      isVideo: mediaModel.isVideo,
      duration: mediaModel.duration,
      asset: mediaModel.asset,
    );
  }

  Future<(int, int)?> _readVideoSize(File file) async {
    final controller = VideoPlayerController.file(file);
    try {
      await controller.initialize();
      final size = controller.value.size;
      if (size.width <= 0 || size.height <= 0) {
        return null;
      }
      return (size.width.round(), size.height.round());
    } catch (_) {
      return null;
    } finally {
      await controller.dispose();
    }
  }

  Future<(int, int)?> _readImageSize(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final size = (image.width, image.height);
      image.dispose();
      codec.dispose();
      return size;
    } catch (_) {
      return null;
    }
  }

  String _buildObjectKey(String path, int index) {
    final time = DateFormat('yyyyMMddHHmmss').format(DateTime.now());
    var ext = p.extension(path);
    if (ext.isEmpty) {
      ext = '.png';
    }
    return 'topic-$time-$index-${_random.nextInt(10000)}$ext';
  }

  void _notify() {
    if (_disposed) {
      return;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelled = true;
    _uploadProgress.stop();
    _cancelUploads();
    super.dispose();
  }
}

/// 列表顶栏上传进度。
///
/// Flutter 七牛 SDK 走 Dio 表单直传时，`onSendProgress` 会在缓冲写满时直接报 1.0，
/// 不能当 Android `UpProgressHandler` 用。这里按「文件格」估算：
/// `progress = (index + filePercent) / total * 0.95`，文件真正传完再填满这一格。
class _TopicUploadProgress {
  static const double progressCap = 0.95;
  static const Duration _tickInterval = Duration(milliseconds: 100);
  static const int _assumedBytesPerSecond = 160 * 1024;
  static const double _minSeconds = 0.8;
  static const double _maxSeconds = 90;
  static const double _inFlightCap = 0.9;

  Timer? _timer;
  int _index = 0;
  int _total = 1;
  int _fileBytes = 0;
  DateTime? _startedAt;

  void startSlot({
    required int index,
    required int total,
    required int fileBytes,
    required void Function(double progress) onProgress,
  }) {
    stop();
    _index = index;
    _total = total <= 0 ? 1 : total;
    _fileBytes = fileBytes;
    _startedAt = DateTime.now();
    onProgress(_slotProgress(0));
    debugPrint(
      '[TopicPublish] 开始上传 ${_index + 1}/$_total size=$_fileBytes',
    );
    _timer = Timer.periodic(_tickInterval, (_) {
      onProgress(_slotProgress(_estimatedFilePercent()));
    });
  }

  void finishSlot({required void Function(double progress) onProgress}) {
    stop();
    onProgress(_slotProgress(1));
    debugPrint('[TopicPublish] 完成上传 ${_index + 1}/$_total');
  }

  void updateFilePercent(
    double filePercent,
    void Function(double progress) onProgress,
  ) {
    onProgress(_slotProgress(filePercent.clamp(0.0, _inFlightCap)));
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _startedAt = null;
  }

  double _estimatedFilePercent() {
    final startedAt = _startedAt;
    if (startedAt == null || _fileBytes <= 0) {
      return 0;
    }
    final elapsedSeconds =
        DateTime.now().difference(startedAt).inMilliseconds / 1000.0;
    final estimatedSeconds = (_fileBytes / _assumedBytesPerSecond).clamp(
      _minSeconds,
      _maxSeconds,
    );
    return (elapsedSeconds / estimatedSeconds).clamp(0.0, _inFlightCap);
  }

  double _slotProgress(double filePercent) {
    final oneCell = progressCap / _total;
    return ((oneCell * _index) + (filePercent.clamp(0.0, 1.0) * oneCell)).clamp(
      0.0,
      progressCap,
    );
  }
}
