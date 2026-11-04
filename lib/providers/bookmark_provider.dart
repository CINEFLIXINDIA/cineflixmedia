import 'package:flutter/foundation.dart';
import '../core/services/storage_service.dart';
import '../data/models/article_model.dart';

class BookmarkProvider extends ChangeNotifier {
  final StorageService _storageService;
  List<ArticleModel> _bookmarks = [];

  BookmarkProvider(this._storageService) {
    _loadBookmarks();
  }

  List<ArticleModel> get bookmarks => List.unmodifiable(_bookmarks);

  bool isBookmarked(int articleId) {
    return _bookmarks.any((item) => item.id == articleId);
  }

  void _loadBookmarks() {
    final rawList = _storageService.getBookmarks();
    _bookmarks = rawList.map((map) => ArticleModel.fromJson(map)).toList();
    notifyListeners();
  }

  Future<bool> toggleBookmark(ArticleModel article) async {
    final existingIndex = _bookmarks.indexWhere((item) => item.id == article.id);
    bool added = false;
    if (existingIndex >= 0) {
      _bookmarks.removeAt(existingIndex);
      added = false;
    } else {
      _bookmarks.insert(0, article);
      added = true;
    }
    notifyListeners();
    await _saveBookmarks();
    return added;
  }

  Future<void> removeBookmark(int articleId) async {
    _bookmarks.removeWhere((item) => item.id == articleId);
    notifyListeners();
    await _saveBookmarks();
  }

  Future<void> _saveBookmarks() async {
    final rawList = _bookmarks.map((item) => item.toJson()).toList();
    await _storageService.saveBookmarks(rawList);
  }
}

