/// One page of results from a Laravel paginated endpoint.
class Paginated<T> {
  const Paginated({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    int? total,
  }) : total = total ?? items.length;

  final List<T> items;
  final int currentPage;
  final int lastPage;

  /// Total matching rows across all pages.
  final int total;

  bool get hasMore => currentPage < lastPage;

  factory Paginated.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemFromJson,
  ) {
    final meta = json['meta'] as Map<String, dynamic>;
    return Paginated(
      items: [
        for (final item in json['data'] as List)
          itemFromJson(item as Map<String, dynamic>),
      ],
      currentPage: meta['current_page'] as int,
      lastPage: meta['last_page'] as int,
      total: meta['total'] as int?,
    );
  }
}
