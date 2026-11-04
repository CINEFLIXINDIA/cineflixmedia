import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/article_model.dart';
import '../../data/models/category_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/home_provider.dart';
import '../widgets/admob_banner_widget.dart';
import '../widgets/article_card.dart';
import '../widgets/breaking_news_ticker.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/shimmer_loading.dart';
import 'article_detail_screen.dart';
import 'author_dashboard_screen.dart';
import 'categories_screen.dart';
import 'category_detail_screen.dart';
import 'create_post_screen.dart';
import 'date_articles_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onSearchTap;

  const HomeScreen({super.key, this.onSearchTap});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final PageController _featuredPageController = PageController();
  final PageController _topicsPageController = PageController(
    viewportFraction: 1,
    initialPage: 6000,
  );
  final PageController _latestPageController = PageController(
    viewportFraction: 1,
    initialPage: 6000,
  );
  final Map<int, PageController> _categoryPageControllers = {};
  Timer? _featuredTimer;
  Timer? _topicsTimer;
  Timer? _latestTimer;
  Timer? _categorySectionsTimer;
  int _featuredIndex = 0;

  Future<void> _openCalendar() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (selectedDate == null || !mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DateArticlesScreen(selectedDate: selectedDate),
      ),
    );
  }

  void _openLogin() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isAuthenticated) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AuthorDashboardScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  Future<void> _openCreatePost() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) {
      final loggedIn = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (loggedIn != true || !mounted) return;
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreatePostScreen()),
    );
  }

  @override
  void initState() {
    super.initState();
    _startFeaturedTimer();
    _startTopicsTimer();
    _startLatestTimer();
    _startCategorySectionsTimer();
  }

  void _startFeaturedTimer() {
    _featuredTimer?.cancel();
    _featuredTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_featuredPageController.hasClients) return;
      final homeProvider = Provider.of<HomeProvider>(context, listen: false);
      if (homeProvider.featuredNews.length <= 1) return;

      final next = (_featuredIndex + 1) % homeProvider.featuredNews.length;
      _featuredPageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
      );
      setState(() => _featuredIndex = next);
    });
  }

  void _startTopicsTimer() {
    _topicsTimer?.cancel();
    _topicsTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_topicsPageController.hasClients) return;
      final categories = Provider.of<HomeProvider>(
        context,
        listen: false,
      ).categories;
      if (categories.length <= 3) return;

      _topicsPageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _startLatestTimer() {
    _latestTimer?.cancel();
    _latestTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_latestPageController.hasClients) return;
      final latest = Provider.of<HomeProvider>(
        context,
        listen: false,
      ).latestNews;
      final itemCount = latest.length > 6 ? 6 : latest.length;
      if (itemCount <= 1) return;

      _latestPageController.nextPage(
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  PageController _categoryPageController(int categoryId) {
    return _categoryPageControllers.putIfAbsent(
      categoryId,
      () => PageController(viewportFraction: 1, initialPage: 6000),
    );
  }

  void _startCategorySectionsTimer() {
    _categorySectionsTimer?.cancel();
    _categorySectionsTimer = Timer.periodic(
      const Duration(milliseconds: 4500),
      (_) {
        if (!mounted) return;
        final provider = Provider.of<HomeProvider>(context, listen: false);
        for (final entry in _categoryPageControllers.entries) {
          final articles = provider.categoryNews[entry.key] ?? const [];
          final controller = entry.value;
          if (articles.length <= 1 || !controller.hasClients) continue;
          controller.nextPage(
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOutCubic,
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _featuredTimer?.cancel();
    _topicsTimer?.cancel();
    _latestTimer?.cancel();
    _categorySectionsTimer?.cancel();
    _scrollController.dispose();
    _featuredPageController.dispose();
    _topicsPageController.dispose();
    _latestPageController.dispose();
    for (final controller in _categoryPageControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final homeProvider = Provider.of<HomeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 74,
        titleSpacing: 14,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF0C131D), // clean solid dark top
                      Color(0xFF060B12), // deep dark body
                      Color(0xFF03070E), // rich solid base matching #030a13
                    ],
                    stops: [0.0, 0.45, 1.0],
                  )
                : const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFFFFF), Color(0xF8F8FAFC)],
                  ),
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? const Color(
                        0x22FFFFFF,
                      ) // clean subtle edge without cyan tint
                    : const Color(0x20000000),
                width: 1.0,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.70 : 0.08),
                blurRadius: 18,
                spreadRadius: 0,
                offset: const Offset(0, 5),
              ),
            ],
          ),
        ),
        title: Transform.scale(
          scale: 1.25,
          alignment: Alignment.centerLeft,
          child: Image.asset(
            AppConstants.logoAsset,
            height: 58,
            alignment: Alignment.centerLeft,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            isAntiAlias: true,
            errorBuilder: (context, error, stackTrace) => const Text(
              AppConstants.appName,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
            child: Tooltip(
              message: '+ Add New Post',
              child: SizedBox(
                width: 52,
                height: 48,
                child: ElevatedButton(
                  key: const Key('home_header_add_post_btn'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _openCreatePost,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 20),
                      SizedBox(height: 1),
                      Text(
                        'Post',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          height: 1.1,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _HeaderAction(
            icon: Icons.calendar_month_rounded,
            label: DateFormat('dd MMM').format(DateTime.now()),
            tooltip: 'Open Calendar',
            onTap: _openCalendar,
          ),
          Consumer<AuthProvider>(
            builder: (context, auth, child) => _HeaderAction(
              icon: auth.isAuthenticated
                  ? Icons.person_rounded
                  : Icons.person_outline_rounded,
              label: auth.isAuthenticated
                  ? (auth.author?.effectiveDisplayName ?? 'Profile')
                  : 'Login',
              tooltip: auth.isAuthenticated ? 'My Profile' : 'Login',
              onTap: _openLogin,
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: _buildBody(homeProvider, isDark),
    );
  }

  BoxDecoration _sectionPanelDecoration(bool isDark) {
    if (!isDark) {
      return BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        border: Border.all(color: const Color(0x30B0B8C4), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
        ],
      );
    }

    return BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(
            0xFF2E5380,
          ), // subtle inner top highlight (real embossed/raised depth)
          Color(0xF5102238), // transition
          Color(0xFA071220), // noticeably darker/more opaque panel fill
          Color(0xFF030811), // deep rich base
        ],
        stops: [0.0, 0.045, 0.22, 1.0],
      ),
      border: Border.all(
        color: const Color(
          0xB84FA2E8,
        ), // brighter thin blue-gray top/outer border
        width: 1.2,
      ),
      boxShadow: [
        // Stronger but soft outer shadow around the complete section
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.75),
          blurRadius: 24,
          spreadRadius: 1,
          offset: const Offset(0, 8),
        ),
        // Soft outer blue-cyan glow around complete section
        BoxShadow(
          color: const Color(0x400095FF),
          blurRadius: 18,
          spreadRadius: 0,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  Widget _buildBody(HomeProvider provider, bool isDark) {
    if (provider.isLoading) {
      return ListView(
        children: const [
          HeroSliderShimmer(),
          SizedBox(height: 12),
          ArticleCardShimmer(),
          ArticleCardShimmer(),
          ArticleCardShimmer(),
          ArticleCardShimmer(),
        ],
      );
    }

    if (provider.errorMessage != null && provider.latestNews.isEmpty) {
      return ErrorStateWidget(
        message: provider.errorMessage,
        onRetry: () => provider.fetchHomeData(),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.refresh(),
      color: AppColors.primary,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Offline Banner
          if (provider.isOffline)
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 16,
                ),
                color: AppColors.warning.withOpacity(0.9),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.cloud_off_rounded,
                      size: 16,
                      color: Colors.black87,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Offline Mode — Showing Cached CineFlix Stories',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Breaking News Ticker
          if (provider.breakingNews.isNotEmpty)
            SliverToBoxAdapter(
              child: BreakingNewsTicker(articles: provider.breakingNews),
            ),

          // Featured Stories Slider
          if (provider.featuredNews.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildFeaturedSlider(provider.featuredNews, isDark),
            ),

          // Categories Horizontal Selector
          if (provider.categories.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildCategoriesSection(provider.categories, isDark),
            ),

          // Latest News Section Panel
          if (provider.latestNews.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: _sectionPanelDecoration(isDark),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 18,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Latest Headlines',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${provider.latestNews.length} Stories',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 132,
                      child: PageView.builder(
                        controller: _latestPageController,
                        padEnds: false,
                        itemBuilder: (context, index) {
                          final itemCount = provider.latestNews.length > 6
                              ? 6
                              : provider.latestNews.length;
                          if (itemCount == 0) return const SizedBox.shrink();
                          return ArticleCard(
                            article: provider.latestNews[index % itemCount],
                            isHorizontal: true,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Google AdMob Banner
          const SliverToBoxAdapter(
            child: AdMobBannerWidget(
              showAdLabel: true,
              margin: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
          ),

          // Admin/API-driven category streams.
          for (final category in provider.categories)
            SliverToBoxAdapter(
              child: _buildCategoryStream(
                category,
                provider.categoryNews[category.id] ?? const [],
                isDark,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _buildFeaturedSlider(List<ArticleModel> items, bool isDark) {
    return Column(
      children: [
        SizedBox(
          height: 230,
          child: PageView.builder(
            controller: _featuredPageController,
            itemCount: items.length,
            onPageChanged: (idx) => setState(() => _featuredIndex = idx),
            itemBuilder: (context, index) {
              final item = items[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ArticleDetailScreen(article: item),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark
                          ? const Color(
                              0x804FA2E8,
                            ) // subtle cyan edge/highlight
                          : const Color(0x20B0B8C4),
                      width: 1.1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.70 : 0.12,
                        ),
                        blurRadius: 22,
                        spreadRadius: 1,
                        offset: const Offset(0, 8),
                      ),
                      if (isDark)
                        const BoxShadow(
                          color: Color(0x350095FF), // subtle cyan ambient depth
                          blurRadius: 16,
                          spreadRadius: 0,
                          offset: Offset(0, 1),
                        ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Image
                      item.image != null && item.image!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: item.image!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: isDark
                                    ? AppColors.darkCard
                                    : const Color(0xFFE8ECEF),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: AppColors.secondary,
                                child: const Center(
                                  child: Icon(
                                    Icons.movie_creation_outlined,
                                    size: 48,
                                    color: Colors.white30,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              color: AppColors.secondary,
                              child: const Center(
                                child: Icon(
                                  Icons.movie_creation_outlined,
                                  size: 48,
                                  color: Colors.white30,
                                ),
                              ),
                            ),

                      // Gradient overlay
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.4),
                              Colors.black.withValues(alpha: 0.85),
                            ],
                            stops: const [0.3, 0.6, 1.0],
                          ),
                        ),
                      ),

                      // Subtle inner top highlight (matching embossed raised depth)
                      if (isDark)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 38,
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0x384FA2E8),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Text and Category on Bottom
                      Positioned(
                        left: 14,
                        right: 14,
                        bottom: 14,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.primaryCategoryName.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time_rounded,
                                  size: 12,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  item.timeAgo,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Icon(
                                  Icons.visibility_outlined,
                                  size: 12,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${item.formattedViews} views',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Dots Indicator
        if (items.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(items.length, (index) {
              final active = index == _featuredIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.primary
                      : (isDark ? const Color(0x55415D7E) : Colors.black12),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
      ],
    );
  }

  Widget _buildCategoriesSection(List<CategoryModel> categories, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: _sectionPanelDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Explore Topics',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CategoriesScreen(),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text(
                    'View All',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 92,
            child: PageView.builder(
              controller: _topicsPageController,
              padEnds: false,
              itemBuilder: (context, index) {
                if (categories.isEmpty) return const SizedBox.shrink();
                final firstIndex = (index * 3) % categories.length;
                final secondIndex = (firstIndex + 1) % categories.length;
                final thirdIndex = (firstIndex + 2) % categories.length;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTopicChip(categories[firstIndex], isDark),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: categories.length > 1
                            ? _buildTopicChip(categories[secondIndex], isDark)
                            : const SizedBox.shrink(),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: categories.length > 2
                            ? _buildTopicChip(categories[thirdIndex], isDark)
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicChip(CategoryModel cat, bool isDark) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryDetailScreen(category: cat),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F1E2E) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0x403A536F) : AppColors.lightBorder,
            width: 1.0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.explore_rounded,
              color: AppColors.primary,
              size: 22,
            ),
            const SizedBox(height: 6),
            Text(
              cat.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryStream(
    CategoryModel category,
    List<ArticleModel> articles,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: _sectionPanelDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CategoryDetailScreen(category: category),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text(
                    'View All →',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (articles.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Text(
                'New stories are coming soon.',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                ),
              ),
            )
          else
            SizedBox(
              height: 240,
              child: PageView.builder(
                controller: _categoryPageController(category.id),
                padEnds: false,
                itemBuilder: (context, index) {
                  final firstIndex = (index * 2) % articles.length;
                  final secondIndex = (firstIndex + 1) % articles.length;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: ArticleCard(
                            article: articles[firstIndex],
                            isHorizontal: false,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: articles.length > 1
                              ? ArticleCard(
                                  article: articles[secondIndex],
                                  isHorizontal: false,
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback onTap;

  const _HeaderAction({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 2),
              Icon(icon, size: 21, color: AppColors.primary),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
