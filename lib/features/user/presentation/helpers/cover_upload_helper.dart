import 'dart:io';
import 'dart:math';

import 'package:all_flutter0709/core/cloud_storage/cloud_storage_service.dart';
import 'package:all_flutter0709/features/common/helpers/album_image_pick_helper.dart';
import 'package:all_flutter0709/features/common/helpers/square_jpeg_fit.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

/// 自定义封面：相册选图、裁成正方形，再上传到当前对象存储。
class CoverUploadHelper {
  CoverUploadHelper({
    required CloudStorageService cloudStorageService,
    ImagePicker? imagePicker,
  }) : _cloudStorageService = cloudStorageService,
       _imagePicker = imagePicker ?? ImagePicker();

  final CloudStorageService _cloudStorageService;
  final ImagePicker _imagePicker;
  final Random _random = Random();

  /// 从相册选一张图并裁成正方形，最长边 1024，体积压到 300KB 以内。取消时返回 null。
  Future<File?> pickAndCrop(BuildContext context) async {
    final File? sourceFile;
    if (Platform.isAndroid) {
      sourceFile = await const AlbumImagePickHelper().pickImage(
        context: context,
      );
    } else {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      sourceFile = pickedFile == null ? null : File(pickedFile.path);
    }
    if (sourceFile == null) {
      return null;
    }

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: sourceFile.path,
      maxWidth: SquareJpegFit.edge,
      maxHeight: SquareJpegFit.edge,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 80,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '裁剪封面',
          toolbarColor: Colors.black,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          aspectRatioPresets: const [CropAspectRatioPreset.square],
          cropStyle: CropStyle.rectangle,
        ),
        IOSUiSettings(
          title: '裁剪封面',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
          aspectRatioPickerButtonHidden: true,
          aspectRatioPresets: const [CropAspectRatioPreset.square],
          cropStyle: CropStyle.rectangle,
        ),
      ],
    );
    if (croppedFile == null) {
      return null;
    }
    return SquareJpegFit.fit(File(croppedFile.path));
  }

  /// 上传自定义封面，返回写入 `user.cover` 的文件名。
  Future<String> upload(File file) {
    return _cloudStorageService.uploadFile(file: file, key: _buildKey());
  }

  /// 封面文件名：`cover-{yyyyMMddHHmmss}-{0~9999}.jpg`。
  String _buildKey() {
    final time = DateFormat('yyyyMMddHHmmss').format(DateTime.now());
    final suffix = _random.nextInt(10000);
    return 'cover-$time-$suffix.jpg';
  }
}
