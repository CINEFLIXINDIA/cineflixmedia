import 'package:cineflix_app/core/services/storage_service.dart';
import 'package:cineflix_app/core/theme/app_theme.dart';
import 'package:cineflix_app/data/models/article_model.dart';
import 'package:cineflix_app/data/models/category_model.dart';
import 'package:cineflix_app/data/repositories/news_repository.dart';
import 'package:cineflix_app/providers/auth_provider.dart';
import 'package:cineflix_app/providers/bookmark_provider.dart';
import 'package:cineflix_app/providers/font_size_provider.dart';
import 'package:cineflix_app/providers/history_provider.dart';
import 'package:cineflix_app/providers/home_provider.dart';
import 'package:cineflix_app/ui/screens/article_detail_screen.dart';
import 'package:cineflix_app/ui/screens/bookmarks_screen.dart';
import 'package:cineflix_app/ui/screens/categories_screen.dart';
import 'package:cineflix_app/ui/screens/home_screen.dart';
import 'package:cineflix_app/ui/widgets/article_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockHomeProvider extends ChangeNotifier implements HomeProvider {
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

  MockHomeProvider({
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
    const CategoryModel(id: 10, name: 'Film Launches', slug: 'film-launches'),
    const CategoryModel(id: 11, name: 'Web Series', slug: 'web-series'),
    const CategoryModel(id: 12, name: 'Box Office', slug: 'box-office'),
  ];

  final List<ArticleModel> testArticles = [
    ArticleModel(
      id: 101,
      title: 'First Big Movie Premiere Announced for Winter Season',
      slug: 'first-big-movie-premiere',
      description: 'Exciting news from Bollywood film industry with massive anticipation.',
      categories: [testCategories[3]], // Talent Spotlight
      createdAt: '2026-11-03T07:00:00Z',
      views: 701,
    ),
    ArticleModel(
      id: 102,
      title: 'Top Music Director Drops Chart-Topping Single',
      slug: 'top-music-director-single',
      description: 'The single crosses records within hours across streaming platforms.',
      categories: [testCategories[1]], // Music Launches
      createdAt: '2026-11-03T06:00:00Z',
      views: 1540,
    ),
    ArticleModel(
      id: 103,
      title: 'Acclaimed Play Begins National Tour Across Cities',
      slug: 'acclaimed-play-tour',
      description: 'Theatre revival draws massive audiences throughout the weekend.',
      categories: [testCategories[2]], // Theatre
      createdAt: '2026-11-03T05:00:00Z',
      views: 320,
    ),
    ArticleModel(
      id: 104,
      title: 'Major New Thriller Breaks Global OTT Viewership Records',
      slug: 'major-thriller-ott',
      description: 'The suspense series reaches #1 spot within 24 hours of release.',
      categories: [testCategories[4]], // OTT
      createdAt: '2026-11-03T04:00:00Z',
      views: 25400,
    ),
    ArticleModel(
      id: 105,
      title: 'Film Launch Gala Brings Stellar Lineup of Creators',
      slug: 'film-launch-gala',
      description: 'Red carpet moments and producer interviews from the launch ceremony.',
      categories: [testCategories[5]], // Film Launches
      createdAt: '2026-11-03T03:00:00Z',
      views: 890,
    ),
  ];

  group('iPad Layout & Responsiveness Tests', () {
    testWidgets('HomeScreen on iPad Portrait (834x1194 & 1024x1366) renders 4-column topics & cinematic hero without clipping or overflows', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.getInstance();

      // iPad 11-inch portrait viewport (834 x 1194)
      await tester.binding.setSurfaceSize(const Size(834, 1194));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final fakeProvider = MockHomeProvider(
        breakingNews: [testArticles[0]],
        featuredNews: [testArticles[0], testArticles[1]],
        categories: testCategories,
        latestNews: testArticles,
        categoryNews: {
          testCategories[0].id: [testArticles[0], testArticles[1], testArticles[2]],
          testCategories[1].id: [testArticles[1], testArticles[2], testArticles[3]],
          testCategories[5].id: [testArticles[4], testArticles[0]],
        },
        storageService: storage,
      );

      final bookmarkProvider = BookmarkProvider(storage);
      final authProvider = AuthProvider(storage);
      final fontSizeProvider = FontSizeProvider(storage);
      final historyProvider = HistoryProvider(storage);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<HomeProvider>.value(value: fakeProvider),
            ChangeNotifierProvider<BookmarkProvider>.value(value: bookmarkProvider),
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<FontSizeProvider>.value(value: fontSizeProvider),
            ChangeNotifierProvider<HistoryProvider>.value(value: historyProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Verify Website-style cinematic hero banner on iPad
      expect(find.text('TALENT SPOTLIGHT'), findsWidgets);
      expect(find.text('Read Full Story'), findsOneWidget);
      expect(find.text('701 Views'), findsOneWidget);
      expect(find.text('First Big Movie Premiere Announced for Winter Season'), findsWidgets);

      // 2. Verify Explore Topics section exists and renders topic cards
      expect(find.text('Explore Topics'), findsOneWidget);
      expect(find.text('Bollywood News'), findsWidgets);
      expect(find.text('Music Launches'), findsWidgets);

      // 3. Verify PageView uses viewportFraction 1.0 (no fractional card cuts)
      final pageViews = tester.widgetList<PageView>(find.byType(PageView)).toList();
      for (final pv in pageViews) {
        if (pv.controller != null) {
          expect(pv.controller!.viewportFraction, 1.0);
        }
      }

      // 4. Scroll down through all category panels on iPad
      final scrollable = find.byType(CustomScrollView);
      expect(scrollable, findsOneWidget);

      await tester.drag(scrollable, const Offset(0, -400));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.drag(scrollable, const Offset(0, -400));
      await tester.pump(const Duration(milliseconds: 100));

      // 5. Switch to iPad 12.9-inch Portrait (1024 x 1366)
      await tester.binding.setSurfaceSize(const Size(1024, 1366));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Assert zero exceptions / overflows on portrait iPad
      expect(tester.takeException(), isNull);
    });

    testWidgets('HomeScreen on iPad (width >= 768) renders website-matching split hero banner with main card and 4 mini cards', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.getInstance();

      await tester.binding.setSurfaceSize(const Size(834, 1194));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final fakeProvider = MockHomeProvider(
        breakingNews: [testArticles[0]],
        featuredNews: testArticles, // exactly 5 articles
        categories: testCategories,
        latestNews: testArticles,
        categoryNews: {
          testCategories[0].id: [testArticles[0]],
        },
        storageService: storage,
      );

      final bookmarkProvider = BookmarkProvider(storage);
      final authProvider = AuthProvider(storage);
      final fontSizeProvider = FontSizeProvider(storage);
      final historyProvider = HistoryProvider(storage);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<HomeProvider>.value(value: fakeProvider),
            ChangeNotifierProvider<BookmarkProvider>.value(value: bookmarkProvider),
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<FontSizeProvider>.value(value: fontSizeProvider),
            ChangeNotifierProvider<HistoryProvider>.value(value: historyProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Verify Left Main Hero Card
      expect(find.text('Read Full Story'), findsOneWidget);
      expect(find.text('First Big Movie Premiere Announced for Winter Season'), findsWidgets);

      // 2. Verify Right Vertical List of 4 Mini Cards
      expect(find.text('Top Music Director Drops Chart-Topping Single'), findsOneWidget);
      expect(find.text('Acclaimed Play Begins National Tour Across Cities'), findsOneWidget);
      expect(find.text('Major New Thriller Breaks Global OTT Viewership Records'), findsOneWidget);
      expect(find.text('Film Launch Gala Brings Stellar Lineup of Creators'), findsOneWidget);

      // 3. Verify category kicker pills on mini cards
      expect(find.text('MUSIC LAUNCHES'), findsWidgets);
      expect(find.text('THEATRE & DRAMA'), findsWidgets);
      expect(find.text('OTT RELEASES'), findsWidgets);
      expect(find.text('FILM LAUNCHES'), findsWidgets);

      // 4. Tap on a mini card to open detail screen
      await tester.tap(find.text('Top Music Director Drops Chart-Topping Single'));
      await tester.pumpAndSettle();
      expect(find.byType(ArticleDetailScreen), findsOneWidget);
    });

    testWidgets('HomeScreen on iPad Landscape (1194x834 & 1366x1024) handles ultra-wide layout with zero overflows', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.getInstance();

      // iPad Landscape viewport (1194 x 834)
      await tester.binding.setSurfaceSize(const Size(1194, 834));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final fakeProvider = MockHomeProvider(
        breakingNews: [testArticles[0]],
        featuredNews: [testArticles[0], testArticles[1]],
        categories: testCategories,
        latestNews: testArticles,
        categoryNews: {
          testCategories[0].id: [testArticles[0], testArticles[1], testArticles[2]],
        },
        storageService: storage,
      );

      final bookmarkProvider = BookmarkProvider(storage);
      final authProvider = AuthProvider(storage);
      final fontSizeProvider = FontSizeProvider(storage);
      final historyProvider = HistoryProvider(storage);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<HomeProvider>.value(value: fakeProvider),
            ChangeNotifierProvider<BookmarkProvider>.value(value: bookmarkProvider),
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<FontSizeProvider>.value(value: fontSizeProvider),
            ChangeNotifierProvider<HistoryProvider>.value(value: historyProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Explore Topics'), findsOneWidget);
      expect(find.text('Read Full Story'), findsOneWidget);

      // Scroll down
      final scrollable = find.byType(CustomScrollView);
      await tester.drag(scrollable, const Offset(0, -350));
      await tester.pump(const Duration(milliseconds: 100));

      // Assert zero exceptions / overflows on landscape iPad
      expect(tester.takeException(), isNull);
    });

    testWidgets('CategoriesScreen on iPad renders exactly 4 columns in GridView', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.getInstance();

      // iPad portrait (834 x 1194)
      await tester.binding.setSurfaceSize(const Size(834, 1194));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final fakeProvider = MockHomeProvider(
        breakingNews: [],
        featuredNews: [],
        categories: testCategories,
        latestNews: [],
        categoryNews: {},
        storageService: storage,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<HomeProvider>.value(value: fakeProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const CategoriesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final gridFinder = find.byType(GridView);
      expect(gridFinder, findsOneWidget);

      final grid = tester.widget<GridView>(gridFinder);
      final delegate = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;

      // iPad width (834 >= 600) MUST produce 4 columns
      expect(delegate.crossAxisCount, 4);

      // Assert no exceptions
      expect(tester.takeException(), isNull);
    });

    testWidgets('BookmarksScreen renders horizontal cards on iPad without overflow', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.getInstance();

      await tester.binding.setSurfaceSize(const Size(834, 1194));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final bookmarkProvider = BookmarkProvider(storage);
      await bookmarkProvider.toggleBookmark(testArticles[0]);
      await bookmarkProvider.toggleBookmark(testArticles[1]);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<BookmarkProvider>.value(value: bookmarkProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const BookmarksScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Saved Articles'), findsOneWidget);
      expect(find.text('First Big Movie Premiere Announced for Winter Season'), findsOneWidget);
      expect(find.byType(ArticleCard), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('ArticleCard horizontal & vertical renders flawlessly on iPad grid slots', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.getInstance();
      final bookmarkProvider = BookmarkProvider(storage);

      // Test across multiple tablet column slot widths: 240px, 320px, 400px
      for (final slotWidth in [240.0, 320.0, 400.0]) {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<BookmarkProvider>.value(value: bookmarkProvider),
            ],
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              home: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: slotWidth,
                    height: 300,
                    child: ArticleCard(article: testArticles[0], isHorizontal: false),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      // Horizontal card in tablet slot (matching HomeScreen tablet carousel height 145px)
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<BookmarkProvider>.value(value: bookmarkProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 800,
                  height: 145,
                  child: ArticleCard(article: testArticles[0], isHorizontal: true),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('ArticleDetailScreen renders hero image, metadata, and share bar on iPad', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.getInstance();

      await tester.binding.setSurfaceSize(const Size(834, 1194));
      addTearDown(() => tester.binding.setSurfaceSize(null));

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
            home: ArticleDetailScreen(article: testArticles[0]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('First Big Movie Premiere Announced for Winter Season'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
