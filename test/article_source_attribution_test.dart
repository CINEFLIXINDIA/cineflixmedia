import 'package:cineflix_app/core/services/storage_service.dart';
import 'package:cineflix_app/core/theme/app_theme.dart';
import 'package:cineflix_app/data/models/article_model.dart';
import 'package:cineflix_app/data/models/category_model.dart';
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

  group('ArticleModel Source Attribution Parsing Tests', () {
    test('In-house article defaults to CineFlix Media Team and has no sourceName', () {
      final json = {
        'id': 1,
        'name': 'Original CineFlix Story',
        'slug': 'original-cineflix-story',
        'description': 'Description here',
        'content': '<p>Content</p>',
        'author_name': null,
        'source_name': null,
        'original_source': null,
      };

      final article = ArticleModel.fromJson(json);
      expect(article.author, 'CineFlix Media Team');
      expect(article.sourceName, isNull);
      expect(article.isThirdPartySource, isFalse);
      expect(article.originalSource, isNull);
      expect(article.sourceAttribution, isNull);
    });

    test('In-house article with explicit author preserves author name and has no sourceName', () {
      final json = {
        'id': 2,
        'name': 'Author Written Article',
        'slug': 'author-written-article',
        'description': 'Description here',
        'content': '<p>Content</p>',
        'author': {
          'id': 5,
          'name': 'Bulah Kuvalis',
        },
        'source_name': null,
      };

      final article = ArticleModel.fromJson(json);
      expect(article.author, 'Bulah Kuvalis');
      expect(article.sourceName, isNull);
      expect(article.isThirdPartySource, isFalse);
    });

    test('Third-party imported article parses source_name and original_url', () {
      final json = {
        'id': 25,
        'name': 'Bollywood Latest News',
        'slug': 'bollywood-latest-news',
        'description': 'Description',
        'content': '<p>Content</p>',
        'author_name': 'CineFlix Media Team',
        'source_name': 'Hindustan Times Bollywood',
        'original_source': 'Hindustan Times Bollywood',
        'original_url': 'https://www.hindustantimes.com/entertainment/bollywood/sample',
      };

      final article = ArticleModel.fromJson(json);
      expect(article.sourceName, 'Hindustan Times Bollywood');
      expect(article.isThirdPartySource, isTrue);
      expect(article.originalSource, 'Hindustan Times Bollywood');
      expect(article.sourceAttribution, 'Source: Hindustan Times Bollywood');
      expect(article.originalUrl, 'https://www.hindustantimes.com/entertainment/bollywood/sample');
    });

    test('Third-party article parses nested attribution metadata if present', () {
      final json = {
        'id': 26,
        'name': 'Filmfare Exclusive Report',
        'slug': 'filmfare-exclusive-report',
        'description': 'Description',
        'content': '<p>Content</p>',
        'attribution': {
          'source_name': 'Filmfare',
          'original_url': 'https://filmfare.com/news/sample',
        },
      };

      final article = ArticleModel.fromJson(json);
      expect(article.sourceName, 'Filmfare');
      expect(article.isThirdPartySource, isTrue);
      expect(article.originalUrl, 'https://filmfare.com/news/sample');
    });
  });

  group('ArticleDetailPage UI Source Attribution Rendering Tests', () {
    late BookmarkProvider bookmarkProvider;
    late FontSizeProvider fontSizeProvider;
    late HistoryProvider historyProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.getInstance();
      bookmarkProvider = BookmarkProvider(storage);
      fontSizeProvider = FontSizeProvider(storage);
      historyProvider = HistoryProvider(storage);
    });

    testWidgets('Original article displays author without Source attribution badge', (tester) async {
      final originalArticle = ArticleModel(
        id: 101,
        title: 'Original CineFlix Story Headline',
        slug: 'original-cineflix-story-headline',
        description: 'Original in-house reporting description.',
        content: '<p>Original in-house reporting content.</p>',
        author: 'CineFlix Media Team',
        sourceName: null,
        categories: const [
          CategoryModel(id: 1, name: 'Cinema', slug: 'cinema'),
        ],
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
            home: ArticleDetailPage(article: originalArticle),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check author is displayed
      expect(find.text('CineFlix Media Team'), findsWidgets);

      // Verify no source attribution badge is rendered
      expect(find.byIcon(Icons.source_rounded), findsNothing);
      expect(find.textContaining('Source:'), findsNothing);
    });

    testWidgets('Imported article renders dedicated Source badge with Icons.source_rounded', (tester) async {
      final importedArticle = ArticleModel(
        id: 102,
        title: 'Star Spotted at Film City',
        slug: 'star-spotted-at-film-city',
        description: 'Imported news coverage description.',
        content: '<p>Imported news coverage content.</p>',
        author: 'CineFlix Media Team',
        sourceName: 'Hindustan Times Bollywood',
        categories: const [
          CategoryModel(id: 2, name: 'Bollywood', slug: 'bollywood'),
        ],
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
            home: ArticleDetailPage(article: importedArticle),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check author is displayed
      expect(find.text('CineFlix Media Team'), findsWidgets);

      // Check source badge is displayed with icon and formatted text
      expect(find.byIcon(Icons.source_rounded), findsOneWidget);
      expect(find.text('Source: Hindustan Times Bollywood'), findsOneWidget);
    });
  });
}
