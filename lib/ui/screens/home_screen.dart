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

  BoxDecoration _sectionPanelDecoration(bool isDark, {Color? accentColor}) {
    final accent = accentColor ?? const Color(0xFF0095FF);
    if (!isDark) {
      return BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        border: Border.all(
          color: accent.withValues(alpha: 0.24),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
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
          Color(0xFF2E5380), // subtle inner top highlight (real embossed/raised depth)
          Color(0xF5102238), // transition
          Color(0xFA071220), // noticeably darker/more opaque panel fill
          Color(0xFF030811), // deep rich base
        ],
        stops: [0.0, 0.045, 0.22, 1.0],
      ),
      border: Border.all(
        color: accent.withValues(alpha: 0.45),
        width: 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.75),
          blurRadius: 24,
          spreadRadius: 1,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: accent.withValues(alpha: 0.22),
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
                color: AppColors.warning.withValues(alpha: 0.9),
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isTablet = MediaQuery.of(context).size.shortestSide >= 600 &&
                      constraints.maxWidth >= 700;
                  final carouselHeight = isTablet ? 145.0 : 132.0;

                  return Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: _sectionPanelDecoration(
                      isDark,
                      accentColor: const Color(0xFF0095FF),
                    ),
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
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFA0967), Color(0xFFFF176F)],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x60FA0967),
                                      blurRadius: 6,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
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
                          height: carouselHeight,
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
                  );
                },
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = MediaQuery.of(context).size.shortestSide >= 600 &&
            constraints.maxWidth >= 768;

        if (!isTablet) {
          // Mobile Viewport: retain intact single-card swipeable carousel
          return SizedBox(
            height: 345.0,
            child: PageView.builder(
              controller: _featuredPageController,
              itemCount: items.length,
              onPageChanged: (idx) => setState(() => _featuredIndex = idx),
              itemBuilder: (context, index) {
                final item = items[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  child: ArticleCard.hero(
                    article: item,
                    sliderIndex: _featuredIndex,
                    sliderTotal: items.length,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ArticleDetailScreen(article: item),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        }

        // Tablet / iPad Viewport (width >= 768): Website Split Hero Banner Design
        return _buildTabletSplitHeroBanner(items, constraints.maxWidth, isDark);
      },
    );
  }

  Widget _buildTabletSplitHeroBanner(
    List<ArticleModel> items,
    double maxWidth,
    bool isDark,
  ) {
    final bannerHeight = (maxWidth * 0.44).clamp(390.0, 440.0);
    final sideArticles =
        items.length > 5 ? items.sublist(1, 5) : items.sublist(1);

    if (sideArticles.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SizedBox(
          height: bannerHeight,
          child: ArticleCard.hero(
            article: items.first,
            sliderIndex: 0,
            sliderTotal: 1,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ArticleDetailScreen(article: items.first),
                ),
              );
            },
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        height: bannerHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left: Large Main Hero Card (Website .cf-hero matching)
            Expanded(
              flex: 58,
              child: PageView.builder(
                controller: _featuredPageController,
                itemCount: items.length,
                onPageChanged: (idx) => setState(() => _featuredIndex = idx),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ArticleCard.hero(
                    article: item,
                    sliderIndex: _featuredIndex,
                    sliderTotal: items.length,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ArticleDetailScreen(article: item),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(width: 14),

            // Right: Vertical list of next 4 mini cards (Website .cf-side-news matching)
            Expanded(
              flex: 42,
              child: Column(
                children: [
                  for (int i = 0; i < sideArticles.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    Expanded(
                      child: _buildSideMiniCard(
                        article: sideArticles[i],
                        actualIndex: i + 1,
                        isSelected: _featuredIndex == (i + 1),
                        isDark: isDark,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSideMiniCard({
    required ArticleModel article,
    required int actualIndex,
    required bool isSelected,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (_featuredPageController.hasClients) {
            _featuredPageController.animateToPage(
              actualIndex,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
            );
          }
          setState(() => _featuredIndex = actualIndex);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ArticleDetailScreen(article: article),
            ),
          );
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: isDark
                ? (isSelected
                    ? const Color(0xFF0D1B2A)
                    : const Color(0xFF050D17))
                : (isSelected
                    ? const Color(0xFFF1F5F9)
                    : Colors.white),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDark
                      ? const Color(0x28FA0967)
                      : const Color(0x18000000)),
              width: isSelected ? 1.4 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Thumbnail Image (.cf-side-card img)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 104,
                  height: double.infinity,
                  child: article.image != null && article.image!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: article.image!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: isDark
                                ? const Color(0xFF0B1725)
                                : const Color(0xFFF0F2F5),
                            child: const Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: isDark
                                ? const Color(0xFF0B1725)
                                : const Color(0xFFF0F2F5),
                            child: const Icon(
                              Icons.movie_creation_outlined,
                              size: 24,
                              color: Colors.white24,
                            ),
                          ),
                        )
                      : Container(
                          color: isDark
                              ? const Color(0xFF0B1725)
                              : const Color(0xFFF0F2F5),
                          child: const Icon(
                            Icons.movie_creation_outlined,
                            size: 24,
                            color: Colors.white24,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),

              // 2. Content Details (.cf-side-copy)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Kicker category tag (.cf-side-copy em)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFA30849), AppColors.primary],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        article.primaryCategoryName.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),

                    // Title (.cf-side-copy strong)
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDark
                            ? Colors.white
                            : AppColors.textPrimaryLight,
                        fontSize: 12.0,
                        fontWeight: FontWeight.w600,
                        height: 1.22,
                      ),
                    ),
                    const SizedBox(height: 3),

                    // Meta: Reading time & Views (.cf-side-copy small)
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 11,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${article.readingTimeMinutes} min read',
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFF9CA8B8)
                                : Colors.black54,
                            fontSize: 10.0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.remove_red_eye_outlined,
                          size: 11,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            '${article.formattedViews} Views',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFF9CA8B8)
                                  : Colors.black54,
                              fontSize: 10.0,
                            ),
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
      ),
    );
  }

  static Map<String, dynamic> _getTopicTheme(String slug, bool isDark) {
    final s = slug.toLowerCase();
    if (s.contains('trailer') || s.contains('premieres') || s.contains('video')) {
      // Fiery Orange
      return {
        'gradient': const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF5722), Color(0xFFF4511E), Color(0xFFBF360C)],
        ),
        'accent': const Color(0xFFFFAB40),
        'icon': Icons.play_circle_fill_rounded,
        'badgeGradient': const [Color(0xFFFFAB40), Color(0xFFFF3D00)],
      };
    } else if (s.contains('ott') || s.contains('series')) {
      // Electric Blue
      return {
        'gradient': const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8), Color(0xFF1E3A8A)],
        ),
        'accent': const Color(0xFF60A5FA),
        'icon': Icons.tv_rounded,
        'badgeGradient': const [Color(0xFF38BDF8), Color(0xFF1D4ED8)],
      };
    } else if (s.contains('theatre') || s.contains('drama')) {
      // Deep Crimson / Magenta
      return {
        'gradient': const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE11D48), Color(0xFFBE123C), Color(0xFF881337)],
        ),
        'accent': const Color(0xFFFB7185),
        'icon': Icons.theater_comedy_rounded,
        'badgeGradient': const [Color(0xFFFB7185), Color(0xFFBE123C)],
      };
    } else if (s.contains('interview') || s.contains('podcast')) {
      // Bright Cyan / Teal
      return {
        'gradient': const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF06B6D4), Color(0xFF0891B2), Color(0xFF0E7490)],
        ),
        'accent': const Color(0xFF67E8F9),
        'icon': Icons.mic_rounded,
        'badgeGradient': const [Color(0xFF22D3EE), Color(0xFF0891B2)],
      };
    } else if (s.contains('bollywood')) {
      // Hot Magenta / Neon Pink
      return {
        'gradient': const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF1493), Color(0xFFD81B60), Color(0xFF880E4F)],
        ),
        'accent': const Color(0xFFFF4081),
        'icon': Icons.movie_filter_rounded,
        'badgeGradient': const [Color(0xFFA30849), Color(0xFFFF0871)],
      };
    } else if (s.contains('music')) {
      // Electric Violet / Purple
      return {
        'gradient': const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFA855F7), Color(0xFF7C3AED), Color(0xFF4C1D95)],
        ),
        'accent': const Color(0xFFE879F9),
        'icon': Icons.music_note_rounded,
        'badgeGradient': const [Color(0xFF9333EA), Color(0xFFC084FC)],
      };
    } else if (s.contains('review')) {
      // Neon Emerald Green
      return {
        'gradient': const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF10B981), Color(0xFF059669), Color(0xFF064E3B)],
        ),
        'accent': const Color(0xFF34D399),
        'icon': Icons.rate_review_rounded,
        'badgeGradient': const [Color(0xFF047857), Color(0xFF34D399)],
      };
    } else if (s.contains('talent') || s.contains('star')) {
      // Golden Amber
      return {
        'gradient': const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF59E0B), Color(0xFFD97706), Color(0xFF78350F)],
        ),
        'accent': const Color(0xFFFDE047),
        'icon': Icons.star_rounded,
        'badgeGradient': const [Color(0xFFA16207), Color(0xFFFACC15)],
      };
    } else if (s.contains('award') || s.contains('event')) {
      // Royal Amethyst
      return {
        'gradient': const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9), Color(0xFF3B0764)],
        ),
        'accent': const Color(0xFFC4B5FD),
        'icon': Icons.emoji_events_rounded,
        'badgeGradient': const [Color(0xFF7E22CE), Color(0xFFC084FC)],
      };
    }
    // Fallback: Vivid Sapphire
    return {
      'gradient': const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8), Color(0xFF172554)],
      ),
      'accent': const Color(0xFF93C5FD),
      'icon': Icons.explore_rounded,
      'badgeGradient': const [Color(0xFF0284C7), Color(0xFF38BDF8)],
    };
  }

  Widget _buildCategoriesSection(List<CategoryModel> categories, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = MediaQuery.of(context).size.shortestSide >= 600 &&
            constraints.maxWidth >= 700;
        final cardsPerRow = isTablet ? 4 : 3;
        final sectionHeight = isTablet ? 122.0 : 102.0;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: _sectionPanelDecoration(
            isDark,
            accentColor: const Color(0xFFFF0871),
          ),
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
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFA0967), Color(0xFFFF176F)],
                        ),
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x60FF0871),
                            blurRadius: 6,
                            offset: Offset(0, 1),
                          ),
                        ],
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
                height: sectionHeight,
                child: PageView.builder(
                  controller: _topicsPageController,
                  padEnds: false,
                  itemBuilder: (context, index) {
                    if (categories.isEmpty) return const SizedBox.shrink();
                    final firstIndex = (index * cardsPerRow) % categories.length;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: List.generate(cardsPerRow, (slot) {
                          final catIdx = (firstIndex + slot) % categories.length;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: slot < cardsPerRow - 1 ? 8.0 : 0.0,
                              ),
                              child: categories.length > slot
                                  ? _buildTopicChip(categories[catIdx], isDark)
                                  : const SizedBox.shrink(),
                            ),
                          );
                        }),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopicChip(CategoryModel cat, bool isDark) {
    final theme = _getTopicTheme(cat.slug, isDark);
    final gradient = theme['gradient'] as LinearGradient;
    final accent = theme['accent'] as Color;
    final icon = theme['icon'] as IconData;

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accent.withValues(alpha: 0.75),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.35),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.white.withValues(alpha: 0.28),
          highlightColor: Colors.white.withValues(alpha: 0.14),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CategoryDetailScreen(category: cat),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(7.5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.45),
                      width: 1.1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.20),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  cat.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.2,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 6,
                        offset: Offset(0, 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryStream(
    CategoryModel category,
    List<ArticleModel> articles,
    bool isDark,
  ) {
    final theme = _getTopicTheme(category.slug, isDark);
    final accent = theme['accent'] as Color;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = MediaQuery.of(context).size.shortestSide >= 600 &&
            constraints.maxWidth >= 700;
        final cardsPerPage = isTablet
            ? (constraints.maxWidth >= 1000 ? 4 : 3)
            : 2;
        final carouselHeight = isTablet ? 285.0 : 245.0;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: _sectionPanelDecoration(isDark, accentColor: accent),
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
                        gradient: LinearGradient(
                          colors: [accent, accent.withValues(alpha: 0.7)],
                        ),
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.5),
                            blurRadius: 6,
                            offset: const Offset(0, 1),
                          ),
                        ],
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                  height: carouselHeight,
                  child: PageView.builder(
                    controller: _categoryPageController(category.id),
                    padEnds: false,
                    itemBuilder: (context, index) {
                      final firstIndex =
                          (index * cardsPerPage) % articles.length;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          children: List.generate(cardsPerPage, (slot) {
                            final artIdx =
                                (firstIndex + slot) % articles.length;
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: slot < cardsPerPage - 1 ? 10.0 : 0.0,
                                ),
                                child: articles.length > slot
                                    ? ArticleCard(
                                        article: articles[artIdx],
                                        isHorizontal: false,
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            );
                          }),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
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
