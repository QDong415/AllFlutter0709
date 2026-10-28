import 'package:all_flutter0709/core/config/app_config.dart';

class ValueUtil {
  const ValueUtil._();

  /// 拼原图地址：已是 http(s) 则原样返回，否则加上 oss 前缀。
  static String? getOriginalImageUrl(String? filename) {
    final value = filename?.trim() ?? '';
    if (value.isEmpty) return null;
    if (value.startsWith('http')) {
      return value;
    }
    return '${AppConfig.instance.ossHttp}$value';
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

  /// 按当前 `OssThumbStyle` 拼文件访问地址；GIF 和 keepOriginal 不加缩略图参数。
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
      ..write(AppConfig.instance.ossHttp)
      ..write(value);

    if (keepOriginal) {
      return buffer.toString();
    }

    if (!value.toLowerCase().endsWith('.gif')) {
      buffer.write(
        AppConfig.instance.ossThumbStyle.query(
          limitPx: limitPx,
          max: max,
          thumbnail: thumbnail,
        ),
      );
    }

    return buffer.toString();
  }
}
