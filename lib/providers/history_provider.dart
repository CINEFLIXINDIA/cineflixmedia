import 'package:flutter/foundation.dart';
import '../core/services/storage_service.dart';
import '../data/models/article_model.dart';

class HistoryItem {
  final ArticleModel article;
  final DateTime readAt;

  HistoryItem({required this.article, required this.readAt});

  Map<String, dynamic> toJson() => {
        'article': article.toJson(),
        'readAt': readAt.toIso8601String(),
      };

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      article: ArticleModel.fromJson(json['article'] as Map<String, dynamic>),
      readAt: DateTime.tryParse(json['readAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class HistoryProvider extends ChangeNotifier {
  final StorageService _storageService;
  List<HistoryItem> _history = [];

  HistoryProvider(this._storageService) {
    _loadHistory();
  }

  List<HistoryItem> get history => List.unmodifiable(_history);

  void _loadHistory() {
    final rawList = _storageService.getHistory();
    _history = rawList.map((map) {
      try {
        return HistoryItem.fromJson(map);
      } catch (_) {
        return null;
      }
    }).whereType<HistoryItem>().toList();
    notifyListeners();
  }

  Future<void> addToHistory(ArticleModel article) async {
    // Remove if already in history so it moves to top
    _history.removeWhere((item) => item.article.id == article.id);
    _history.insert(0, HistoryItem(article: article, readAt: DateTime.now()));

    // Limit history to 100 items
    if (_history.length > 100) {
      _history = _history.sublist(0, 100);
    }

    notifyListeners();
    await _saveHistory();
  }

  Future<void> clearHistory() async {
    _history.clear();
    notifyListeners();
    await _storageService.clearHistory();
  }

  Future<void> _saveHistory() async {
    final rawList = _history.map((item) => item.toJson()).toList();
    await _storageService.saveHistory(rawList);
  }
}

