import 'package:flutter/material.dart';

import '../core/services/storage_service.dart';

class ThemeProvider extends ChangeNotifier {
  final StorageService _storageService;
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeProvider(this._storageService) {
    _loadTheme();
  }

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.dark) return true;
    if (_themeMode == ThemeMode.light) return false;
    return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
  }

  void _loadTheme() {
    final saved = _storageService.getThemeMode();
    switch (saved) {
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      case 'light':
        _themeMode = ThemeMode.light;
        break;
      default:
        _themeMode = ThemeMode.dark;
        break;
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();

    String modeStr = 'system';
    if (mode == ThemeMode.dark) modeStr = 'dark';
    if (mode == ThemeMode.light) modeStr = 'light';
    await _storageService.setThemeMode(modeStr);
  }
}
