import 'package:all_flutter0709/core/network/app_env.dart';

class ValueUtil {
  const ValueUtil._();

  static String? getQiniuUrlByFileName(
    String? filename, {
    int limitPx = 240,
    bool max = false,
    bool keepOriginal = false,
    bool thumbnail = false,
  }) {
    final value = filename?.trim() ?? '';
    if (value.isEmpty || value.startsWith('http')) {
      return value.isEmpty ? null : value;
    }

    final buffer = StringBuffer()
      ..write(AppEnv.qiniuBaseUrl)
      ..write(value);

    if (keepOriginal) {
      return buffer.toString();
    }

    if (thumbnail && !value.toLowerCase().endsWith('.gif')) {
      buffer
        ..write('?imageView2/1/w/')
        ..write(limitPx)
        ..write('/h/')
        ..write(limitPx);
      return buffer.toString();
    }

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
