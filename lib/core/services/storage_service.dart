import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

class StorageService {
  static StorageService? _instance;
  static SharedPreferences? _prefs;

  StorageService._();

  static Future<StorageService> getInstance() async {
    if (_instance == null) {
      _instance = StorageService._();
      _prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  // Bookmarks
  List<Map<String, dynamic>> getBookmarks() {
    final raw = _prefs?.getString(AppConstants.keyBookmarks);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<bool> saveBookmarks(List<Map<String, dynamic>> bookmarks) async {
    return await _prefs?.setString(
          AppConstants.keyBookmarks,
          jsonEncode(bookmarks),
        ) ??
        false;
  }

  // Reading History
  List<Map<String, dynamic>> getHistory() {
    final raw = _prefs?.getString(AppConstants.keyHistory);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<bool> saveHistory(List<Map<String, dynamic>> history) async {
    return await _prefs?.setString(
          AppConstants.keyHistory,
          jsonEncode(history),
        ) ??
        false;
  }

  Future<bool> clearHistory() async {
    return await _prefs?.remove(AppConstants.keyHistory) ?? false;
  }

  // Theme Mode
  String getThemeMode() {
    return _prefs?.getString(AppConstants.keyThemeMode) ?? 'system';
  }

  Future<bool> setThemeMode(String mode) async {
    return await _prefs?.setString(AppConstants.keyThemeMode, mode) ?? false;
  }

  // Font Size Scale
  double getFontSizeScale() {
    return _prefs?.getDouble(AppConstants.keyFontSizeScale) ?? 1.0;
  }

  Future<bool> setFontSizeScale(double scale) async {
    return await _prefs?.setDouble(AppConstants.keyFontSizeScale, scale) ??
        false;
  }

  // Recent Searches
  List<String> getRecentSearches() {
    return _prefs?.getStringList(AppConstants.keyRecentSearches) ?? [];
  }

  Future<bool> saveRecentSearches(List<String> searches) async {
    return await _prefs?.setStringList(
          AppConstants.keyRecentSearches,
          searches,
        ) ??
        false;
  }

  // Cached Home Posts (Offline fallback)
  List<Map<String, dynamic>> getCachedHomePosts() {
    final raw = _prefs?.getString(AppConstants.keyCachedHomePosts);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<bool> saveCachedHomePosts(List<Map<String, dynamic>> posts) async {
    return await _prefs?.setString(
          AppConstants.keyCachedHomePosts,
          jsonEncode(posts),
        ) ??
        false;
  }

  // Notifications Enabled
  bool getNotificationsEnabled() {
    return _prefs?.getBool(AppConstants.keyNotificationsEnabled) ?? true;
  }

  Future<bool> setNotificationsEnabled(bool enabled) async {
    return await _prefs?.setBool(
          AppConstants.keyNotificationsEnabled,
          enabled,
        ) ??
        false;
  }

  // Device Token
  String? getDeviceToken() {
    return _prefs?.getString(AppConstants.keyDeviceToken);
  }

  Future<bool> setDeviceToken(String token) async {
    return await _prefs?.setString(AppConstants.keyDeviceToken, token) ?? false;
  }

  // Newsletter popup preference
  bool getHideNewsletterPopup() {
    return _prefs?.getBool(AppConstants.keyHideNewsletterPopup) ?? false;
  }

  Future<bool> setHideNewsletterPopup(bool hide) async {
    return await _prefs?.setBool(AppConstants.keyHideNewsletterPopup, hide) ??
        false;
  }

  // Author Auth Token
  String? getAuthToken() {
    return _prefs?.getString(AppConstants.keyAuthToken);
  }

  Future<bool> setAuthToken(String? token) async {
    if (token == null) {
      return await _prefs?.remove(AppConstants.keyAuthToken) ?? false;
    }
    return await _prefs?.setString(AppConstants.keyAuthToken, token) ?? false;
  }

  // Cached Author Profile
  Map<String, dynamic>? getAuthorData() {
    final raw = _prefs?.getString(AppConstants.keyAuthorData);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<bool> setAuthorData(Map<String, dynamic>? data) async {
    if (data == null) {
      return await _prefs?.remove(AppConstants.keyAuthorData) ?? false;
    }
    return await _prefs?.setString(
          AppConstants.keyAuthorData,
          jsonEncode(data),
        ) ??
        false;
  }

  Future<void> clearAuth() async {
    await _prefs?.remove(AppConstants.keyAuthToken);
    await _prefs?.remove(AppConstants.keyAuthorData);
  }
}
