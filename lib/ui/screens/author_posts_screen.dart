import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/article_model.dart';
import '../../data/repositories/news_repository.dart';
import '../../providers/auth_provider.dart';
import '../widgets/shimmer_loading.dart';
import 'article_detail_screen.dart';
import 'create_post_screen.dart';

class AuthorPostsScreen extends StatefulWidget {
  final String initialStatus;

  const AuthorPostsScreen({
    super.key,
    this.initialStatus = 'all',
  });

  @override
  State<AuthorPostsScreen> createState() => _AuthorPostsScreenState();
}

class _AuthorPostsScreenState extends State<AuthorPostsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NewsRepository _newsRepository = NewsRepository();

  final List<String> _statuses = ['all', 'published', 'pending', 'draft'];
  final List<String> _statusLabels = ['All Posts', 'Published', 'Pending', 'Drafts'];

  final Map<String, List<ArticleModel>> _postsByStatus = {};
  final Map<String, bool> _isLoadingByStatus = {};
  final Map<String, String?> _errorByStatus = {};
  final Map<String, int> _totalByStatus = {};

  @override
  void initState() {
    super.initState();
    final initialIndex = _statuses.indexOf(widget.initialStatus);
    _tabController = TabController(
      length: _statuses.length,
      vsync: this,
      initialIndex: initialIndex >= 0 ? initialIndex : 0,
    );

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      final currentStatus = _statuses[_tabController.index];
      if (!_postsByStatus.containsKey(currentStatus)) {
        _fetchPosts(currentStatus);
      }
    });

    _fetchPosts(_statuses[_tabController.index]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchPosts(String status) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;

    if (token == null) return;

    setState(() {
      _isLoadingByStatus[status] = true;
      _errorByStatus[status] = null;
    });

    try {
      final res = await _newsRepository.getAuthorPosts(
        token: token,
        status: status,
        page: 1,
        perPage: 30,
      );

      setState(() {
        _postsByStatus[status] = res.data;
        _totalByStatus[status] = res.total;
        _isLoadingByStatus[status] = false;
      });
    } catch (e) {
      setState(() {
        _errorByStatus[status] = e.toString();
        _isLoadingByStatus[status] = false;
      });
    }
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String text;

    switch (status.toLowerCase()) {
      case 'published':
        bg = AppColors.primary.withValues(alpha: 0.15);
        fg = AppColors.primary;
        text = 'Published';
        break;
      case 'pending':
        bg = const Color(0xFF10B981).withValues(alpha: 0.15);
        fg = const Color(0xFF10B981);
        text = 'Pending';
        break;
      case 'draft':
        bg = const Color(0xFFEF4444).withValues(alpha: 0.15);
        fg = const Color(0xFFEF4444);
        text = 'Draft';
        break;
      default:
        bg = Colors.grey.withValues(alpha: 0.15);
        fg = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildPostItem(ArticleModel article, bool isDark) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ArticleDetailScreen(article: article),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 90,
                height: 75,
                child: article.image != null && article.image!.isNotEmpty
                    ? Image.network(
                        article.image!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: isDark ? Colors.white10 : Colors.black12,
                          child: const Icon(Icons.article_rounded, size: 28, color: Colors.grey),
                        ),
                      )
                    : Container(
                        color: isDark ? Colors.white10 : Colors.black12,
                        child: const Icon(Icons.article_rounded, size: 28, color: Colors.grey),
                      ),
              ),
            ),

            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildStatusBadge(article.status),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          article.primaryCategoryName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    article.timeAgo.isNotEmpty ? article.timeAgo : article.formattedDate,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBody(String status, bool isDark) {
    final isLoading = _isLoadingByStatus[status] ?? false;
    final error = _errorByStatus[status];
    final posts = _postsByStatus[status];

    if (isLoading && (posts == null || posts.isEmpty)) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: 4,
        itemBuilder: (_, _) => const ArticleCardShimmer(),
      );
    }

    if (error != null && (posts == null || posts.isEmpty)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 44),
              const SizedBox(height: 12),
              Text(
                'Failed to load articles',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                error,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _fetchPosts(status),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (posts == null || posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.article_outlined,
              size: 52,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
            const SizedBox(height: 12),
            Text(
              'No ${status == "all" ? "" : status} posts found',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Articles authored by you will appear here.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white38 : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _fetchPosts(status),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: posts.length,
        itemBuilder: (context, index) => _buildPostItem(posts[index], isDark),
      ),
    );
  }

  Future<void> _openCreatePost() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreatePostScreen()),
    );
    if (result != null && mounted) {
      if (result is ArticleModel) {
        if (result.status.toLowerCase() == 'published') {
          final idx = _statuses.indexOf('published');
          if (idx != -1 && _tabController.index != idx) {
            _tabController.animateTo(idx);
          }
        } else if (result.status.toLowerCase() == 'draft') {
          final idx = _statuses.indexOf('draft');
          if (idx != -1 && _tabController.index != idx) {
            _tabController.animateTo(idx);
          }
        }
      }
      _fetchPosts(_statuses[_tabController.index]);
      if (_tabController.index != 0) {
        _fetchPosts('all');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Author Posts'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
              onPressed: _openCreatePost,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('+ Add New Post', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: _statusLabels.map((label) => Tab(text: label)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _statuses.map((s) => _buildTabBody(s, isDark)).toList(),
      ),
    );
  }
}
