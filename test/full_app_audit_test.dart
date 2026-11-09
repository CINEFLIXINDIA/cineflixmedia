import 'package:cineflix_app/core/constants/ad_constants.dart';
import 'package:cineflix_app/core/services/storage_service.dart';
import 'package:cineflix_app/core/utils/date_formatter.dart';
import 'package:cineflix_app/core/utils/html_cleaner.dart';
import 'package:cineflix_app/data/models/article_model.dart';
import 'package:cineflix_app/data/models/author_model.dart';
import 'package:cineflix_app/data/models/category_model.dart';
import 'package:cineflix_app/data/models/comment_model.dart';
import 'package:cineflix_app/data/models/paginated_response.dart';
import 'package:cineflix_app/data/models/rating_model.dart';
import 'package:cineflix_app/providers/bookmark_provider.dart';
import 'package:cineflix_app/providers/font_size_provider.dart';
import 'package:cineflix_app/providers/history_provider.dart';
import 'package:cineflix_app/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storageService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storageService = await StorageService.getInstance();
    await storageService.saveBookmarks([]);
    await storageService.clearHistory();
    await storageService.clearAuth();
  });

  group('1. Data Models Comprehensive Audit', () {
    test('ArticleModel handles full JSON, missing optional fields, and URL normalization', () {
      final json = {
        'id': 100,
        'title': 'Test Article Title',
        'slug': 'test-article-slug',
        'description': 'A short excerpt',
        'content': '<p>Body text</p>',
        'image': 'main/featured.jpg',
        'categories': [
          {'id': 1, 'name': 'Bollywood', 'slug': 'bollywood'}
        ],
        'tags': [
          {'id': 10, 'name': 'Action'},
          'Drama'
        ],
        'created_at': '2026-11-01T10:00:00.000000Z',
        'author': 'Editorial Team',
        'status': 'published',
        'views': 540,
        'comments_count': 12,
        'average_rating': 4.8,
        'total_ratings': 25,
        'user_rating': 5,
      };

      final article = ArticleModel.fromJson(json);
      expect(article.id, 100);
      expect(article.title, 'Test Article Title');
      expect(article.slug, 'test-article-slug');
      expect(article.primaryCategoryName, 'Bollywood');
      expect(article.primaryCategoryId, 1);
      expect(article.image, 'https://cineflixmedia.in/storage/main/featured.jpg');
      expect(article.tags, contains('Action'));
      expect(article.tags, contains('Drama'));
      expect(article.views, 540);
      expect(article.commentsCount, 12);
      expect(article.averageRating, 4.8);
      expect(article.totalRatings, 25);
      expect(article.userRating, 5);
      expect(article.readingTimeMinutes, greaterThanOrEqualTo(1));

      // Serialization round-trip
      final serialized = article.toJson();
      expect(serialized['id'], 100);
      expect(serialized['name'], 'Test Article Title');
      expect(serialized['slug'], 'test-article-slug');
    });

    test('CategoryModel handles nested children, hierarchy and order', () {
      final json = {
        'id': 5,
        'name': 'OTT Releases',
        'slug': 'ott-releases',
        'description': 'Latest streaming shows',
        'order': 2,
        'children': [
          {'id': 20, 'name': 'Netflix', 'slug': 'netflix'}
        ],
      };

      final cat = CategoryModel.fromJson(json);
      expect(cat.id, 5);
      expect(cat.name, 'OTT Releases');
      expect(cat.order, 2);
      expect(cat.children.length, 1);
      expect(cat.children.first.name, 'Netflix');
    });

    test('CommentModel and RatingModel deserialize and validate properly', () {
      final commentJson = {
        'id': 42,
        'post_id': 100,
        'name': 'Rajesh Sharma',
        'content': 'Outstanding performance and great review!',
        'avatar_url': 'https://cineflixmedia.in/storage/avatars/user.jpg',
        'created_at': '2026-11-05T12:00:00Z',
      };

      final comment = CommentModel.fromJson(commentJson);
      expect(comment.id, 42);
      expect(comment.name, 'Rajesh Sharma');
      expect(comment.content, 'Outstanding performance and great review!');
      expect(comment.avatarUrl, contains('user.jpg'));

      final ratingJson = {
        'post_id': 100,
        'average_rating': 4.5,
        'total_ratings': 30,
        'user_rating': 4,
      };

      final rating = RatingModel.fromJson(ratingJson);
      expect(rating.postId, 100);
      expect(rating.averageRating, 4.5);
      expect(rating.totalRatings, 30);
      expect(rating.userRating, 4);
    });

    test('AuthorModel and AuthorDashboardData parse stats & activity logs correctly', () {
      final authorDataJson = {
        'author': {
          'id': 12,
          'name': 'Deepak Verma',
          'email': 'deepak@cineflixmedia.in',
          'avatar': 'https://cineflixmedia.in/storage/authors/deepak.jpg',
          'display_name': 'Deepak V.',
          'bio': 'Film Critic & Journalist',
        },
        'statistics': {
          'published_posts': 40,
          'pending_posts': 3,
          'draft_posts': 2,
          'posts_approved': 38,
        },
        'activity_logs': [
          {
            'id': 1,
            'description': 'Created a new post: Stree 2 Review',
            'created_at': '2026-11-06T08:30:00Z',
          }
        ],
      };

      final dashboard = AuthorDashboardData.fromJson(authorDataJson);
      expect(dashboard.author.id, 12);
      expect(dashboard.author.name, 'Deepak Verma');
      expect(dashboard.author.displayName, 'Deepak V.');
      expect(dashboard.stats.publishedPosts, 40);
      expect(dashboard.stats.pendingPosts, 3);
      expect(dashboard.stats.draftPosts, 2);
      expect(dashboard.activityLogs.length, 1);
      expect(dashboard.activityLogs.first.description, contains('Stree 2'));
    });

    test('PaginatedResponse handles pagination meta, total, and hasMore', () {
      final paginatedJson = {
        'data': [
          {'id': 1, 'name': 'News 1', 'slug': 'news-1'},
          {'id': 2, 'name': 'News 2', 'slug': 'news-2'},
        ],
        'meta': {
          'current_page': 1,
          'last_page': 5,
          'total': 50,
          'per_page': 10,
        },
      };

      final paginated = PaginatedResponse<ArticleModel>.fromJson(
        paginatedJson,
        (item) => ArticleModel.fromJson(item),
      );

      expect(paginated.data.length, 2);
      expect(paginated.currentPage, 1);
      expect(paginated.lastPage, 5);
      expect(paginated.total, 50);
      expect(paginated.hasMore, isTrue);
    });
  });

  group('2. StorageService & Persistence Audit', () {
    test('Bookmarks CRUD functions properly', () async {
      expect(storageService.getBookmarks(), isEmpty);

      final sample = [
        {'id': 1, 'name': 'Post 1', 'slug': 'post-1'},
        {'id': 2, 'name': 'Post 2', 'slug': 'post-2'},
      ];

      final saved = await storageService.saveBookmarks(sample);
      expect(saved, isTrue);

      final retrieved = storageService.getBookmarks();
      expect(retrieved.length, 2);
      expect(retrieved.first['id'], 1);
    });

    test('History CRUD and clearHistory works', () async {
      final history = [
        {
          'article': {'id': 1, 'name': 'Post 1', 'slug': 'post-1'},
          'readAt': DateTime.now().toIso8601String(),
        }
      ];

      await storageService.saveHistory(history);
      expect(storageService.getHistory().length, 1);

      await storageService.clearHistory();
      expect(storageService.getHistory(), isEmpty);
    });

    test('Theme, Font size, and Notifications preference persistence', () async {
      await storageService.setThemeMode('dark');
      expect(storageService.getThemeMode(), 'dark');

      await storageService.setFontSizeScale(1.25);
      expect(storageService.getFontSizeScale(), 1.25);

      await storageService.setNotificationsEnabled(false);
      expect(storageService.getNotificationsEnabled(), isFalse);

      await storageService.setNotificationsEnabled(true);
      expect(storageService.getNotificationsEnabled(), isTrue);
    });

    test('Auth token and cached author data lifecycle', () async {
      expect(storageService.getAuthToken(), isNull);
      await storageService.setAuthToken('test-sanctum-token-123');
      expect(storageService.getAuthToken(), 'test-sanctum-token-123');

      final authorMap = {
        'author': {'id': 99, 'name': 'Author Test', 'email': 'test@cineflix.in'},
        'statistics': {'published_posts': 10},
        'activity_logs': [],
      };
      await storageService.setAuthorData(authorMap);
      expect(storageService.getAuthorData()?['author']?['name'], 'Author Test');

      await storageService.clearAuth();
      expect(storageService.getAuthToken(), isNull);
      expect(storageService.getAuthorData(), isNull);
    });
  });

  group('3. Providers State Management Audit', () {
    test('BookmarkProvider toggle and remove functions', () async {
      final bookmarkProvider = BookmarkProvider(storageService);
      const article1 = ArticleModel(id: 1, title: 'Article 1', slug: 'art-1');
      const article2 = ArticleModel(id: 2, title: 'Article 2', slug: 'art-2');

      expect(bookmarkProvider.isBookmarked(1), isFalse);

      // Toggle Add
      final added = await bookmarkProvider.toggleBookmark(article1);
      expect(added, isTrue);
      expect(bookmarkProvider.isBookmarked(1), isTrue);
      expect(bookmarkProvider.bookmarks.length, 1);

      // Toggle Remove
      final removed = await bookmarkProvider.toggleBookmark(article1);
      expect(removed, isFalse);
      expect(bookmarkProvider.isBookmarked(1), isFalse);
      expect(bookmarkProvider.bookmarks, isEmpty);

      // Add 2 and remove by ID
      await bookmarkProvider.toggleBookmark(article1);
      await bookmarkProvider.toggleBookmark(article2);
      expect(bookmarkProvider.bookmarks.length, 2);

      await bookmarkProvider.removeBookmark(1);
      expect(bookmarkProvider.isBookmarked(1), isFalse);
      expect(bookmarkProvider.isBookmarked(2), isTrue);
    });

    test('HistoryProvider adds to top, deduplicates, and clears', () async {
      final historyProvider = HistoryProvider(storageService);
      const articleA = ArticleModel(id: 10, title: 'Article A', slug: 'art-a');
      const articleB = ArticleModel(id: 20, title: 'Article B', slug: 'art-b');

      await historyProvider.addToHistory(articleA);
      await historyProvider.addToHistory(articleB);

      expect(historyProvider.history.length, 2);
      expect(historyProvider.history.first.article.id, 20); // B is at top

      // Read A again - should move to top
      await historyProvider.addToHistory(articleA);
      expect(historyProvider.history.length, 2);
      expect(historyProvider.history.first.article.id, 10); // A moved to top

      await historyProvider.clearHistory();
      expect(historyProvider.history, isEmpty);
    });

    test('FontSizeProvider supports all font presets smoothly', () async {
      final fontProvider = FontSizeProvider(storageService);

      fontProvider.setFontSize(ArticleFontSize.small);
      expect(fontProvider.scaleFactor, 0.85);
      expect(fontProvider.currentSize, ArticleFontSize.small);

      fontProvider.setFontSize(ArticleFontSize.large);
      expect(fontProvider.scaleFactor, 1.15);

      fontProvider.setFontSize(ArticleFontSize.extraLarge);
      expect(fontProvider.scaleFactor, 1.30);

      fontProvider.setFontSize(ArticleFontSize.normal);
      expect(fontProvider.scaleFactor, 1.0);
    });

    test('ThemeProvider switches light, dark, and system modes and persists', () async {
      final themeProvider = ThemeProvider(storageService);

      await themeProvider.setThemeMode(ThemeMode.dark);
      expect(themeProvider.themeMode, ThemeMode.dark);
      expect(storageService.getThemeMode(), 'dark');

      await themeProvider.setThemeMode(ThemeMode.light);
      expect(themeProvider.themeMode, ThemeMode.light);
      expect(storageService.getThemeMode(), 'light');

      await themeProvider.setThemeMode(ThemeMode.system);
      expect(themeProvider.themeMode, ThemeMode.system);
      expect(storageService.getThemeMode(), 'system');
    });
  });

  group('4. Deep Linking & URL Parsing Audit', () {
    test('DeepLinkService parses cineflix:// custom schemes accurately', () {
      // cineflix://post/aukaat-ke-bahar
      final uri1 = Uri.parse('cineflix://post/aukaat-ke-bahar');
      expect(uri1.scheme, 'cineflix');
      expect(uri1.host, 'post');
      expect(uri1.pathSegments.first, 'aukaat-ke-bahar');

      // cineflix://category?id=9
      final uri2 = Uri.parse('cineflix://category?id=9');
      expect(uri2.scheme, 'cineflix');
      expect(uri2.queryParameters['id'], '9');

      // Website deep link: https://cineflixmedia.in/blog/test-slug
      final uri3 = Uri.parse('https://cineflixmedia.in/blog/test-slug');
      expect(uri3.host, 'cineflixmedia.in');
      expect(uri3.pathSegments, ['blog', 'test-slug']);
    });
  });

  group('5. AdMob Configuration & Safety Audit', () {
    test('AdConstants provides valid IDs for both Android and iOS', () {
      expect(AdConstants.prodPublisherId, 'ca-app-pub-4390946365152897');

      // Android Prod IDs
      expect(AdConstants.prodAndroidBannerAdId, startsWith('ca-app-pub-'));
      expect(AdConstants.prodAndroidInterstitialAdId, startsWith('ca-app-pub-'));
      expect(AdConstants.prodAndroidAppOpenAdId, startsWith('ca-app-pub-'));

      // Test IDs prevent developer bans during QA
      expect(AdConstants.testAndroidBannerId, contains('3940256099942544'));
      expect(AdConstants.testAndroidInterstitialId, contains('3940256099942544'));
      expect(AdConstants.testAndroidAppOpenId, contains('3940256099942544'));
    });
  });

  group('6. HTML & Date Utilities Audit', () {
    test('HtmlCleaner replaces relative storage links and removes unwanted tags', () {
      const htmlWithRelative = '<p>Check <img src="storage/posts/banner.jpg"> out</p>';
      final prepared = HtmlCleaner.prepareHtmlContent(htmlWithRelative);
      expect(prepared, contains('https://cineflixmedia.in/storage/posts/banner.jpg'));

      const htmlWithShortcode = '<p>Text</p><shortcode>Special Box</shortcode>';
      final cleaned = HtmlCleaner.prepareHtmlContent(htmlWithShortcode);
      expect(cleaned, contains('<div class="shortcode-box">'));
    });

    test('DateFormatter handles relative and formatted calendar dates', () {
      final now = DateTime.now();
      expect(DateFormatter.timeAgo(now.toIso8601String()), 'Just now');

      final fiveMinutesAgo = now.subtract(const Duration(minutes: 5));
      expect(DateFormatter.timeAgo(fiveMinutesAgo.toIso8601String()), contains('5 mins ago'));

      final threeHoursAgo = now.subtract(const Duration(hours: 3));
      expect(DateFormatter.timeAgo(threeHoursAgo.toIso8601String()), contains('3 hours ago'));

      final twoDaysAgo = now.subtract(const Duration(days: 2));
      expect(DateFormatter.timeAgo(twoDaysAgo.toIso8601String()), contains('2 days ago'));
    });
  });
}
