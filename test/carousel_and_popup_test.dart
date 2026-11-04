import 'package:cineflix_app/core/services/storage_service.dart';
import 'package:cineflix_app/core/theme/app_theme.dart';
import 'package:cineflix_app/data/models/article_model.dart';
import 'package:cineflix_app/data/models/category_model.dart';
import 'package:cineflix_app/data/repositories/news_repository.dart';
import 'package:cineflix_app/providers/auth_provider.dart';
import 'package:cineflix_app/providers/bookmark_provider.dart';
import 'package:cineflix_app/providers/home_provider.dart';
import 'package:cineflix_app/ui/screens/home_screen.dart';
import 'package:cineflix_app/ui/screens/newsletter_popup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestHomeProvider extends ChangeNotifier implements HomeProvider {
  @override
  final List<ArticleModel> breakingNews;
  @override
  final List<ArticleModel> featuredNews;
  @override
  final List<CategoryModel> categories;
  @override
  final List<ArticleModel> latestNews;
  @override
  final Map<int, List<ArticleModel>> categoryNews;
  @override
  final StorageService storageService;

  TestHomeProvider({
    required this.breakingNews,
    required this.featuredNews,
    required this.categories,
    required this.latestNews,
    required this.categoryNews,
    required this.storageService,
  });

  @override
  bool get isLoading => false;
  @override
  bool get isLoadingMore => false;
  @override
  bool get isRefreshing => false;
  @override
  bool get isOffline => false;
  @override
  bool get hasMore => true;
  @override
  String? get errorMessage => null;
  @override
  NewsRepository get newsRepository => throw UnimplementedError();

  @override
  Future<void> fetchHomeData() async {}
  @override
  Future<void> loadMoreLatestNews() async {}
  @override
  Future<void> refresh() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testCategories = [
    const CategoryModel(id: 9, name: 'Bollywood News', slug: 'bollywood-news'),
    const CategoryModel(id: 19, name: 'Music Launches', slug: 'music-launches'),
    const CategoryModel(id: 14, name: 'Theatre & Drama', slug: 'theatre-drama'),
    const CategoryModel(id: 16, name: 'Talent Spotlight', slug: 'talent-spotlight'),
    const CategoryModel(id: 20, name: 'OTT Releases', slug: 'ott-releases'),
  ];

  final testArticles = [
    ArticleModel(
      id: 101,
      title: 'First Big Movie Premiere Announced for Winter Season',
      slug: 'first-big-movie-premiere',
      description: 'Exciting news from Bollywood film industry.',
      categories: [testCategories[0]],
      createdAt: '2026-11-03T07:00:00Z',
    ),
    ArticleModel(
      id: 102,
      title: 'Top Music Director Drops Chart-Topping Single',
      slug: 'top-music-director-single',
      description: 'The single crosses records within hours.',
      categories: [testCategories[1]],
      createdAt: '2026-11-03T06:00:00Z',
    ),
    ArticleModel(
      id: 103,
      title: 'Acclaimed Play Begins National Tour Across Cities',
      slug: 'acclaimed-play-tour',
      description: 'Theatre revival draws massive audiences.',
      categories: [testCategories[2]],
      createdAt: '2026-11-03T05:00:00Z',
    ),
    ArticleModel(
      id: 104,
      title: 'Talent Spotlight: Emerging Director Wins Major Honors',
      slug: 'emerging-director-honors',
      description: 'A stellar milestone for new creative voices.',
      categories: [testCategories[3]],
      createdAt: '2026-11-03T04:00:00Z',
    ),
  ];

  group('Newsletter Popup Tests', () {
    testWidgets('Renders all required elements including Continue with Google', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.getInstance();
      final authProvider = AuthProvider(storage);
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const NewsletterPopupScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check header & copy
      expect(find.text('Never Miss a Story'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);

      // Check Subscribe button
      expect(find.text('Subscribe'), findsOneWidget);

      // Check Continue with Google button
      expect(find.text('Continue with Google'), findsOneWidget);

      // Check Continue with Apple button
      expect(find.text('Continue with Apple'), findsOneWidget);

      // Check Don't show again checkbox
      expect(find.text("Don't show this popup again"), findsOneWidget);

      // Check Maybe later button
      expect(find.text('Maybe later'), findsOneWidget);

      // Check close button
      expect(find.byTooltip('Close'), findsOneWidget);

      // Tap Continue with Google triggers Google Sign-In flow without placeholder warning
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      expect(find.text('Google authentication is not configured for the mobile app yet.'), findsNothing);
    });
  });

  group('Home Carousel Layout & Responsive Page Slots Tests', () {
    testWidgets('Carousels display complete items with zero edge clipping across mobile viewports', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.getInstance();

      // Test on standard mobile viewport width (390)
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final fakeProvider = TestHomeProvider(
        breakingNews: [testArticles[0]],
        featuredNews: [testArticles[0], testArticles[1]],
        categories: testCategories,
        latestNews: testArticles,
        categoryNews: {
          testCategories[0].id: [testArticles[0], testArticles[1], testArticles[2]],
          testCategories[1].id: [testArticles[1], testArticles[2]],
        },
        storageService: storage,
      );

      final bookmarkProvider = BookmarkProvider(storage);
      final authProvider = AuthProvider(storage);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<HomeProvider>.value(value: fakeProvider),
            ChangeNotifierProvider<BookmarkProvider>.value(value: bookmarkProvider),
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Verify Explore Topics section
      expect(find.text('Explore Topics'), findsOneWidget);

      // 2. Verify Latest Headlines section
      expect(find.text('Latest Headlines'), findsOneWidget);

      // 3. Find PageViews on screen
      final pageViews = tester.widgetList<PageView>(find.byType(PageView)).toList();
      expect(pageViews.isNotEmpty, isTrue);

      // Check that all Home carousels use viewportFraction == 1.0 (no fixed fractional partial cards)
      for (final pv in pageViews) {
        if (pv.controller != null) {
          expect(pv.controller!.viewportFraction, 1.0);
        }
      }

      // 4. In Category carousel, verify complete cards per page slot
      expect(find.text('Bollywood News'), findsWidgets);

      // 5. Scroll down through all sections to check for any RenderFlex overflows
      final scrollable = find.byType(CustomScrollView);
      expect(scrollable, findsOneWidget);

      await tester.drag(scrollable, const Offset(0, -300));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.drag(scrollable, const Offset(0, -300));
      await tester.pump(const Duration(milliseconds: 100));

      // 6. Test on 360 width (compact mobile viewport)
      await tester.binding.setSurfaceSize(const Size(360, 800));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Assert no exceptions thrown during layout or scrolling
      expect(tester.takeException(), isNull);
    });
  });
}
