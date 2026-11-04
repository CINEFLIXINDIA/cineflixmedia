class CategoryModel {
  final int id;
  final String name;
  final String slug;
  final int order;
  final String? description;
  final String? url;
  final int? parentId;
  final List<CategoryModel> children;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.order = 0,
    this.description,
    this.url,
    this.parentId,
    this.children = const [],
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    int id = 0;
    if (json['id'] is int) {
      id = json['id'];
    } else if (json['id'] != null) {
      id = int.tryParse(json['id'].toString()) ?? 0;
    }

    int order = 0;
    if (json['order'] is int) {
      order = json['order'];
    } else if (json['order'] != null) {
      order = int.tryParse(json['order'].toString()) ?? 0;
    }

    final childrenList = <CategoryModel>[];
    if (json['children'] is List) {
      for (var item in json['children']) {
        if (item is Map<String, dynamic>) {
          childrenList.add(CategoryModel.fromJson(item));
        }
      }
    }

    return CategoryModel(
      id: id,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      order: order,
      description: json['description']?.toString(),
      url: json['url']?.toString(),
      parentId: (json['parent'] is Map && json['parent']['id'] != null)
          ? int.tryParse(json['parent']['id'].toString())
          : null,
      children: childrenList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'order': order,
      'description': description,
      'url': url,
      'parent_id': parentId,
      'children': children.map((c) => c.toJson()).toList(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

