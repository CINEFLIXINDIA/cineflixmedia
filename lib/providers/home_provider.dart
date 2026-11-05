import 'package:flutter/foundation.dart';

import '../core/services/storage_service.dart';
import '../data/models/article_model.dart';
import '../data/models/category_model.dart';
import '../data/repositories/news_repository.dart';

class HomeProvider extends ChangeNotifier {
  final NewsRepository newsRepository;
  final StorageService storageService;

  HomeProvider({required this.newsRepository, required this.storageService});

  List<ArticleModel> _breakingNews = [];
  List<ArticleModel> _featuredNews = [];
  List<CategoryModel> _categories = [];
  List<ArticleModel> _latestNews = [];
  Map<int, List<ArticleModel>> _categoryNews = {};

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isRefreshing = false;
  String? _errorMessage;
  bool _isOffline = false;

  int _currentPage = 1;
  bool _hasMore = true;

  // Getters
  List<ArticleModel> get breakingNews => _breakingNews;
  List<ArticleModel> get featuredNews => _featuredNews;
  List<CategoryModel> get categories => _categories;
  List<ArticleModel> get latestNews => _latestNews;
  Map<int, List<ArticleModel>> get categoryNews => _categoryNews;

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isRefreshing => _isRefreshing;
  String? get errorMessage => _errorMessage;
  bool get isOffline => _isOffline;
  bool get hasMore => _hasMore;

  Future<void> fetchHomeData() async {
    _isLoading = true;
    _errorMessage = null;
    _isOffline = false;
    notifyListeners();

    try {
      // Parallel fetch for speed
      final results = await Future.wait([
        newsRepository.getLatestNews(page: 1, perPage: 12),
        newsRepository.getFeaturedNews(perPage: 6),
        newsRepository.getCategories(),
      ]);

      final latestPaginated = results[0] as dynamic;
      _latestNews = latestPaginated.data;
      _hasMore = latestPaginated.hasMore;
      _currentPage = 1;

      // Breaking news from top 5 latest
      _breakingNews = _latestNews.take(5).toList();

      final featured = results[1] as List<ArticleModel>;
      // Website Hero is single source of truth - direct assignment
      _featuredNews = featured;

      final fetchedCategories = results[2] as List<CategoryModel>;
      fetchedCategories.sort((a, b) {
        if (a.order != b.order) {
          return a.order.compareTo(b.order);
        }
        return a.id.compareTo(b.id);
      });
      _categories = fetchedCategories;
      _categoryNews = await _fetchCategoryNews(_categories);

      // Cache latest posts for offline readiness
      if (_latestNews.isNotEmpty) {
        storageService.saveCachedHomePosts(
          _latestNews.map((e) => e.toJson()).toList(),
        );
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // Offline fallback: load from cached home posts
      final cached = storageService.getCachedHomePosts();
      if (cached.isNotEmpty) {
        _latestNews = cached.map((m) => ArticleModel.fromJson(m)).toList();
        _breakingNews = _latestNews.take(5).toList();
        _featuredNews = _latestNews.take(5).toList();
        _isOffline = true;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      } else {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('ApiException: ', '');
        notifyListeners();
      }
    }
  }

  Future<void> refresh() async {
    _isRefreshing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        newsRepository.getLatestNews(page: 1, perPage: 12),
        newsRepository.getFeaturedNews(perPage: 6),
        newsRepository.getCategories(),
      ]);

      final latestPaginated = results[0] as dynamic;
      _latestNews = latestPaginated.data;
      _hasMore = latestPaginated.hasMore;
      _currentPage = 1;

      _breakingNews = _latestNews.take(5).toList();
      final featured = results[1] as List<ArticleModel>;
      // Website Hero is single source of truth - direct assignment
      _featuredNews = featured;
      final fetchedCategories = results[2] as List<CategoryModel>;
      fetchedCategories.sort((a, b) {
        if (a.order != b.order) {
          return a.order.compareTo(b.order);
        }
        return a.id.compareTo(b.id);
      });
      _categories = fetchedCategories;
      _categoryNews = await _fetchCategoryNews(_categories);

      storageService.saveCachedHomePosts(
        _latestNews.map((e) => e.toJson()).toList(),
      );
      _isOffline = false;
    } catch (e) {
      // Don't wipe existing news on pull-to-refresh failure
      debugPrint('Refresh error: $e');
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreLatestNews() async {
    if (_isLoadingMore || !_hasMore || _isOffline) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final paginated = await newsRepository.getLatestNews(
        page: nextPage,
        perPage: 10,
      );

      _latestNews.addAll(paginated.data);
      _currentPage = nextPage;
      _hasMore = paginated.hasMore;
    } catch (e) {
      debugPrint('Error loading more latest news: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<Map<int, List<ArticleModel>>> _fetchCategoryNews(
    List<CategoryModel> categories,
  ) async {
    final entries = await Future.wait(
      categories.map((category) async {
        try {
          final response = await newsRepository.getNewsByCategory(
            categoryId: category.id,
            perPage: 6,
          );
          return MapEntry(category.id, response.data);
        } catch (error) {
          debugPrint('Category ${category.id} sync error: $error');
          return MapEntry(category.id, <ArticleModel>[]);
        }
      }),
    );

    return Map<int, List<ArticleModel>>.fromEntries(entries);
  }
}
