// ignore_for_file: depend_on_referenced_packages

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import 'package:cineflix_app/core/constants/app_constants.dart';
import 'package:cineflix_app/core/services/storage_service.dart';
import 'package:cineflix_app/core/theme/app_theme.dart';
import 'package:cineflix_app/providers/font_size_provider.dart';
import 'package:cineflix_app/providers/theme_provider.dart';
import 'package:cineflix_app/ui/screens/contact_us_screen.dart';
import 'package:cineflix_app/ui/screens/settings_screen.dart';

class FakeWebViewPlatform extends WebViewPlatform {
  late FakePlatformWebViewController lastController;
  late FakePlatformNavigationDelegate lastDelegate;

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) {
    lastDelegate = FakePlatformNavigationDelegate(params);
    return lastDelegate;
  }

  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) {
    lastController = FakePlatformWebViewController(params);
    return lastController;
  }

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) {
    return FakePlatformWebViewWidget(params);
  }
}

class FakePlatformWebViewController extends PlatformWebViewController {
  FakePlatformWebViewController(super.params) : super.implementation();

  String? loadedUrl;
  Color? backgroundColor;
  JavaScriptMode? jsMode;
  PlatformNavigationDelegate? delegate;

  @override
  Future<void> loadRequest(LoadRequestParams params) async {
    loadedUrl = params.uri.toString();
  }

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {
    jsMode = javaScriptMode;
  }

  @override
  Future<void> setBackgroundColor(Color color) async {
    backgroundColor = color;
  }

  @override
  Future<void> setPlatformNavigationDelegate(PlatformNavigationDelegate handler) async {
    delegate = handler;
  }

  @override
  Future<bool> canGoBack() async => false;

  @override
  Future<void> reload() async {}
}

class FakePlatformNavigationDelegate extends PlatformNavigationDelegate {
  FakePlatformNavigationDelegate(super.params) : super.implementation();

  void Function(int)? onProgress;
  void Function(String)? onPageStarted;
  void Function(String)? onPageFinished;

  @override
  Future<void> setOnProgress(void Function(int) progressCallback) async {
    onProgress = progressCallback;
  }

  @override
  Future<void> setOnPageStarted(void Function(String) startedCallback) async {
    onPageStarted = startedCallback;
  }

  @override
  Future<void> setOnPageFinished(void Function(String) finishedCallback) async {
    onPageFinished = finishedCallback;
  }

  @override
  Future<void> setOnWebResourceError(void Function(WebResourceError) errorCallback) async {}

  @override
  Future<void> setOnNavigationRequest(FutureOr<NavigationDecision> Function(NavigationRequest) navigationRequestCallback) async {}
}

class FakePlatformWebViewWidget extends PlatformWebViewWidget {
  FakePlatformWebViewWidget(super.params) : super.implementation();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      key: Key('fake_webview_widget'),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storageService;
  late FakeWebViewPlatform fakeWebViewPlatform;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storageService = await StorageService.getInstance();
    fakeWebViewPlatform = FakeWebViewPlatform();
    WebViewPlatform.instance = fakeWebViewPlatform;
  });

  Widget buildTestApp({required Widget home, ThemeMode themeMode = ThemeMode.dark}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(storageService)),
        ChangeNotifierProvider(create: (_) => FontSizeProvider(storageService)),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        home: home,
      ),
    );
  }

  group('ContactUsScreen - In-App WebView Tests', () {
    testWidgets('renders AppBar with title "Contact Us", back button, and loads target contact URL', (tester) async {
      await tester.pumpWidget(
        buildTestApp(home: const ContactUsScreen()),
      );
      await tester.pump();

      // Verify AppBar Title & Leading Back Button
      expect(find.text('Contact Us'), findsOneWidget);
      expect(find.byTooltip('Back'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);

      // Verify Reload action button
      expect(find.byTooltip('Reload'), findsOneWidget);

      // Verify WebViewController configuration
      expect(fakeWebViewPlatform.lastController.loadedUrl, '${AppConstants.websiteUrl}/contact');
      expect(fakeWebViewPlatform.lastController.jsMode, JavaScriptMode.unrestricted);
      expect(fakeWebViewPlatform.lastController.backgroundColor, const Color(0xFF081725));

      // Verify loading state indicator is visible while loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading Contact Desk...'), findsOneWidget);
    });

    testWidgets('Tapping leading back button pops the route', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ContactUsScreen()),
                );
              },
              child: const Text('Open Contact Us'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to ContactUsScreen
      await tester.tap(find.text('Open Contact Us'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(ContactUsScreen), findsOneWidget);

      // Simulate page finished loading to stop circular progress indicator
      fakeWebViewPlatform.lastDelegate.onPageFinished?.call('https://cineflixmedia.in/contact');
      await tester.pump();

      // Tap Back button in AppBar
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      // Verify popped back to root
      expect(find.byType(ContactUsScreen), findsNothing);
      expect(find.text('Open Contact Us'), findsOneWidget);
    });
  });

  group('SettingsScreen - Contact Us WebView Integration Tests', () {
    testWidgets('Settings screen contains Contact Us tile and tapping navigates to ContactUsScreen', (tester) async {
      await tester.pumpWidget(
        buildTestApp(home: const SettingsScreen()),
      );
      await tester.pumpAndSettle();

      // Find Contact Us tile
      final contactUsTile = find.widgetWithText(ListTile, 'Contact Us');
      expect(contactUsTile, findsOneWidget);

      // Ensure visible and tap
      await tester.ensureVisible(contactUsTile);
      await tester.pumpAndSettle();
      await tester.tap(contactUsTile);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Verify ContactUsScreen is now presented
      expect(find.byType(ContactUsScreen), findsOneWidget);
      expect(fakeWebViewPlatform.lastController.loadedUrl, '${AppConstants.websiteUrl}/contact');
    });
  });
}
