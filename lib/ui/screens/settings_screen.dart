import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/font_size_provider.dart';
import '../../providers/theme_provider.dart';
import '../widgets/font_size_modal.dart';
import 'history_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;

  void _openWebsite() async {
    final uri = Uri.parse(AppConstants.websiteUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _shareApp(BuildContext context) async {
    try {
      final box = context.findRenderObject() as RenderBox?;
      final size = MediaQuery.maybeOf(context)?.size;
      final Rect shareOrigin = (box != null && box.hasSize)
          ? (box.localToGlobal(Offset.zero) & box.size)
          : (size != null
              ? Rect.fromLTWH(0, 0, size.width, size.height / 2)
              : const Rect.fromLTWH(0, 0, 300, 300));

      final shareText =
          '${AppConstants.appName} — Stay updated with the latest Film Launches, Bollywood News, OTT Releases, and Reviews!\n\n'
          'Explore stories & download the app:\n${AppConstants.websiteUrl}';

      final result = await Share.share(
        shareText,
        subject: AppConstants.appName,
        sharePositionOrigin: shareOrigin,
      );

      // Handle share cancellation normally
      if (result.status == ShareResultStatus.dismissed) {
        debugPrint('[SettingsScreen] Share CineFlix App dismissed by user');
      } else if (result.status == ShareResultStatus.success) {
        debugPrint('[SettingsScreen] Share CineFlix App shared to: ${result.raw}');
      }
    } catch (e) {
      debugPrint('[SettingsScreen] Share CineFlix App exception: $e');
    }
  }

  void _showThemePicker(BuildContext context, ThemeProvider themeProvider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              const Text(
                'Choose Appearance',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.brightness_auto_rounded),
                title: const Text('System Default'),
                trailing: themeProvider.themeMode == ThemeMode.system
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  themeProvider.setThemeMode(ThemeMode.system);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.light_mode_rounded),
                title: const Text('Light Mode'),
                trailing: themeProvider.themeMode == ThemeMode.light
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  themeProvider.setThemeMode(ThemeMode.light);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.dark_mode_rounded),
                title: const Text('Dark Mode'),
                trailing: themeProvider.themeMode == ThemeMode.dark
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  themeProvider.setThemeMode(ThemeMode.dark);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);

    String themeLabel = 'System Default';
    if (themeProvider.themeMode == ThemeMode.dark) themeLabel = 'Dark Mode';
    if (themeProvider.themeMode == ThemeMode.light) themeLabel = 'Light Mode';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Preferences'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Section: Reading Experience
          _sectionHeader('READING EXPERIENCE', isDark),
          _cardWrapper(
            isDark: isDark,
            children: [
              ListTile(
                leading: const Icon(Icons.palette_outlined, color: AppColors.primary),
                title: const Text('App Theme'),
                subtitle: Text(themeLabel),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showThemePicker(context, themeProvider),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.format_size_rounded, color: AppColors.primary),
                title: const Text('Article Font Size'),
                subtitle: Text(fontSizeProvider.currentSize.label),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => FontSizeModal.show(context),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.history_rounded, color: AppColors.primary),
                title: const Text('Reading History'),
                subtitle: const Text('Articles you recently viewed'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Section: Notifications
          _sectionHeader('NOTIFICATIONS', isDark),
          _cardWrapper(
            isDark: isDark,
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.notifications_active_outlined, color: AppColors.primary),
                title: const Text('Breaking News Alerts'),
                subtitle: const Text('Real-time alerts for top Bollywood & OTT stories'),
                value: _notifications,
                activeThumbColor: AppColors.primary,
                onChanged: (val) {
                  setState(() => _notifications = val);
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Section: About & Connect
          _sectionHeader('ABOUT CINEFLIX MEDIA', isDark),
          _cardWrapper(
            isDark: isDark,
            children: [
              ListTile(
                leading: const Icon(Icons.public, color: AppColors.primary),
                title: const Text('Visit Official Website'),
                subtitle: const Text('cineflixmedia.in'),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: _openWebsite,
              ),
              const Divider(height: 1),
              Builder(
                builder: (tileContext) => ListTile(
                  leading: const Icon(Icons.share_outlined, color: AppColors.primary),
                  title: const Text('Share CineFlix App'),
                  subtitle: const Text('Tell friends & film buffs'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _shareApp(tileContext),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.info_outline_rounded, color: AppColors.primary),
                title: const Text('App Version'),
                subtitle: const Text('1.0.0 (Build 1) Native Flutter'),
              ),
            ],
          ),

          const SizedBox(height: 36),

          // Footer branding
          Center(
            child: Column(
              children: [
                Image.asset(
                  AppConstants.logoAsset,
                  height: 36,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Text(
                    AppConstants.appName,
                    style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '© 2026 CineFlix Media. All Rights Reserved.',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
        ),
      ),
    );
  }

  Widget _cardWrapper({required bool isDark, required List<Widget> children}) {
    return Material(
      color: isDark ? AppColors.darkCard : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
        child: Column(children: children),
      ),
    );
  }
}
