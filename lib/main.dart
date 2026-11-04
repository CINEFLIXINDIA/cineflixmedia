import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/services/ad_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/news_repository.dart';
import 'providers/bookmark_provider.dart';
import 'providers/category_news_provider.dart';
import 'providers/font_size_provider.dart';
import 'providers/history_provider.dart';
import 'providers/home_provider.dart';
import 'providers/search_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/widgets/global_app_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay defaults
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  // Initialize Local Storage Service
  final storageService = await StorageService.getInstance();
  final newsRepository = NewsRepository();

  // Initialize Google Mobile Ads SDK (AdMob)
  await AdService().initialize();

  // Initialize notification service
  final notificationService = NotificationService(
    newsRepository: newsRepository,
    storageService: storageService,
  );
  notificationService.init(
    onNotificationTapped: (payload) {
      debugPrint('[Notification] Tapped: ${payload.postSlug}');
    },
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(storageService)),
        ChangeNotifierProvider(create: (_) => AuthProvider(storageService)),
        ChangeNotifierProvider(create: (_) => FontSizeProvider(storageService)),
        ChangeNotifierProvider(create: (_) => BookmarkProvider(storageService)),
        ChangeNotifierProvider(create: (_) => HistoryProvider(storageService)),
        ChangeNotifierProvider(
          create: (_) => HomeProvider(
            newsRepository: newsRepository,
            storageService: storageService,
          ),
        ),
        ChangeNotifierProvider(create: (_) => CategoryNewsProvider(newsRepository)),
        ChangeNotifierProvider(
          create: (_) => SearchProvider(
            newsRepository: newsRepository,
            storageService: storageService,
          ),
        ),
      ],
      child: const CineFlixApp(),
    ),
  );
}

class CineFlixApp extends StatelessWidget {
  const CineFlixApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      builder: (context, child) => GlobalAppBackground(
        child: child ?? const SizedBox.shrink(),
      ),
      home: const SplashScreen(),
    );
  }
}
