import 'package:flutter/material.dart';

import '../../data/models/article_model.dart';
import '../../data/models/category_model.dart';
import '../../data/repositories/news_repository.dart';
import '../widgets/article_card.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/shimmer_loading.dart';

class CategoryDetailScreen extends StatefulWidget {
  final CategoryModel category;

  const CategoryDetailScreen({super.key, required this.category});

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  final NewsRepository _newsRepository = NewsRepository();
  final ScrollController _scrollController = ScrollController();

  List<ArticleModel> _articles = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadCategoryNews();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadCategoryNews() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = 1;
    });

    try {
      final paginated = await _newsRepository.getNewsByCategory(
        categoryId: widget.category.id,
        page: 1,
        perPage: 10,
      );

      if (!mounted) return;
      setState(() {
        _articles = paginated.data;
        _hasMore = paginated.hasMore;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('ApiException: ', '');
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final nextPage = _currentPage + 1;
      final paginated = await _newsRepository.getNewsByCategory(
        categoryId: widget.category.id,
        page: nextPage,
        perPage: 10,
      );

      if (!mounted) return;
      setState(() {
        _articles.addAll(paginated.data);
        _currentPage = nextPage;
        _hasMore = paginated.hasMore;
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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.category.name),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView.builder(
        itemCount: 6,
        itemBuilder: (context, index) => const ArticleCardShimmer(),
      );
    }

    if (_errorMessage != null) {
      return ErrorStateWidget(
        message: _errorMessage,
        onRetry: _loadCategoryNews,
      );
    }

    if (_articles.isEmpty) {
      return EmptyStateWidget(
        title: 'No Articles in this Category',
        message: 'Stories in ${widget.category.name} will appear here soon.',
        icon: Icons.newspaper_rounded,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCategoryNews,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _articles.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _articles.length) {
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
          return ArticleCard(article: _articles[index], isHorizontal: true);
        },
      ),
    );
  }
}
