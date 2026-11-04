import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/article_model.dart';
import '../../data/repositories/news_repository.dart';
import '../widgets/article_card.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/shimmer_loading.dart';

class DateArticlesScreen extends StatefulWidget {
  final DateTime selectedDate;

  const DateArticlesScreen({super.key, required this.selectedDate});

  @override
  State<DateArticlesScreen> createState() => _DateArticlesScreenState();
}

class _DateArticlesScreenState extends State<DateArticlesScreen> {
  final NewsRepository _newsRepository = NewsRepository();
  final ScrollController _scrollController = ScrollController();

  final List<ArticleModel> _articles = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  int _currentPage = 1;
  String? _errorMessage;

  String get _apiDate => DateFormat('yyyy-MM-dd').format(widget.selectedDate);
  String get _displayDate =>
      DateFormat('EEEE, MMMM d, yyyy').format(widget.selectedDate);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadArticles();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadArticles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = 1;
    });

    try {
      final response = await _newsRepository.getNewsByDate(
        date: _apiDate,
        page: 1,
      );
      if (!mounted) return;
      setState(() {
        _articles
          ..clear()
          ..addAll(response.data);
        _hasMore = response.hasMore;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error.toString().replaceFirst('ApiException: ', '');
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    try {
      final nextPage = _currentPage + 1;
      final response = await _newsRepository.getNewsByDate(
        date: _apiDate,
        page: nextPage,
      );
      if (!mounted) return;
      setState(() {
        _articles.addAll(response.data);
        _currentPage = nextPage;
        _hasMore = response.hasMore;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Stories by Date'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month_rounded,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _displayDate,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (!_isLoading && _articles.isNotEmpty)
                  Text(
                    '${_articles.length} ${_articles.length == 1 ? 'story' : 'stories'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView.builder(
        itemCount: 5,
        itemBuilder: (_, _) => const ArticleCardShimmer(),
      );
    }

    if (_errorMessage != null) {
      return ErrorStateWidget(message: _errorMessage, onRetry: _loadArticles);
    }

    if (_articles.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.event_busy_rounded,
                color: AppColors.primary,
                size: 48,
              ),
              SizedBox(height: 14),
              Text(
                'No stories published on this date',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadArticles,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _articles.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _articles.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          return ArticleCard(article: _articles[index], isHorizontal: true);
        },
      ),
    );
  }
}
