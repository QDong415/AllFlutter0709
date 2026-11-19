import 'package:all_flutter0709/app/theme/app_palette.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';

/// 经典下拉头。浅色沿用库里的深色箭头和转圈，黑夜改成白色。
ClassicHeader appClassicHeader(BuildContext context) {
  final dark = context.palette.brightness == Brightness.dark;
  return ClassicHeader(
    showMessage: false,
    showText: false,
    iconTheme: dark ? const IconThemeData(color: Colors.white) : null,
  );
}
