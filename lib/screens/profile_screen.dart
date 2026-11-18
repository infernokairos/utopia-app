import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../services/cache_service.dart';
import '../services/email_service.dart';
import '../services/file_upload_service.dart';
import '../services/people_interaction_service.dart';
import '../services/platform_support.dart';
import '../services/role_service.dart';
import '../widgets/instagram_badge.dart';
import '../widgets/superuser_badge.dart';
import '../widgets/wave_count_badge.dart';
import '../models/project_model.dart';
import '../services/project_service.dart';
import 'create_project_screen.dart';
import 'project_detail_screen.dart';
import 'app_shell.dart';
import 'university_selection_screen.dart';
import 'user_profile_screen.dart';
import 'utopia_section_screen.dart';
import 'whatsapp_profile_crop_screen.dart';
import '../theme/m3_expressive_theme.dart';
import '../widgets/app_motion.dart';
import '../services/ads/consent_service.dart';

const List<String> kBTechBranches = [
  'Agri Engg',
  'CSE (AI & ML)',
  'CSE (AI & ML - Microsoft)',
  'CSE (AI & ML - Google)',
  'Civil Engg',
  'CSE',
  'CSE (Data Science)',
  'CSE (Data Science - Google)',
  'CSE (Google Cloud)',
  'CSE (SAP)',
  'EEE',
  'ECE',
  'Mechanical Engg',
  'Mining Engg',
  'Petroleum Tech',
];

/// Simple, clean, Material 3 Expressive Profile Screen
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isSuperUser = false;
  bool _updatingTheme = false;

  @override
  void initState() {
    super.initState();
    PeopleInteractionService().syncMyWavesCount();
    RoleService().isSuperUser().then((v) {
      if (mounted) setState(() => _isSuperUser = v);
    });
  }

  Future<void> _signOut() async {
    RoleService().clearCache();
    await CacheService().deleteAppSetting('cached_university_id');
    await CacheService().deleteAppSetting('cached_university_name');
    AppShell.resetSession();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('app_open_count');
    await prefs.remove('last_seen_popup_event_id');
    U.cachedUniversityId = '';
    U.cachedUniversityName = '';
    if (PlatformSupport.supportsGoogleSignIn) {
      await GoogleSignIn.instance.initialize(
        serverClientId:
            '402670858978-94eqn0qvvrtv59ijne3hn1g5flr4ahve.apps.googleusercontent.com',
      );
      await GoogleSignIn.instance.signOut();
    }
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _showSignOutDialog() {
    final isDark = appThemeNotifier.value.isDark;
    const dangerRed = Color(0xFFEF4444);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: U.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(
            color: U.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.5),
            width: 0.8,
          ),
        ),
        title: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: dangerRed.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.logout_rounded, color: dangerRed, size: 24),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Sign Out',
              style: GoogleFonts.robotoFlex(
                color: U.text,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to sign out of UTOPIA?',
          textAlign: TextAlign.center,
          style: GoogleFonts.robotoFlex(
            color: U.sub,
            fontSize: 13.5,
            height: 1.45,
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: U.text,
                    side: BorderSide(color: U.outlineVariant.withValues(alpha: 0.6)),
                    shape: RoundedRectangleBorder(borderRadius: M3Shapes.fullRadius),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.robotoFlex(
                      color: U.text,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _signOut();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: dangerRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: M3Shapes.fullRadius),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Sign Out',
                    style: GoogleFonts.robotoFlex(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selectThemeStyle() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _updatingTheme) return;

    final initialThemeKey = U.currentThemeKey;
    final selectedKey = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ThemeStyleSheet(currentKey: initialThemeKey),
    );

    final finalKey = selectedKey ?? U.currentThemeKey;
    if (finalKey != initialThemeKey) {
      setState(() => _updatingTheme = true);
      U.applyTheme(finalKey);
      await CacheService().saveAppSetting('theme_accent', finalKey);
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'themeAccent': finalKey,
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error saving theme: $e');
      }

      if (mounted) {
        setState(() => _updatingTheme = false);
      }
    }
  }

  Future<void> _toggleDarkMode(bool isDark) async {
    HapticFeedback.selectionClick();
    final nextKey = U.counterpartKey(U.currentThemeKey, isDark);
    U.applyTheme(nextKey);
    await CacheService().saveAppSetting('theme_accent', nextKey);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'themeAccent': nextKey,
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error saving dark mode: $e');
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _openEditProfile({
    required String name,
    required String bio,
    required String instagram,
    required String github,
    required String discord,
    required String branch,
    required String rollNumber,
    required String? photoUrl,
  }) async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditProfileSheet(
        initialName: name,
        initialBio: bio,
        initialInstagram: instagram,
        initialGithub: github,
        initialDiscord: discord,
        initialBranch: branch,
        initialRollNumber: rollNumber,
        initialPhotoUrl: photoUrl,
      ),
    );
    if (updated == true && mounted) {
      setState(() {});
    }
  }

  void _openRaiseIssue() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _RaiseIssueSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = appThemeNotifier.value;
    final cs = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;
    final userDocStream = user == null
        ? null
        : FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots();

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: userDocStream,
          builder: (context, snapshot) {
            final userData = snapshot.data?.data() ?? {};
            final displayName = UtopiaApp.sanitizeDisplayName(
              (userData['displayName'] as String?) ?? user?.displayName,
            );
            final bio = (userData['bio'] ?? '').toString().trim();
            final branch = (userData['branch'] ?? '').toString().trim();
            final instagramId = (userData['instagramId'] ?? '').toString().trim();
            final githubId = (userData['githubId'] ?? userData['githubUsername'] ?? '').toString().trim();
            final discordId = (userData['discordId'] ?? userData['discordUsername'] ?? '').toString().trim();
            final rollNumber = (userData['rollNumber'] ?? '').toString().trim();
            final showRollNumber = (userData['showRollNumberOnProfile'] as bool?) ?? true;
            final wavesCount = (userData['wavesReceivedCount'] as num?)?.toInt() ?? 0;
            final rawPhotoUrl = (userData['photoUrl'] as String?)?.trim();
            final displayPhotoUrl = (rawPhotoUrl != null && rawPhotoUrl.isNotEmpty)
                ? rawPhotoUrl
                : user?.photoURL;
            final email = user?.email ?? '';

            return ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
              children: [
                // ── Interceptor-style Header Row ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (Navigator.canPop(context))
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back_rounded),
                              color: cs.onSurface,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Profile',
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.4,
                                color: cs.onSurface,
                              ),
                            ),
                          ],
                        )
                      else
                        Text.rich(
                          TextSpan(
                            text: 'profile',
                            style: GoogleFonts.inter(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -1.2,
                              color: cs.onSurface,
                            ),
                            children: [
                              TextSpan(
                                text: '.',
                                style: TextStyle(color: cs.primary),
                              ),
                            ],
                          ),
                          maxLines: 1,
                        ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (user != null)
                            IconButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  buildForwardRoute(
                                    UserProfileScreen(
                                      uid: user.uid,
                                      displayName: displayName,
                                      email: email,
                                      photoUrl: displayPhotoUrl,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.arrow_outward_rounded),
                              color: cs.onSurfaceVariant,
                              iconSize: 21,
                              tooltip: 'View public profile',
                            ),
                          IconButton(
                            onPressed: () {
                              SharePlus.instance.share(
                                ShareParams(
                                  text:
                                      'Join me on UTOPIA! 🚀 The academic productivity platform.\n\nhttps://inferalis.space/download-utopia',
                                ),
                              );
                            },
                            icon: const Icon(Icons.ios_share_rounded),
                            color: cs.onSurfaceVariant,
                            iconSize: 20,
                            tooltip: 'Share app',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // ── Profile Identity Card (stroke-free surfaceContainer) ──
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: cs.primaryContainer,
                            backgroundImage:
                                displayPhotoUrl != null && displayPhotoUrl.isNotEmpty
                                    ? CachedNetworkImageProvider(displayPhotoUrl)
                                    : null,
                            child: (displayPhotoUrl == null || displayPhotoUrl.isEmpty)
                                ? Text(
                                    (displayName.isNotEmpty ? displayName[0] : 'U')
                                        .toUpperCase(),
                                    style: GoogleFonts.inter(
                                      color: cs.onPrimaryContainer,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        displayName,
                                        style: GoogleFonts.inter(
                                          color: cs.onSurface,
                                          fontSize: 19,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.4,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (_isSuperUser) ...[
                                      const SizedBox(width: 6),
                                      const SuperUserBadge(size: 16),
                                    ],
                                  ],
                                ),
                                if (email.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  GestureDetector(
                                    onTap: () {
                                      Clipboard.setData(ClipboardData(text: email));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Email copied',
                                            style: GoogleFonts.inter(fontSize: 13),
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                          duration: const Duration(milliseconds: 1500),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      email,
                                      style: GoogleFonts.inter(
                                        color: cs.onSurfaceVariant,
                                        fontSize: 12.5,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (bio.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text(
                          bio,
                          style: GoogleFonts.inter(
                            color: cs.onSurfaceVariant,
                            fontSize: 13.5,
                            height: 1.45,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (branch.isNotEmpty ||
                          instagramId.isNotEmpty ||
                          githubId.isNotEmpty ||
                          discordId.isNotEmpty ||
                          wavesCount > 0 ||
                          (rollNumber.isNotEmpty && showRollNumber)) ...[
                        const SizedBox(height: 14),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (branch.isNotEmpty)
                              _FlatChip(
                                icon: Icons.school_outlined,
                                label: branch,
                                color: cs.primary,
                              ),
                            if (rollNumber.isNotEmpty && showRollNumber)
                              _FlatChip(
                                icon: Icons.badge_outlined,
                                label: rollNumber,
                                color: cs.onSurfaceVariant,
                              ),
                            if (instagramId.isNotEmpty)
                              InstagramBadge(handle: instagramId),
                            if (githubId.isNotEmpty)
                              GithubBadge(handle: githubId),
                            if (discordId.isNotEmpty)
                              DiscordBadge(handle: discordId),
                            WaveCountBadge(count: wavesCount),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonalIcon(
                          onPressed: () => _openEditProfile(
                            name: displayName,
                            bio: bio,
                            instagram: instagramId,
                            github: githubId,
                            discord: discordId,
                            branch: branch,
                            rollNumber: rollNumber,
                            photoUrl: displayPhotoUrl,
                          ),
                          icon: Icon(Icons.edit_outlined, size: 16, color: cs.onSurface),
                          label: Text(
                            'Edit profile',
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: cs.surfaceContainerHigh,
                            foregroundColor: cs.onSurface,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Projects Showcase Section ──
                _UserProjectsProfileSection(userId: user?.uid ?? ''),
                const SizedBox(height: 20),

                // ── Section 1: Appearance (exact Interceptor Chrome M3 Settings layout) ──
                const _ProfileSectionHeader('Appearance'),
                _ProfileSettingsGroup(
                  children: [
                    _ProfileSettingsTile(
                      leading: Icon(
                        Icons.dark_mode_outlined,
                        size: 22,
                        color: cs.onSurfaceVariant,
                      ),
                      title: 'Dark theme',
                      subtitle: theme.isDark ? 'On' : 'Off',
                      trailing: Switch.adaptive(
                        value: theme.isDark,
                        activeTrackColor: cs.primary,
                        onChanged: _toggleDarkMode,
                      ),
                      onTap: () => _toggleDarkMode(!theme.isDark),
                    ),
                    _ProfileSettingsTile(
                      leading: Icon(
                        Icons.palette_outlined,
                        size: 22,
                        color: cs.onSurfaceVariant,
                      ),
                      title: 'Theme accent',
                      subtitle: _updatingTheme
                          ? 'Updating...'
                          : U.themeForKey(U.currentThemeKey).label,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: cs.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                          ),
                        ],
                      ),
                      onTap: _selectThemeStyle,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Section 2: General ──
                const _ProfileSectionHeader('General'),
                _ProfileSettingsGroup(
                  children: [
                    _ProfileSettingsTile(
                      leading: Icon(
                        Icons.school_outlined,
                        size: 22,
                        color: cs.onSurfaceVariant,
                      ),
                      title: 'University Campus',
                      subtitle: U.cachedUniversityName.isNotEmpty
                          ? U.cachedUniversityName
                          : 'Choose campus',
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const UniversitySelectionScreen(),
                        ),
                      ),
                    ),
                    _ProfileSettingsTile(
                      leading: Icon(
                        Icons.info_outline_rounded,
                        size: 22,
                        color: cs.onSurfaceVariant,
                      ),
                      title: 'About UTOPIA',
                      subtitle: 'Info & releases',
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UtopiaSectionScreen(
                            initialIsSuperUser: _isSuperUser,
                          ),
                        ),
                      ),
                    ),
                    _ProfileSettingsTile(
                      leading: Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 22,
                        color: cs.onSurfaceVariant,
                      ),
                      title: 'Feedback & Support',
                      subtitle: 'Bugs & features',
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                      onTap: _openRaiseIssue,
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable:
                          ConsentService.instance.privacyOptionsRequired,
                      builder: (context, isRequired, _) {
                        if (!isRequired) return const SizedBox.shrink();
                        return Column(
                          children: [
                            Divider(
                              height: 1,
                              thickness: 1,
                              indent: 68,
                              endIndent: 16,
                              color: cs.outlineVariant.withValues(alpha: 0.22),
                            ),
                            _ProfileSettingsTile(
                              leading: Icon(
                                Icons.privacy_tip_outlined,
                                size: 22,
                                color: cs.onSurfaceVariant,
                              ),
                              title: 'Privacy Settings',
                              subtitle: 'Ad consent',
                              trailing: Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                                color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                              ),
                              onTap: () async {
                                final ok = await ConsentService.instance
                                    .showPrivacyOptionsForm();
                                if (!ok && context.mounted) {
                                  U.showSnackBar(
                                    context,
                                    'Privacy settings are not available at this time.',
                                    icon: Icons.info_outline_rounded,
                                    iconColor: U.sub,
                                  );
                                }
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Section 3: Account ──
                const _ProfileSectionHeader('Account'),
                _ProfileSettingsGroup(
                  children: [
                    _ProfileSettingsTile(
                      leading: Icon(
                        Icons.logout_rounded,
                        size: 22,
                        color: cs.error,
                      ),
                      title: 'Sign out',
                      titleColor: cs.error,
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: cs.error.withValues(alpha: 0.65),
                      ),
                      onTap: _showSignOutDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                Center(
                  child: Text(
                    'utopia.',
                    style: GoogleFonts.inter(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ]
                  .animate(interval: 30.ms)
                  .fadeIn(duration: 250.ms, curve: Curves.easeOut),
            );
          },
        ),
      ),
    );
  }
}

class _ProfileSectionHeader extends StatelessWidget {
  final String title;
  const _ProfileSectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: cs.onSurfaceVariant.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}

class _ProfileSettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _ProfileSettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0 && children[i] is! ValueListenableBuilder)
              Divider(
                height: 1,
                thickness: 1,
                indent: 68,
                endIndent: 16,
                color: cs.outlineVariant.withValues(alpha: 0.22),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _ProfileSettingsTile extends StatelessWidget {
  final Widget leading;
  final String title;
  final Color? titleColor;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _ProfileSettingsTile({
    required this.leading,
    required this.title,
    this.titleColor,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              SizedBox(
                width: 38,
                child: Center(child: leading),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.2,
                        color: titleColor ?? cs.onSurface,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          height: 1.25,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 10),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Minimal flat chip — no border, just subtle tinted background
class _FlatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _FlatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: M3Shapes.fullRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Simple, Clean, Single-Source Edit Profile Sheet ──
class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({
    required this.initialName,
    required this.initialBio,
    required this.initialInstagram,
    required this.initialGithub,
    required this.initialDiscord,
    required this.initialBranch,
    required this.initialRollNumber,
    required this.initialPhotoUrl,
  });

  final String initialName;
  final String initialBio;
  final String initialInstagram;
  final String initialGithub;
  final String initialDiscord;
  final String initialBranch;
  final String initialRollNumber;
  final String? initialPhotoUrl;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  late final TextEditingController _instagramController;
  late final TextEditingController _githubController;
  late final TextEditingController _discordController;
  late final TextEditingController _rollController;
  String? _selectedBranch;
  String? _photoUrl;
  bool _uploadingPhoto = false;
  bool _saving = false;
  bool _showRollNumberOnProfile = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _bioController = TextEditingController(text: widget.initialBio);
    _instagramController = TextEditingController(text: widget.initialInstagram);
    _githubController = TextEditingController(text: widget.initialGithub);
    _discordController = TextEditingController(text: widget.initialDiscord);
    _rollController = TextEditingController(text: widget.initialRollNumber);
    _photoUrl = widget.initialPhotoUrl;
    _selectedBranch = widget.initialBranch.isNotEmpty && kBTechBranches.contains(widget.initialBranch)
        ? widget.initialBranch
        : null;
    _loadProfileSettings();
  }

  Future<void> _loadProfileSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final rollVal = doc.data()?['showRollNumberOnProfile'] as bool?;
      if (mounted) {
        setState(() {
          _showRollNumberOnProfile = rollVal ?? true;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _instagramController.dispose();
    _githubController.dispose();
    _discordController.dispose();
    _rollController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 92,
      );
      if (picked == null) return;

      if (!mounted) return;
      final croppedFile = await Navigator.push<File>(
        context,
        MaterialPageRoute(
          builder: (_) => WhatsAppProfileCropScreen(
            imageFile: File(picked.path),
          ),
        ),
      );
      if (croppedFile == null) return; // User cancelled cropping

      setState(() => _uploadingPhoto = true);
      final uniId = U.cachedUniversityId.isNotEmpty ? U.cachedUniversityId : 'profiles';
      final downloadUrl = await FileUploadService().uploadProfilePhoto(
        file: croppedFile,
        universityId: uniId,
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updatePhotoURL(downloadUrl);
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'photoUrl': downloadUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        await user.reload();
      }

      if (mounted) {
        setState(() => _photoUrl = downloadUrl);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: U.red,
            content: Text(
              e is FileUploadException ? e.message : 'Failed to update photo',
              style: GoogleFonts.robotoFlex(color: Colors.white, fontSize: 13),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _removePhoto() async {
    try {
      setState(() => _uploadingPhoto = true);
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updatePhotoURL(null);
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'photoUrl': null,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        await user.reload();
      }
      if (mounted) {
        setState(() => _photoUrl = null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: U.red,
            content: Text('Failed to remove photo', style: GoogleFonts.robotoFlex(color: Colors.white, fontSize: 13)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _save() async {
    final nextName = _nameController.text.trim();
    final nextBio = _bioController.text.trim();
    final nextInstagram = _instagramController.text.trim().replaceAll('@', '');
    final nextGithub = GithubBadge.sanitizeHandle(_githubController.text);
    final nextDiscord = DiscordBadge.sanitizeHandle(_discordController.text);
    final nextRollNumber = _rollController.text.trim().toUpperCase();

    if (nextName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: U.red,
          content: Text('Name cannot be empty', style: GoogleFonts.robotoFlex(color: Colors.white, fontSize: 13)),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updateDisplayName(nextName);
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
          {
            'displayName': nextName,
            'bio': nextBio,
            'instagramId': nextInstagram,
            'githubId': nextGithub,
            'discordId': nextDiscord,
            'branch': _selectedBranch ?? '',
            'showRollNumberOnProfile': _showRollNumberOnProfile,
            'rollNumber': nextRollNumber,
            'email': user.email ?? '',
            'lastSeen': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            if (_photoUrl != null) 'photoUrl': _photoUrl,
          },
          SetOptions(merge: true),
        );
        await user.reload();
      }
      if (mounted) {
        HapticFeedback.lightImpact();
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: U.red,
            content: Text('Could not update profile', style: GoogleFonts.robotoFlex(color: Colors.white, fontSize: 13)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = appThemeNotifier.value;
    final isDark = theme.isDark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.90,
        minChildSize: 0.50,
        maxChildSize: 0.96,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: U.surfaceContainerHigh,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(
                color: U.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.5),
                width: 0.8,
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  // Drag handle
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: U.outlineVariant,
                        borderRadius: M3Shapes.fullRadius,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Top Header Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: _saving ? null : () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.robotoFlex(
                              color: U.sub,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          'Edit Profile',
                          style: GoogleFonts.robotoFlex(
                            color: U.text,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        FilledButton(
                          onPressed: _saving ? null : _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(borderRadius: M3Shapes.fullRadius),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                            minimumSize: const Size(0, 36),
                          ),
                          child: _saving
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      theme.colorScheme.onPrimary,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Save',
                                  style: GoogleFonts.robotoFlex(fontSize: 13.5, fontWeight: FontWeight.w700),
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Divider(height: 1, thickness: 0.5, color: U.outlineVariant.withValues(alpha: 0.35)),

                  // Form List
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(22, 18, 22, 36),
                      children: [
                        // Avatar Editor
                        Center(
                          child: Column(
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 42,
                                    backgroundColor: theme.primary.withValues(alpha: 0.12),
                                    backgroundImage: _photoUrl != null && _photoUrl!.isNotEmpty
                                        ? CachedNetworkImageProvider(_photoUrl!)
                                        : null,
                                    child: (_photoUrl == null || _photoUrl!.isEmpty)
                                        ? Text(
                                            (_nameController.text.isNotEmpty ? _nameController.text : 'U')[0].toUpperCase(),
                                            style: GoogleFonts.robotoFlex(
                                              color: theme.primary,
                                              fontSize: 32,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          )
                                        : null,
                                  ),
                                  if (_uploadingPhoto)
                                    Container(
                                      width: 84,
                                      height: 84,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.6),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Center(
                                        child: SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Photo Action Chips
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ActionChip(
                                    avatar: Icon(Icons.photo_camera_rounded, size: 15, color: theme.primary),
                                    label: Text('Camera', style: GoogleFonts.robotoFlex(fontSize: 12, fontWeight: FontWeight.w600)),
                                    onPressed: _uploadingPhoto ? null : () => _pickPhoto(ImageSource.camera),
                                  ),
                                  const SizedBox(width: 8),
                                  ActionChip(
                                    avatar: Icon(Icons.photo_library_rounded, size: 15, color: theme.primary),
                                    label: Text('Gallery', style: GoogleFonts.robotoFlex(fontSize: 12, fontWeight: FontWeight.w600)),
                                    onPressed: _uploadingPhoto ? null : () => _pickPhoto(ImageSource.gallery),
                                  ),
                                  if (_photoUrl != null && _photoUrl!.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    ActionChip(
                                      avatar: Icon(Icons.delete_outline_rounded, size: 15, color: U.red),
                                      label: Text('Remove', style: GoogleFonts.robotoFlex(fontSize: 12, fontWeight: FontWeight.w600, color: U.red)),
                                      onPressed: _uploadingPhoto ? null : _removePhoto,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),

                        // Name
                        _fieldLabel('FULL NAME'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _nameController,
                          maxLength: 40,
                          textInputAction: TextInputAction.next,
                          scrollPadding: const EdgeInsets.only(bottom: 80, top: 20),
                          style: GoogleFonts.robotoFlex(color: U.text, fontSize: 14.5),
                          cursorColor: theme.primary,
                          decoration: _inputDec(
                            hint: 'Your name',
                            icon: Icon(Icons.person_outline_rounded, size: 20, color: theme.primary),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Bio
                        _fieldLabel('BIO'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _bioController,
                          maxLines: 3,
                          maxLength: 150,
                          scrollPadding: const EdgeInsets.only(bottom: 80, top: 20),
                          style: GoogleFonts.robotoFlex(color: U.text, fontSize: 14),
                          cursorColor: theme.primary,
                          decoration: _inputDec(
                            hint: 'About you...',
                            icon: Padding(
                              padding: const EdgeInsets.only(bottom: 36),
                              child: Icon(Icons.format_quote_rounded, size: 20, color: theme.primary),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Instagram
                        _fieldLabel('INSTAGRAM USERNAME'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _instagramController,
                          maxLength: 30,
                          textInputAction: TextInputAction.next,
                          scrollPadding: const EdgeInsets.only(bottom: 80, top: 20),
                          style: GoogleFonts.robotoFlex(color: U.text, fontSize: 14.5),
                          cursorColor: theme.primary,
                          decoration: _inputDec(
                            hint: 'username',
                            prefixText: '@ ',
                            icon: const Padding(
                              padding: EdgeInsets.all(12),
                              child: RealInstagramIcon(size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // GitHub
                        _fieldLabel('GITHUB USERNAME'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _githubController,
                          maxLength: 39,
                          textInputAction: TextInputAction.next,
                          scrollPadding: const EdgeInsets.only(bottom: 80, top: 20),
                          style: GoogleFonts.robotoFlex(color: U.text, fontSize: 14.5),
                          cursorColor: theme.primary,
                          decoration: _inputDec(
                            hint: 'username',
                            prefixText: '@ ',
                            icon: const Padding(
                              padding: EdgeInsets.all(12),
                              child: RealGithubIcon(size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Discord
                        _fieldLabel('DISCORD USERNAME OR TAG'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _discordController,
                          maxLength: 37,
                          textInputAction: TextInputAction.next,
                          scrollPadding: const EdgeInsets.only(bottom: 80, top: 20),
                          style: GoogleFonts.robotoFlex(color: U.text, fontSize: 14.5),
                          cursorColor: theme.primary,
                          decoration: _inputDec(
                            hint: 'username or username#0000',
                            prefixText: '@ ',
                            icon: const Padding(
                              padding: EdgeInsets.all(12),
                              child: RealDiscordIcon(size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Branch Dropdown
                        _fieldLabel('BRANCH / SPECIALIZATION'),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedBranch,
                          isExpanded: true,
                          dropdownColor: U.surfaceContainerHigh,
                          style: GoogleFonts.robotoFlex(color: U.text, fontSize: 14),
                          icon: Icon(Icons.keyboard_arrow_down_rounded, color: U.sub),
                          decoration: _inputDec(
                            hint: 'Select branch...',
                            icon: Icon(Icons.school_outlined, size: 20, color: theme.primary),
                          ),
                          items: kBTechBranches.map((branch) {
                            return DropdownMenuItem<String>(
                              value: branch,
                              child: Text(
                                branch,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.robotoFlex(color: U.text, fontSize: 13.5),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedBranch = val),
                        ),
                        const SizedBox(height: 16),

                        // Roll Number
                        _fieldLabel('ROLL NUMBER (OPTIONAL)'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _rollController,
                          maxLength: 20,
                          textCapitalization: TextCapitalization.characters,
                          textInputAction: TextInputAction.done,
                          scrollPadding: const EdgeInsets.only(bottom: 80, top: 20),
                          style: GoogleFonts.robotoFlex(color: U.text, fontSize: 14.5, letterSpacing: 0.5),
                          cursorColor: theme.primary,
                          decoration: _inputDec(
                            hint: 'e.g. 21A91A0501',
                            icon: Icon(Icons.badge_outlined, size: 20, color: theme.primary),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Show Roll Number on Profile toggle
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark
                                ? U.surfaceContainerLowest.withValues(alpha: 0.6)
                                : U.surfaceContainerHighest.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: U.outlineVariant.withValues(alpha: 0.4),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.badge_outlined, size: 20, color: theme.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Show Roll Number on Profile',
                                      style: GoogleFonts.robotoFlex(
                                        color: U.text,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      'Make your student roll ID visible to other students',
                                      style: GoogleFonts.robotoFlex(
                                        color: U.sub,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _showRollNumberOnProfile,
                                activeThumbColor: theme.primary,
                                activeTrackColor: theme.primary.withValues(alpha: 0.25),
                                inactiveThumbColor: isDark ? const Color(0xFFD4D4D8) : U.sub,
                                inactiveTrackColor: isDark ? const Color(0xFF27272A) : U.surfaceContainerHighest,
                                trackOutlineColor: WidgetStateProperty.resolveWith(
                                  (states) => states.contains(WidgetState.selected)
                                      ? theme.primary.withValues(alpha: 0.5)
                                      : U.outlineVariant.withValues(alpha: 0.5),
                                ),
                                onChanged: (val) => setState(() => _showRollNumberOnProfile = val),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.robotoFlex(
        color: U.sub,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    );
  }

  InputDecoration _inputDec({
    required String hint,
    required Widget icon,
    String? prefixText,
  }) {
    final theme = appThemeNotifier.value;
    final isDark = theme.isDark;
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.robotoFlex(color: U.dim, fontSize: 13.5),
      prefixIcon: icon,
      prefixText: prefixText,
      prefixStyle: GoogleFonts.robotoFlex(color: theme.primary, fontWeight: FontWeight.w700, fontSize: 14.5),
      filled: true,
      fillColor: isDark
          ? U.surfaceContainerLowest.withValues(alpha: 0.6)
          : U.surfaceContainerHighest.withValues(alpha: 0.5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: U.outlineVariant.withValues(alpha: 0.4), width: 0.8),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: U.outlineVariant.withValues(alpha: 0.4), width: 0.8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.primary, width: 1.5),
      ),
    );
  }
}

// ── Interceptor-style Theme Selector Sheet (Dark/Light + 5 Accent Swatches) ──
class _ThemeStyleSheet extends StatefulWidget {
  const _ThemeStyleSheet({required this.currentKey});

  final String currentKey;

  @override
  State<_ThemeStyleSheet> createState() => _ThemeStyleSheetState();
}

class _ThemeStyleSheetState extends State<_ThemeStyleSheet> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: appThemeNotifier,
      builder: (context, activeTheme, _) {
        final cs = activeTheme.colorScheme;
        final isDark = activeTheme.isDark;
        final accents = U.themesForBrightness(isDark);

        return Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainer,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Theme accent',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: cs.onSurfaceVariant,
                          size: 20,
                        ),
                        onPressed: () =>
                            Navigator.pop(context, activeTheme.key),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Dark Theme Toggle (exact Interceptor Settings style)
                  InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      final nextKey = U.counterpartKey(
                        activeTheme.key,
                        !isDark,
                      );
                      U.applyTheme(nextKey);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isDark
                                ? Icons.dark_mode_outlined
                                : Icons.light_mode_outlined,
                            color: cs.primary,
                            size: 22,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Dark theme',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurface,
                                  ),
                                ),
                                Text(
                                  isDark ? 'On' : 'Off',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: isDark,
                            activeTrackColor: cs.primary,
                            onChanged: (val) {
                              HapticFeedback.selectionClick();
                              final nextKey = U.counterpartKey(
                                activeTheme.key,
                                val,
                              );
                              U.applyTheme(nextKey);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // 5 Interceptor Circular Accent Swatches
                  Wrap(
                    spacing: 18,
                    runSpacing: 16,
                    children: accents.map((t) {
                      final isSelected = t.key == activeTheme.key;
                      final accentColor = t.primary;
                      final iconColor =
                          ThemeData.estimateBrightnessForColor(accentColor) ==
                                  Brightness.dark
                              ? Colors.white
                              : Colors.black;

                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          U.applyTheme(t.key);
                          Navigator.pop(context, t.key);
                        },
                        child: SizedBox(
                          width: 58,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  shape: BoxShape.circle,
                                ),
                                child: isSelected
                                    ? Icon(
                                        Icons.check_rounded,
                                        size: 24,
                                        color: iconColor,
                                      )
                                    : null,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                t.label.split(' ').first,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? cs.onSurface
                                      : cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Raise Issue / Contact Support Sheet ──
class _RaiseIssueSheet extends StatefulWidget {
  const _RaiseIssueSheet();

  @override
  State<_RaiseIssueSheet> createState() => _RaiseIssueSheetState();
}

class _RaiseIssueSheetState extends State<_RaiseIssueSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  File? _selectedFile;
  String? _selectedFilename;
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final result = await FileUploadService().pickFile();
      if (result != null) {
        final size = await result.$1.length();
        if (size > 5 * 1024 * 1024) {
          throw Exception('Image size must be less than 5 MB.');
        }
        setState(() {
          _selectedFile = result.$1;
          _selectedFilename = result.$2;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: U.red,
            content: Text(e.toString(), style: GoogleFonts.robotoFlex(color: Colors.white, fontSize: 13)),
          ),
        );
      }
    }
  }

  void _clearImage() {
    setState(() {
      _selectedFile = null;
      _selectedFilename = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final userName = user?.displayName ?? 'Student';
      final userEmail = user?.email ?? 'anonymous';

      String imageUrl = '';
      if (_selectedFile != null) {
        final univId = U.cachedUniversityId.isNotEmpty ? U.cachedUniversityId : 'support';
        imageUrl = await FileUploadService().uploadFile(
          file: _selectedFile!,
          originalFilename: _selectedFilename ?? 'image.png',
          universityId: univId,
        );
      }

      final success = await EmailService().sendIssueReport(
        userName: userName,
        userEmail: userEmail,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        imageUrls: imageUrl,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: U.green,
              content: Text(
                'Report submitted successfully!',
                style: GoogleFonts.robotoFlex(color: U.bg, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          );
          Navigator.pop(context);
        }
      } else {
        throw Exception('Failed to send report');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: U.red,
            content: Text(e.toString(), style: GoogleFonts.robotoFlex(color: Colors.white, fontSize: 13)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = appThemeNotifier.value;
    final isDark = theme.isDark;

    return Container(
      decoration: BoxDecoration(
        color: U.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: U.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.5),
          width: 0.8,
        ),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: U.outlineVariant,
                      borderRadius: M3Shapes.fullRadius,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: _submitting ? null : () => Navigator.pop(context),
                      child: Text('Cancel', style: GoogleFonts.robotoFlex(color: U.sub, fontSize: 14.5)),
                    ),
                    Text(
                      'Feedback & Support',
                      style: GoogleFonts.robotoFlex(color: U.text, fontSize: 16.5, fontWeight: FontWeight.w700),
                    ),
                    FilledButton(
                      onPressed: _submitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(borderRadius: M3Shapes.fullRadius),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: _submitting
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.onPrimary,
                                ),
                              ),
                            )
                          : Text('Submit', style: GoogleFonts.robotoFlex(fontSize: 13.5, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  enabled: !_submitting,
                  style: GoogleFonts.robotoFlex(color: U.text, fontSize: 14.5),
                  decoration: InputDecoration(
                    labelText: 'TITLE',
                    hintText: 'e.g. Attendance page sync issue',
                    filled: true,
                    fillColor: isDark
                        ? U.surfaceContainerLowest.withValues(alpha: 0.6)
                        : U.surfaceContainerHighest.withValues(alpha: 0.5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Enter a title' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descController,
                  enabled: !_submitting,
                  maxLines: 4,
                  style: GoogleFonts.robotoFlex(color: U.text, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'DESCRIPTION',
                    hintText: 'Describe the issue in detail...',
                    filled: true,
                    fillColor: isDark
                        ? U.surfaceContainerLowest.withValues(alpha: 0.6)
                        : U.surfaceContainerHighest.withValues(alpha: 0.5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Enter a description' : null,
                ),
                const SizedBox(height: 14),
                if (_selectedFile == null)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _submitting ? null : _pickImage,
                      icon: Icon(Icons.add_a_photo_outlined, size: 17, color: theme.primary),
                      label: Text('Attach Screenshot (Optional)', style: GoogleFonts.robotoFlex(color: theme.primary, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? U.surfaceContainerLowest : U.surfaceContainer,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: U.outlineVariant.withValues(alpha: 0.45)),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: Image.file(_selectedFile!, fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _selectedFilename ?? 'screenshot.png',
                            style: GoogleFonts.robotoFlex(color: U.text, fontSize: 13, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: _submitting ? null : _clearImage,
                          icon: Icon(Icons.close_rounded, color: U.red, size: 18),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Profile Section displaying projects authored or contributed to by the user.
class _UserProjectsProfileSection extends StatefulWidget {
  final String userId;

  const _UserProjectsProfileSection({required this.userId});

  @override
  State<_UserProjectsProfileSection> createState() => _UserProjectsProfileSectionState();
}

class _UserProjectsProfileSectionState extends State<_UserProjectsProfileSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.userId.isEmpty) return const SizedBox.shrink();

    final theme = appThemeNotifier.value;
    final isDark = theme.isDark;

    return StreamBuilder<List<ProjectModel>>(
      stream: ProjectService().getUserProjectsStream(widget.userId),
      builder: (context, snapshot) {
        final projects = snapshot.data ?? [];

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: U.surfaceContainer,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: U.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.5),
              width: 0.8,
            ),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header (Tappable to Expand / Collapse)
              InkWell(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: U.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.rocket_launch_rounded, color: U.primary, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                'PROJECTS',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.robotoFlex(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                  color: U.primary,
                                ),
                              ),
                            ),

                            if (projects.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: U.primary.withValues(alpha: 0.14),
                                  borderRadius: M3Shapes.fullRadius,
                                ),
                                child: Text(
                                  '${projects.length}',
                                  style: GoogleFonts.robotoFlex(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: U.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Post / Showcase Button
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const CreateProjectScreen()),
                          );
                        },
                        icon: const Icon(Icons.add_rounded, size: 15),
                        label: const Text('Add'),
                        style: TextButton.styleFrom(
                          foregroundColor: U.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          textStyle: GoogleFonts.robotoFlex(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Expand/Collapse Chevron Icon
                      Icon(
                        _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        color: U.primary,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),

              if (_isExpanded) ...[
                const SizedBox(height: 14),

                if (projects.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: U.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: U.outlineVariant.withValues(alpha: 0.25),
                        width: 0.8,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.lightbulb_outline_rounded, size: 28, color: U.sub),
                        const SizedBox(height: 6),
                        Text(
                          'No projects showcased yet',
                          style: GoogleFonts.robotoFlex(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: U.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Publish your academic projects, hackathons, or apps to get recognized.',
                          style: GoogleFonts.robotoFlex(fontSize: 12, color: U.sub),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: projects.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final p = projects[index];
                      final isOwner = p.ownerId == widget.userId;
                      final role = isOwner
                          ? 'Owner & Lead'
                          : (p.contributors.firstWhere(
                              (c) => c.userId == widget.userId,
                              orElse: () => ProjectContributor(userId: widget.userId, name: '', role: 'Contributor'),
                            ).role ?? 'Contributor');

                      return InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ProjectDetailScreen(projectId: p.id, initialProject: p),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: U.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: U.outlineVariant.withValues(alpha: 0.35),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Thumbnail
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  color: U.surfaceContainerHighest,
                                  child: p.coverImage.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: p.coverImage,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Center(
                                            child: SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(strokeWidth: 2, color: U.primary),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) => Icon(Icons.code_rounded, color: U.sub, size: 24),
                                        )
                                      : Icon(Icons.palette_outlined, color: U.sub, size: 24),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.robotoFlex(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: U.text,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isOwner
                                                ? U.primary.withValues(alpha: 0.12)
                                                : U.peach.withValues(alpha: 0.12),
                                            borderRadius: M3Shapes.fullRadius,
                                          ),
                                          child: Text(
                                            role,
                                            style: GoogleFonts.robotoFlex(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                              color: isOwner ? U.primary : U.peach,
                                            ),
                                          ),
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.schedule_rounded, size: 11, color: U.sub),
                                            const SizedBox(width: 3),
                                            Text(
                                              p.relativeTime,
                                              style: GoogleFonts.robotoFlex(fontSize: 10.5, color: U.sub, fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.favorite_rounded, size: 12, color: U.red),
                                            const SizedBox(width: 3),
                                            Text(
                                              '${p.likesCount}',
                                              style: GoogleFonts.robotoFlex(fontSize: 11, color: U.sub, fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios_rounded, size: 12, color: U.dim),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

