import 'package:all_flutter0709/core/bridge/native_channel.dart';
import 'package:all_flutter0709/core/bridge/native_methods.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Flutter → Native 业务 API（页面禁止直接碰 MethodChannel）。
class NativeBridge {
  NativeBridge._();

  static final NativeBridge instance = NativeBridge._();

  final MethodChannel _channel = NativeChannel.instance.method;

  /// 连通性探测：期望原生返回 `"pong"`。
  Future<String> ping() async {
    final result = await call<String>(api: NativeApis.ping);
    return result ?? '';
  }

  /// 拉取原生侧设备信息。
  Future<Map<String, dynamic>> getDeviceInfo() async {
    final result = await call<Map<Object?, Object?>>(
      api: NativeApis.getDeviceInfo,
    );
    if (result == null) {
      return const <String, dynamic>{};
    }
    return Map<String, dynamic>.from(
      result.map((key, value) => MapEntry('$key', value)),
    );
  }

  /// 请求原生推送学习事件（MethodChannel.emit + EventChannel 各一条）。
  Future<bool> requestEmitDemo() async {
    final result = await call<bool>(api: NativeApis.emitDemo);
    return result == true;
  }

  /// 通用 `call`：payload 带 `v: 1`，与文档协议一致。
  Future<T?> call<T>({
    required String api,
    Map<String, dynamic>? args,
  }) async {
    try {
      final raw = await _channel.invokeMethod<dynamic>(
        NativeMethods.call,
        <String, dynamic>{
          'v': 1,
          'api': api,
          'args': ?args,
        },
      );
      return raw as T?;
    } on MissingPluginException catch (error, stackTrace) {
      debugPrint('[NativeBridge] MissingPluginException: $error\n$stackTrace');
      rethrow;
    } on PlatformException catch (error, stackTrace) {
      debugPrint('[NativeBridge] PlatformException: $error\n$stackTrace');
      rethrow;
    }
  }
}
