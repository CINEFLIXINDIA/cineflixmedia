import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF1E2130) : const Color(0xFFE5E7EB),
      highlightColor: isDark ? const Color(0xFF2C3147) : const Color(0xFFF3F4F6),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class ArticleCardShimmer extends StatelessWidget {
  const ArticleCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerBox(width: 110, height: 95, borderRadius: 12),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerBox(width: 80, height: 16, borderRadius: 4),
                const SizedBox(height: 8),
                const ShimmerBox(width: double.infinity, height: 16, borderRadius: 4),
                const SizedBox(height: 6),
                const ShimmerBox(width: 180, height: 16, borderRadius: 4),
                const SizedBox(height: 10),
                const ShimmerBox(width: 100, height: 12, borderRadius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HeroSliderShimmer extends StatelessWidget {
  const HeroSliderShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: ShimmerBox(width: double.infinity, height: 230, borderRadius: 16),
    );
  }
}

class ArticleDetailShimmer extends StatelessWidget {
  const ArticleDetailShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        ShimmerBox(width: double.infinity, height: 250, borderRadius: 0),
        Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerBox(width: 100, height: 20, borderRadius: 4),
              SizedBox(height: 12),
              ShimmerBox(width: double.infinity, height: 24, borderRadius: 4),
              SizedBox(height: 8),
              ShimmerBox(width: 260, height: 24, borderRadius: 4),
              SizedBox(height: 16),
              ShimmerBox(width: 140, height: 14, borderRadius: 4),
              SizedBox(height: 24),
              ShimmerBox(width: double.infinity, height: 16, borderRadius: 4),
              SizedBox(height: 10),
              ShimmerBox(width: double.infinity, height: 16, borderRadius: 4),
              SizedBox(height: 10),
              ShimmerBox(width: 220, height: 16, borderRadius: 4),
            ],
          ),
        ),
      ],
    );
  }
}

