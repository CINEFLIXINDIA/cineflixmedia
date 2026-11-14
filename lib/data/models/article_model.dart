import '../../core/constants/app_constants.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/html_cleaner.dart';
import 'category_model.dart';

class ArticleModel {
  final int id;
  final String title;
  final String slug;
  final String? description;
  final String? content;
  final String? image;
  final List<CategoryModel> categories;
  final List<String> tags;
  final String? createdAt;
  final String? updatedAt;
  final String? author;
  final String? sourceName;
  final String? originalUrl;
  final String status;
  final int views;
  final int commentsCount;
  final double averageRating;
  final int totalRatings;
  final int? userRating;

  const ArticleModel({
    required this.id,
    required this.title,
    required this.slug,
    this.description,
    this.content,
    this.image,
    this.categories = const [],
    this.tags = const [],
    this.createdAt,
    this.updatedAt,
    this.author,
    this.sourceName,
    this.originalUrl,
    this.status = 'published',
    this.views = 0,
    this.commentsCount = 0,
    this.averageRating = 0.0,
    this.totalRatings = 0,
    this.userRating,
  });

  /// Normalizes image URL to always be fully qualified
  static String? _normalizeImageUrl(dynamic rawImage) {
    if (rawImage == null) return null;
    final str = rawImage.toString().trim();
    if (str.isEmpty) return null;

    if (str.startsWith('http://') || str.startsWith('https://')) {
      return str;
    }
    if (str.startsWith('/storage/')) {
      return '${AppConstants.websiteUrl}$str';
    }
    if (str.startsWith('storage/')) {
      return '${AppConstants.websiteUrl}/$str';
    }
    return '${AppConstants.mediaBaseUrl}$str';
  }

  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    int id = 0;
    if (json['id'] is int) {
      id = json['id'];
    } else if (json['id'] != null) {
      id = int.tryParse(json['id'].toString()) ?? 0;
    }

    // Title can be in 'name' or 'title'
    String title = json['name']?.toString() ?? json['title']?.toString() ?? '';

    // Slug
    String slug = json['slug']?.toString() ?? '';
    if (slug.isEmpty && json['slugable'] is Map) {
      slug = json['slugable']['key']?.toString() ?? '';
    }

    // Categories
    final categoriesList = <CategoryModel>[];
    if (json['categories'] is List) {
      for (var cat in json['categories']) {
        if (cat is Map<String, dynamic>) {
          categoriesList.add(CategoryModel.fromJson(cat));
        }
      }
    }

    // Tags
    final tagsList = <String>[];
    if (json['tags'] is List) {
      for (var tag in json['tags']) {
        if (tag is Map && tag['name'] != null) {
          tagsList.add(tag['name'].toString());
        } else if (tag is String) {
          tagsList.add(tag);
        }
      }
    }

    // Author
    String? authorName;
    if (json['author'] is Map && json['author']['name'] != null) {
      authorName = json['author']['name'].toString();
    } else if (json['author_name'] != null) {
      authorName = json['author_name'].toString();
    } else if (json['author'] is String) {
      authorName = json['author'].toString();
    }
    if (authorName == null || authorName.trim().isEmpty || authorName == 'null') {
      authorName = AppConstants.defaultAuthor;
    }

    // Source Attribution (Google Play News Policy Compliance)
    String? sourceName;
    if (json['source_name'] != null &&
        json['source_name'].toString().trim().isNotEmpty) {
      sourceName = json['source_name'].toString().trim();
    } else if (json['original_source'] != null &&
        json['original_source'].toString().trim().isNotEmpty) {
      sourceName = json['original_source'].toString().trim();
    } else if (json['attribution'] is Map &&
        json['attribution']['source_name'] != null) {
      sourceName = json['attribution']['source_name'].toString().trim();
    } else if (json['source'] is String &&
        json['source'].toString().trim().isNotEmpty) {
      sourceName = json['source'].toString().trim();
    }

    String? originalUrl = json['original_url']?.toString();
    if (originalUrl == null && json['attribution'] is Map) {
      originalUrl = json['attribution']['original_url']?.toString();
    }

    int commentsCount = 0;
    if (json['comments_count'] is int) {
      commentsCount = json['comments_count'];
    } else if (json['comments_count'] != null) {
      commentsCount = int.tryParse(json['comments_count'].toString()) ?? 0;
    }

    double averageRating = 0.0;
    if (json['average_rating'] is num) {
      averageRating = (json['average_rating'] as num).toDouble();
    } else if (json['average_rating'] != null) {
      averageRating =
          double.tryParse(json['average_rating'].toString()) ?? 0.0;
    }

    int totalRatings = 0;
    if (json['total_ratings'] is int) {
      totalRatings = json['total_ratings'];
    } else if (json['total_ratings'] != null) {
      totalRatings = int.tryParse(json['total_ratings'].toString()) ?? 0;
    }

    int? userRating;
    if (json['user_rating'] is int) {
      userRating = json['user_rating'];
    } else if (json['user_rating'] != null) {
      userRating = int.tryParse(json['user_rating'].toString());
    }

    return ArticleModel(
      id: id,
      title: title,
      slug: slug,
      description: json['description']?.toString(),
      content: json['content']?.toString(),
      image: _normalizeImageUrl(json['image']),
      categories: categoriesList,
      tags: tagsList,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      author: authorName,
      sourceName: sourceName,
      originalUrl: originalUrl,
      status: json['status']?.toString() ?? 'published',
      views: int.tryParse(json['views']?.toString() ?? '0') ?? 0,
      commentsCount: commentsCount,
      averageRating: averageRating,
      totalRatings: totalRatings,
      userRating: userRating,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': title,
      'title': title,
      'slug': slug,
      'status': status,
      'description': description,
      'content': content,
      'image': image,
      'categories': categories.map((c) => c.toJson()).toList(),
      'tags': tags,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'author': author,
      'source_name': sourceName,
      'original_source': sourceName,
      'original_url': originalUrl,
      'views': views,
      'comments_count': commentsCount,
      'average_rating': averageRating,
      'total_ratings': totalRatings,
      'user_rating': userRating,
    };
  }

  // Helper Getters
  String get primaryCategoryName {
    if (categories.isNotEmpty) {
      return categories.first.name;
    }
    return 'Entertainment';
  }

  int? get primaryCategoryId {
    if (categories.isNotEmpty) {
      return categories.first.id;
    }
    return null;
  }

  String get timeAgo => DateFormatter.timeAgo(createdAt);

  String get formattedDate => DateFormatter.formatFullDate(createdAt);

  int get readingTimeMinutes =>
      HtmlCleaner.estimateReadingTime(content ?? description);

  String get formattedViews {
    if (views >= 1000000) return '${(views / 1000000).toStringAsFixed(1)}M';
    if (views >= 1000) return '${(views / 1000).toStringAsFixed(1)}K';
    return views.toString();
  }

  String get cleanSummary {
    if (description != null && description!.trim().isNotEmpty) {
      return HtmlCleaner.stripHtml(description);
    }
    return HtmlCleaner.stripHtml(content);
  }

  String get webUrl => '${AppConstants.websiteUrl}/blog/$slug';

  String get appDeepLink => Uri(
    scheme: 'cineflix',
    host: 'post',
    queryParameters: {'slug': slug},
  ).toString();

  /// Checks whether this article originated from an auto-imported or 3rd-party source
  bool get isThirdPartySource =>
      sourceName != null && sourceName!.trim().isNotEmpty;

  /// Alias for sourceName (nullable for original in-house articles)
  String? get originalSource => sourceName;

  /// Formatted source attribution string compliant with Google Play News policy
  String? get sourceAttribution =>
      isThirdPartySource ? 'Source: ${sourceName!.trim()}' : null;

  /// Primary display author string based on attribution logic
  String get displayAuthor {
    if (isThirdPartySource) {
      return 'Source: ${sourceName!.trim()}';
    }
    if (author != null && author!.trim().isNotEmpty && author != 'null') {
      return author!.trim();
    }
    return AppConstants.defaultAuthor;
  }

  ArticleModel copyWith({
    int? id,
    String? title,
    String? slug,
    String? description,
    String? content,
    String? image,
    List<CategoryModel>? categories,
    List<String>? tags,
    String? createdAt,
    String? updatedAt,
    String? author,
    String? sourceName,
    String? originalUrl,
    String? status,
    int? views,
    int? commentsCount,
    double? averageRating,
    int? totalRatings,
    int? userRating,
  }) {
    return ArticleModel(
      id: id ?? this.id,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      content: content ?? this.content,
      image: image ?? this.image,
      categories: categories ?? this.categories,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      author: author ?? this.author,
      sourceName: sourceName ?? this.sourceName,
      originalUrl: originalUrl ?? this.originalUrl,
      status: status ?? this.status,
      views: views ?? this.views,
      commentsCount: commentsCount ?? this.commentsCount,
      averageRating: averageRating ?? this.averageRating,
      totalRatings: totalRatings ?? this.totalRatings,
      userRating: userRating ?? this.userRating,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArticleModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
