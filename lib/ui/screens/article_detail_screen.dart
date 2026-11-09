import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/html_cleaner.dart';
import '../../data/models/article_model.dart';
import '../../data/models/comment_model.dart';
import '../../data/models/rating_model.dart';
import '../../data/repositories/news_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bookmark_provider.dart';
import '../../providers/font_size_provider.dart';
import '../../providers/history_provider.dart';
import '../widgets/article_card.dart';
import '../widgets/font_size_modal.dart';
import '../widgets/shimmer_loading.dart';
import 'login_screen.dart';

class ArticleDetailScreen extends StatefulWidget {
  final ArticleModel? article;
  final String? slug;

  const ArticleDetailScreen({super.key, this.article, this.slug})
    : assert(
        article != null || slug != null,
        'Either article or slug must be provided',
      );

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  late NewsRepository _newsRepository;
  ArticleModel? _article;
  bool _isLoading = false;
  String? _errorMessage;

  List<ArticleModel> _relatedArticles = [];
  bool _isLoadingRelated = false;

  // Engagement State
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _ratingKey = GlobalKey();
  final GlobalKey _commentsKey = GlobalKey();
  final TextEditingController _commentController = TextEditingController();

  List<CommentModel> _comments = [];
  bool _isLoadingComments = false;
  bool _isSubmittingComment = false;

  RatingModel? _ratingData;
  bool _isLoadingRating = false;
  bool _isSubmittingRating = false;

  @override
  void initState() {
    super.initState();
    _newsRepository = NewsRepository();
    _article = widget.article;

    if (_article == null && widget.slug != null) {
      _fetchArticleBySlug(widget.slug!);
    } else if (_article != null) {
      _onArticleLoaded(_article!);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  AuthProvider? _getAuthProvider({bool listen = false}) {
    try {
      return Provider.of<AuthProvider>(context, listen: listen);
    } catch (_) {
      return null;
    }
  }

  double get _currentAverageRating =>
      _ratingData?.averageRating ?? _article?.averageRating ?? 0.0;

  int get _currentTotalRatings =>
      _ratingData?.totalRatings ?? _article?.totalRatings ?? 0;

  int? get _currentUserRating =>
      _ratingData?.userRating ?? _article?.userRating;

  int get _currentCommentsCount =>
      _comments.isNotEmpty ? _comments.length : (_article?.commentsCount ?? 0);

  Future<void> _fetchArticleBySlug(String slug) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final fetched = await _newsRepository.getArticleDetail(slug);
      if (!mounted) return;
      setState(() {
        _article = fetched;
        _isLoading = false;
      });
      _onArticleLoaded(fetched);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('ApiException: ', '');
      });
    }
  }

  void _onArticleLoaded(ArticleModel article) {
    // Record into local reading history
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          Provider.of<HistoryProvider>(
            context,
            listen: false,
          ).addToHistory(article);
        } catch (_) {}
      }
    });

    // If content is empty (e.g., from list), fetch full article
    if (article.content == null || article.content!.isEmpty) {
      _fetchFullContent(article.slug);
    }

    // Load related articles
    _loadRelated(article);

    // Load Engagement Data (comments & ratings)
    _loadRatings(article.id);
    _loadComments(article.id);
  }

  Future<void> _fetchFullContent(String slug) async {
    try {
      final full = await _newsRepository.getArticleDetail(slug);
      if (mounted) {
        setState(() {
          _article = full;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadRelated(ArticleModel article) async {
    if (article.primaryCategoryId == null) return;
    setState(() => _isLoadingRelated = true);
    try {
      final related = await _newsRepository.getRelatedNews(
        categoryId: article.primaryCategoryId!,
        excludeId: article.id,
        perPage: 4,
      );
      if (mounted) {
        setState(() {
          _relatedArticles = related;
          _isLoadingRelated = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingRelated = false);
    }
  }

  Future<void> _loadRatings(dynamic postId) async {
    setState(() => _isLoadingRating = true);
    try {
      final auth = _getAuthProvider();
      final rating = await _newsRepository.getRatings(postId, token: auth?.token);
      if (!mounted) return;
      setState(() {
        _ratingData = rating;
        _isLoadingRating = false;
        if (_article != null) {
          _article = _article!.copyWith(
            averageRating: rating.averageRating,
            totalRatings: rating.totalRatings,
            userRating: rating.userRating,
          );
        }
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingRating = false);
    }
  }

  Future<void> _loadComments(dynamic postId) async {
    setState(() => _isLoadingComments = true);
    try {
      final comments = await _newsRepository.getComments(postId);
      if (!mounted) return;
      setState(() {
        _comments = comments;
        _isLoadingComments = false;
        if (_article != null) {
          _article = _article!.copyWith(commentsCount: comments.length);
        }
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingComments = false);
    }
  }

  Future<void> _onRateArticle(int ratingValue) async {
    if (_article == null) return;
    final auth = _getAuthProvider();
    if (auth == null || !auth.isAuthenticated) {
      _showLoginPrompt('Sign in to submit your rating');
      return;
    }

    final dynamic postIdentifier =
        (_article!.id > 0) ? _article!.id : _article!.slug;

    setState(() => _isSubmittingRating = true);
    try {
      final updated = await _newsRepository.submitRating(
        postIdentifier,
        ratingValue,
        token: auth.token!,
      );
      if (!mounted) return;
      setState(() {
        _ratingData = updated;
        _isSubmittingRating = false;
        _article = _article!.copyWith(
          averageRating: updated.averageRating,
          totalRatings: updated.totalRatings,
          userRating: updated.userRating,
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rating saved: $ratingValue ★. Thank you!'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmittingRating = false);
      final msg = e.toString().replaceFirst('ApiException: ', '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit rating: $msg'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _onSubmitComment() async {
    if (_article == null) return;
    final text = _commentController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a comment'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final auth = _getAuthProvider();
    if (auth == null || !auth.isAuthenticated) {
      _showLoginPrompt('Sign in to share your comment');
      return;
    }

    final dynamic postIdentifier =
        (_article!.id > 0) ? _article!.id : _article!.slug;

    setState(() => _isSubmittingComment = true);
    try {
      final newComment = await _newsRepository.addComment(
        postIdentifier,
        text,
        token: auth.token!,
      );
      _commentController.clear();
      if (mounted) {
        FocusScope.of(context).unfocus();
      }

      if (!mounted) return;
      setState(() {
        _comments.insert(0, newComment);
        _isSubmittingComment = false;
        if (_article != null) {
          _article = _article!.copyWith(commentsCount: _comments.length);
        }
      });

      // Synchronize comments list from server
      _loadComments(postIdentifier);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comment posted successfully!'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmittingComment = false);
      final msg = e.toString().replaceFirst('ApiException: ', '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to post comment: $msg'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showLoginPrompt(String reason) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 48,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'Sign In Required',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  reason,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final nav = Navigator.of(context);
                          Navigator.pop(ctx);
                          nav
                              .push(
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              )
                              .then((_) {
                                if (mounted && _article != null) {
                                  _loadRatings(_article!.id);
                                  _loadComments(_article!.id);
                                }
                              });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Sign In'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _scrollToRating() {
    if (_ratingKey.currentContext != null) {
      Scrollable.ensureVisible(
        _ratingKey.currentContext!,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _scrollToComments() {
    if (_commentsKey.currentContext != null) {
      Scrollable.ensureVisible(
        _commentsKey.currentContext!,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _shareArticle([BuildContext? buttonContext]) async {
    if (_article == null) return;
    final article = _article!;
    final shareUrl =
        (article.webUrl.isNotEmpty && article.webUrl.startsWith('http'))
            ? article.webUrl
            : '${AppConstants.websiteUrl}/blog/${article.slug}';

    Rect? shareOrigin;
    final targetContext = (buttonContext != null && buttonContext.mounted)
        ? buttonContext
        : (mounted ? context : null);

    if (targetContext != null) {
      final box = targetContext.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize && box.size.width > 0 && box.size.height > 0) {
        final mediaSize = MediaQuery.maybeSizeOf(targetContext) ??
            (mounted ? MediaQuery.maybeSizeOf(context) : null);
        final isFullScreenBox = mediaSize != null &&
            box.size.width >= mediaSize.width * 0.9 &&
            box.size.height >= mediaSize.height * 0.9;

        // On iPadOS, UIPopoverPresentationController requires a discrete anchor element
        if (!isFullScreenBox) {
          final origin = box.localToGlobal(Offset.zero);
          shareOrigin = origin & box.size;
        }
      }
    }

    // iPadOS Popover safe fallback anchor: center a small 10x10 point instead of full-screen
    if (shareOrigin == null && mounted) {
      final size = MediaQuery.sizeOf(context);
      shareOrigin = Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.5),
        width: 10,
        height: 10,
      );
    }

    try {
      await Share.share(
        '${article.title}\n\nRead more on CineFlix Media:\n$shareUrl',
        subject: article.title,
        sharePositionOrigin: shareOrigin,
      );
    } catch (e) {
      debugPrint('[ArticleDetailScreen] Share error: $e');
    }
  }

  String _prepareArticleBody(String html) {
    var cleaned = HtmlCleaner.prepareHtmlContent(html);
    final inlineStyleAttribute = RegExp(
      r'''style\s*=\s*(["'])(.*?)\1''',
      caseSensitive: false,
      dotAll: true,
    );
    cleaned = cleaned.replaceAllMapped(inlineStyleAttribute, (match) {
      final declarations = match
          .group(2)!
          .split(';')
          .map((declaration) => declaration.trim())
          .where((declaration) {
            final property = declaration.split(':').first.trim().toLowerCase();
            return property != 'background' &&
                property != 'background-color' &&
                property != 'color';
          })
          .toList();
      return declarations.isEmpty ? '' : 'style="${declarations.join('; ')}"';
    });
    cleaned = cleaned.replaceAll(
      RegExp(r'''\sbgcolor\s*=\s*(["']).*?\1''', caseSensitive: false),
      '',
    );
    return cleaned;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = _getAuthProvider(listen: true);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(leading: const BackButton()),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _article == null) {
      return Scaffold(
        appBar: AppBar(leading: const BackButton()),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage ?? 'Unable to load article',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (widget.slug != null) {
                      _fetchArticleBySlug(widget.slug!);
                    } else if (_article != null) {
                      _fetchFullContent(_article!.slug);
                    }
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final article = _article!;

    return Scaffold(
      backgroundColor: isDark ? AppColors.secondary : Colors.white,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Collapsible Image Header
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            leading: CircleAvatar(
              backgroundColor: Colors.black.withValues(alpha: 0.4),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              // Bookmark Button
              Consumer<BookmarkProvider>(
                builder: (context, bookmarkProvider, child) {
                  final isSaved = bookmarkProvider.isBookmarked(article.id);
                  return CircleAvatar(
                    backgroundColor: Colors.black.withValues(alpha: 0.4),
                    child: IconButton(
                      icon: Icon(
                        isSaved ? Icons.bookmark : Icons.bookmark_border,
                        color: isSaved ? AppColors.accent : Colors.white,
                        size: 20,
                      ),
                      onPressed: () {
                        bookmarkProvider.toggleBookmark(article);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isSaved
                                  ? 'Removed from bookmarks'
                                  : 'Saved to bookmarks',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              // Font Size Button
              CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.4),
                child: IconButton(
                  icon: const Icon(
                    Icons.format_size_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () => FontSizeModal.show(context),
                ),
              ),
              const SizedBox(width: 8),
              // Share Button
              Builder(
                builder: (btnContext) => CircleAvatar(
                  backgroundColor: Colors.black.withValues(alpha: 0.4),
                  child: IconButton(
                    icon: const Icon(
                      Icons.share_rounded,
                      color: Colors.white,
                      size: 19,
                    ),
                    onPressed: () => _shareArticle(btnContext),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  article.image != null && article.image!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: article.image!,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.secondary,
                            child: const Center(
                              child: Icon(
                                Icons.movie_creation_outlined,
                                size: 64,
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
                              size: 64,
                              color: Colors.white30,
                            ),
                          ),
                        ),
                  // Gradient shadow for readability
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.6),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Article Body
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Tag + Read Time
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          article.primaryCategoryName.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${article.readingTimeMinutes} min read',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.visibility_outlined,
                        size: 12,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${article.formattedViews} views',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Title
                  Consumer<FontSizeProvider>(
                    builder: (context, fontProvider, _) {
                      return Text(
                        article.title,
                        style: TextStyle(
                          fontSize: 22 * fontProvider.scaleFactor,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Author & Date Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkCard
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                          child: const Icon(
                            Icons.person,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                article.author ?? AppConstants.defaultAuthor,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                article.formattedDate,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Description / Excerpt (Lead Paragraph)
                  if (article.description != null &&
                      article.description!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkCard.withValues(alpha: 0.5)
                            : AppColors.lightCard,
                        borderRadius: BorderRadius.circular(8),
                        border: const Border(
                          left: BorderSide(
                            color: AppColors.primary,
                            width: 3.5,
                          ),
                        ),
                      ),
                      child: Consumer<FontSizeProvider>(
                        builder: (context, fontProvider, _) {
                          return Text(
                            HtmlCleaner.stripHtml(article.description!),
                            style: TextStyle(
                              fontSize: 15 * fontProvider.scaleFactor,
                              fontStyle: FontStyle.italic,
                              height: 1.5,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Main HTML Content
                  Consumer<FontSizeProvider>(
                    builder: (context, fontProvider, _) {
                      final rawContent = article.content ?? article.description ?? '';
                      final cleanContent = _prepareArticleBody(rawContent);

                      return HtmlWidget(
                        cleanContent,
                        textStyle: TextStyle(
                          fontSize: 16 * fontProvider.scaleFactor,
                          height: 1.7,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                        onTapUrl: (url) async {
                          final uri = Uri.parse(url);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                            return true;
                          }
                          return false;
                        },
                        customStylesBuilder: (element) {
                          if (element.localName == 'img') {
                            return {'border-radius': '8px', 'margin': '12px 0'};
                          }
                          if (element.localName == 'blockquote') {
                            return {
                              'border-left': '4px solid #537FE7',
                              'padding-left': '12px',
                              'font-style': 'italic',
                              'margin': '12px 0',
                            };
                          }
                          return null;
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Tags Wrap
                  if (article.tags.isNotEmpty) ...[
                    const Divider(),
                    const SizedBox(height: 12),
                    Text(
                      'Related Topics',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: article.tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkCard
                                : const Color(0xFFF0F2F5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                            ),
                          ),
                          child: Text(
                            '#$tag',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Related News Section
                  if (_isLoadingRelated) ...[
                    const SizedBox(height: 16),
                    const ArticleCardShimmer(),
                  ] else if (_relatedArticles.isNotEmpty) ...[
                    const Divider(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 18,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Related Stories',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._relatedArticles.map(
                      (rel) => ArticleCard(article: rel, isHorizontal: true),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // 1. Rating & Reviews Section
                  const Divider(),
                  const SizedBox(height: 16),
                  Container(
                    key: _ratingKey,
                    child: _buildRatingCard(isDark, auth),
                  ),

                  const SizedBox(height: 24),

                  // 2. Comments Section
                  const Divider(),
                  const SizedBox(height: 16),
                  Container(
                    key: _commentsKey,
                    child: _buildCommentsSection(isDark, auth),
                  ),

                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom Engagement Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Rating Quick Pill
              InkWell(
                onTap: _scrollToRating,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkCard
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFF59E0B),
                        size: 19,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _currentAverageRating > 0
                            ? _currentAverageRating.toStringAsFixed(1)
                            : 'Rate',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      if (_currentTotalRatings > 0) ...[
                        const SizedBox(width: 3),
                        Text(
                          '($_currentTotalRatings)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Comments Quick Pill
              InkWell(
                onTap: _scrollToComments,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkCard
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: AppColors.primary,
                        size: 17,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '$_currentCommentsCount',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Share Article Button (Expanded) - Preserves iPad Popover Origin
              Expanded(
                child: Builder(
                  builder: (btnContext) => ElevatedButton.icon(
                    onPressed: () => _shareArticle(btnContext),
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text(
                      'Share Article',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingCard(bool isDark, AuthProvider? auth) {
    final avg = _currentAverageRating;
    final total = _currentTotalRatings;
    final userRating = _currentUserRating;
    final isAuthenticated = auth?.isAuthenticated ?? false;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Rate this Article',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const Spacer(),
              if (_isLoadingRating)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Average score block
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    avg > 0 ? avg.toStringAsFixed(1) : '—',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (index) {
                      final starNum = index + 1;
                      return Icon(
                        starNum <= avg.round()
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 15,
                        color: const Color(0xFFF59E0B),
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    total == 1 ? '1 rating' : '$total ratings',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 18),
              Container(
                width: 1,
                height: 70,
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
              const SizedBox(width: 18),
              // User interactive stars
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userRating != null ? 'Your Rating' : 'Tap to rate:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (index) {
                        final starNumber = index + 1;
                        final isFilled =
                            userRating != null && starNumber <= userRating;
                        return InkWell(
                          onTap: _isSubmittingRating
                              ? null
                              : () => _onRateArticle(starNumber),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.only(
                              right: 6,
                              top: 4,
                              bottom: 4,
                            ),
                            child: Icon(
                              isFilled
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: isFilled
                                  ? const Color(0xFFF59E0B)
                                  : (isDark
                                      ? Colors.white30
                                      : Colors.grey[400]),
                              size: 28,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 4),
                    if (_isSubmittingRating) ...[
                      const Row(
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Saving rating...',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ] else if (userRating != null) ...[
                      Text(
                        'You rated $userRating ★ (tap star to change)',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ] else if (!isAuthenticated) ...[
                      InkWell(
                        onTap: () =>
                            _showLoginPrompt('Sign in to submit your rating'),
                        child: const Text(
                          'Sign in to submit rating',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ] else ...[
                      Text(
                        'Share what you think of this piece',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection(bool isDark, AuthProvider? auth) {
    final isAuthenticated = auth?.isAuthenticated ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
            Text(
              'Comments ($_currentCommentsCount)',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const Spacer(),
            if (_isLoadingComments)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20),
                tooltip: 'Refresh comments',
                color: isDark ? Colors.white60 : Colors.black54,
                onPressed: () {
                  if (_article != null) _loadComments(_article!.id);
                },
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Post Comment input card or Login prompt banner
        if (isAuthenticated) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) {
                      if (!_isSubmittingComment) {
                        _onSubmitComment();
                      }
                    },
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Add to the conversation...',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _isSubmittingComment
                    ? const Padding(
                        padding: EdgeInsets.all(8),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.send_rounded),
                        color: AppColors.primary,
                        onPressed: _isSubmittingComment ? null : _onSubmitComment,
                        tooltip: 'Post Comment',
                      ),
              ],
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Sign in to leave a comment and share your opinion.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () =>
                      _showLoginPrompt('Sign in to leave a comment'),
                  child: const Text(
                    'Sign In',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Comments List
        if (_isLoadingComments && _comments.isEmpty) ...[
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
        ] else if (_comments.isEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: 28,
              horizontal: 16,
            ),
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.02)
                  : Colors.black.withValues(alpha: 0.01),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.forum_outlined,
                  size: 38,
                  color: isDark ? Colors.white24 : Colors.black26,
                ),
                const SizedBox(height: 10),
                Text(
                  'No comments yet',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Be the first to share your thoughts on this article!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.black45,
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _comments.length,
            separatorBuilder: (context, index) => Divider(
              height: 24,
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
            itemBuilder: (context, index) {
              final comment = _comments[index];
              return _buildCommentTile(comment, isDark);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildCommentTile(CommentModel comment, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
          backgroundImage: (comment.avatarUrl != null &&
                  comment.avatarUrl!.isNotEmpty &&
                  comment.avatarUrl!.startsWith('http'))
              ? CachedNetworkImageProvider(comment.avatarUrl!)
              : null,
          child: (comment.avatarUrl == null ||
                  comment.avatarUrl!.isEmpty ||
                  !comment.avatarUrl!.startsWith('http'))
              ? Text(
                  comment.initials,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 12),
        // Comment content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      comment.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    comment.timeAgo,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                comment.content,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
