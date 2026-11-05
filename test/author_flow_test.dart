import 'package:cineflix_app/core/services/apple_auth_service.dart';
import 'package:cineflix_app/core/services/storage_service.dart';
import 'package:cineflix_app/core/theme/app_theme.dart';
import 'package:cineflix_app/data/models/author_model.dart';
import 'package:cineflix_app/data/repositories/news_repository.dart';
import 'package:cineflix_app/providers/auth_provider.dart';
import 'package:cineflix_app/providers/bookmark_provider.dart';
import 'package:cineflix_app/providers/font_size_provider.dart';
import 'package:cineflix_app/providers/history_provider.dart';
import 'package:cineflix_app/providers/home_provider.dart';
import 'package:cineflix_app/providers/search_provider.dart';
import 'package:cineflix_app/providers/theme_provider.dart';
import 'package:cineflix_app/ui/screens/author_dashboard_screen.dart';
import 'package:cineflix_app/ui/screens/author_posts_screen.dart';
import 'package:cineflix_app/ui/screens/create_post_screen.dart';
import 'package:cineflix_app/ui/screens/home_screen.dart';
import 'package:cineflix_app/ui/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Author Models Unit Tests', () {
    test('AppleAuthResult data container retains credentials', () {
      const result = AppleAuthResult(
        id: '000123.apple.sub',
        identityToken: 'jwt-header.jwt-payload.jwt-sig',
        email: 'test@privaterelay.appleid.com',
        name: 'Apple User',
        authorizationCode: 'auth-code-123',
      );
      expect(result.id, '000123.apple.sub');
      expect(result.identityToken, 'jwt-header.jwt-payload.jwt-sig');
      expect(result.email, 'test@privaterelay.appleid.com');
      expect(result.name, 'Apple User');
      expect(result.authorizationCode, 'auth-code-123');
    });

    test('AppleAuthService client ID and redirect URI configuration are valid', () {
      expect(AppleAuthService.appleClientId, 'com.cineflixmedia.app.service');
      expect(AppleAuthService.appleRedirectUri, 'https://cineflixmedia.in/api/v1/auth/apple/callback');
    });

    test('AuthorModel and Dashboard data deserialize accurately from backend JSON', () {
      final json = {
        'author': {
          'id': 2,
          'name': 'Cristian Watsica',
          'first_name': 'Cristian',
          'last_name': 'Watsica',
          'email': 'ycollins@nicolas.com',
          'phone': '+1 (689) 575-5062',
          'avatar': 'https://cineflixmedia.in/storage/main/members/2.png',
          'description': 'Editorial Author',
          'joined_date': 'Dec 24, 2025',
          'created_at': '2025-12-24T07:28:44+05:30',
        },
        'statistics': {
          'posts_approved': 2,
          'published_posts': 2,
          'pending_posts': 0,
          'draft_posts': 0,
        },
        'activity_logs': [
          {
            'id': 15,
            'action': 'login',
            'description': 'You logged in . 5 seconds ago',
            'ip_address': '31.97.227.41',
            'created_at': '2026-11-03T16:05:56+05:30',
            'time_ago': '5 seconds ago',
          }
        ],
      };

      final dashboard = AuthorDashboardData.fromJson(json);

      expect(dashboard.author.id, 2);
      expect(dashboard.author.name, 'Cristian Watsica');
      expect(dashboard.author.email, 'ycollins@nicolas.com');
      expect(dashboard.author.joinedDate, 'Dec 24, 2025');
      expect(dashboard.stats.postsApproved, 2);
      expect(dashboard.stats.publishedPosts, 2);
      expect(dashboard.stats.pendingPosts, 0);
      expect(dashboard.stats.draftPosts, 0);
      expect(dashboard.activityLogs.length, 1);
      expect(dashboard.activityLogs.first.description, 'You logged in . 5 seconds ago');
      expect(dashboard.activityLogs.first.ipAddress, '31.97.227.41');
    });
  });

  group('Author Flow Widget Tests', () {
    testWidgets('LoginScreen renders native form, CineFlix branding and handles validation', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.getInstance();
      final authProvider = AuthProvider(storage);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check Native Header & Elements
      expect(find.text('Author Login'), findsOneWidget);
      expect(find.text('Author & Contributor Portal'), findsOneWidget);
      expect(find.text('Author Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign In to Dashboard'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Continue with Apple'), findsOneWidget);

      // Tap Sign In with empty fields to verify native validation
      await tester.tap(find.text('Sign In to Dashboard'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email address'), findsOneWidget);
    });

    testWidgets('AuthorDashboardScreen renders profile, metrics, stats and activity logs', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.getInstance();

      // Seed cached author dashboard data
      await storage.setAuthToken('test-token-123');
      await storage.setAuthorData({
        'author': {
          'id': 2,
          'name': 'Cristian Watsica',
          'email': 'ycollins@nicolas.com',
          'joined_date': 'Dec 24, 2025',
          'avatar': 'https://cineflixmedia.in/storage/main/members/2.png',
        },
        'statistics': {
          'posts_approved': 2,
          'published_posts': 2,
          'pending_posts': 0,
          'draft_posts': 0,
        },
        'activity_logs': [
          {
            'id': 1,
            'action': 'login',
            'description': 'You logged in . 5 seconds ago',
            'ip_address': '31.97.227.41',
            'time_ago': '5 seconds ago',
          }
        ],
      });

      final authProvider = AuthProvider(storage);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const AuthorDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify My Profile screen header & Profile details
      expect(find.text('My Profile'), findsOneWidget);
      expect(find.text('Cristian Watsica'), findsOneWidget);
      expect(find.text('Joined Dec 24, 2025'), findsOneWidget);
      expect(find.text('ycollins@nicolas.com'), findsOneWidget);
      expect(find.text('CineFlix Media'), findsWidgets);
      expect(find.text('Edit Profile'), findsOneWidget);

      // Posts Approved box
      expect(find.text('POSTS APPROVED'), findsOneWidget);
      expect(find.text('2'), findsWidgets); // Posts approved and Published count

      // Stat widgets
      expect(find.text('Published'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Drafts'), findsOneWidget);

      // Menu Actions - Settings removed
      expect(find.text('Dashboard'), findsWidgets);
      expect(find.text('Posts'), findsOneWidget);
      expect(find.text('Settings'), findsNothing);
      expect(find.widgetWithText(ListTile, 'Logout'), findsOneWidget);
      expect(find.byTooltip('Logout'), findsNothing); // Duplicate top-right logout icon removed
      expect(find.text('Delete Account'), findsOneWidget);

      // Verify Delete Account confirmation dialog
      final deleteAccountTile = find.widgetWithText(ListTile, 'Delete Account');
      await tester.ensureVisible(deleteAccountTile);
      expect(deleteAccountTile, findsOneWidget);
      await tester.tap(deleteAccountTile);
      await tester.pumpAndSettle();

      expect(find.text('Are you sure?'), findsOneWidget);
      expect(
        find.text('Your account and profile with all data will be permanently deleted. This action cannot be undone.'),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Delete Account'), findsOneWidget);

      // Dismiss dialog with Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Activity Logs - default collapsed
      final activityLogsHeader = find.text('Activity Logs');
      expect(activityLogsHeader, findsOneWidget);
      expect(find.text('You logged in . 5 seconds ago'), findsNothing);

      // Tap Activity Logs header to expand
      await tester.tap(activityLogsHeader);
      await tester.pumpAndSettle();

      expect(find.text('You logged in . 5 seconds ago'), findsOneWidget);
      expect(find.text('(31.97.227.41)'), findsOneWidget);

      // Tap again to collapse
      await tester.tap(activityLogsHeader);
      await tester.pumpAndSettle();

      expect(find.text('You logged in . 5 seconds ago'), findsNothing);
    });

    testWidgets('AuthorPostsScreen renders tabs and navigation', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.getInstance();
      await storage.setAuthToken('test-token-123');
      final authProvider = AuthProvider(storage);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const AuthorPostsScreen(),
          ),
        ),
      );
      await tester.pump();

      // Check Tabs
      expect(find.text('Author Posts'), findsOneWidget);
      expect(find.text('All Posts'), findsOneWidget);
      expect(find.text('Published'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Drafts'), findsOneWidget);
    });

    testWidgets('EditProfileScreen loads real profile data and validates fields', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.getInstance();
      await storage.setAuthToken('test-token-123');
      await storage.setAuthorData({
        'author': {
          'id': 9,
          'name': 'CINEFLIX INDIA',
          'first_name': 'CineFlix',
          'last_name': 'India',
          'email': 'cineflixcreations@gmail.com',
          'phone': '07405878389',
          'description': 'Official CineFlix Media author profile.',
          'joined_date': 'Mar 01, 2026',
        },
        'statistics': {},
        'activity_logs': [],
      });
      final authProvider = AuthProvider(storage);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const AuthorDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Edit Profile button
      await tester.tap(find.text('Edit Profile'));
      await tester.pumpAndSettle();

      // Verify Edit Profile Screen is displayed
      expect(find.text('Edit Profile'), findsWidgets);
      expect(find.text('DISPLAY NAME'), findsOneWidget);
      expect(find.text('FIRST NAME'), findsOneWidget);
      expect(find.text('LAST NAME'), findsOneWidget);
      expect(find.text('ORGANIZATION'), findsOneWidget);
      expect(find.text('CineFlix Media'), findsWidgets);
      expect(find.text('DESIGNATION'), findsOneWidget);
      expect(find.text('EXPERIENCE'), findsOneWidget);
      expect(find.text('EDUCATION'), findsOneWidget);
      expect(find.text('DATE OF BIRTH (DOB)'), findsOneWidget);
      expect(find.text('GENDER'), findsOneWidget);
      expect(find.text('PHONE NUMBER'), findsOneWidget);
      expect(find.text('EMAIL ADDRESS'), findsOneWidget);
      expect(find.text('CITY'), findsOneWidget);
      expect(find.text('STATE'), findsOneWidget);
      expect(find.text('ADDRESS'), findsOneWidget);
      expect(find.text('BIO / ABOUT'), findsOneWidget);
      expect(find.text('FACEBOOK'), findsOneWidget);
      expect(find.text('INSTAGRAM'), findsOneWidget);
      expect(find.text('X (TWITTER)'), findsOneWidget);
      expect(find.text('YOUTUBE'), findsOneWidget);
      expect(find.text('LINKEDIN'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);

      // Verify fields pre-filled from backend author model
      expect(find.text('CineFlix'), findsOneWidget);
      expect(find.text('India'), findsOneWidget);
      expect(find.text('07405878389'), findsOneWidget);
      expect(find.text('Official CineFlix Media author profile.'), findsOneWidget);
    });

    testWidgets('Header + Add New Post button is on HomeScreen and AuthorPostsScreen, and not on AuthorDashboardScreen', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.getInstance();
      await storage.setAuthToken('test-token-123');
      final authProvider = AuthProvider(storage);
      final newsRepo = NewsRepository();

      // 1. AuthorDashboardScreen (My Profile) header should NOT have + Add New Post button
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider(create: (_) => HomeProvider(newsRepository: newsRepo, storageService: storage)),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const AuthorDashboardScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('My Profile'), findsOneWidget);
      expect(find.text('+ Add New Post'), findsNothing);

      // 2. HomeScreen header MUST have + Add New Post button
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider(create: (_) => HomeProvider(newsRepository: newsRepo, storageService: storage)),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const HomeScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.byTooltip('+ Add New Post'), findsOneWidget);
      expect(find.text('Post'), findsOneWidget);

      // 3. AuthorPostsScreen header MUST have + Add New Post button
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider(create: (_) => HomeProvider(newsRepository: newsRepo, storageService: storage)),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const AuthorPostsScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('+ Add New Post'), findsOneWidget);
      expect(find.text('Author Posts'), findsOneWidget);
    });

    testWidgets('HomeScreen header Profile button shows Display Name instead of Full Name', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.getInstance();
      await storage.setAuthToken('test-token-123');
      await storage.setAuthorData({
        'author': {
          'id': 22,
          'name': 'Bharat Patel CineFlix India',
          'first_name': 'Bharat Patel CineFlix',
          'last_name': 'India',
          'display_name': 'Bharat Patel',
          'email': 'bharat@cineflixmedia.in',
        },
        'statistics': {
          'posts_approved': 5,
          'published_posts': 5,
          'pending_posts': 0,
          'draft_posts': 0,
        },
        'activity_logs': [],
      });
      final authProvider = AuthProvider(storage);
      final newsRepo = NewsRepository();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider(create: (_) => HomeProvider(newsRepository: newsRepo, storageService: storage)),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const HomeScreen(),
          ),
        ),
      );

      await tester.pump();

      // Display Name ("Bharat Patel") is shown
      expect(find.text('Bharat Patel'), findsOneWidget);
      // Full Name / First Name is NOT shown in header profile button
      expect(find.text('Bharat Patel CineFlix'), findsNothing);
      expect(find.text('Bharat Patel CineFlix India'), findsNothing);
    });

    testWidgets('CreatePostScreen renders complete native form with fields and bottom actions', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.getInstance();
      await storage.setAuthToken('test-token-123');
      final authProvider = AuthProvider(storage);
      final newsRepo = NewsRepository();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider(create: (_) => HomeProvider(newsRepository: newsRepo, storageService: storage)),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CreatePostScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Screen Title
      expect(find.text('Create New Post'), findsOneWidget);

      // Verify all Form Fields
      expect(find.text('POST TITLE *'), findsOneWidget);
      expect(find.text('CATEGORY'), findsOneWidget);
      expect(find.text('SHORT DESCRIPTION / EXCERPT'), findsOneWidget);
      expect(find.text('FULL ARTICLE CONTENT *'), findsOneWidget);
      expect(find.text('FEATURED IMAGE'), findsOneWidget);
      expect(find.text('Upload Featured Image'), findsOneWidget);
      expect(find.text('MEDIA GALLERY (0)'), findsOneWidget);
      expect(find.text('MEDIA URL (YOUTUBE / VIDEO / PODCAST)'), findsOneWidget);
      expect(find.text('TAGS / KEYWORDS'), findsOneWidget);

      // Verify Bottom Actions
      expect(find.text('Save Draft'), findsOneWidget);
      expect(find.text('Publish'), findsOneWidget);

      // Verify Validation triggers on empty submit
      await tester.tap(find.text('Publish'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a post title'), findsOneWidget);
    });

    testWidgets('Tapping Dashboard row in My Profile triggers navigation to Author Dashboard screen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.getInstance();
      await storage.setAuthToken('test-token-123');
      final authProvider = AuthProvider(storage);
      final newsRepo = NewsRepository();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider(storage)),
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider(create: (_) => FontSizeProvider(storage)),
            ChangeNotifierProvider(create: (_) => BookmarkProvider(storage)),
            ChangeNotifierProvider(create: (_) => HistoryProvider(storage)),
            ChangeNotifierProvider(
              create: (_) => HomeProvider(
                newsRepository: newsRepo,
                storageService: storage,
              ),
            ),
            ChangeNotifierProvider(
              create: (_) => SearchProvider(
                newsRepository: newsRepo,
                storageService: storage,
              ),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const AuthorDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final dashboardFinder = find.widgetWithText(ListTile, 'Dashboard');
      await tester.scrollUntilVisible(dashboardFinder, 300);
      expect(dashboardFinder, findsOneWidget);

      await tester.tap(dashboardFinder);
      await tester.pumpAndSettle();

      // Successfully navigated to Author Dashboard screen instead of returning to Home
      expect(find.text('Author Dashboard'), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });
  });
}
