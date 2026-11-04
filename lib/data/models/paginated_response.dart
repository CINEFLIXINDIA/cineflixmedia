class PaginatedResponse<T> {
  final List<T> data;
  final int currentPage;
  final int lastPage;
  final int total;
  final bool hasMore;

  const PaginatedResponse({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.hasMore,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemParser,
  ) {
    List<T> items = [];
    int currentPage = 1;
    int lastPage = 1;
    int total = 0;

    // Check if json['data'] is a List (standard Botble API collection response)
    if (json['data'] is List) {
      for (var item in json['data']) {
        if (item is Map<String, dynamic>) {
          try {
            items.add(itemParser(item));
          } catch (_) {}
        }
      }
      if (json['meta'] is Map) {
        final meta = json['meta'] as Map;
        currentPage = int.tryParse(meta['current_page']?.toString() ?? '1') ?? 1;
        lastPage = int.tryParse(meta['last_page']?.toString() ?? '1') ?? 1;
        total = int.tryParse(meta['total']?.toString() ?? '0') ?? items.length;
      }
    }
    // Check if json['data'] is a Map containing 'items' (Botble search response)
    else if (json['data'] is Map) {
      final dataMap = json['data'] as Map;
      if (dataMap['items'] is Map) {
        final itemsMap = dataMap['items'] as Map;
        if (itemsMap['data'] is List) {
          for (var item in itemsMap['data']) {
            if (item is Map<String, dynamic>) {
              try {
                items.add(itemParser(item));
              } catch (_) {}
            }
          }
        }
        currentPage = int.tryParse(itemsMap['current_page']?.toString() ?? '1') ?? 1;
        lastPage = int.tryParse(itemsMap['last_page']?.toString() ?? '1') ?? 1;
        total = int.tryParse(itemsMap['total']?.toString() ?? '0') ?? items.length;
      } else if (dataMap['items'] is List) {
        for (var item in dataMap['items']) {
          if (item is Map<String, dynamic>) {
            try {
              items.add(itemParser(item));
            } catch (_) {}
          }
        }
        total = items.length;
        lastPage = 1;
      }
    }

    final hasMore = currentPage < lastPage;

    return PaginatedResponse<T>(
      data: items,
      currentPage: currentPage,
      lastPage: lastPage,
      total: total,
      hasMore: hasMore,
    );
  }
}

