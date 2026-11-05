import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/home_provider.dart';
import 'category_detail_screen.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  static Map<String, dynamic> _getCategoryTheme(String slug, bool isDark) {
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final homeProvider = Provider.of<HomeProvider>(context);
    final categories = homeProvider.categories;
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600 &&
        MediaQuery.of(context).size.width >= 700;

    return Scaffold(
      appBar: AppBar(
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Back',
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text('Categories'),
      ),
      body: categories.isEmpty
          ? Center(
              child: homeProvider.isLoading
                  ? const CircularProgressIndicator()
                  : const Text('No categories found'),
            )
          : RefreshIndicator(
              onRefresh: () => homeProvider.refresh(),
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isTablet ? 4 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: isTablet ? 1.25 : 1.15,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final theme = _getCategoryTheme(cat.slug, isDark);
                  final gradient = theme['gradient'] as LinearGradient;
                  final accent = theme['accent'] as Color;
                  final icon = theme['icon'] as IconData;
                  final badgeGradient = theme['badgeGradient'] as List<Color>;

                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CategoryDetailScreen(category: cat),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: gradient,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: accent.withValues(alpha: isDark ? 0.38 : 0.28),
                          width: 1.1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.40 : 0.06,
                            ),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: badgeGradient,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      badgeGradient.last.withValues(alpha: 0.35),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              icon,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cat.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                              ),
                              if (cat.description != null &&
                                  cat.description!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  cat.description!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? AppColors.darkTextMuted
                                        : AppColors.lightTextMuted,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
