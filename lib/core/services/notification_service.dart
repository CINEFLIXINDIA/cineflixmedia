import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../services/storage_service.dart';
import '../../data/repositories/news_repository.dart';

class NotificationPayload {
  final String? postSlug;
  final int? postId;
  final String? title;

  NotificationPayload({this.postSlug, this.postId, this.title});
}

class NotificationService {
  final NewsRepository newsRepository;
  final StorageService storageService;

  NotificationService({
    required this.newsRepository,
    required this.storageService,
  });

  Future<void> init({required Function(NotificationPayload) onNotificationTapped}) async {
    // Check if push notifications are enabled in user settings
    final enabled = storageService.getNotificationsEnabled();
    if (!enabled) return;

    try {
      final platform = Platform.isIOS ? 'ios' : 'android';
      String? currentToken = storageService.getDeviceToken();

      if (currentToken == null) {
        // Generate persistent local device token ID
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        currentToken = 'fcm_token_${platform}_$timestamp';
        await storageService.setDeviceToken(currentToken);
      }

      // Register with CineFlix Media Botble CMS FCM Backend
      final registered = await newsRepository.registerDeviceToken(
        token: currentToken,
        platform: platform,
        deviceId: 'device_${platform}_cineflix',
        appVersion: '1.0.0',
      );

      debugPrint('[NotificationService] Registered device token with backend: $registered');
    } catch (e) {
      debugPrint('[NotificationService] Init error: $e');
    }
  }

  Future<void> setEnabled(bool enabled) async {
    await storageService.setNotificationsEnabled(enabled);
  }

  static const MethodChannel _notificationChannel =
      MethodChannel('com.cineflixmedia.app/notifications');

  static Future<bool> postNotification({
    String title = 'CineFlix Media',
    String body = 'Latest film, OTT & theatre news is live!',
  }) async {
    try {
      if (Platform.isAndroid) {
        final success = await _notificationChannel.invokeMethod<bool>(
          'showNotification',
          {'title': title, 'body': body},
        );
        return success ?? false;
      }
      return true;
    } catch (e) {
      debugPrint('[NotificationService] postNotification error: $e');
      return false;
    }
  }
}
