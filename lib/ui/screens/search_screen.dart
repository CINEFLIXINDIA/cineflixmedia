import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/search_provider.dart';
import '../widgets/article_card.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/shimmer_loading.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final searchProvider = Provider.of<SearchProvider>(context, listen: false);
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !searchProvider.isLoadingMore &&
        searchProvider.hasMore) {
      searchProvider.loadMore();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final searchProvider = Provider.of<SearchProvider>(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Container(
          height: 44,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : const Color(0xFFF0F2F5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : Colors.transparent,
            ),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: false,
            textInputAction: TextInputAction.search,
            onChanged: (val) => searchProvider.onQueryChanged(val),
            onSubmitted: (val) => searchProvider.executeSearch(val),
            style: TextStyle(
              fontSize: 14.5,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Search films, stars, OTT, reviews...',
              hintStyle: TextStyle(
                fontSize: 13.5,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        searchProvider.clearSearch();
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ),
      body: _buildContent(searchProvider, isDark),
    );
  }

  Widget _buildContent(SearchProvider provider, bool isDark) {
    if (provider.isSearching) {
      return ListView.builder(
        itemCount: 6,
        itemBuilder: (context, index) => const ArticleCardShimmer(),
      );
    }

    if (provider.errorMessage != null) {
      return ErrorStateWidget(
        message: provider.errorMessage,
        onRetry: () => provider.executeSearch(_searchController.text),
      );
    }

    // Results state
    if (provider.searchResults.isNotEmpty) {
      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: provider.searchResults.length + (provider.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == provider.searchResults.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          return ArticleCard(article: provider.searchResults[index], isHorizontal: true);
        },
      );
    }

    // Empty search result
    if (provider.hasSearched && provider.searchResults.isEmpty) {
      return EmptyStateWidget(
        title: 'No Stories Found',
        message: 'No articles matching "${provider.currentQuery}". Try searching for another topic or actor.',
        icon: Icons.search_off_rounded,
      );
    }

    // Default: Recent Searches & Suggestions
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (provider.recentSearches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Searches',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () => provider.clearRecentSearches(),
                  child: const Text('Clear All', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: provider.recentSearches.map((term) {
                return InputChip(
                  label: Text(term),
                  onPressed: () {
                    _searchController.text = term;
                    provider.executeSearch(term);
                  },
                  onDeleted: () => provider.removeRecentSearch(term),
                  deleteIconColor: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  backgroundColor: isDark ? AppColors.darkCard : const Color(0xFFF0F2F5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Popular suggestions
          Text(
            'Trending Topics',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'Bollywood News',
              'OTT Releases',
              'Web Series',
              'Movie Reviews',
              'Trailers',
              'Pankaj Tripathi',
              'Elvish Yadav',
              'Filmfare Awards',
            ].map((trend) {
              return ActionChip(
                label: Text(trend),
                onPressed: () {
                  _searchController.text = trend;
                  provider.executeSearch(trend);
                },
                backgroundColor: isDark ? AppColors.darkCard : const Color(0xFFF0F2F5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
