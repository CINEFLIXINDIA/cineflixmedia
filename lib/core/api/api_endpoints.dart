import '../constants/app_constants.dart';

class ApiEndpoints {
  ApiEndpoints._();

  static const String posts = '${AppConstants.apiBaseUrl}/posts';
  static const String postsHero = '${AppConstants.apiBaseUrl}/posts/hero';
  static const String postsFilters = '${AppConstants.apiBaseUrl}/posts/filters';
  static const String search = '${AppConstants.apiBaseUrl}/search';
  static const String categories = '${AppConstants.apiBaseUrl}/categories';
  static const String deviceTokens = '${AppConstants.apiBaseUrl}/device-tokens';

  // Author Auth & Dashboard Endpoints
  static const String login = '${AppConstants.apiBaseUrl}/login';
  static const String logout = '${AppConstants.apiBaseUrl}/logout';
  static const String authGoogle = '${AppConstants.apiBaseUrl}/auth/google';
  static const String authApple = '${AppConstants.apiBaseUrl}/auth/apple';
  static const String me = '${AppConstants.apiBaseUrl}/me';
  static const String authorDashboard = '${AppConstants.apiBaseUrl}/author/dashboard';
  static const String authorPosts = '${AppConstants.apiBaseUrl}/author/posts';
  static const String authorCreatePost = '${AppConstants.apiBaseUrl}/author/posts';
  static const String authorActivityLogs = '${AppConstants.apiBaseUrl}/author/activity-logs';
  static const String authorUpdateAvatar = '${AppConstants.apiBaseUrl}/author/update-avatar';
  static const String authorUpdateProfile = '${AppConstants.apiBaseUrl}/author/update-profile';
  static const String authorDeleteAccount = '${AppConstants.apiBaseUrl}/author/delete-account';

  static String postDetail(String slug) => '${AppConstants.apiBaseUrl}/posts/$slug';
  static String postComments(dynamic postId) => '${AppConstants.apiBaseUrl}/posts/$postId/comments';
  static String postRatings(dynamic postId) => '${AppConstants.apiBaseUrl}/posts/$postId/ratings';
  static String categoryDetail(String slug) => '${AppConstants.apiBaseUrl}/categories/$slug';
}

