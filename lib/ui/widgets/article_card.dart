import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/ad_service.dart';
import '../../data/models/article_model.dart';
import '../../providers/bookmark_provider.dart';
import '../screens/article_detail_screen.dart';

class ArticleCard extends StatelessWidget {
  final ArticleModel article;
  final bool isHorizontal;
  final bool isHero;
  final int? sliderIndex;
  final int? sliderTotal;
  final VoidCallback? onTap;

  const ArticleCard({
    super.key,
    required this.article,
    this.isHorizontal = true,
    this.isHero = false,
    this.sliderIndex,
    this.sliderTotal,
    this.onTap,
  });

  const ArticleCard.hero({
    super.key,
    required this.article,
    this.sliderIndex,
    this.sliderTotal,
    this.onTap,
  })  : isHorizontal = false,
        isHero = true;

  void _openDetail(BuildContext context) {
    if (onTap != null) {
      onTap!();
      return;
    }

    AdService().showInterstitialWithInterval(
      interval: 4,
      onDismissed: () {
        if (!context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ArticleDetailScreen(article: article),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isHero) {
      return _buildHeroCard(context, isDark);
    }

    if (isHorizontal) {
      return InkWell(
        onTap: () => _openDetail(context),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 105,
                  height: 95,
                  child: article.image != null && article.image!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: article.image!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: isDark
                                ? AppColors.darkSurface
                                : const Color(0xFFF0F2F5),
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) =>
                              _fallbackImage(isDark),
                        )
                      : _fallbackImage(isDark),
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Category badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              article.primaryCategoryName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        // Quick bookmark
                        Consumer<BookmarkProvider>(
                          builder: (context, bookmarkProvider, child) {
                            final isSaved = bookmarkProvider.isBookmarked(
                              article.id,
                            );
                            return GestureDetector(
                              onTap: () =>
                                  bookmarkProvider.toggleBookmark(article),
                              child: Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: Icon(
                                  isSaved
                                      ? Icons.bookmark
                                      : Icons.bookmark_border,
                                  size: 19,
                                  color: isSaved
                                      ? AppColors.accent
                                      : (isDark
                                            ? AppColors.darkTextMuted
                                            : AppColors.lightTextMuted),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    // Title
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Metadata row
                    LayoutBuilder(
                      builder: (context, metaConstraints) {
                        final showReadingTime = metaConstraints.maxWidth >= 190;
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 12.5,
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted,
                            ),
                            const SizedBox(width: 3.5),
                            Flexible(
                              child: Text(
                                article.timeAgo,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark
                                      ? AppColors.darkTextMuted
                                      : AppColors.lightTextMuted,
                                ),
                              ),
                            ),
                            if (showReadingTime) ...[
                              const SizedBox(width: 6),
                              Text(
                                '${article.readingTimeMinutes} min read',
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark
                                      ? AppColors.darkTextMuted
                                      : AppColors.lightTextMuted,
                                ),
                              ),
                            ],
                            const SizedBox(width: 6),
                            Icon(
                              Icons.visibility_outlined,
                              size: 12.5,
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              article.formattedViews,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Vertical / Featured style
    return InkWell(
      onTap: () => _openDetail(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 12,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  article.image != null && article.image!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: article.image!,
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                          placeholder: (context, url) => Container(
                            color: isDark
                                ? AppColors.darkSurface
                                : const Color(0xFFF0F2F5),
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) =>
                              _fallbackImage(isDark),
                        )
                      : _fallbackImage(isDark),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            article.primaryCategoryName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          article.timeAgo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(
                        Icons.visibility_outlined,
                        size: 12,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${article.formattedViews} views',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
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
  }

  Widget _buildHeroCard(BuildContext context, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        final isTabletDevice =
            MediaQuery.of(context).size.width >= 768 || cardWidth >= 500;
        final isTablet = cardWidth >= 650;
        final titleSize = isTablet
            ? (cardWidth * 0.032).clamp(24.0, 34.0)
            : 18.0;

        return InkWell(
          onTap: () => _openDetail(context),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF020811),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? const Color(0x35FA0967)
                    : const Color(0x20B0B8C4),
                width: 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.70 : 0.12),
                  blurRadius: 22,
                  spreadRadius: 1,
                  offset: const Offset(0, 8),
                ),
                if (isDark)
                  const BoxShadow(
                    color: Color(0x20FA0967),
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
                // 1. Cover Image
                article.image != null && article.image!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: article.image!,
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
                              size: 48,
                              color: Colors.white24,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        color: const Color(0xFF020811),
                        child: const Center(
                          child: Icon(
                            Icons.movie_creation_outlined,
                            size: 48,
                            color: Colors.white24,
                          ),
                        ),
                      ),

                // 2. Clear Gradient Overlay (Keeps image bright and clear while ensuring text contrast)
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: isTabletDevice
                          ? const [0.0, 0.65, 0.88, 1.0]
                          : const [0.0, 0.40, 0.70, 1.0],
                      colors: isTabletDevice
                          ? const [
                              Colors.transparent,
                              Colors.transparent,
                              Color(0x18000000),
                              Color(0x45000000),
                            ]
                          : const [
                              Colors.transparent,
                              Colors.transparent,
                              Color(0x66020811),
                              Color(0xE6020811),
                            ],
                    ),
                  ),
                ),

                // 3. Website Content (.cf-hero-content)
                Positioned(
                  left: isTablet ? 22 : 16,
                  right: isTablet ? 22 : 16,
                  bottom: (sliderTotal != null && sliderTotal! > 1) ? 26 : 16,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Kicker badge (.cf-kicker)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4.5,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFA30849), Color(0xFFFF0871)],
                          ),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF0871)
                                  .withValues(alpha: 0.35),
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
                              article.primaryCategoryName.toUpperCase(),
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

                      // Title (.cf-hero h1)
                      Text(
                        article.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: titleSize,
                          fontWeight: FontWeight.w800,
                          height: 1.18,
                          shadows: const [
                            Shadow(color: Colors.black87, blurRadius: 12),
                          ],
                        ),
                      ),

                      // Description (.cf-hero p)
                      if (article.cleanSummary.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          article.cleanSummary,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xFFE1E5EC),
                            fontSize: isTablet ? 14.0 : 12.0,
                            height: 1.35,
                            shadows: const [
                              Shadow(color: Colors.black87, blurRadius: 8),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ] else ...[
                        const SizedBox(height: 8),
                      ],

                      // Action Row (.cf-hero-views + .cf-primary-btn)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.visibility_outlined,
                                size: 14,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${article.formattedViews} Views',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          // Pink CTA Button (.cf-primary-btn)
                          Flexible(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 18 : 14,
                                vertical: isTablet ? 8.5 : 7.0,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFFA0967),
                                    Color(0xFFFF176F),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF0871)
                                        .withValues(alpha: 0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      'Read Full Story',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isTablet ? 12.5 : 11.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 4. Slider Dots (.cf-slider-dots)
                if (sliderTotal != null && sliderTotal! > 1)
                  Positioned(
                    bottom: 8,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(sliderTotal!, (dotIdx) {
                        final active = dotIdx == (sliderIndex ?? 0);
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: active ? 24 : 14,
                          height: 4.5,
                          decoration: BoxDecoration(
                            color: active
                                ? const Color(0xFFFF0871)
                                : const Color(0x668B8B8B),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _fallbackImage(bool isDark) {
    return Container(
      color: isDark ? AppColors.darkSurface : const Color(0xFFE8ECEF),
      child: Center(
        child: Icon(
          Icons.movie_creation_outlined,
          size: 32,
          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
        ),
      ),
    );
  }
}
