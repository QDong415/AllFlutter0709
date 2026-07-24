/// 一条来自原生的事件（MethodChannel.emit 或 EventChannel）。
class NativeEventModel {
  const NativeEventModel({
    required this.event,
    required this.source,
    this.version = 1,
    this.data,
  });

  /// 从 Channel 原始 Map 解析；失败返回 null。
  static NativeEventModel? tryParse(
    dynamic raw, {
    required String source,
  }) {
    if (raw is! Map) {
      return null;
    }
    final map = Map<Object?, Object?>.from(raw);
    final event = map['event']?.toString();
    if (event == null || event.isEmpty) {
      return null;
    }
    final version = map['v'];
    final dataRaw = map['data'];
    return NativeEventModel(
      event: event,
      source: source,
      version: version is int ? version : 1,
      data: dataRaw is Map
          ? Map<String, dynamic>.from(
              dataRaw.map((key, value) => MapEntry('$key', value)),
            )
          : null,
    );
  }

  /// 协议版本。
  final int version;

  /// 事件名，例如 [NativeEventNames.demoTick]。
  final String event;

  /// 来源标识：`method` 或 `eventChannel`。
  final String source;

  /// 可选业务数据。
  final Map<String, dynamic>? data;

  @override
  String toString() {
    return 'NativeEventModel(v=$version, event=$event, source=$source, data=$data)';
  }
}
