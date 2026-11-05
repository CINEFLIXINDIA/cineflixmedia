import 'package:cineflix_app/core/services/storage_service.dart';
import 'package:cineflix_app/core/theme/app_theme.dart';
import 'package:cineflix_app/data/models/article_model.dart';
import 'package:cineflix_app/data/models/category_model.dart';
import 'package:cineflix_app/data/models/comment_model.dart';
import 'package:cineflix_app/data/models/rating_model.dart';
import 'package:cineflix_app/providers/bookmark_provider.dart';
import 'package:cineflix_app/providers/font_size_provider.dart';
import 'package:cineflix_app/providers/history_provider.dart';
import 'package:cineflix_app/ui/screens/article_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleArticle = ArticleModel(
    id: 1,
    title: 'Breakthrough Cinema Innovation Revealed at CineFlix Fest',
    slug: 'breakthrough-cinema-innovation',
    description: 'A comprehensive report on the latest visual storytelling techniques.',
    content: '<p>A comprehensive report on the latest visual storytelling techniques.</p>',
    image: 'https://cineflixmedia.in/storage/posts/breakthrough.jpg',
    categories: const [
      CategoryModel(id: 1, name: 'Web Series & OTT', slug: 'web-series-ott'),
    ],
    tags: const ['Cinema', 'OTT', 'Tech'],
    commentsCount: 3,
    averageRating: 4.8,
    totalRatings: 12,
    userRating: 5,
    views: 1240,
  );

  group('Engagement System - Model Tests', () {
    test('CommentModel parses from JSON correctly and generates initials', () {
      final json = {
        'id': 42,
        'name': 'Rahul Sharma',
        'email': 'rahul@example.com',
        'content': 'Brilliant review of the premiere!',
        'avatar_url': 'https://cineflixmedia.in/storage/members/1/avatar.png',
        'reply_to': null,
        'created_at': '2026-11-05T12:00:00Z',
      };

      final comment = CommentModel.fromJson(json);
      expect(comment.id, 42);
      expect(comment.name, 'Rahul Sharma');
      expect(comment.email, 'rahul@example.com');
      expect(comment.content, 'Brilliant review of the premiere!');
      expect(comment.avatarUrl, 'https://cineflixmedia.in/storage/members/1/avatar.png');
      expect(comment.initials, 'RS');
      expect(comment.replyTo, isNull);

      final singleNameComment = CommentModel.fromJson({
        'id': 43,
        'name': 'Pooja',
        'content': 'Great story!',
      });
      expect(singleNameComment.initials, 'PO');
    });

    test('RatingModel parses and handles copyWith properly', () {
      final json = {
        'post_id': 1,
        'average_rating': 4.5,
        'total_ratings': 20,
        'user_rating': 4,
      };

      final rating = RatingModel.fromJson(json);
      expect(rating.postId, 1);
      expect(rating.averageRating, 4.5);
      expect(rating.totalRatings, 20);
      expect(rating.userRating, 4);

      final updated = rating.copyWith(averageRating: 4.7, totalRatings: 21, userRating: 5);
      expect(updated.averageRating, 4.7);
      expect(updated.totalRatings, 21);
      expect(updated.userRating, 5);
    });

    test('ArticleModel preserves engagement fields in JSON cycle and copyWith', () {
      final json = sampleArticle.toJson();
      expect(json['comments_count'], 3);
      expect(json['average_rating'], 4.8);
      expect(json['total_ratings'], 12);
      expect(json['user_rating'], 5);

      final restored = ArticleModel.fromJson(json);
      expect(restored.commentsCount, 3);
      expect(restored.averageRating, 4.8);
      expect(restored.totalRatings, 12);
      expect(restored.userRating, 5);

      final updated = sampleArticle.copyWith(
        commentsCount: 4,
        averageRating: 5.0,
        totalRatings: 13,
      );
      expect(updated.commentsCount, 4);
      expect(updated.averageRating, 5.0);
      expect(updated.totalRatings, 13);
    });
  });

  group('ArticleDetailScreen - Engagement UI Tests', () {
    testWidgets('Removes "Open on CineFlix" and displays Rating, Comments & Share in bottom bar', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.getInstance();

      final bookmarkProvider = BookmarkProvider(storage);
      final fontSizeProvider = FontSizeProvider(storage);
      final historyProvider = HistoryProvider(storage);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<BookmarkProvider>.value(value: bookmarkProvider),
            ChangeNotifierProvider<FontSizeProvider>.value(value: fontSizeProvider),
            ChangeNotifierProvider<HistoryProvider>.value(value: historyProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: ArticleDetailScreen(article: sampleArticle),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. "Open on CineFlix" must NOT exist anywhere on the screen
      expect(find.text('Open on CineFlix'), findsNothing);
      expect(find.byIcon(Icons.open_in_browser), findsNothing);

      // 2. Share Article button exists and has share icon
      expect(find.text('Share Article'), findsOneWidget);

      // 3. Bottom bar has rating indicator pill
      expect(find.text('4.8'), findsWidgets);

      // 4. Rate this Article section exists in the body
      expect(find.text('Rate this Article'), findsOneWidget);

      // 5. Comments section header exists
      expect(find.textContaining('Comments'), findsWidgets);

      // 6. Star icons are interactive and render properly
      expect(find.byIcon(Icons.star_rounded), findsWidgets);
    });

    testWidgets('Unauthenticated user tapping rating star opens Sign In prompt modal', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.getInstance();

      final bookmarkProvider = BookmarkProvider(storage);
      final fontSizeProvider = FontSizeProvider(storage);
      final historyProvider = HistoryProvider(storage);

      final unratedArticle = ArticleModel(
        id: 2,
        title: 'New Drama Series Announced',
        slug: 'new-drama-series',
        description: 'Upcoming streaming drama series breakdown.',
        content: '<p>Upcoming streaming drama series breakdown.</p>',
        categories: const [
          CategoryModel(id: 2, name: 'Drama', slug: 'drama'),
        ],
        tags: const ['Drama', 'OTT'],
        commentsCount: 0,
        averageRating: 0.0,
        totalRatings: 0,
        userRating: null,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<BookmarkProvider>.value(value: bookmarkProvider),
            ChangeNotifierProvider<FontSizeProvider>.value(value: fontSizeProvider),
            ChangeNotifierProvider<HistoryProvider>.value(value: historyProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: ArticleDetailScreen(article: unratedArticle),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the "Sign in to submit rating" button / prompt
      final signInPrompt = find.text('Sign in to submit rating');
      expect(signInPrompt, findsOneWidget);

      await tester.ensureVisible(signInPrompt);
      await tester.pumpAndSettle();
      await tester.tap(signInPrompt);
      await tester.pumpAndSettle();

      // Verify Sign In modal bottom sheet appears
      expect(find.text('Sign In Required'), findsOneWidget);
      expect(find.text('Sign in to submit your rating'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Sign In'), findsOneWidget);
    });
  });
}
