class ApiResponse<T> {
  const ApiResponse({
    required this.code,
    required this.message,
    this.data,
  });

  final int code;
  final String message;
  final T? data;

  bool get success => code == 1;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json, [
    T Function(Object? json)? fromJsonT,
  ]) {
    final dataJson = json['data'];
    return ApiResponse<T>(
      code: (json['code'] as num?)?.toInt() ?? 0,
      message: json['message'] as String? ?? '',
      data: dataJson != null && fromJsonT != null ? fromJsonT(dataJson) : null,
    );
  }
}
