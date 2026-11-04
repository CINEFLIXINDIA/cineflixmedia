import 'package:flutter/material.dart';
import '../core/services/storage_service.dart';

enum ArticleFontSize {
  small(0.85, 'Small'),
  normal(1.0, 'Default'),
  large(1.15, 'Large'),
  extraLarge(1.30, 'Extra Large');

  final double scale;
  final String label;
  const ArticleFontSize(this.scale, this.label);
}

class FontSizeProvider extends ChangeNotifier {
  final StorageService _storageService;
  ArticleFontSize _currentSize = ArticleFontSize.normal;

  FontSizeProvider(this._storageService) {
    _loadFontSize();
  }

  ArticleFontSize get currentSize => _currentSize;
  double get scaleFactor => _currentSize.scale;

  void _loadFontSize() {
    final scale = _storageService.getFontSizeScale();
    for (var size in ArticleFontSize.values) {
      if ((size.scale - scale).abs() < 0.05) {
        _currentSize = size;
        break;
      }
    }
    notifyListeners();
  }

  Future<void> setFontSize(ArticleFontSize size) async {
    if (_currentSize == size) return;
    _currentSize = size;
    notifyListeners();
    await _storageService.setFontSizeScale(size.scale);
  }
}

