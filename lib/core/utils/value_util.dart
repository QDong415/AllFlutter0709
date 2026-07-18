import 'package:all_flutter0709/core/network/app_env.dart';

class ValueUtil {
  const ValueUtil._();

  static String? getQiniuUrlByFileName(
    String? filename, {
    int limitPx = 240,
    bool max = false,
  }) {
    final value = filename?.trim() ?? '';
    if (value.isEmpty || value.startsWith('http')) {
      return value.isEmpty ? null : value;
    }

    final buffer = StringBuffer()
      ..write(AppEnv.qiniuBaseUrl)
      ..write(value);

    if (!value.toLowerCase().endsWith('.gif')) {
      buffer
        ..write('?imageView2/')
        ..write(max ? 3 : 2)
        ..write('/w/')
        ..write(limitPx)
        ..write('/h/')
        ..write(limitPx);
    }

    return buffer.toString();
  }
}
