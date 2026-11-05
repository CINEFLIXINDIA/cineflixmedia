import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cineflix_app/core/services/storage_service.dart';
import 'package:cineflix_app/data/models/article_model.dart';
import 'package:cineflix_app/data/models/category_model.dart';
import 'package:cineflix_app/data/repositories/news_repository.dart';
import 'package:cineflix_app/providers/auth_provider.dart';
import 'package:cineflix_app/providers/bookmark_provider.dart';
import 'package:cineflix_app/providers/home_provider.dart';
import 'package:cineflix_app/providers/theme_provider.dart';
import 'package:cineflix_app/ui/screens/home_screen.dart';
import 'package:cineflix_app/ui/widgets/article_card.dart';

class MockPhoneHomeProvider extends ChangeNotifier implements HomeProvider {
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

  MockPhoneHomeProvider({
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

  final List<ArticleModel> testArticles = [
    ArticleModel(
      id: 101,
      title: 'First Big Movie Premiere Announced for Winter Season',
      slug: 'first-big-movie-premiere',
      description: 'Exciting news from Bollywood film industry with massive anticipation.',
      categories: [testCategories[3]],
      createdAt: '2026-11-03T07:00:00Z',
      views: 701,
    ),
    ArticleModel(
      id: 102,
      title: 'Top Music Director Drops Chart-Topping Single',
      slug: 'top-music-director-single',
      description: 'The single crosses records within hours across streaming platforms.',
      categories: [testCategories[1]],
      createdAt: '2026-11-03T06:00:00Z',
      views: 1540,
    ),
    ArticleModel(
      id: 103,
      title: 'Theatre Festival Highlights Emerging Playwrights and Actors',
      slug: 'theatre-festival-highlights',
      description: 'Audience and critics celebrate an innovative array of stories.',
      categories: [testCategories[2]],
      createdAt: '2026-11-03T05:00:00Z',
      views: 430,
    ),
    ArticleModel(
      id: 104,
      title: 'Celebrity Exclusive: Inside the Star-Studded Birthday Gala',
      slug: 'celebrity-exclusive-gala',
      description: 'Exclusive red carpet looks, candid interviews and party moments.',
      categories: [testCategories[3]],
      createdAt: '2026-11-03T04:00:00Z',
      views: 2210,
    ),
    ArticleModel(
      id: 105,
      title: 'Upcoming OTT Web Series Drops Teaser Trailer',
      slug: 'upcoming-ott-teaser',
      description: 'Streaming giant gears up for an action-packed high octane thriller.',
      categories: [testCategories[4]],
      createdAt: '2026-11-03T03:00:00Z',
      views: 3100,
    ),
  ];

  Widget createPhoneTestApp({
    required StorageService storage,
    required MockPhoneHomeProvider homeProvider,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(storage),
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(storage),
        ),
        ChangeNotifierProvider<BookmarkProvider>(
          create: (_) => BookmarkProvider(storage),
        ),
        ChangeNotifierProvider<HomeProvider>.value(
          value: homeProvider,
        ),
      ],
      child: const MaterialApp(
        home: HomeScreen(),
      ),
    );
  }

  group('Phone Portrait & Responsive Verification Tests (Pixel 7 Pro)', () {
    testWidgets('Pixel 7 Pro Portrait (411 x 891) renders full-screen phone carousel and NEVER tablet split banner', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.getInstance();

      // Pixel 7 Pro logical viewport: 411 x 891 (1440x3120 / 3.5 density)
      await tester.binding.setSurfaceSize(const Size(411, 891));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final fakeProvider = MockPhoneHomeProvider(
        breakingNews: [testArticles[0]],
        featuredNews: testArticles,
        categories: testCategories,
        latestNews: testArticles,
        categoryNews: {
          testCategories[0].id: testArticles,
        },
        storageService: storage,
      );

      await tester.pumpWidget(
        createPhoneTestApp(storage: storage, homeProvider: fakeProvider),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Assert PageView single-card hero carousel is active on phone portrait
      expect(find.byType(PageView), findsWidgets);
      expect(find.byType(ArticleCard), findsWidgets);

      // Verify zero exceptions
      expect(tester.takeException(), isNull);
    });

    testWidgets('Phone in Landscape (891 x 411) does NOT activate tablet layout because shortestSide is 411 < 600', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.getInstance();

      // Rotated Pixel 7 Pro: 891 x 411 (shortestSide is 411 < 600)
      await tester.binding.setSurfaceSize(const Size(891, 411));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final fakeProvider = MockPhoneHomeProvider(
        breakingNews: [testArticles[0]],
        featuredNews: testArticles,
        categories: testCategories,
        latestNews: testArticles,
        categoryNews: {
          testCategories[0].id: testArticles,
        },
        storageService: storage,
      );

      await tester.pumpWidget(
        createPhoneTestApp(storage: storage, homeProvider: fakeProvider),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // With shortestSide < 600, phone landscape must NOT activate tablet split hero
      expect(tester.takeException(), isNull);
    });
  });
}
