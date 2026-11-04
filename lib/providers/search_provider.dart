import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/services/storage_service.dart';
import '../data/models/article_model.dart';
import '../data/repositories/news_repository.dart';

class SearchProvider extends ChangeNotifier {
  final NewsRepository newsRepository;
  final StorageService storageService;

  SearchProvider({
    required this.newsRepository,
    required this.storageService,
  }) {
    _loadRecentSearches();
  }

  String _currentQuery = '';
  List<ArticleModel> _searchResults = [];
  List<String> _recentSearches = [];
  bool _isSearching = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMore = false;
  Timer? _debounceTimer;

  String get currentQuery => _currentQuery;
  List<ArticleModel> get searchResults => _searchResults;
  List<String> get recentSearches => _recentSearches;
  bool get isSearching => _isSearching;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;
  bool get hasSearched => _currentQuery.trim().isNotEmpty && !_isSearching;

  void _loadRecentSearches() {
    _recentSearches = storageService.getRecentSearches();
    notifyListeners();
  }

  void onQueryChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      clearSearch();
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      executeSearch(query);
    });
  }

  Future<void> executeSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    _currentQuery = trimmed;
    _currentPage = 1;
    _isSearching = true;
    _errorMessage = null;
    notifyListeners();

    _saveRecentSearch(trimmed);

    try {
      final paginated = await newsRepository.searchNews(
        query: trimmed,
        page: 1,
        perPage: 12,
      );

      _searchResults = paginated.data;
      _hasMore = paginated.hasMore;
      _isSearching = false;
      notifyListeners();
    } catch (e) {
      _isSearching = false;
      _errorMessage = e.toString().replaceFirst('ApiException: ', '');
      _searchResults = [];
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || _currentQuery.isEmpty) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final paginated = await newsRepository.searchNews(
        query: _currentQuery,
        page: nextPage,
        perPage: 10,
      );

      _searchResults.addAll(paginated.data);
      _currentPage = nextPage;
      _hasMore = paginated.hasMore;
    } catch (e) {
      debugPrint('Search pagination error: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _currentQuery = '';
    _searchResults = [];
    _isSearching = false;
    _errorMessage = null;
    _hasMore = false;
    notifyListeners();
  }

  Future<void> _saveRecentSearch(String query) async {
    _recentSearches.remove(query);
    _recentSearches.insert(0, query);
    if (_recentSearches.length > 10) {
      _recentSearches = _recentSearches.sublist(0, 10);
    }
    notifyListeners();
    await storageService.saveRecentSearches(_recentSearches);
  }

  Future<void> removeRecentSearch(String query) async {
    _recentSearches.remove(query);
    notifyListeners();
    await storageService.saveRecentSearches(_recentSearches);
  }

  Future<void> clearRecentSearches() async {
    _recentSearches.clear();
    notifyListeners();
    await storageService.saveRecentSearches([]);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
