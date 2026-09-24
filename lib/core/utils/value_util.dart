import 'package:all_flutter0709/core/network/app_env.dart';

class ValueUtil {
  const ValueUtil._();

  static String? getOriginalImageUrl(String? filename) {
    final value = filename?.trim() ?? '';
    if (value.isEmpty) return null;

    final original = value.startsWith('http')
        ? value
        : '${AppEnv.qiniuBaseUrl}$value';

    return _stripImageProcessQuery(original);
  }

  /// 相对时间，对齐 Android `getTimeStringFromNow`：一天内显示 HH:mm，否则 yyyy-MM-dd。
  static String getTimeStringFromNow(int timestamp) {
    if (timestamp <= 0) {
      return '';
    }
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final gapSeconds = DateTime.now().difference(date).inSeconds;
    if (gapSeconds > 24 * 60 * 60) {
      final month = date.month.toString().padLeft(2, '0');
      final day = date.day.toString().padLeft(2, '0');
      return '${date.year}-$month-$day';
    }
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

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

  static String _stripImageProcessQuery(String url) {
    final markerIndex = url.indexOf('?image');
    if (markerIndex >= 0) {
      return url.substring(0, markerIndex);
    }
    return url;
  }
}
