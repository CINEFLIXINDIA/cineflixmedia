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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isTablet = constraints.maxWidth >= 700;
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
        final isIPad = constraints.maxWidth >= 700;

        return Column(
          children: [
            SizedBox(
              height: isIPad
                  ? (constraints.maxWidth * 0.42).clamp(360.0, 480.0)
                  : 325,
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
                              ? const Color(0x403A536F)
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
                              color: Color(0x250095FF),
                              blurRadius: 16,
                              spreadRadius: 0,
                              offset: Offset(0, 1),
                            ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: isIPad
                          ? _buildTabletFeaturedCard(
                              items[index],
                              items.length,
                              constraints.maxWidth - 28,
                              isDark,
                            )
                          : _buildPhoneFeaturedCard(items[index], isDark),
                    ),
                  );
                },
              ),
            ),
            if (items.length > 1 && !isIPad)
              _buildPhoneFeaturedIndicators(items.length, isDark),
          ],
        );
      },
    );
  }

  Widget _buildPhoneFeaturedCard(ArticleModel item, bool isDark) {
    return Stack(
      fit: StackFit.expand,
      children: [
        item.image != null && item.image!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: item.image!,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                placeholder: (context, url) => Container(
                  color: isDark ? AppColors.darkCard : const Color(0xFF07111D),
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
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 0.20, 0.50, 1.0],
              colors: [
                Color(0x33000000),
                Color(0x66000000),
                Color(0xDD020811),
                Color(0xF8020811),
              ],
            ),
          ),
        ),
        if (isDark)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 38,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x384FA2E8), Colors.transparent],
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          left: 14,
          right: 14,
          bottom: 14,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFA30849), Color(0xFFFF0871)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF0871).withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.mic_rounded,
                      size: 11,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      item.primaryCategoryName.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                  shadows: [
                    Shadow(color: Colors.black87, blurRadius: 10),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              if (item.cleanSummary.isNotEmpty) ...[
                Text(
                  item.cleanSummary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                    height: 1.35,
                    shadows: const [
                      Shadow(color: Colors.black87, blurRadius: 8),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ] else ...[
                const SizedBox(height: 6),
              ],
              Row(
                children: [
                  const Icon(
                    Icons.visibility_outlined,
                    size: 13,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${item.formattedViews} Views',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7.5,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFA0967), Color(0xFFFF176F)],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF0871).withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Read Full Story',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        SizedBox(width: 5),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 12,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabletFeaturedCard(
    ArticleModel item,
    int itemCount,
    double cardWidth,
    bool isDark,
  ) {
    final titleSize = (cardWidth * 0.032).clamp(24.0, 34.0);
    final theme = _getTopicTheme(item.primaryCategoryName, isDark);
    final badgeGradient = theme['badgeGradient'] as List<Color>;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background Hero Image
        if (item.image != null && item.image!.isNotEmpty)
          CachedNetworkImage(
            imageUrl: item.image!,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            placeholder: (context, url) => Container(
              color: const Color(0xFF020811),
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: const Color(0xFF020811),
              child: const Center(
                child: Icon(
                  Icons.movie_creation_outlined,
                  size: 64,
                  color: Colors.white24,
                ),
              ),
            ),
          )
        else
          Container(color: const Color(0xFF020811)),

        // Dark cinematic vignette overlays (website matching)
        // 1. Horizontal gradient: deep black on left, fading to right
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [0.0, 0.40, 0.70, 1.0],
              colors: [
                Color(0xF5020811),
                Color(0xCC020811),
                Color(0x44020811),
                Color(0x15020811),
              ],
            ),
          ),
        ),
        // 2. Vertical bottom gradient: deep black at bottom
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 0.50, 1.0],
              colors: [
                Color(0x10020811),
                Color(0x66020811),
                Color(0xF0020811),
              ],
            ),
          ),
        ),

        // Text & Content Column
        Positioned(
          left: 28,
          right: cardWidth * 0.35,
          bottom: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category kicker badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: badgeGradient,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: badgeGradient.first.withValues(alpha: 0.45),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.mic_rounded,
                      color: Colors.white,
                      size: 13,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      item.primaryCategoryName.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Bold Title
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: titleSize,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                  shadows: const [
                    Shadow(color: Colors.black87, blurRadius: 16),
                  ],
                ),
              ),
              if (item.cleanSummary.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  item.cleanSummary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 14.5,
                    height: 1.35,
                    shadows: const [
                      Shadow(color: Colors.black87, blurRadius: 12),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              // Action Row: Views + Pink CTA Button
              Row(
                children: [
                  const Icon(
                    Icons.visibility_outlined,
                    size: 17,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${item.formattedViews} Views',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFA0967), Color(0xFFFF176F)],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF0871).withValues(alpha: 0.45),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Read Full Story',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 15,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (itemCount > 1) _buildTabletFeaturedIndicatorsOverlay(itemCount),
      ],
    );
  }

  Widget _buildPhoneFeaturedIndicators(int count, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (index) {
          final active = index == _featuredIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: active ? 24 : 6,
            height: 5,
            decoration: BoxDecoration(
              color: active
                  ? AppColors.primary
                  : (isDark ? const Color(0x55415D7E) : Colors.black12),
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabletFeaturedIndicatorsOverlay(int count) {
    return Positioned(
      bottom: 7,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (index) {
          final active = index == _featuredIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: active ? 22 : 8,
            height: 5,
            decoration: BoxDecoration(
              color: active ? const Color(0xFFE83E78) : Colors.white70,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }

  static Map<String, dynamic> _getTopicTheme(String slug, bool isDark) {
    final s = slug.toLowerCase();
    if (s.contains('bollywood')) {
      return {
        'gradient': isDark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF380E23), Color(0xFF1E0713), Color(0xFF0C0308)],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFF0F5), Color(0xFFFFDEE9)],
              ),
        'accent': const Color(0xFFFF1493),
        'icon': Icons.movie_filter_rounded,
        'badgeGradient': const [Color(0xFFA30849), Color(0xFFFF0871)],
      };
    } else if (s.contains('music')) {
      return {
        'gradient': isDark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF320E3D), Color(0xFF1B0721), Color(0xFF0C0310)],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFBF0FF), Color(0xFFF1DEFF)],
              ),
        'accent': const Color(0xFFD946EF),
        'icon': Icons.music_note_rounded,
        'badgeGradient': const [Color(0xFF9333EA), Color(0xFFC084FC)],
      };
    } else if (s.contains('theatre') || s.contains('drama')) {
      return {
        'gradient': isDark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF381014), Color(0xFF1F080A), Color(0xFF0F0304)],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFF1F2), Color(0xFFFFE4E6)],
              ),
        'accent': const Color(0xFFF43F5E),
        'icon': Icons.theater_comedy_rounded,
        'badgeGradient': const [Color(0xFFBE123C), Color(0xFFFB7185)],
      };
    } else if (s.contains('ott') || s.contains('series')) {
      return {
        'gradient': isDark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F1E38), Color(0xFF08101F), Color(0xFF03070F)],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
              ),
        'accent': const Color(0xFF3B82F6),
        'icon': Icons.tv_rounded,
        'badgeGradient': const [Color(0xFF1D4ED8), Color(0xFF60A5FA)],
      };
    } else if (s.contains('review')) {
      return {
        'gradient': isDark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D2E2B), Color(0xFF071A18), Color(0xFF030D0C)],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
              ),
        'accent': const Color(0xFF10B981),
        'icon': Icons.rate_review_rounded,
        'badgeGradient': const [Color(0xFF047857), Color(0xFF34D399)],
      };
    } else if (s.contains('trailer') || s.contains('premieres') || s.contains('video')) {
      return {
        'gradient': isDark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3A180D), Color(0xFF200D07), Color(0xFF0F0603)],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
              ),
        'accent': const Color(0xFFF97316),
        'icon': Icons.play_circle_fill_rounded,
        'badgeGradient': const [Color(0xFFC2410C), Color(0xFFFB923C)],
      };
    } else if (s.contains('talent') || s.contains('star')) {
      return {
        'gradient': isDark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF382A0D), Color(0xFF1F1707), Color(0xFF0F0B03)],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFEFCE8), Color(0xFFFEF08A)],
              ),
        'accent': const Color(0xFFEAB308),
        'icon': Icons.star_rounded,
        'badgeGradient': const [Color(0xFFA16207), Color(0xFFFACC15)],
      };
    } else if (s.contains('interview') || s.contains('podcast')) {
      return {
        'gradient': isDark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF102A36), Color(0xFF08171E), Color(0xFF040B0F)],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFECFEFF), Color(0xFFCFFAFE)],
              ),
        'accent': const Color(0xFF06B6D4),
        'icon': Icons.mic_rounded,
        'badgeGradient': const [Color(0xFF0E7490), Color(0xFF22D3EE)],
      };
    } else if (s.contains('award') || s.contains('event')) {
      return {
        'gradient': isDark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2E0F38), Color(0xFF1A0820), Color(0xFF0D0410)],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFAF5FF), Color(0xFFF3E8FF)],
              ),
        'accent': const Color(0xFFA855F7),
        'icon': Icons.emoji_events_rounded,
        'badgeGradient': const [Color(0xFF7E22CE), Color(0xFFC084FC)],
      };
    }
    return {
      'gradient': isDark
          ? const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF14243B), Color(0xFF0B1422), Color(0xFF050A12)],
            )
          : const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
            ),
      'accent': const Color(0xFF0095FF),
      'icon': Icons.explore_rounded,
      'badgeGradient': const [Color(0xFF0284C7), Color(0xFF38BDF8)],
    };
  }

  Widget _buildCategoriesSection(List<CategoryModel> categories, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 700;
        final cardsPerRow = isTablet ? 4 : 3;
        final sectionHeight = isTablet ? 116.0 : 96.0;

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
    final badgeGradient = theme['badgeGradient'] as List<Color>;

    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryDetailScreen(category: cat),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: accent.withValues(alpha: isDark ? 0.40 : 0.28),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
            if (isDark)
              BoxShadow(
                color: accent.withValues(alpha: 0.16),
                blurRadius: 8,
                offset: const Offset(0, 1),
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: badgeGradient,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: badgeGradient.last.withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 16,
              ),
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
    final theme = _getTopicTheme(category.slug, isDark);
    final accent = theme['accent'] as Color;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 700;
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
