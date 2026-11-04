import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class AppleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String text;
  final double height;

  const AppleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.text = 'Continue with Apple',
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor:
              isDark ? const Color(0xFF0F1B2B) : const Color(0xFFFAF7F9),
          foregroundColor:
              isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          disabledBackgroundColor: isDark
              ? const Color(0xFF0F1B2B).withValues(alpha: 0.6)
              : const Color(0xFFFAF7F9),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          side: BorderSide(
            color: isDark ? const Color(0xFF233649) : const Color(0xFFDFD6DC),
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.apple,
                    size: 24,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

