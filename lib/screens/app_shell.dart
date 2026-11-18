import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';

import '../main.dart';
import '../services/app_update_service.dart';
import '../theme/m3_expressive_theme.dart';
import 'focus_screen.dart';
import 'people_screen.dart';
import 'profile_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  static bool _sessionCounted = false;

  static void resetSession() {
    _sessionCounted = false;
  }

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  late final PageController _pageController;

  final List<Widget?> _screens = [
    const FocusScreen(),
    null,
    null,
  ];

  Widget _getScreen(int index) {
    if (_screens[index] == null) {
      switch (index) {
        case 1:
          _screens[index] = const PeopleScreen();
          break;
        case 2:
          _screens[index] = const ProfileScreen();
          break;
      }
    }
    return _screens[index]!;
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _index);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        await AppUpdateService.checkForUpdate(context);
      }
      if (mounted) {
        _checkPopupEvent();
      }
    });
  }

  Future<void> _checkPopupEvent() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (!AppShell._sessionCounted) {
        AppShell._sessionCounted = true;
        final currentCount = prefs.getInt('app_open_count') ?? 0;
        await prefs.setInt('app_open_count', currentCount + 1);
      }

      final openCount = prefs.getInt('app_open_count') ?? 0;
      if (openCount < 2) {
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('config')
          .doc('app_config')
          .get();

      final eventId = doc.data()?['popup_event_id'] as String?;
      if (eventId != null && eventId.isNotEmpty) {
        final lastSeen = prefs.getString('last_seen_popup_event_id');
        if (lastSeen != eventId) {
          if (mounted) {
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => Dialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: U.surfaceContainerHigh,
                    borderRadius: M3Shapes.extraLargeRadius,
                    border: Border.all(
                      color: U.outlineVariant.withValues(alpha: 0.5),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: appThemeNotifier.value.isDark ? 0.4 : 0.12,
                        ),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: U.primaryContainer.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          color: U.primary,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Share UTOPIA',
                        style: GoogleFonts.inter(
                          color: U.text,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Love using UTOPIA? Help your friends elevate their university experience by inviting them to the app!',
                        style: GoogleFonts.inter(
                          color: U.sub,
                          fontSize: 14,
                          height: 1.45,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: U.text,
                                side: BorderSide(color: U.outlineVariant),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                'Later',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: U.primary,
                                foregroundColor: U.colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                SharePlus.instance.share(
                                  ShareParams(
                                    text:
                                        'Join me on UTOPIA! 🚀 The productivity platform.\n\nhttps://inferalis.space/download-utopia',
                                  ),
                                );
                                Navigator.pop(context);
                              },
                              child: Text(
                                'Share App',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
            await prefs.setString('last_seen_popup_event_id', eventId);
          }
        }
      }
    } catch (e) {
      // Ignore errors silently
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _setIndex(int nextIndex) {
    if (nextIndex == _index) {
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _index = nextIndex);
    if (_pageController.hasClients) {
      _pageController.jumpToPage(nextIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: appThemeNotifier,
      builder: (context, theme, _) {
        final cs = theme.colorScheme;
        final isDark = theme.isDark;
        final screenWidth = MediaQuery.sizeOf(context).width;
        final isDesktopWeb = kIsWeb || screenWidth > 768;

        final systemUiStyle = SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: cs.surfaceContainerLow,
          systemNavigationBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarContrastEnforced: false,
        );

        Widget wrapPage(Widget child) {
          return _KeepAliveWrapper(
            child: isDesktopWeb
                ? Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 960),
                      child: child,
                    ),
                  )
                : child,
          );
        }

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: systemUiStyle,
          child: Scaffold(
            backgroundColor: cs.surfaceContainerLowest,
            extendBody: false,
            body: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                if (_index != index) {
                  setState(() => _index = index);
                }
              },
              physics: const ClampingScrollPhysics(),
              children: [
                wrapPage(_getScreen(0)),
                wrapPage(_getScreen(1)),
                wrapPage(_getScreen(2)),
              ],
            ),
            bottomNavigationBar: _SharpBottomNavBar(
              currentIndex: _index,
              onTap: _setIndex,
            ),
          ),
        );
      },
    );
  }
}

/// Standard sharp rectangular bottom navigation bar with icon background highlight.
class _SharpBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _SharpBottomNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    (
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    (
      icon: Icons.groups_outlined,
      activeIcon: Icons.groups_rounded,
      label: 'People',
    ),
    (
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border(
          top: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.45),
            width: 0.8,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final isActive = i == currentIndex;

              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onTap(i),
                    borderRadius: BorderRadius.zero,
                    splashColor: cs.primary.withValues(alpha: 0.08),
                    highlightColor: cs.primary.withValues(alpha: 0.04),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          width: isActive ? 58 : 36,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isActive
                                ? cs.primaryContainer
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Icon(
                              isActive ? item.activeIcon : item.icon,
                              size: 22,
                              color: isActive
                                  ? cs.onPrimaryContainer
                                  : cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight:
                                isActive ? FontWeight.w600 : FontWeight.w500,
                            color: isActive
                                ? cs.onSurface
                                : cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const _KeepAliveWrapper({required this.child});

  @override
  State<_KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<_KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
