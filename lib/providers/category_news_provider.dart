import 'package:flutter/foundation.dart';
import '../data/models/article_model.dart';
import '../data/repositories/news_repository.dart';

class CategoryNewsProvider extends ChangeNotifier {
  final NewsRepository _newsRepository;

  CategoryNewsProvider(this._newsRepository);

  int? _currentCategoryId;
  List<ArticleModel> _articles = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMore = true;

  List<ArticleModel> get articles => _articles;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;
  int? get currentCategoryId => _currentCategoryId;

  Future<void> fetchNewsForCategory(int categoryId) async {
    _currentCategoryId = categoryId;
    _currentPage = 1;
    _articles = [];
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final paginated = await _newsRepository.getNewsByCategory(
        categoryId: categoryId,
        page: 1,
        perPage: 12,
      );

      _articles = paginated.data;
      _hasMore = paginated.hasMore;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('ApiException: ', '');
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || _currentCategoryId == null) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final paginated = await _newsRepository.getNewsByCategory(
        categoryId: _currentCategoryId!,
        page: nextPage,
        perPage: 10,
      );

      _articles.addAll(paginated.data);
      _currentPage = nextPage;
      _hasMore = paginated.hasMore;
    } catch (e) {
      debugPrint('Error loading more category news: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (_currentCategoryId == null) return;
    await fetchNewsForCategory(_currentCategoryId!);
  }
}

