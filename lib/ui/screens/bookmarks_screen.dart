import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/bookmark_provider.dart';
import '../widgets/article_card.dart';
import '../widgets/empty_state_widget.dart';

class BookmarksScreen extends StatelessWidget {
  final VoidCallback? onExploreTap;

  const BookmarksScreen({super.key, this.onExploreTap});

  @override
  Widget build(BuildContext context) {
    final bookmarkProvider = Provider.of<BookmarkProvider>(context);
    final bookmarks = bookmarkProvider.bookmarks;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Saved Articles'),
            if (bookmarks.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${bookmarks.length}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      body: bookmarks.isEmpty
          ? EmptyStateWidget(
              title: 'No Saved Articles Yet',
              message: 'Tap the bookmark icon on any news story to save it for quick reading later.',
              icon: Icons.bookmark_border_rounded,
              action: onExploreTap != null
                  ? ElevatedButton(
                      onPressed: onExploreTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Explore Latest News'),
                    )
                  : null,
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: bookmarks.length,
              itemBuilder: (context, index) {
                final article = bookmarks[index];
                return Dismissible(
                  key: Key('bookmark_${article.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    color: AppColors.error,
                    child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
                  ),
                  onDismissed: (_) {
                    bookmarkProvider.removeBookmark(article.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Removed "${article.title}"'),
                        action: SnackBarAction(
                          label: 'Undo',
                          onPressed: () => bookmarkProvider.toggleBookmark(article),
                        ),
                      ),
                    );
                  },
                  child: ArticleCard(article: article, isHorizontal: true),
                );
              },
            ),
    );
  }
}
