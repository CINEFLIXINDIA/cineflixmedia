import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/author_model.dart';
import '../../providers/auth_provider.dart';
import 'author_posts_screen.dart';
import 'edit_profile_screen.dart';
import 'main_navigation_screen.dart';

class AuthorDashboardScreen extends StatefulWidget {
  final bool showOverview;

  const AuthorDashboardScreen({super.key, this.showOverview = false});

  @override
  State<AuthorDashboardScreen> createState() => _AuthorDashboardScreenState();
}

class _AuthorDashboardScreenState extends State<AuthorDashboardScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isActivityLogsExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.isAuthenticated) {
        auth.loadDashboard(refresh: true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _navigateToDashboard() {
    MainNavigationScreen.switchToTab(0);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const MainNavigationScreen(initialIndex: 0),
      ),
      (route) => false,
    );
  }

  void _confirmLogout(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.cardDark
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Confirm Logout',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out of your CineFlix author account?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final nav = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              await auth.logout();
              if (!mounted) return;
              nav.popUntil((route) => route.isFirst);
              messenger.showSnackBar(
                SnackBar(
                  content: const Text('Logged out successfully'),
                  backgroundColor: Colors.grey.shade800,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.cardDark
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actionsOverflowButtonSpacing: 8,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Are you sure?',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: const Text(
          'Your account and profile with all data will be permanently deleted. This action cannot be undone.',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final nav = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);

              final success = await auth.deleteAccount();
              if (!mounted) return;

              if (success) {
                nav.pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const MainNavigationScreen(),
                  ),
                  (route) => false,
                );
                messenger.showSnackBar(
                  SnackBar(
                    content: const Text(
                      'Your account has been permanently deleted.',
                    ),
                    backgroundColor: Colors.red.shade700,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              } else {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      auth.errorMessage ??
                          'Failed to delete account. Please try again.',
                    ),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfoTile(
    IconData icon,
    String label,
    String value,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 8),
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white54 : AppColors.textSecondaryLight,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialChips(AuthorModel? author, bool isDark) {
    final links = <Map<String, dynamic>>[
      if (author?.facebook != null && author!.facebook!.trim().isNotEmpty)
        {
          'name': 'Facebook',
          'icon': Icons.facebook_rounded,
          'url': author.facebook!.trim(),
          'color': const Color(0xFF1877F2),
        },
      if (author?.instagram != null && author!.instagram!.trim().isNotEmpty)
        {
          'name': 'Instagram',
          'icon': Icons.camera_alt_rounded,
          'url': author.instagram!.trim(),
          'color': const Color(0xFFE4405F),
        },
      if (author?.xTwitter != null && author!.xTwitter!.trim().isNotEmpty)
        {
          'name': 'X',
          'icon': Icons.alternate_email_rounded,
          'url': author.xTwitter!.trim(),
          'color': isDark ? Colors.white70 : Colors.black87,
        },
      if (author?.youtube != null && author!.youtube!.trim().isNotEmpty)
        {
          'name': 'YouTube',
          'icon': Icons.smart_display_rounded,
          'url': author.youtube!.trim(),
          'color': const Color(0xFFFF0000),
        },
      if (author?.linkedin != null && author!.linkedin!.trim().isNotEmpty)
        {
          'name': 'LinkedIn',
          'icon': Icons.link_rounded,
          'url': author.linkedin!.trim(),
          'color': const Color(0xFF0A66C2),
        },
    ];

    if (links.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: links.map((link) {
          final color = link['color'] as Color;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(link['icon'] as IconData, size: 13, color: color),
                const SizedBox(width: 5),
                Text(
                  link['name'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProfileCard(AuthProvider auth, bool isDark) {
    final author = auth.author;
    final displayName =
        author?.effectiveDisplayName ?? author?.name ?? 'Author';
    final fullName = author?.name ?? displayName;
    final email = author?.email ?? '';
    final phone = author?.phone;
    final description = author?.description;
    final joined = author?.joinedDate ?? 'Recently';
    final avatarUrl = author?.avatar;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Avatar, Name, Email, Joined date, Logout
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2.2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: avatarUrl != null && avatarUrl.isNotEmpty
                      ? Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildAvatarFallback(displayName),
                        )
                      : _buildAvatarFallback(displayName),
                ),
              ),

              const SizedBox(width: 14),

              // User Info: Display Name, Email, Joined
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? Colors.white
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.email_outlined,
                            size: 13,
                            color: isDark
                                ? Colors.white54
                                : AppColors.textSecondaryLight,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white60
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 12,
                          color: isDark
                              ? Colors.white54
                              : AppColors.textSecondaryLight,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            'Joined $joined',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white60
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Organization & Designation Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_rounded,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    author?.designation != null &&
                            author!.designation!.trim().isNotEmpty
                        ? '${author.designation!.trim()} · CineFlix Media'
                        : 'CineFlix Media Author',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Detailed Profile Information Container
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (fullName.isNotEmpty && fullName != displayName)
                  _buildProfileInfoTile(
                    Icons.person_outline_rounded,
                    'Full Name',
                    fullName,
                    isDark,
                  ),
                _buildProfileInfoTile(
                  Icons.business_rounded,
                  'Organization',
                  'CineFlix Media',
                  isDark,
                ),
                if (phone != null && phone.trim().isNotEmpty)
                  _buildProfileInfoTile(
                    Icons.phone_outlined,
                    'Mobile',
                    phone.trim(),
                    isDark,
                  ),
                if (author?.formattedDobWithAge != null &&
                    author!.formattedDobWithAge!.isNotEmpty)
                  _buildProfileInfoTile(
                    Icons.cake_outlined,
                    'DOB / Age',
                    author.formattedDobWithAge!,
                    isDark,
                  ),
                if (author?.gender != null && author!.gender!.isNotEmpty)
                  _buildProfileInfoTile(
                    Icons.wc_rounded,
                    'Gender',
                    author.gender!.toUpperCase(),
                    isDark,
                  ),
                if (author?.designation != null &&
                    author!.designation!.trim().isNotEmpty)
                  _buildProfileInfoTile(
                    Icons.work_outline_rounded,
                    'Designation',
                    author.designation!.trim(),
                    isDark,
                  ),
                if (author?.experience != null &&
                    author!.experience!.trim().isNotEmpty)
                  _buildProfileInfoTile(
                    Icons.timeline_rounded,
                    'Experience',
                    author.experience!.trim(),
                    isDark,
                  ),
                if (author?.education != null &&
                    author!.education!.trim().isNotEmpty)
                  _buildProfileInfoTile(
                    Icons.school_outlined,
                    'Education',
                    author.education!.trim(),
                    isDark,
                  ),
                if (author?.cityState != null && author!.cityState.isNotEmpty)
                  _buildProfileInfoTile(
                    Icons.location_city_rounded,
                    'City / State',
                    author.cityState,
                    isDark,
                  ),
                if (author?.address != null &&
                    author!.address!.trim().isNotEmpty)
                  _buildProfileInfoTile(
                    Icons.place_outlined,
                    'Address',
                    author.address!.trim(),
                    isDark,
                  ),
                if (description != null && description.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    description.trim(),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: isDark
                          ? Colors.white70
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],

                // Social Links
                _buildSocialChips(author, isDark),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Edit Profile Button
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.edit_rounded, size: 16),
              label: const Text(
                'Edit Profile',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  width: 1.2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: AppColors.primary.withValues(alpha: 0.08),
              ),
              onPressed: () async {
                final updated = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                );
                if (updated == true && mounted) {
                  auth.loadDashboard(refresh: true, silent: true);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'A';
    return Container(
      color: AppColors.primary.withValues(alpha: 0.2),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
          fontSize: 22,
        ),
      ),
    );
  }

  Widget _buildPostsApprovedCard(int count, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [AppColors.primary.withValues(alpha: 0.25), AppColors.cardDark]
              : [AppColors.primary.withValues(alpha: 0.12), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'POSTS APPROVED',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                count.toString(),
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                  height: 1.0,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_rounded,
              color: AppColors.primary,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1.2),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuSection(AuthProvider auth, bool isDark) {
    return Material(
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: Column(
          children: [
            Material(
              color: Colors.transparent,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: InkWell(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                onTap: _navigateToDashboard,
                child: ListTile(
                  leading: const Icon(
                    Icons.dashboard_rounded,
                    color: AppColors.primary,
                  ),
                  title: const Text(
                    'Dashboard',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Overview & performance'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(
                Icons.article_rounded,
                color: AppColors.primary,
              ),
              title: const Text(
                'Posts',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${auth.stats.publishedPosts + auth.stats.pendingPosts + auth.stats.draftPosts} total author articles',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthorPostsScreen()),
                );
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(
                Icons.logout_rounded,
                color: Colors.redAccent,
              ),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text('Sign out from author session'),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: Colors.redAccent,
              ),
              onTap: () => _confirmLogout(context, auth),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(
                Icons.delete_forever_rounded,
                color: Colors.red,
              ),
              title: const Text(
                'Delete Account',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text('Permanently remove your account & data'),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: Colors.red,
              ),
              onTap: () => _confirmDeleteAccount(context, auth),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityLogsSection(AuthProvider auth, bool isDark) {
    final logs = auth.activityLogs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _isActivityLogsExpanded = !_isActivityLogsExpanded;
            });
          },
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            child: Row(
              children: [
                const Icon(
                  Icons.history_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Activity Logs',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                  ),
                ),
                if (logs.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${logs.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Icon(
                  _isActivityLogsExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
        if (_isActivityLogsExpanded) ...[
          const SizedBox(height: 12),
          if (logs.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.history_toggle_off_rounded,
                    size: 38,
                    color: isDark ? Colors.white30 : Colors.black26,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No Activities!',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'You have no activity logs yet',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? Colors.white54
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                ),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: logs.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (_, index) {
                  final log = logs[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.access_time_rounded,
                            size: 15,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                log.description,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textPrimaryLight,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 6,
                                runSpacing: 2,
                                children: [
                                  if (log.ipAddress != null &&
                                      log.ipAddress!.isNotEmpty)
                                    Text(
                                      '(${log.ipAddress})',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark
                                            ? Colors.white38
                                            : AppColors.textSecondaryLight,
                                      ),
                                    ),
                                  if (log.timeAgo != null &&
                                      log.timeAgo!.isNotEmpty)
                                    Text(
                                      log.timeAgo!,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(widget.showOverview ? 'Author Dashboard' : 'My Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
              );
            }
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Profile',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => auth.loadDashboard(refresh: true),
          ),
        ],
      ),
      body: auth.isLoading && auth.author == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => auth.loadDashboard(refresh: true),
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                children: [
                  // 1. Profile / Hello Card
                  _buildProfileCard(auth, isDark),

                  const SizedBox(height: 16),

                  // 2. Posts Approved Count Box
                  _buildPostsApprovedCard(auth.stats.postsApproved, isDark),

                  const SizedBox(height: 14),

                  // 3. Stat Widgets Row (Published, Pending, Draft)
                  Row(
                    children: [
                      _buildStatBox(
                        title: 'Published',
                        count: auth.stats.publishedPosts,
                        icon: Icons.check_circle_rounded,
                        color: AppColors.primary,
                        isDark: isDark,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AuthorPostsScreen(
                                initialStatus: 'published',
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      _buildStatBox(
                        title: 'Pending',
                        count: auth.stats.pendingPosts,
                        icon: Icons.schedule_rounded,
                        color: const Color(0xFF10B981),
                        isDark: isDark,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AuthorPostsScreen(
                                initialStatus: 'pending',
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      _buildStatBox(
                        title: 'Drafts',
                        count: auth.stats.draftPosts,
                        icon: Icons.edit_note_rounded,
                        color: const Color(0xFFEF4444),
                        isDark: isDark,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AuthorPostsScreen(
                                initialStatus: 'draft',
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 4. Menu Actions (Dashboard, Posts, Settings, Logout)
                  if (!widget.showOverview) ...[
                    _buildMenuSection(auth, isDark),
                    const SizedBox(height: 24),
                  ],

                  // 5. Activity Logs Component
                  _buildActivityLogsSection(auth, isDark),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
