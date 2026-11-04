import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class GoogleLogoPainter extends CustomPainter {
  const GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Offset center = Offset(w / 2, h / 2);
    final double radius = w / 2;
    final double strokeWidth = w * 0.21;
    final Rect arcRect = Rect.fromCircle(
      center: center,
      radius: radius - strokeWidth / 2,
    );

    final Paint arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // Red: Top arc
    arcPaint.color = const Color(0xFFEA4335);
    canvas.drawArc(arcRect, -2.4, 1.6, false, arcPaint);

    // Yellow: Left arc
    arcPaint.color = const Color(0xFFFBBC05);
    canvas.drawArc(arcRect, 2.3, 1.5, false, arcPaint);

    // Green: Bottom arc
    arcPaint.color = const Color(0xFF34A853);
    canvas.drawArc(arcRect, 0.75, 1.55, false, arcPaint);

    // Blue: Right arc
    arcPaint.color = const Color(0xFF4285F4);
    canvas.drawArc(arcRect, -0.8, 1.55, false, arcPaint);

    // Blue: Horizontal bar to center
    final Paint barPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF4285F4);
    final double barHeight = strokeWidth;
    canvas.drawRect(
      Rect.fromLTRB(
        w * 0.45,
        center.dy - barHeight / 2,
        w,
        center.dy + barHeight / 2,
      ),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String text;
  final double height;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.text = 'Continue with Google',
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
          disabledBackgroundColor:
              isDark ? const Color(0xFF0F1B2B).withValues(alpha: 0.6) : const Color(0xFFFAF7F9),
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
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? Colors.white70 : AppColors.primary,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomPaint(
                    size: const Size(20, 20),
                    painter: const GoogleLogoPainter(),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        text,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

