import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/storage_service.dart';
import '../../providers/auth_provider.dart';
import '../widgets/apple_sign_in_button.dart';
import '../widgets/google_sign_in_button.dart';
import 'main_navigation_screen.dart';

class NewsletterPopupScreen extends StatefulWidget {
  const NewsletterPopupScreen({super.key});

  @override
  State<NewsletterPopupScreen> createState() => _NewsletterPopupScreenState();
}

class _NewsletterPopupScreenState extends State<NewsletterPopupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _dontShowAgain = false;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _continueToHome() async {
    if (_dontShowAgain) {
      final storage = await StorageService.getInstance();
      await storage.setHideNewsletterPopup(true);
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
    );
  }

  Future<void> _subscribe() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    await _continueToHome();
  }

  Future<void> _continueWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    auth.clearError();

    final success = await auth.loginWithGoogle();
    if (!mounted) return;
    setState(() => _isGoogleLoading = false);

    if (success) {
      if (_dontShowAgain) {
        final storage = await StorageService.getInstance();
        await storage.setHideNewsletterPopup(true);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Signed in as ${auth.author?.name ?? "Google User"}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage!),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _continueWithApple() async {
    setState(() => _isAppleLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    auth.clearError();

    final success = await auth.loginWithApple();
    if (!mounted) return;
    setState(() => _isAppleLoading = false);

    if (success) {
      if (_dontShowAgain) {
        final storage = await StorageService.getInstance();
        await storage.setHideNewsletterPopup(true);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Signed in as ${auth.author?.name ?? "Apple User"}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage!),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkCard : AppColors.lightCard;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final muted = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black.withValues(
              alpha: isDark ? 0.45 : 0.25,
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 430),
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 26),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.45 : 0.16,
                        ),
                        blurRadius: 32,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            tooltip: 'Close',
                            onPressed: _continueToHome,
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ),
                        Image.asset(
                          AppConstants.logoAsset,
                          width: 210,
                          height: 70,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Never Miss a Story',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Get the latest film, OTT and theatre news delivered straight to your inbox.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: muted),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.email],
                          onFieldSubmitted: (_) => _subscribe(),
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                            hintText: 'you@example.com',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            if (email.isEmpty) {
                              return 'Please enter your email address';
                            }
                            if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                .hasMatch(email)) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _subscribe,
                            child: const Text(
                              'Subscribe',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        GoogleSignInButton(
                          onPressed: _continueWithGoogle,
                          isLoading: _isGoogleLoading,
                        ),
                        const SizedBox(height: 10),
                        AppleSignInButton(
                          onPressed: _continueWithApple,
                          isLoading: _isAppleLoading,
                        ),
                        const SizedBox(height: 12),
                        Material(
                          color: Colors.transparent,
                          child: CheckboxListTile(
                            value: _dontShowAgain,
                            onChanged: (value) =>
                                setState(() => _dontShowAgain = value ?? false),
                            activeColor: AppColors.primary,
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            title: const Text("Don't show this popup again"),
                          ),
                        ),
                        TextButton(
                          onPressed: _continueToHome,
                          child: const Text('Maybe later'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
