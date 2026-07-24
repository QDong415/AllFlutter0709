import 'dart:io';

import 'package:all_flutter0709/features/conversation/presentation/conversation_controller.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// 聊天发送：选图、读尺寸、提交文本/图片。不改 UI 状态。
class ChatSendHelper {
  ChatSendHelper({ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  /// 从相册选择图片；取消时返回 null。
  Future<File?> pickImageFile() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 92,
    );
    if (pickedFile == null) {
      return null;
    }
    return File(pickedFile.path);
  }

  /// 读取图片像素尺寸；失败时返回兜底尺寸。
  Future<Size> readImageSize(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final image = await decodeImageFromList(bytes);
      final size = Size(image.width.toDouble(), image.height.toDouble());
      image.dispose();
      return size;
    } catch (_) {
      return const Size(1080, 1439);
    }
  }

  /// 发送文本消息。
  Future<void> sendText({
    required ConversationController controller,
    required String conversationId,
    required String text,
  }) {
    return controller.sendTextMessage(
      conversationId: conversationId,
      text: text,
    );
  }

  /// 发送图片消息。
  Future<void> sendImage({
    required ConversationController controller,
    required String conversationId,
    required File imageFile,
    required Size imageSize,
  }) {
    return controller.sendImageMessage(
      conversationId: conversationId,
      imageFile: imageFile,
      imageSize: imageSize,
    );
  }
}
