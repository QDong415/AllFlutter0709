class PageData<T> {
  const PageData({
    required this.total,
    required this.totalPage,
    this.items,
  });

  final int total;
  final int totalPage;
  final List<T>? items;

  factory PageData.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    final rawItems = json['items'] as List<dynamic>? ?? <dynamic>[];
    return PageData<T>(
      total: (json['total'] as num?)?.toInt() ?? 0,
      totalPage: (json['totalpage'] as num?)?.toInt() ?? 0,
      items: rawItems.map(fromJsonT).toList(),
    );
  }
}
