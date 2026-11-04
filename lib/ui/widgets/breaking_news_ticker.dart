import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/article_model.dart';
import '../screens/article_detail_screen.dart';

class BreakingNewsTicker extends StatefulWidget {
  final List<ArticleModel> articles;

  const BreakingNewsTicker({super.key, required this.articles});

  @override
  State<BreakingNewsTicker> createState() => _BreakingNewsTickerState();
}

class _BreakingNewsTickerState extends State<BreakingNewsTicker> {
  final PageController _pageController = PageController();
  Timer? _timer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    if (widget.articles.length <= 1) return;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted || !_pageController.hasClients) return;
      final nextIndex = (_currentIndex + 1) % widget.articles.length;
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
      setState(() {
        _currentIndex = nextIndex;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.articles.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF24446A), // subtle inner top highlight
                  Color(0xF50F2236),
                  Color(0xFA071220),
                  Color(0xFF040A14),
                ],
                stops: [0.0, 0.12, 0.45, 1.0],
              )
            : null,
        color: isDark ? null : const Color(0xFFFFF1F2),
        border: Border.all(
          color: isDark
              ? const Color(0x804FA2E8) // subtle cyan edge/highlight
              : AppColors.accent.withValues(alpha: 0.3),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.60 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
          if (isDark)
            const BoxShadow(
              color: Color(0x280095FF), // subtle cyan ambient depth
              blurRadius: 12,
              offset: Offset(0, 1),
            ),
        ],
      ),
      child: Row(
        children: [
          // Breaking Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.bolt, color: Colors.white, size: 14),
                SizedBox(width: 2),
                Text(
                  'BREAKING',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // News Headline Carousel
          Expanded(
            child: SizedBox(
              height: 26,
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.articles.length,
                onPageChanged: (idx) => _currentIndex = idx,
                itemBuilder: (context, index) {
                  final item = widget.articles[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ArticleDetailScreen(article: item),
                        ),
                      );
                    },
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

