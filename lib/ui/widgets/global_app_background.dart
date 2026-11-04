import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';

/// Centralized global background widget applied across the entire CineFlix Media app.
///
/// It renders the news studio image edge-to-edge with [BoxFit.cover] and an editorial
/// translucent overlay for high contrast, ensuring the image is decoded once and
/// persists smoothly across all route transitions and native screens.
class GlobalAppBackground extends StatelessWidget {
  final Widget child;

  const GlobalAppBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.secondary : AppColors.lightBackground,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Edge-to-edge responsive news studio background image
          Image.asset(
            AppConstants.globalBackgroundAsset,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            alignment: Alignment.center,
            gaplessPlayback: true,
            excludeFromSemantics: true,
            filterQuality: FilterQuality.medium,
          ),

          // 2. Translucent editorial scrim to preserve high text contrast & pink accents
          ColoredBox(
            color: isDark
                ? const Color(0x33000000) // 20% soft black scrim
                : const Color(0xCCF6F4F7), // 80% light wash for light mode
          ),

          // 3. Child Navigator / Screen stack
          child,
        ],
      ),
    );
  }
}
