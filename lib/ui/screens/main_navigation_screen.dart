import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/deep_link_service.dart';
import '../../providers/home_provider.dart';
import 'article_detail_screen.dart';
import 'bookmarks_screen.dart';
import 'categories_screen.dart';
import 'category_detail_screen.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  const MainNavigationScreen({super.key, this.initialIndex = 0});

  static final ValueNotifier<int?> tabNotifier = ValueNotifier<int?>(null);

  static void switchToTab(int index) {
    tabNotifier.value = null;
    tabNotifier.value = index;
  }

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;
  final DeepLinkService _deepLinkService = DeepLinkService();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _initDeepLinks();
    MainNavigationScreen.tabNotifier.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    final target = MainNavigationScreen.tabNotifier.value;
    if (target != null && mounted) {
      setState(() => _currentIndex = target);
    }
  }

  @override
  void dispose() {
    MainNavigationScreen.tabNotifier.removeListener(_handleTabChange);
    _deepLinkService.dispose();
    super.dispose();
  }

  void _initDeepLinks() {
    _deepLinkService.init(
      onLinkReceived: (data) {
        if (!mounted) return;
        if (data.postSlug != null && data.postSlug!.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ArticleDetailScreen(slug: data.postSlug),
            ),
          );
        } else if (data.categoryId != null) {
          final homeProvider = Provider.of<HomeProvider>(context, listen: false);
          final match = homeProvider.categories.where((c) => c.id == data.categoryId).firstOrNull;
          if (match != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CategoryDetailScreen(category: match),
              ),
            );
          }
        }
      },
    );
  }

  void _switchTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final screens = [
      HomeScreen(onSearchTap: () => _switchTab(2)),
      const CategoriesScreen(),
      const SearchScreen(),
      BookmarksScreen(onExploreTap: () => _switchTab(0)),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xF50E2034), // subtle inner top highlight
                    Color(0xF8081626), // dark glass body
                    Color(0xFF040A14), // deep rich base extending to absolute screen bottom
                  ],
                  stops: [0.0, 0.35, 1.0],
                )
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFFFFFF),
                    Color(0xF8F8FAFC),
                  ],
                ),
          border: Border(
            top: BorderSide(
              color: isDark
                  ? const Color(0x704FA2E8) // subtle cyan top edge
                  : const Color(0x20000000),
              width: 1.0,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.65 : 0.08),
              blurRadius: 18,
              spreadRadius: 0,
              offset: const Offset(0, -5), // soft depth projecting upward
            ),
            if (isDark)
              const BoxShadow(
                color: Color(0x300095FF), // subtle cyan ambient depth
                blurRadius: 14,
                spreadRadius: 0,
                offset: Offset(0, -2),
              ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            currentIndex: _currentIndex,
            onTap: _switchTab,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: isDark ? Colors.white54 : Colors.black45,
            items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined),
              activeIcon: Icon(Icons.grid_view_rounded),
              label: 'Topics',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_outlined),
              activeIcon: Icon(Icons.search_rounded),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bookmark_border_rounded),
              activeIcon: Icon(Icons.bookmark_rounded),
              label: 'Saved',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    ),
  );
}
}

