import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/home_provider.dart';
import 'category_detail_screen.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  static Map<String, dynamic> _getCategoryTheme(String slug, bool isDark) {
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final homeProvider = Provider.of<HomeProvider>(context);
    final categories = homeProvider.categories;
    final isTablet = MediaQuery.of(context).size.width >= 700;

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
