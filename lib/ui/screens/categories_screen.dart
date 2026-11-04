import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/home_provider.dart';
import 'category_detail_screen.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  IconData _getCategoryIcon(String slug) {
    if (slug.contains('bollywood')) return Icons.movie_filter_rounded;
    if (slug.contains('music')) return Icons.music_note_rounded;
    if (slug.contains('theatre')) return Icons.theater_comedy_rounded;
    if (slug.contains('ott') || slug.contains('series')) {
      return Icons.tv_rounded;
    }
    if (slug.contains('review')) return Icons.rate_review_rounded;
    if (slug.contains('trailer') || slug.contains('premieres')) {
      return Icons.play_circle_fill_rounded;
    }
    if (slug.contains('talent') || slug.contains('star')) {
      return Icons.star_rounded;
    }
    if (slug.contains('interview')) return Icons.mic_rounded;
    if (slug.contains('award') || slug.contains('event')) {
      return Icons.emoji_events_rounded;
    }
    if (slug.contains('business')) return Icons.business_center_rounded;
    return Icons.category_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final homeProvider = Provider.of<HomeProvider>(context);
    final categories = homeProvider.categories;

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
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.15,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final icon = _getCategoryIcon(cat.slug);

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
                        color: isDark ? AppColors.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              icon,
                              color: AppColors.primary,
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
