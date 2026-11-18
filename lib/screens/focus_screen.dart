import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../models/event_model.dart';
import '../services/attendance_cache_service.dart';
import '../services/event_service.dart';
import '../services/focus_supabase_service.dart';
import '../services/notification_service.dart';
import '../services/secure_storage_service.dart';
import '../services/uni_chat_service.dart';
import '../widgets/app_motion.dart';
import 'attendance_screen.dart';
import 'event_notifications_screen.dart';
import 'friends_screen.dart';
import 'projects_feed_screen.dart';
import 'uni_chat_screen.dart';

/// Minimal Interceptor-inspired Home screen for UTOPIA.
class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  final _service = FocusSupabaseService();
  double? _attendancePct;
  bool _isAttendanceConnected = false;
  DateTime? _lastAttendanceFetched;
  String _universityId = U.cachedUniversityId;
  String _universityName = U.cachedUniversityName;
  int _notificationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadNotificationCount();
  }

  Future<void> _loadNotificationCount() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final dismissedIds =
          await NotificationService.getDismissedNotificationIds();
      final lastClearedAt =
          await NotificationService.getLastNotificationsClearedAt();

      int socialCount = 0;
      if (uid.isNotEmpty) {
        try {
          final pendingReqs = await FirebaseFirestore.instance
              .collection('follows')
              .where('followingId', isEqualTo: uid)
              .where('status', isEqualTo: 'pending')
              .get();
          final unseenWaves = await FirebaseFirestore.instance
              .collection('waves')
              .where('receiverId', isEqualTo: uid)
              .limit(10)
              .get();
          final unreadNotifs = await FirebaseFirestore.instance
              .collection('notifications')
              .where('recipientId', isEqualTo: uid)
              .limit(10)
              .get();

          final validReqs = pendingReqs.docs
              .where(
                (d) => !NotificationService.isNotificationDismissed(
                  d.id,
                  dismissedIds: dismissedIds,
                  lastClearedAt: lastClearedAt,
                ),
              )
              .length;

          final validWaves = unseenWaves.docs.where((d) {
            final createdAt = (d.data()['createdAt'] as Timestamp?)?.toDate();
            return !NotificationService.isNotificationDismissed(
              d.id,
              dismissedIds: dismissedIds,
              lastClearedAt: lastClearedAt,
              createdAt: createdAt,
            );
          }).length;

          final validNotifs = unreadNotifs.docs.where((d) {
            final createdAt = (d.data()['createdAt'] as Timestamp?)?.toDate();
            return !NotificationService.isNotificationDismissed(
              d.id,
              dismissedIds: dismissedIds,
              lastClearedAt: lastClearedAt,
              createdAt: createdAt,
            );
          }).length;

          socialCount = validReqs + validWaves + validNotifs;
        } catch (_) {}
      }

      final results = await Future.wait([
        EventService.instance.getEndingSoonEvents(limit: 5),
        EventService.instance.getUpcomingEvents(limit: 5),
        EventService.instance.getMyCertificates(),
      ]);

      final endingSoon = (results[0] as List<EventModel>)
          .where(
            (e) => !NotificationService.isNotificationDismissed(
              e.id,
              dismissedIds: dismissedIds,
              lastClearedAt: lastClearedAt,
              createdAt: e.createdAt ?? e.date,
            ),
          )
          .toList();
      final newEvents = (results[1] as List<EventModel>)
          .where(
            (e) => !NotificationService.isNotificationDismissed(
              e.id,
              dismissedIds: dismissedIds,
              lastClearedAt: lastClearedAt,
              createdAt: e.createdAt ?? e.date,
            ),
          )
          .toList();
      final certificates = (results[2] as List<EventCertificate>)
          .where(
            (c) => !NotificationService.isNotificationDismissed(
              c.id,
              dismissedIds: dismissedIds,
              lastClearedAt: lastClearedAt,
              createdAt: c.issuedAt,
            ),
          )
          .toList();

      if (mounted) {
        setState(() {
          _notificationCount =
              socialCount +
              endingSoon.length +
              newEvents.length +
              certificates.length;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final uniId = userDoc.data()?['selectedUniversityId'] as String?;
        final uniName =
            userDoc.data()?['universityName'] as String? ??
            userDoc.data()?['university'] as String?;
        if (uniId != null && uniId.isNotEmpty) {
          _universityId = uniId;
          U.cachedUniversityId = uniId;
        }
        if (uniName != null && uniName.isNotEmpty) {
          _universityName = uniName;
          U.cachedUniversityName = uniName;
        }
      }
      await _service.initialize();
      _service.syncDownAllData().then((_) => _loadStats());
      _loadStats();
    } catch (_) {}
  }

  Future<void> _loadStats() async {
    try {
      double? attendancePct;
      bool isConnected = false;
      DateTime? lastFetched;
      try {
        final credentials = await SecureStorageService.getCredentials();
        if (credentials != null) {
          isConnected = true;
          final roll = credentials['rollNumber'];
          if (roll != null) {
            final cachedAttendance = await AttendanceCacheService.load(roll);
            if (cachedAttendance != null) {
              attendancePct =
                  (cachedAttendance.data['overallPercentage'] as num?)
                      ?.toDouble();
              lastFetched = cachedAttendance.cachedAt;
            } else {
              final prefs = await SharedPreferences.getInstance();
              final currJson = prefs.getString(
                'attendance_history_curr_${roll.trim().toUpperCase()}',
              );
              if (currJson != null) {
                try {
                  final Map<String, dynamic> currMap = jsonDecode(currJson);
                  final tsStr = currMap['timestamp'] as String?;
                  if (tsStr != null) {
                    lastFetched = DateTime.tryParse(tsStr);
                  }
                  attendancePct ??=
                      (currMap['overallPercentage'] as num?)?.toDouble();
                } catch (_) {}
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Error loading cached attendance: $e');
      }

      if (mounted) {
        setState(() {
          _attendancePct = attendancePct;
          _isAttendanceConnected = isConnected;
          _lastAttendanceFetched = lastFetched;
        });
      }
    } catch (_) {}
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  String get _attendanceSubtitle {
    if (!_isAttendanceConnected) {
      return 'Connect portal';
    }
    if (_lastAttendanceFetched != null) {
      return 'Synced ${_formatDate(_lastAttendanceFetched!)}';
    }
    return 'Portal connected';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isAditya = U.isAdityaCollege(_universityId, _universityName);
    final hasAttendancePct =
        _isAttendanceConnected &&
        _attendancePct != null &&
        _attendancePct! > 0;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
              children: [
                // ── Header (exact Interceptor HubScreen style) ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'utopia',
                          style: GoogleFonts.inter(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1.2,
                            color: colorScheme.onSurface,
                          ),
                          children: [
                            TextSpan(
                              text: '.',
                              style: TextStyle(color: colorScheme.primary),
                            ),
                          ],
                        ),
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const EventNotificationsScreen(),
                              ),
                            );
                            _loadNotificationCount();
                          },
                          icon: const Icon(Icons.notifications_none_rounded),
                          color: colorScheme.onSurfaceVariant,
                          iconSize: 24,
                          tooltip: 'Notifications',
                        ),
                        if (_notificationCount > 0)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // ── Primary Card (exact Interceptor Moodify card style) ──
                if (isAditya)
                  _PrimaryBannerCard(
                    icon: Icons.donut_large_rounded,
                    title: 'Attendance',
                    subtitle: _attendanceSubtitle,
                    trailingValue: hasAttendancePct
                        ? '${_attendancePct!.toStringAsFixed(1)}%'
                        : null,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AttendanceScreen(),
                      ),
                    ).then((_) => _loadData()),
                  )
                else
                  _PrimaryBannerCard(
                    icon: Icons.rocket_launch_outlined,
                    title: 'Projects',
                    subtitle: 'Explore & showcase campus builds',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProjectsFeedScreen(),
                      ),
                    ),
                  ),
                const SizedBox(height: 36),

                // ── Section Header (exact Interceptor Collection header style) ──
                Text(
                  'Explore',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 14),

                // ── Squared Cards Grid (exact Interceptor Drive-style cards) ──
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.0,
                  children: [
                    _CampusChatSquaredCard(),
                    _SquaredHubCard(
                      title: 'Friends',
                      icon: Icons.people_outline_rounded,
                      onTap: () => Navigator.push(
                        context,
                        buildForwardRoute(const FriendsScreen()),
                      ),
                    ),
                  ],
                ),
              ]
                  .animate(interval: 40.ms)
                  .fadeIn(duration: 300.ms, curve: Curves.easeOut),
            ),
          ),
        ),
      ),
    );
  }
}

/// Primary stroke-free banner card modeled after Interceptor's Moodify card.
class _PrimaryBannerCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailingValue;
  final VoidCallback onTap;

  const _PrimaryBannerCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailingValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final muted = colorScheme.onSurfaceVariant.withValues(alpha: 0.65);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Icon(icon, size: 24, color: colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailingValue != null) ...[
                const SizedBox(width: 12),
                Text(
                  trailingValue!,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Icon(Icons.chevron_right_rounded, size: 20, color: muted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Clean, stroke-free squared card modeled after Interceptor's _SquaredFolderCard.
class _SquaredHubCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool showBadge;
  final VoidCallback onTap;

  const _SquaredHubCard({
    required this.title,
    required this.icon,
    this.showBadge = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (showBadge)
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              Expanded(
                child: Center(
                  child: Icon(
                    icon,
                    size: 76,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Campus Chat squared card with live unread stream indicator.
class _CampusChatSquaredCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: currentUid.isNotEmpty
          ? FirebaseFirestore.instance
              .collection('users')
              .doc(currentUid)
              .snapshots()
          : const Stream.empty(),
      builder: (context, userSnap) {
        final liveUniId =
            userSnap.data?.data()?['selectedUniversityId'] as String?;
        final uniId = (liveUniId != null && liveUniId.isNotEmpty)
            ? liveUniId
            : (U.cachedUniversityId.isNotEmpty
                ? U.cachedUniversityId
                : 'support');
        if (liveUniId != null &&
            liveUniId.isNotEmpty &&
            liveUniId != U.cachedUniversityId) {
          U.cachedUniversityId = liveUniId;
        }

        return StreamBuilder<bool>(
          stream: UniChatService().unreadStatusStream(uniId),
          initialData: false,
          builder: (context, snapshot) {
            final hasUnread = snapshot.data ?? false;
            return _SquaredHubCard(
              title: 'Campus Chat',
              icon: Icons.forum_outlined,
              showBadge: hasUnread,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UniChatScreen(universityId: uniId),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
