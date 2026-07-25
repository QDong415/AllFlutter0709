import 'dart:io';
import 'dart:math';

import 'package:all_flutter0709/core/qiniu/qiniu_upload_service.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

/// 注册头像：选图、1:1 裁剪、上传七牛。
class SignupAvatarHelper {
  SignupAvatarHelper({
    required QiniuUploadService qiniuUploadService,
    ImagePicker? imagePicker,
  }) : _qiniuUploadService = qiniuUploadService,
       _imagePicker = imagePicker ?? ImagePicker();

  final QiniuUploadService _qiniuUploadService;
  final ImagePicker _imagePicker;
  final Random _random = Random();

  /// 从相册选图并裁剪为 1:1，返回本地文件；取消则返回 null。
  Future<File?> pickAndCropAvatar() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (pickedFile == null) {
      return null;
    }

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 90,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '裁剪头像',
          toolbarColor: Colors.black,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          aspectRatioPresets: const [CropAspectRatioPreset.square],
          cropStyle: CropStyle.circle,
        ),
        IOSUiSettings(
          title: '裁剪头像',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
          aspectRatioPickerButtonHidden: true,
          aspectRatioPresets: const [CropAspectRatioPreset.square],
          cropStyle: CropStyle.circle,
        ),
      ],
    );
    if (croppedFile == null) {
      return null;
    }
    return File(croppedFile.path);
  }

  /// 上传头像到七牛，返回服务端可用的 filename。
  Future<String> uploadAvatar(File file) {
    return _qiniuUploadService.uploadFile(file: file, key: _buildAvatarKey());
  }

  /// 对齐 iTopicX：`user-{yyyyMMddHHmmss}-{0~9999}`。
  String _buildAvatarKey() {
    final time = DateFormat('yyyyMMddHHmmss').format(DateTime.now());
    final suffix = _random.nextInt(10000);
    return 'user-$time-$suffix';
  }
}
