import 'package:http/http.dart' as http;
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../models/article_model.dart';
import '../models/category_model.dart';
import '../models/comment_model.dart';
import '../models/paginated_response.dart';
import '../models/rating_model.dart';

class NewsRepository {
  final ApiClient _apiClient;

  NewsRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  /// Fetches latest articles ordered by publication date descending
  Future<PaginatedResponse<ArticleModel>> getLatestNews({
    int page = 1,
    int perPage = 10,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.postsFilters,
      queryParameters: {
        'order': 'desc',
        'order_by': 'created_at',
        'page': page,
        'per_page': perPage,
      },
    );

    return PaginatedResponse<ArticleModel>.fromJson(
      response as Map<String, dynamic>,
      (item) => ArticleModel.fromJson(item),
    );
  }

  /// Fetches only articles published on the requested calendar date.
  Future<PaginatedResponse<ArticleModel>> getNewsByDate({
    required String date,
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.postsFilters,
      queryParameters: {
        'date': date,
        'order': 'desc',
        'order_by': 'created_at',
        'page': page,
        'per_page': perPage,
      },
    );

    return PaginatedResponse<ArticleModel>.fromJson(
      response as Map<String, dynamic>,
      (item) => ArticleModel.fromJson(item),
    );
  }

  /// Fetches website-driven hero articles (Single source of truth from Website Hero)
  Future<List<ArticleModel>> getFeaturedNews({int perPage = 5}) async {
    final response = await _apiClient.get(
      ApiEndpoints.postsHero,
      queryParameters: {'per_page': perPage},
    );

    final paginated = PaginatedResponse<ArticleModel>.fromJson(
      response as Map<String, dynamic>,
      (item) => ArticleModel.fromJson(item),
    );

    return paginated.data;
  }

  /// Fetches all active categories
  Future<List<CategoryModel>> getCategories() async {
    final response = await _apiClient.get(
      ApiEndpoints.categories,
      queryParameters: {'per_page': 50},
    );

    final list = <CategoryModel>[];
    if (response is Map && response['data'] is List) {
      for (var item in response['data']) {
        if (item is Map<String, dynamic>) {
          try {
            list.add(CategoryModel.fromJson(item));
          } catch (_) {}
        }
      }
    }
    return list;
  }

  /// Fetches articles for a specific category with pagination
  Future<PaginatedResponse<ArticleModel>> getNewsByCategory({
    required int categoryId,
    int page = 1,
    int perPage = 10,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.postsFilters,
      queryParameters: {
        'categories': categoryId,
        'order': 'desc',
        'order_by': 'created_at',
        'page': page,
        'per_page': perPage,
      },
    );

    return PaginatedResponse<ArticleModel>.fromJson(
      response as Map<String, dynamic>,
      (item) => ArticleModel.fromJson(item),
    );
  }

  /// Fetches full single article details by slug
  Future<ArticleModel> getArticleDetail(String slug) async {
    final response = await _apiClient.get(ApiEndpoints.postDetail(slug));

    if (response is Map && response['data'] is Map<String, dynamic>) {
      return ArticleModel.fromJson(response['data'] as Map<String, dynamic>);
    }

    throw ApiException('Article not found or empty response');
  }

  /// Fetches related articles by category, excluding the current article
  Future<List<ArticleModel>> getRelatedNews({
    required int categoryId,
    required int excludeId,
    int perPage = 4,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.postsFilters,
        queryParameters: {
          'categories': categoryId,
          'exclude': excludeId,
          'per_page': perPage,
        },
      );

      final paginated = PaginatedResponse<ArticleModel>.fromJson(
        response as Map<String, dynamic>,
        (item) => ArticleModel.fromJson(item),
      );

      return paginated.data;
    } catch (_) {
      return [];
    }
  }

  /// Searches articles with query
  Future<PaginatedResponse<ArticleModel>> searchNews({
    required String query,
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.postsFilters,
        queryParameters: {'search': query, 'page': page, 'per_page': perPage},
      );

      return PaginatedResponse<ArticleModel>.fromJson(
        response as Map<String, dynamic>,
        (item) => ArticleModel.fromJson(item),
      );
    } catch (_) {
      // Fallback to /search?q=
      final response = await _apiClient.get(
        ApiEndpoints.search,
        queryParameters: {'q': query, 'page': page},
      );

      return PaginatedResponse<ArticleModel>.fromJson(
        response as Map<String, dynamic>,
        (item) => ArticleModel.fromJson(item),
      );
    }
  }

  /// Registers device token with Botble FCM push system
  Future<bool> registerDeviceToken({
    required String token,
    required String platform,
    String? deviceId,
    String? appVersion,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.deviceTokens,
        body: {
          'token': token,
          'platform': platform,
          'device_id': deviceId ?? 'cineflix-device',
          'app_version': appVersion ?? '1.0.0',
        },
      );
      return response is Map && response['error'] == false;
    } catch (_) {
      return false;
    }
  }

  /// Fetches articles for a specific author using the authenticated API
  Future<PaginatedResponse<ArticleModel>> getAuthorPosts({
    required String token,
    String? status,
    int page = 1,
    int perPage = 10,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      if (status != null && status.isNotEmpty && status != 'all')
        'status': status,
    };

    final response = await _apiClient.get(
      ApiEndpoints.authorPosts,
      queryParameters: query,
      token: token,
    );

    return PaginatedResponse<ArticleModel>.fromJson(
      response as Map<String, dynamic>,
      (item) => ArticleModel.fromJson(item),
    );
  }

  /// Creates a new author post with optional featured image and gallery media files
  Future<ArticleModel> createAuthorPost({
    required String token,
    required String title,
    required String content,
    String? description,
    int? categoryId,
    String? status,
    String? featuredImagePath,
    List<String>? galleryPaths,
    String? mediaUrl,
    String? tags,
  }) async {
    final fields = <String, String>{
      'name': title,
      'content': content,
      if (description != null && description.isNotEmpty) 'description': description,
      if (categoryId != null) 'category_id': categoryId.toString(),
      if (status != null && status.isNotEmpty) 'status': status,
      if (mediaUrl != null && mediaUrl.isNotEmpty) 'media_url': mediaUrl,
      if (tags != null && tags.isNotEmpty) 'tags': tags,
    };

    final files = <http.MultipartFile>[];

    if (featuredImagePath != null && featuredImagePath.isNotEmpty) {
      files.add(await http.MultipartFile.fromPath('featured_image', featuredImagePath));
    }

    if (galleryPaths != null && galleryPaths.isNotEmpty) {
      for (final path in galleryPaths) {
        if (path.isNotEmpty) {
          files.add(await http.MultipartFile.fromPath('gallery_files[]', path));
        }
      }
    }

    final response = await _apiClient.postMultipart(
      ApiEndpoints.authorCreatePost,
      fields: fields,
      files: files,
      token: token,
    );

    if (response is Map<String, dynamic> && response['data'] is Map<String, dynamic>) {
      return ArticleModel.fromJson(response['data'] as Map<String, dynamic>);
    }

    throw ApiException('Failed to parse created post response');
  }

  /// Fetches comments for a post (by ID or slug)
  Future<List<CommentModel>> getComments(dynamic postId) async {
    final response = await _apiClient.get(ApiEndpoints.postComments(postId));
    final commentsList = <CommentModel>[];
    if (response is Map && response['data'] is Map) {
      final data = response['data'] as Map;
      if (data['comments'] is List) {
        for (final item in data['comments']) {
          if (item is Map) {
            try {
              commentsList.add(
                CommentModel.fromJson(Map<String, dynamic>.from(item)),
              );
            } catch (_) {}
          }
        }
      }
    }
    return commentsList;
  }

  /// Posts a new comment (requires auth token)
  Future<CommentModel> addComment(
    dynamic postId,
    String content, {
    required String token,
    int? replyTo,
  }) async {
    final Map<String, dynamic> body = {'content': content};
    if (replyTo != null) {
      body['reply_to'] = replyTo;
    }
    final response = await _apiClient.post(
      ApiEndpoints.postComments(postId),
      body: body,
      token: token,
    );

    if (response is Map && response['data'] is Map) {
      final dataMap = response['data'] as Map;
      if (dataMap['comment'] is Map) {
        return CommentModel.fromJson(
          Map<String, dynamic>.from(dataMap['comment'] as Map),
        );
      }
    }
    throw ApiException('Failed to post comment');
  }

  /// Fetches ratings for a post
  Future<RatingModel> getRatings(dynamic postId, {String? token}) async {
    final response = await _apiClient.get(
      ApiEndpoints.postRatings(postId),
      token: token,
    );
    if (response is Map && response['data'] is Map) {
      return RatingModel.fromJson(
        Map<String, dynamic>.from(response['data'] as Map),
      );
    }
    throw ApiException('Failed to fetch ratings');
  }

  /// Submits or updates rating (requires auth token)
  Future<RatingModel> submitRating(
    dynamic postId,
    int rating, {
    required String token,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.postRatings(postId),
      body: {'rating': rating},
      token: token,
    );
    if (response is Map && response['data'] is Map) {
      return RatingModel.fromJson(
        Map<String, dynamic>.from(response['data'] as Map),
      );
    }
    throw ApiException('Failed to submit rating');
  }
}
