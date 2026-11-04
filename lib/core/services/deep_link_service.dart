import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

class DeepLinkData {
  final String? postSlug;
  final int? categoryId;

  DeepLinkData({this.postSlug, this.categoryId});
}

class DeepLinkService {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  void init({required Function(DeepLinkData) onLinkReceived}) async {
    try {
      // Check initial link when app launched from dead state
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        final data = _parseUri(initialUri);
        if (data != null) {
          onLinkReceived(data);
        }
      }

      // Listen for links while app is in foreground/background
      _sub = _appLinks.uriLinkStream.listen((uri) {
        final data = _parseUri(uri);
        if (data != null) {
          onLinkReceived(data);
        }
      }, onError: (err) {
        debugPrint('[DeepLinkService] Stream error: $err');
      });
    } catch (e) {
      debugPrint('[DeepLinkService] Init error: $e');
    }
  }

  DeepLinkData? _parseUri(Uri uri) {
    debugPrint('[DeepLinkService] Received URI: $uri');

    // Case 1: cineflix://post/:slug
    if (uri.scheme == 'cineflix') {
      if (uri.host == 'post' || (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'post')) {
        final slug = uri.pathSegments.length > 1
            ? uri.pathSegments[1]
            : uri.queryParameters['slug'] ?? uri.host;
        return DeepLinkData(postSlug: slug);
      }
      if (uri.host == 'category') {
        final catId = int.tryParse(uri.queryParameters['id'] ?? uri.pathSegments.last);
        return DeepLinkData(categoryId: catId);
      }
    }

    // Case 2: https://cineflixmedia.in/blog/:slug
    if (uri.host.contains('cineflixmedia.in')) {
      final segments = uri.pathSegments;
      if (segments.isNotEmpty && segments.first == 'blog' && segments.length > 1) {
        return DeepLinkData(postSlug: segments[1]);
      }
    }

    return null;
  }

  void dispose() {
    _sub?.cancel();
  }
}

