import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../main.dart';
import '../services/follow_service.dart';
import '../services/people_interaction_service.dart';
import '../widgets/app_motion.dart';
import '../widgets/social_badge.dart';
import '../widgets/superuser_badge.dart';
import '../widgets/thought_cloud_badge.dart';

import '../models/project_model.dart';
import '../services/project_service.dart';
import 'project_detail_screen.dart';
import 'create_project_screen.dart';
import 'chat_screen.dart';
import 'followers_following_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({
    super.key,
    required this.uid,
    required this.displayName,
    this.email = '',
    this.photoUrl,
  });

  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FollowService _followService = FollowService();
  final PeopleInteractionService _interactionService = PeopleInteractionService();

  bool _actionLoading = false;
  bool _waving = false;
  bool _hasWavedRecently = false;

  String get _currentUid => FirebaseAuth.instance.currentUser?.uid ?? '';
  bool get _isOwnProfile => _currentUid == widget.uid;

  @override
  void initState() {
    super.initState();
    _checkWaveState();
  }

  Future<void> _checkWaveState() async {
    if (_isOwnProfile) return;
    try {
      final waved = await _interactionService.hasWavedRecently(widget.uid);
      if (mounted) {
        setState(() => _hasWavedRecently = waved);
      }
    } catch (_) {}
  }

  Future<void> _handleWave() async {
    if (_isOwnProfile || _waving) return;
    setState(() => _waving = true);
    try {
      final success = await _interactionService.sendWave(widget.uid);
      if (mounted && success) {
        setState(() => _hasWavedRecently = true);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            backgroundColor: U.peach,
            content: Row(
              children: [
                const Text('👋', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Waved at ${widget.displayName}!',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error waving: $e');
    } finally {
      if (mounted) setState(() => _waving = false);
    }
  }

  Future<void> _handleLinkToggle(LinkStatus status, String displayName) async {
    if (_actionLoading) return;

    if (status == LinkStatus.linked) {
      final confirm = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: U.card,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: U.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Unlink with $displayName?',
                  style: GoogleFonts.outfit(
                    color: U.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Both of you will be unlinked and won\'t be able to direct message each other until linked again.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(color: U.sub, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: U.text,
                          side: BorderSide(color: U.border),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: U.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(
                          'Unlink',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
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

      if (confirm != true) return;
    } else if (status == LinkStatus.requested) {
      final confirm = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: U.card,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: U.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Cancel Link Request?',
                  style: GoogleFonts.outfit(
                    color: U.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Withdraw your link request to $displayName?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(color: U.sub, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: U.text,
                          side: BorderSide(color: U.border),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(
                          'Keep',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: U.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(
                          'Cancel Request',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
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

      if (confirm != true) return;
    }

    setState(() => _actionLoading = true);
    try {
      if (status == LinkStatus.linked) {
        await _followService.unlink(widget.uid);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: U.card,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Text('Unlinked from $displayName', style: GoogleFonts.outfit(color: U.text)),
          ));
        }
      } else if (status == LinkStatus.requested) {
        await _followService.cancelRequest(widget.uid);
      } else if (status == LinkStatus.hasIncomingRequest) {
        await _followService.acceptIncomingFrom(widget.uid);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: U.card,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Text('Linked up with $displayName! 🔗', style: GoogleFonts.outfit(color: U.text)),
          ));
        }
      } else {
        await _followService.sendLinkRequest(widget.uid);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: U.card,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Text('Link request sent to $displayName', style: GoogleFonts.outfit(color: U.text)),
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: U.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text('Action failed', style: GoogleFonts.outfit(color: Colors.white)),
        ));
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _openChat(Map<String, dynamic> userData) async {
    final canChat = await _followService.canChat(_currentUid, widget.uid);
    if (!mounted) return;
    if (!canChat) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: U.card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          'You can only message students you are linked with.',
          style: GoogleFonts.outfit(color: U.text, fontSize: 13),
        ),
      ));
      return;
    }
    Navigator.of(context).push(buildForwardRoute(ChatScreen(
      otherUserId: widget.uid,
      displayName: widget.displayName,
      email: widget.email,
      photoUrl: widget.photoUrl,
    )));
  }

  void _navigateToFollows(bool showFollowers, String name) {
    Navigator.of(context).push(
      buildForwardRoute(
        FollowersFollowingScreen(
          uid: widget.uid,
          displayName: name,
          showFollowers: showFollowers,
        ),
      ),
    );
  }

  void _openPhotoViewer(String photoUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: photoUrl,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: U.bg,
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.uid)
            .snapshots(),
        builder: (context, userSnap) {
          final userData = userSnap.data?.data() ?? {};
          final displayName = UtopiaApp.sanitizeDisplayName(
            (userData['displayName'] ?? widget.displayName).toString(),
          );
          final photoUrl = (userData['photoUrl'] ?? widget.photoUrl)?.toString();
          final bio = (userData['bio'] ?? '').toString().trim();

          // Resolve university name cleanly
          String university = (userData['universityName'] ?? userData['university'] ?? '').toString().trim();
          if (university.isEmpty) {
            final uniId = (userData['selectedUniversityId'] ?? '').toString().trim();
            if (uniId.isNotEmpty) {
              if (uniId.toLowerCase() == U.cachedUniversityId.toLowerCase() && U.cachedUniversityName.isNotEmpty) {
                university = U.cachedUniversityName;
              } else {
                university = uniId.toUpperCase();
              }
            }
          }
          if (university.isEmpty && U.cachedUniversityName.isNotEmpty) {
            university = U.cachedUniversityName;
          }

          final branch = (userData['branch'] ?? userData['department'] ?? '').toString().trim();
          final rollNumber = (userData['rollNumber'] ?? userData['rollNo'] ?? '').toString().trim();
          final showRollNumber = (userData['showRollNumberOnProfile'] as bool?) ?? true;

          final instagramId = (userData['instagramId'] ?? '').toString().trim();
          final githubId = (userData['githubId'] ?? userData['githubUsername'] ?? '').toString().trim();
          final discordId = (userData['discordId'] ?? userData['discordUsername'] ?? '').toString().trim();
          final isSuperuser = userData['role'] == 'superuser';
          final wavesCount = (userData['wavesReceivedCount'] as num?)?.toInt() ?? 0;

          // Parse campus vibe if active
          CampusVibe? vibe;
          if (userData['vibe'] != null) {
            final parsed = CampusVibe.fromMap(widget.uid, userData);
            if ((parsed.text.isNotEmpty || (parsed.mediaUrl != null && parsed.mediaUrl!.isNotEmpty)) &&
                !parsed.isExpired) {
              vibe = parsed;
            }
          }

          final hasSocialLinks = instagramId.isNotEmpty || githubId.isNotEmpty || discordId.isNotEmpty;


          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Top App Bar ─────────────────────────────────────────
              SliverAppBar(
                backgroundColor: U.bg,
                elevation: 0,
                surfaceTintColor: Colors.transparent,
                pinned: true,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Material(
                    color: U.surface.withValues(alpha: 0.8),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: U.text,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),

              // ── Main Centered Body ──────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // ── 1. Centered Hero Avatar & Thought Cloud ─────
                      Center(
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: U.primary.withValues(alpha: 0.35),
                                  width: 2.0,
                                ),
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  if (photoUrl != null && photoUrl.isNotEmpty) {
                                    _openPhotoViewer(photoUrl);
                                  }
                                },
                                child: CircleAvatar(
                                  radius: 52,
                                  backgroundColor: U.primary.withValues(alpha: 0.08),
                                  backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                                      ? CachedNetworkImageProvider(photoUrl)
                                      : null,
                                  child: photoUrl == null || photoUrl.isEmpty
                                      ? Text(
                                          displayName.isEmpty ? 'U' : displayName[0].toUpperCase(),
                                          style: GoogleFonts.outfit(
                                            color: U.primary,
                                            fontSize: 38,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                            ),

                            // Active Vibe Thought Cloud
                            if (vibe != null)
                              Positioned(
                                top: -6,
                                right: -8,
                                child: ThoughtCloudBadge(
                                  vibe: vibe,
                                  avatarRadius: 52,
                                ),
                              ),
                          ],
                        ),
                      ).animate().scale(
                            duration: 320.ms,
                            curve: Curves.easeOutBack,
                            begin: const Offset(0.85, 0.85),
                          ),

                      const SizedBox(height: 16),

                      // ── 2. Centered Name & Verification ──────────────
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              displayName,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                color: U.text,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          if (isSuperuser) ...[
                            const SizedBox(width: 6),
                            const SuperUserBadge(size: 19),
                          ],
                        ],
                      ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.1, end: 0),

                      // ── 3. Academic Subtitle (plain text, no pills) ───
                      if (university.isNotEmpty || branch.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          [
                            if (branch.isNotEmpty) branch,
                            if (university.isNotEmpty) university,
                          ].join(' · '),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            color: U.sub,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],

                      // ── 4. Bio (plain text, no card) ──────────────────
                      if (bio.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 360),
                          child: Text(
                            bio,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              color: U.text.withValues(alpha: 0.75),
                              fontSize: 13.5,
                              height: 1.5,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 22),

                      // ── 5. Action Hub (Link, Message, Wave) ──────────
                      if (!_isOwnProfile)
                        StreamBuilder<LinkStatus>(
                          stream: _followService.linkStatusStream(_currentUid, widget.uid),
                          builder: (context, statusSnap) {
                            final status = statusSnap.data ?? LinkStatus.notLinked;

                            return StreamBuilder<bool>(
                              stream: _followService.canChatStream(_currentUid, widget.uid),
                              builder: (context, chatSnap) {
                                final canChat = chatSnap.data ?? false;

                                return Container(
                                  constraints: const BoxConstraints(maxWidth: 440),
                                  child: Row(
                                    children: [
                                      // Main Link Toggle Button
                                      Expanded(
                                        flex: 5,
                                        child: _LinkActionButton(
                                          status: status,
                                          loading: _actionLoading,
                                          onPressed: () => _handleLinkToggle(status, displayName),
                                        ),
                                      ),

                                      // Direct Message (available if linked / canChat)
                                      if (canChat) ...[
                                        const SizedBox(width: 8),
                                        Expanded(
                                          flex: 4,
                                          child: _MessageActionButton(
                                            onPressed: () => _openChat(userData),
                                          ),
                                        ),
                                      ],

                                      // Friendly Wave Button
                                      const SizedBox(width: 8),
                                      _WaveActionButton(
                                        hasWaved: _hasWavedRecently,
                                        loading: _waving,
                                        onWave: _handleWave,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        )
                      else
                        Container(
                          constraints: const BoxConstraints(maxWidth: 440),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: U.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.visibility_outlined, size: 16, color: U.primary),
                              const SizedBox(width: 8),
                              Text(
                                'This is how other students see your profile',
                                style: GoogleFonts.outfit(
                                  color: U.primary,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // ── 6. Community Stats (inline, no card) ──────────
                      const SizedBox(height: 24),
                      StreamBuilder<int>(
                        stream: _followService.linksCountStream(widget.uid),
                        builder: (context, linksSnap) {
                          final linksCount = linksSnap.data ?? 0;

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _InlineStat(
                                count: linksCount,
                                label: 'Links',
                                onTap: () => _navigateToFollows(true, displayName),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Container(
                                  width: 1,
                                  height: 28,
                                  color: U.border.withValues(alpha: 0.5),
                                ),
                              ),
                              _InlineStat(
                                count: wavesCount,
                                label: 'Waves',
                              ),
                            ],
                          );
                        },
                      ),

                      // ── Thin separator ──
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Divider(height: 1, thickness: 0.5, color: U.border.withValues(alpha: 0.4)),
                      ),

                      // ── 7. Academic Identity (flat rows, no card) ─────
                      if (branch.isNotEmpty || (rollNumber.isNotEmpty && (_isOwnProfile || showRollNumber))) ...[
                        _FlatInfoRow(
                          icon: Icons.school_outlined,
                          label: 'Branch',
                          value: branch,
                        ),
                        if (rollNumber.isNotEmpty && (_isOwnProfile || showRollNumber))
                          _FlatInfoRow(
                            icon: Icons.numbers_rounded,
                            label: 'Roll Number',
                            value: _isOwnProfile && !showRollNumber
                                ? '$rollNumber (Hidden)'
                                : rollNumber,
                          ),
                        const SizedBox(height: 8),
                      ],

                      // ── 7.8. Projects Showcase Section ──
                      _UserProjectsProfileSection(userId: widget.uid, isOwnProfile: _isOwnProfile),

                      // ── 8. Active Campus Vibe (accent left-border strip) ──
                      if (vibe != null) ...[
                        const SizedBox(height: 20),
                        Container(
                          constraints: const BoxConstraints(maxWidth: 440),
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: U.primary.withValues(alpha: 0.6),
                                width: 3,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(vibe.emoji, style: const TextStyle(fontSize: 18)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'CAMPUS VIBE',
                                    style: GoogleFonts.outfit(
                                      color: U.sub,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: U.teal,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Live',
                                    style: GoogleFonts.outfit(
                                      color: U.teal,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              if (vibe.text.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                  '"${vibe.text}"',
                                  style: GoogleFonts.outfit(
                                    color: U.text,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                              if (vibe.location != null || vibe.statusTag != null) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 6,
                                  children: [
                                    if (vibe.location != null)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.place_outlined, size: 12, color: U.sub),
                                          const SizedBox(width: 3),
                                          Text(
                                            vibe.location!,
                                            style: GoogleFonts.outfit(
                                              color: U.sub,
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    if (vibe.statusTag != null)
                                      Text(
                                        vibe.statusTag!,
                                        style: GoogleFonts.outfit(
                                          color: U.sub,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],

                      // ── 9. Social Badges (flat, no card) ──────────────
                      if (hasSocialLinks) ...[
                        const SizedBox(height: 20),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              'SOCIALS',
                              style: GoogleFonts.outfit(
                                color: U.dim,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (instagramId.isNotEmpty)
                              InstagramBadge(handle: instagramId),
                            if (githubId.isNotEmpty)
                              GithubBadge(handle: githubId),
                            if (discordId.isNotEmpty)
                              DiscordBadge(handle: discordId),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

/// Inline stat — just a number + label, no card
class _InlineStat extends StatelessWidget {
  final int count;
  final String label;
  final VoidCallback? onTap;

  const _InlineStat({
    required this.count,
    required this.label,
    this.onTap,
  });

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _fmt(count),
            style: GoogleFonts.outfit(
              color: U.text,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: U.sub,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Flat label → value row with hairline divider below
class _FlatInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _FlatInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 18, color: U.sub),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: U.sub,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: U.text,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, thickness: 0.4, color: U.border.withValues(alpha: 0.3)),
      ],
    );
  }
}


class _LinkActionButton extends StatelessWidget {
  const _LinkActionButton({
    required this.status,
    required this.loading,
    required this.onPressed,
  });

  final LinkStatus status;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    String label;
    IconData icon;
    Color bg;
    Color fg;
    bool outlined = false;

    switch (status) {
      case LinkStatus.notLinked:
        label = 'Link Up';
        icon = Icons.link_rounded;
        bg = U.primary;
        fg = U.getContrastColor(U.primary);
        break;
      case LinkStatus.requested:
        label = 'Requested';
        icon = Icons.schedule_rounded;
        bg = U.card;
        fg = U.sub;
        outlined = true;
        break;
      case LinkStatus.hasIncomingRequest:
        label = 'Accept Link';
        icon = Icons.check_rounded;
        bg = U.primary;
        fg = U.getContrastColor(U.primary);
        break;
      case LinkStatus.linked:
        label = 'Linked';
        icon = Icons.link_rounded;
        bg = U.card;
        fg = U.text;
        outlined = true;
        break;
    }

    if (loading) {
      return Container(
        height: 42,
        decoration: BoxDecoration(
          color: U.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: U.border),
        ),
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: U.primary,
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 42,
          decoration: BoxDecoration(
            color: outlined ? U.card : bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: outlined ? U.border : Colors.transparent,
              width: 0.9,
            ),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    color: fg,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
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

class _MessageActionButton extends StatelessWidget {
  const _MessageActionButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 42,
          decoration: BoxDecoration(
            color: U.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: U.border, width: 0.9),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chat_bubble_outline_rounded, size: 15, color: U.text),
                const SizedBox(width: 6),
                Text(
                  'Message',
                  style: GoogleFonts.outfit(
                    color: U.text,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
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

class _WaveActionButton extends StatelessWidget {
  const _WaveActionButton({
    required this.hasWaved,
    required this.loading,
    required this.onWave,
  });

  final bool hasWaved;
  final bool loading;
  final VoidCallback onWave;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasWaved ? null : onWave,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: hasWaved ? U.peach.withValues(alpha: 0.12) : U.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasWaved ? U.peach.withValues(alpha: 0.4) : U.border,
              width: 0.9,
            ),
          ),
          child: Center(
            child: loading
                ? SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(strokeWidth: 2, color: U.peach),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('👋', style: TextStyle(fontSize: 15)),
                      const SizedBox(width: 5),
                      Text(
                        hasWaved ? 'Waved' : 'Wave',
                        style: GoogleFonts.outfit(
                          color: hasWaved ? U.peach : U.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
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


/// Profile Section displaying projects authored or contributed to by this user.
class _UserProjectsProfileSection extends StatefulWidget {
  final String userId;
  final bool isOwnProfile;

  const _UserProjectsProfileSection({
    required this.userId,
    this.isOwnProfile = false,
  });

  @override
  State<_UserProjectsProfileSection> createState() => _UserProjectsProfileSectionState();
}

class _UserProjectsProfileSectionState extends State<_UserProjectsProfileSection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = !widget.isOwnProfile;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.userId.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<List<ProjectModel>>(
      stream: ProjectService().getUserProjectsStream(widget.userId),
      builder: (context, snapshot) {
        final projects = snapshot.data ?? [];

        if (projects.isEmpty && !widget.isOwnProfile) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section header — flat, no card ──
            GestureDetector(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.rocket_launch_rounded, color: U.dim, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'PROJECTS',
                      style: GoogleFonts.outfit(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: U.dim,
                      ),
                    ),
                    if (projects.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        '${projects.length}',
                        style: GoogleFonts.outfit(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: U.sub,
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (widget.isOwnProfile)
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const CreateProjectScreen()),
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_rounded, size: 14, color: U.primary),
                            const SizedBox(width: 2),
                            Text(
                              'Add',
                              style: GoogleFonts.outfit(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: U.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: U.dim,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Content ──
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: projects.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            'No projects showcased yet',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: U.sub,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          for (int i = 0; i < projects.length; i++) ...[
                            _buildProjectItem(projects[i]),
                            if (i < projects.length - 1)
                              Divider(
                                height: 1,
                                thickness: 0.4,
                                color: U.border.withValues(alpha: 0.3),
                              ),
                          ],
                        ],
                      ),
              ),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProjectItem(ProjectModel p) {
    final isOwner = p.ownerId == widget.userId;
    final role = isOwner
        ? 'Owner'
        : (p.contributors.firstWhere(
            (c) => c.userId == widget.userId,
            orElse: () => ProjectContributor(
              userId: widget.userId,
              name: '',
              role: 'Contributor',
            ),
          ).role ?? 'Contributor');

    return M3Pressable(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProjectDetailScreen(projectId: p.id, initialProject: p),
          ),
        );
      },
      scaleFactor: 0.98,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 52,
                height: 52,
                color: U.primary.withValues(alpha: 0.06),
                child: p.coverImage.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: p.coverImage,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Center(
                          child: SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: U.primary,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) =>
                            Icon(Icons.code_rounded, color: U.sub, size: 22),
                      )
                    : Icon(Icons.palette_outlined, color: U.sub, size: 22),
              ),
            ),
            const SizedBox(width: 14),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    p.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: U.text,
                    ),
                  ),

                  // Tagline
                  if (p.tagline.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      p.tagline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: U.sub,
                        fontWeight: FontWeight.w400,
                        height: 1.3,
                      ),
                    ),
                  ],

                  const SizedBox(height: 6),

                  // Metadata row: category · role · likes
                  Row(
                    children: [
                      // Category
                      Text(
                        p.category.label,
                        style: GoogleFonts.outfit(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: U.primary,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '·',
                          style: TextStyle(color: U.dim, fontSize: 10),
                        ),
                      ),
                      // Role
                      Text(
                        role,
                        style: GoogleFonts.outfit(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: isOwner ? U.text : U.sub,
                        ),
                      ),
                      if (p.likesCount > 0) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            '·',
                            style: TextStyle(color: U.dim, fontSize: 10),
                          ),
                        ),
                        Icon(Icons.favorite_rounded, size: 11, color: U.red),
                        const SizedBox(width: 3),
                        Text(
                          '${p.likesCount}',
                          style: GoogleFonts.outfit(
                            fontSize: 10.5,
                            color: U.sub,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Chevron
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 11,
                color: U.dim,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

