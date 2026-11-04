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
import '../../data/repositories/news_repository.dart';
import '../../providers/bookmark_provider.dart';
import '../../providers/font_size_provider.dart';
import '../../providers/history_provider.dart';
import '../widgets/article_card.dart';
import '../widgets/font_size_modal.dart';
import '../widgets/shimmer_loading.dart';

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
        Provider.of<HistoryProvider>(
          context,
          listen: false,
        ).addToHistory(article);
      }
    });

    // If content is empty (e.g., from list), fetch full article
    if (article.content == null || article.content!.isEmpty) {
      _fetchFullContent(article.slug);
    }

    // Load related articles
    _loadRelated(article);
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

  void _shareArticle() {
    if (_article == null) return;
    Share.share(
      '${_article!.title}\n\nRead more on CineFlix Media:\n${_article!.appDeepLink}',
      subject: _article!.title,
    );
  }

  void _openInBrowser() async {
    if (_article == null) return;
    final uri = Uri.parse(_article!.webUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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
    final fontScale = Provider.of<FontSizeProvider>(context).scaleFactor;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: const Text('Loading Story...'),
        ),
        body: const SingleChildScrollView(child: ArticleDetailShimmer()),
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
        slivers: [
          // Collapsible Image Header
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            leading: CircleAvatar(
              backgroundColor: Colors.black.withOpacity(0.4),
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
                backgroundColor: Colors.black.withOpacity(0.4),
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
              CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.4),
                child: IconButton(
                  icon: const Icon(
                    Icons.share_rounded,
                    color: Colors.white,
                    size: 19,
                  ),
                  onPressed: _shareArticle,
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
                          Colors.black.withOpacity(0.6),
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
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
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category & Reading Time
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          article.primaryCategoryName.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${article.readingTimeMinutes} min read',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.visibility_outlined,
                        size: 14,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${article.formattedViews} views',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Headline
                  Text(
                    article.title,
                    style: TextStyle(
                      fontSize: 22 * fontScale,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                      letterSpacing: -0.3,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Author & Date
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkCard
                          : const Color(0xFFF6F8FA),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.primary,
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                article.author ?? AppConstants.defaultAuthor,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                              ),
                              Text(
                                article.formattedDate,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark
                                      ? AppColors.darkTextMuted
                                      : AppColors.lightTextMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Summary / Lead paragraph if distinct
                  if (article.description != null &&
                      article.description!.trim().isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: const Border(
                          left: BorderSide(color: AppColors.primary, width: 4),
                        ),
                      ),
                      child: Text(
                        article.cleanSummary,
                        style: TextStyle(
                          fontSize: 15.5 * fontScale,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                          height: 1.45,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // HTML Content
                  HtmlWidget(
                    _prepareArticleBody(
                      article.content ?? article.description ?? '',
                    ),
                    textStyle: TextStyle(
                      fontSize: 16 * fontScale,
                      height: 1.6,
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

                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ],
      ),
      // Bottom Floating Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openInBrowser,
                  icon: const Icon(Icons.open_in_browser, size: 18),
                  label: const Text('Open on CineFlix'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _shareArticle,
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Share Article'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
