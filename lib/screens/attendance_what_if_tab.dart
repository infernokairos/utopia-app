// lib/screens/attendance_what_if_tab.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../main.dart';

/// A super simple, clean, and intuitive "What-If" attendance simulator.
/// Provides real-time bidirectional cause-and-effect projections:
/// - Sliding Bunks shows exactly how many classes you must attend to recover.
/// - Sliding Attends shows how many safe bunks you unlock/earn.
class AttendanceWhatIfTab extends StatefulWidget {
  const AttendanceWhatIfTab({
    super.key,
    required this.attendanceData,
    required this.targetPercentage,
    required this.isColoredMode,
    this.onTargetChanged,
    this.onRefresh,
  });

  final Map<String, dynamic>? attendanceData;
  final int targetPercentage;
  final bool isColoredMode;
  final ValueChanged<double>? onTargetChanged;
  final VoidCallback? onRefresh;

  @override
  State<AttendanceWhatIfTab> createState() => _AttendanceWhatIfTabState();
}

class _AttendanceWhatIfTabState extends State<AttendanceWhatIfTab> {
  // Key '__overall__' denotes aggregate attendance; otherwise subject title string.
  String _selectedScope = '__overall__';

  int _bunkCount = 0;
  int _attendCount = 0;

  // Maximum slider value
  static const int _maxSliderVal = 30;

  // Manual fallback inputs when portal data is not yet synced
  static const int _fallbackHeld = 40;
  static const int _fallbackAttended = 32;

  @override
  void didUpdateWidget(covariant AttendanceWhatIfTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.attendanceData != widget.attendanceData) {
      final subjects = _getSubjectList();
      if (_selectedScope != '__overall__' &&
          !subjects.any((s) => s['subject'] == _selectedScope)) {
        setState(() => _selectedScope = '__overall__');
      }
    }
  }

  List<Map<String, dynamic>> _getSubjectList() {
    final data = widget.attendanceData;
    if (data == null) return const [];
    return (data['subjects'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
  }

  void _haptic() {
    HapticFeedback.selectionClick();
  }

  void _reset() {
    _haptic();
    setState(() {
      _bunkCount = 0;
      _attendCount = 0;
    });
  }

  Color _statusColor(double pct) {
    if (widget.isColoredMode) {
      if (pct < 65) return const Color(0xFFEF4444); // Red (<65%)
      if (pct < widget.targetPercentage) return const Color(0xFFF59E0B); // Amber (< target)
      return const Color(0xFF10B981); // Emerald (>= target)
    }
    return pct >= widget.targetPercentage ? U.primary : const Color(0xFFEF4444);
  }

  /// Calculates consecutive classes needed to attend to recover to target.
  int _calcClassesToRecover(int attended, int held, double targetPct) {
    if (held <= 0 || targetPct >= 100) return 0;
    final currentPct = (attended / held) * 100.0;
    if (currentPct >= targetPct) return 0;
    final needed = ((targetPct * held - attended * 100.0) / (100.0 - targetPct)).ceil();
    return math.max(0, needed);
  }

  /// Calculates max classes that can be safely missed without dropping below target.
  int _calcSafeBunks(int attended, int held, double targetPct) {
    if (held <= 0 || targetPct <= 0) return 0;
    final currentPct = (attended / held) * 100.0;
    if (currentPct < targetPct) return 0;
    final safe = ((attended * 100.0 - targetPct * held) / targetPct).floor();
    return math.max(0, safe);
  }

  @override
  Widget build(BuildContext context) {
    final subjects = _getSubjectList();
    final isDark = appThemeNotifier.value.isDark;
    final double targetPct = widget.targetPercentage.toDouble();

    // Baseline values for current selected scope
    int currentHeld = 0;
    int currentAttended = 0;
    String scopeTitle = 'Overall Attendance';

    if (widget.attendanceData != null && widget.attendanceData!.isNotEmpty) {
      if (_selectedScope == '__overall__') {
        currentHeld = (widget.attendanceData!['totalClasses'] as num?)?.toInt() ?? 0;
        currentAttended = (widget.attendanceData!['totalAttended'] as num?)?.toInt() ?? 0;
        scopeTitle = 'Overall Attendance';
      } else {
        final match = subjects.firstWhere(
          (s) => s['subject'] == _selectedScope,
          orElse: () => const <String, dynamic>{},
        );
        currentHeld = (match['totalClasses'] as num?)?.toInt() ?? 0;
        currentAttended = (match['attendedClasses'] as num?)?.toInt() ?? 0;
        scopeTitle = (match['subject'] ?? 'Subject').toString();
      }
    } else {
      currentHeld = _fallbackHeld;
      currentAttended = _fallbackAttended;
      scopeTitle = 'Manual Simulator';
    }

    final double currentPct = currentHeld > 0
        ? ((currentAttended / currentHeld) * 100.0)
        : 0.0;

    // Projected values with user sliders
    final int projectedHeld = currentHeld + _bunkCount + _attendCount;
    final int projectedAttended = currentAttended + _attendCount;
    final double projectedPct = projectedHeld > 0
        ? ((projectedAttended / projectedHeld) * 100.0)
        : 0.0;

    final double deltaPct = projectedPct - currentPct;
    final bool isModified = _bunkCount > 0 || _attendCount > 0;
    final Color projectedColor = _statusColor(projectedPct);
    final bool isSafe = projectedPct >= targetPct;

    // Calculations for cause-and-effect
    final int baselineSafeBunks = _calcSafeBunks(currentAttended, currentHeld, targetPct);
    final int baselineRecoveryNeeded = _calcClassesToRecover(currentAttended, currentHeld, targetPct);

    final int projectedSafeBunks = _calcSafeBunks(projectedAttended, projectedHeld, targetPct);
    final int projectedRecoveryNeeded = _calcClassesToRecover(projectedAttended, projectedHeld, targetPct);

    // Specific calculation for bunk slider alone:
    // If we only take into account the bunk count from current state:
    final int heldAfterBunkOnly = currentHeld + _bunkCount;
    final int attendedAfterBunkOnly = currentAttended;
    final int recoveryNeededForBunkOnly = _calcClassesToRecover(
      attendedAfterBunkOnly,
      heldAfterBunkOnly,
      targetPct,
    );
    final int safeBunksLeftAfterBunkOnly = _calcSafeBunks(
      attendedAfterBunkOnly,
      heldAfterBunkOnly,
      targetPct,
    );

    // Specific calculation for attend slider alone:
    // If we only take into account attend count from current state:
    final int heldAfterAttendOnly = currentHeld + _attendCount;
    final int attendedAfterAttendOnly = currentAttended + _attendCount;
    final int safeBunksAfterAttendOnly = _calcSafeBunks(
      attendedAfterAttendOnly,
      heldAfterAttendOnly,
      targetPct,
    );
    final int recoveryNeededAfterAttendOnly = _calcClassesToRecover(
      attendedAfterAttendOnly,
      heldAfterAttendOnly,
      targetPct,
    );
    final int extraSafeBunksEarned = math.max(0, safeBunksAfterAttendOnly - baselineSafeBunks);

    return RefreshIndicator(
      color: U.primary,
      backgroundColor: U.card,
      onRefresh: () async => widget.onRefresh?.call(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
        children: [
          // ── 1. Top Controls Bar: Scope & Target ──
          _buildTopBar(
            subjects: subjects,
            currentPct: currentPct,
            scopeTitle: scopeTitle,
            targetPct: targetPct,
            isModified: isModified,
            isDark: isDark,
          ),
          const SizedBox(height: 12),

          // ── 2. Hero Projected Attendance Card ──
          _buildHeroCard(
            scopeTitle: scopeTitle,
            currentPct: currentPct,
            projectedPct: projectedPct,
            deltaPct: deltaPct,
            projectedHeld: projectedHeld,
            projectedAttended: projectedAttended,
            projectedColor: projectedColor,
            isSafe: isSafe,
            targetPct: targetPct,
            isModified: isModified,
            projectedSafeBunks: projectedSafeBunks,
            projectedRecoveryNeeded: projectedRecoveryNeeded,
            isDark: isDark,
          ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.04, end: 0),
          const SizedBox(height: 14),

          // ── 3. Bunk Slider Card (With "How many more classes to attend" readout) ──
          _buildBunkSliderCard(
            baselineSafeBunks: baselineSafeBunks,
            bunkCount: _bunkCount,
            recoveryNeeded: recoveryNeededForBunkOnly,
            safeBunksRemaining: safeBunksLeftAfterBunkOnly,
            targetPct: targetPct,
            isDark: isDark,
          ).animate().fadeIn(delay: 40.ms).slideY(begin: 0.03, end: 0),
          const SizedBox(height: 12),

          // ── 4. Attend Slider Card (With "How many bunks unlocked/earned" readout) ──
          _buildAttendSliderCard(
            attendCount: _attendCount,
            baselineRecoveryNeeded: baselineRecoveryNeeded,
            recoveryNeededNow: recoveryNeededAfterAttendOnly,
            safeBunksUnlocked: safeBunksAfterAttendOnly,
            extraBunksEarned: extraSafeBunksEarned,
            targetPct: targetPct,
            isDark: isDark,
          ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.03, end: 0),
          const SizedBox(height: 14),

          // ── 5. Quick Bunk vs Recovery Matrix (Instant Reference) ──
          _buildQuickBunkTradeoffMatrix(
            currentHeld: currentHeld,
            currentAttended: currentAttended,
            targetPct: targetPct,
            isDark: isDark,
          ).animate().fadeIn(delay: 110.ms),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 1. TOP CONTROLS BAR (Scope Picker, Target Selector, Reset)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTopBar({
    required List<Map<String, dynamic>> subjects,
    required double currentPct,
    required String scopeTitle,
    required double targetPct,
    required bool isModified,
    required bool isDark,
  }) {
    final bool isOverall = _selectedScope == '__overall__';
    final Color scopeCol = _statusColor(currentPct);

    return Row(
      children: [
        // Scope Selector Dropdown Pill
        Expanded(
          child: GestureDetector(
            onTap: () {
              _haptic();
              _showSubjectPickerSheet(
                context: context,
                subjects: subjects,
                targetPct: targetPct,
                isDark: isDark,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: U.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: U.border.withValues(alpha: 0.7),
                  width: 0.9,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: (isOverall ? U.primary : scopeCol).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      isOverall ? Icons.pie_chart_rounded : Icons.menu_book_rounded,
                      size: 15,
                      color: isOverall ? U.primary : scopeCol,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isOverall ? 'OVERALL' : 'SUBJECT',
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: U.sub,
                          ),
                        ),
                        Text(
                          scopeTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: U.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: scopeCol.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${currentPct.toStringAsFixed(0)}%',
                      style: GoogleFonts.robotoFlex(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: scopeCol,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: U.sub,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Target Threshold Pill Toggle (75% / 65%)
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: U.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: U.border.withValues(alpha: 0.7),
              width: 0.9,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTargetOption(
                label: '75%',
                isSelected: targetPct == 75.0,
                onTap: () {
                  if (targetPct != 75.0 && widget.onTargetChanged != null) {
                    _haptic();
                    widget.onTargetChanged!(0.75);
                  }
                },
              ),
              _buildTargetOption(
                label: '65%',
                isSelected: targetPct == 65.0,
                onTap: () {
                  if (targetPct != 65.0 && widget.onTargetChanged != null) {
                    _haptic();
                    widget.onTargetChanged!(0.65);
                  }
                },
              ),
            ],
          ),
        ),

        // Instant Reset Button (Appears only when simulated)
        if (isModified) ...[
          const SizedBox(width: 6),
          GestureDetector(
            onTap: _reset,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: U.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: U.primary.withValues(alpha: 0.4),
                  width: 0.9,
                ),
              ),
              child: Icon(
                Icons.restart_alt_rounded,
                size: 18,
                color: U.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTargetOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? U.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.black : U.sub,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 2. HERO PROJECTED ATTENDANCE CARD
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildHeroCard({
    required String scopeTitle,
    required double currentPct,
    required double projectedPct,
    required double deltaPct,
    required int projectedHeld,
    required int projectedAttended,
    required Color projectedColor,
    required bool isSafe,
    required double targetPct,
    required bool isModified,
    required int projectedSafeBunks,
    required int projectedRecoveryNeeded,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: U.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: projectedColor.withValues(alpha: isModified ? 0.45 : 0.25),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: projectedColor.withValues(alpha: isDark ? 0.12 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Status Badge
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: projectedColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                isModified ? 'PROJECTED ATTENDANCE' : 'CURRENT STATUS',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: U.sub,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: projectedColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isSafe
                      ? 'Safe (≥${targetPct.toInt()}%)'
                      : 'Shortfall (<${targetPct.toInt()}%)',
                  style: GoogleFonts.outfit(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: projectedColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Main Metric Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${projectedPct.toStringAsFixed(1)}%',
                style: GoogleFonts.outfit(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  color: projectedColor,
                  letterSpacing: -1.0,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 8),
              if (isModified) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: (deltaPct >= 0
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444))
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        deltaPct >= 0
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 13,
                        color: deltaPct >= 0
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${deltaPct >= 0 ? '+' : ''}${deltaPct.toStringAsFixed(1)}%',
                        style: GoogleFonts.robotoFlex(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: deltaPct >= 0
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              Text(
                '$projectedAttended / $projectedHeld classes',
                style: GoogleFonts.outfit(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: U.sub,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress Track with Target Marker
          _buildMilestoneProgressBar(
            projectedPct: projectedPct,
            targetPct: targetPct,
            projectedColor: projectedColor,
          ),
          const SizedBox(height: 12),

          // Core Clear Conclusion Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: projectedColor.withValues(alpha: isDark ? 0.12 : 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: projectedColor.withValues(alpha: 0.28),
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSafe ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                  size: 17,
                  color: projectedColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _buildHeroSummaryText(
                      projectedPct: projectedPct,
                      targetPct: targetPct,
                      isSafe: isSafe,
                      projectedSafeBunks: projectedSafeBunks,
                      projectedRecoveryNeeded: projectedRecoveryNeeded,
                      isModified: isModified,
                    ),
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: U.text,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneProgressBar({
    required double projectedPct,
    required double targetPct,
    required Color projectedColor,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final targetPosition = (targetPct / 100.0).clamp(0.0, 1.0) * totalWidth;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Background & Fill
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: SizedBox(
                height: 7,
                child: Stack(
                  children: [
                    Container(color: U.border.withValues(alpha: 0.35)),
                    FractionallySizedBox(
                      widthFactor: (projectedPct / 100.0).clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: projectedColor,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Target Marker Pin
            Positioned(
              left: (targetPosition - 1.5).clamp(0.0, totalWidth - 3),
              top: -3,
              child: Container(
                width: 3,
                height: 13,
                decoration: BoxDecoration(
                  color: U.text,
                  borderRadius: BorderRadius.circular(1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 3,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _buildHeroSummaryText({
    required double projectedPct,
    required double targetPct,
    required bool isSafe,
    required int projectedSafeBunks,
    required int projectedRecoveryNeeded,
    required bool isModified,
  }) {
    if (!isSafe) {
      return 'Deficit: Attend $projectedRecoveryNeeded consecutive classes to hit ${targetPct.toInt()}%.';
    }
    if (projectedSafeBunks > 0) {
      return 'You can safely bunk $projectedSafeBunks more ${projectedSafeBunks == 1 ? "class" : "classes"} before dropping below ${targetPct.toInt()}%.';
    }
    return 'Right at boundary (${targetPct.toInt()}%). Missing any class will cause a shortfall.';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 3. BUNK SLIDER CARD (With Live "Classes to Attend" Consequence)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildBunkSliderCard({
    required int baselineSafeBunks,
    required int bunkCount,
    required int recoveryNeeded,
    required int safeBunksRemaining,
    required double targetPct,
    required bool isDark,
  }) {
    const Color coralRed = Color(0xFFEF4444);
    final bool causingDeficit = recoveryNeeded > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: U.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: bunkCount > 0 ? coralRed.withValues(alpha: 0.45) : U.border.withValues(alpha: 0.7),
          width: bunkCount > 0 ? 1.1 : 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: coralRed.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.event_busy_rounded,
                  size: 15,
                  color: coralRed,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BUNK / SKIP CLASSES',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: U.sub,
                      ),
                    ),
                    Text(
                      'Simulate missing classes',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: U.text,
                      ),
                    ),
                  ],
                ),
              ),
              // Value Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: bunkCount > 0
                      ? coralRed.withValues(alpha: 0.15)
                      : U.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: bunkCount > 0 ? coralRed.withValues(alpha: 0.4) : Colors.transparent,
                  ),
                ),
                child: Text(
                  '$bunkCount ${bunkCount == 1 ? "bunk" : "bunks"}',
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: bunkCount > 0 ? coralRed : U.sub,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Slider with Steppers
          Row(
            children: [
              _buildStepperBtn(
                icon: Icons.remove_rounded,
                enabled: bunkCount > 0,
                onTap: () {
                  _haptic();
                  setState(() => _bunkCount = math.max(0, _bunkCount - 1));
                },
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 5,
                    activeTrackColor: coralRed,
                    inactiveTrackColor: U.border.withValues(alpha: 0.35),
                    thumbColor: coralRed,
                    overlayColor: coralRed.withValues(alpha: 0.14),
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 8,
                      elevation: 2,
                    ),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 15),
                  ),
                  child: Slider(
                    value: bunkCount.toDouble(),
                    min: 0,
                    max: _maxSliderVal.toDouble(),
                    divisions: _maxSliderVal,
                    onChanged: (v) {
                      final val = v.round();
                      if (val != _bunkCount) {
                        _haptic();
                        setState(() => _bunkCount = val);
                      }
                    },
                  ),
                ),
              ),
              _buildStepperBtn(
                icon: Icons.add_rounded,
                enabled: bunkCount < _maxSliderVal,
                onTap: () {
                  _haptic();
                  setState(() => _bunkCount = math.min(_maxSliderVal, _bunkCount + 1));
                },
              ),
            ],
          ),

          // Quick Pills Row
          Row(
            children: [
              _buildQuickPill(
                label: '+1',
                accentColor: coralRed,
                onTap: () {
                  _haptic();
                  setState(() => _bunkCount = math.min(_maxSliderVal, _bunkCount + 1));
                },
              ),
              const SizedBox(width: 6),
              _buildQuickPill(
                label: '+2',
                accentColor: coralRed,
                onTap: () {
                  _haptic();
                  setState(() => _bunkCount = math.min(_maxSliderVal, _bunkCount + 2));
                },
              ),
              const SizedBox(width: 6),
              _buildQuickPill(
                label: '+3',
                accentColor: coralRed,
                onTap: () {
                  _haptic();
                  setState(() => _bunkCount = math.min(_maxSliderVal, _bunkCount + 3));
                },
              ),
              if (baselineSafeBunks > 0) ...[
                const SizedBox(width: 6),
                _buildQuickPill(
                  label: 'Max Safe ($baselineSafeBunks)',
                  accentColor: const Color(0xFF10B981),
                  isSelected: bunkCount == baselineSafeBunks,
                  onTap: () {
                    _haptic();
                    setState(() => _bunkCount = baselineSafeBunks);
                  },
                ),
              ],
              const Spacer(),
              if (bunkCount > 0)
                GestureDetector(
                  onTap: () {
                    _haptic();
                    setState(() => _bunkCount = 0);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Text(
                      'Clear',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: U.sub,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // ── THE USER'S SPECIFIC FEATURE: "How many more classes to attend if I bunk" ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8.5),
            decoration: BoxDecoration(
              color: (causingDeficit ? coralRed : const Color(0xFF10B981))
                  .withValues(alpha: isDark ? 0.12 : 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (causingDeficit ? coralRed : const Color(0xFF10B981))
                    .withValues(alpha: 0.35),
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  causingDeficit ? Icons.school_rounded : Icons.shield_rounded,
                  size: 16,
                  color: causingDeficit ? coralRed : const Color(0xFF10B981),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: U.text,
                        height: 1.25,
                      ),
                      children: causingDeficit
                          ? [
                              const TextSpan(text: 'To make up for this bunk: attend '),
                              TextSpan(
                                text: '+$recoveryNeeded classes in a row',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w800,
                                  color: coralRed,
                                ),
                              ),
                              TextSpan(text: ' to reach ${targetPct.toInt()}%.'),
                            ]
                          : [
                              TextSpan(
                                text: bunkCount > 0
                                    ? 'Still safe! '
                                    : 'Current standing: ',
                              ),
                              TextSpan(
                                text: '$safeBunksRemaining bunks remaining',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF10B981),
                                ),
                              ),
                              TextSpan(text: ' before falling below ${targetPct.toInt()}%.'),
                            ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 4. ATTEND SLIDER CARD (With Live "How many safe bunks unlocked" Readout)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildAttendSliderCard({
    required int attendCount,
    required int baselineRecoveryNeeded,
    required int recoveryNeededNow,
    required int safeBunksUnlocked,
    required int extraBunksEarned,
    required double targetPct,
    required bool isDark,
  }) {
    const Color emerald = Color(0xFF10B981);
    final bool recoveringDeficit = baselineRecoveryNeeded > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: U.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: attendCount > 0 ? emerald.withValues(alpha: 0.45) : U.border.withValues(alpha: 0.7),
          width: attendCount > 0 ? 1.1 : 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: emerald.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  size: 15,
                  color: emerald,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ATTEND CLASSES',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: U.sub,
                      ),
                    ),
                    Text(
                      'Simulate attending next classes',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: U.text,
                      ),
                    ),
                  ],
                ),
              ),
              // Value Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: attendCount > 0
                      ? emerald.withValues(alpha: 0.15)
                      : U.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: attendCount > 0 ? emerald.withValues(alpha: 0.4) : Colors.transparent,
                  ),
                ),
                child: Text(
                  '+$attendCount ${attendCount == 1 ? "class" : "classes"}',
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: attendCount > 0 ? emerald : U.sub,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Slider with Steppers
          Row(
            children: [
              _buildStepperBtn(
                icon: Icons.remove_rounded,
                enabled: attendCount > 0,
                onTap: () {
                  _haptic();
                  setState(() => _attendCount = math.max(0, _attendCount - 1));
                },
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 5,
                    activeTrackColor: emerald,
                    inactiveTrackColor: U.border.withValues(alpha: 0.35),
                    thumbColor: emerald,
                    overlayColor: emerald.withValues(alpha: 0.14),
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 8,
                      elevation: 2,
                    ),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 15),
                  ),
                  child: Slider(
                    value: attendCount.toDouble(),
                    min: 0,
                    max: _maxSliderVal.toDouble(),
                    divisions: _maxSliderVal,
                    onChanged: (v) {
                      final val = v.round();
                      if (val != _attendCount) {
                        _haptic();
                        setState(() => _attendCount = val);
                      }
                    },
                  ),
                ),
              ),
              _buildStepperBtn(
                icon: Icons.add_rounded,
                enabled: attendCount < _maxSliderVal,
                onTap: () {
                  _haptic();
                  setState(() => _attendCount = math.min(_maxSliderVal, _attendCount + 1));
                },
              ),
            ],
          ),

          // Quick Pills Row
          Row(
            children: [
              _buildQuickPill(
                label: '+1',
                accentColor: emerald,
                onTap: () {
                  _haptic();
                  setState(() => _attendCount = math.min(_maxSliderVal, _attendCount + 1));
                },
              ),
              const SizedBox(width: 6),
              _buildQuickPill(
                label: '+3',
                accentColor: emerald,
                onTap: () {
                  _haptic();
                  setState(() => _attendCount = math.min(_maxSliderVal, _attendCount + 3));
                },
              ),
              const SizedBox(width: 6),
              _buildQuickPill(
                label: '+5',
                accentColor: emerald,
                onTap: () {
                  _haptic();
                  setState(() => _attendCount = math.min(_maxSliderVal, _attendCount + 5));
                },
              ),
              const SizedBox(width: 6),
              _buildQuickPill(
                label: '+10',
                accentColor: emerald,
                onTap: () {
                  _haptic();
                  setState(() => _attendCount = math.min(_maxSliderVal, _attendCount + 10));
                },
              ),
              const Spacer(),
              if (attendCount > 0)
                GestureDetector(
                  onTap: () {
                    _haptic();
                    setState(() => _attendCount = 0);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Text(
                      'Clear',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: U.sub,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // ── THE USER'S SPECIFIC FEATURE: "Vice-versa: if I am present more, how many bunks unlocked" ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8.5),
            decoration: BoxDecoration(
              color: emerald.withValues(alpha: isDark ? 0.12 : 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: emerald.withValues(alpha: 0.35),
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  recoveringDeficit && recoveryNeededNow > 0
                      ? Icons.trending_up_rounded
                      : Icons.lock_open_rounded,
                  size: 16,
                  color: emerald,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: U.text,
                        height: 1.25,
                      ),
                      children: _buildAttendInsightSpans(
                        attendCount: attendCount,
                        recoveringDeficit: recoveringDeficit,
                        recoveryNeededNow: recoveryNeededNow,
                        safeBunksUnlocked: safeBunksUnlocked,
                        extraBunksEarned: extraBunksEarned,
                        targetPct: targetPct,
                        emerald: emerald,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<TextSpan> _buildAttendInsightSpans({
    required int attendCount,
    required bool recoveringDeficit,
    required int recoveryNeededNow,
    required int safeBunksUnlocked,
    required int extraBunksEarned,
    required double targetPct,
    required Color emerald,
  }) {
    if (recoveringDeficit) {
      if (recoveryNeededNow > 0) {
        return [
          const TextSpan(text: 'Reduces debt: '),
          TextSpan(
            text: 'only $recoveryNeededNow more classes needed',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w800,
              color: const Color(0xFFF59E0B),
            ),
          ),
          TextSpan(text: ' to reach ${targetPct.toInt()}%.'),
        ];
      } else {
        return [
          const TextSpan(text: 'Target reached! '),
          TextSpan(
            text: 'Unlocks $safeBunksUnlocked safe bunks',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w800,
              color: emerald,
            ),
          ),
          TextSpan(text: ' after attending $attendCount classes!'),
        ];
      }
    } else {
      if (attendCount > 0) {
        return [
          const TextSpan(text: 'Earns you '),
          TextSpan(
            text: '+$extraBunksEarned extra safe bunks',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w800,
              color: emerald,
            ),
          ),
          TextSpan(text: ' (Total safety cushion: $safeBunksUnlocked bunks).'),
        ];
      } else {
        return [
          const TextSpan(text: 'Attending upcoming classes will '),
          TextSpan(
            text: 'earn you additional safe bunks',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w800,
              color: emerald,
            ),
          ),
          const TextSpan(text: ' above your current cushion.'),
        ];
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 5. QUICK BUNK VS RECOVERY MATRIX (INSTANT ACTIONABLE REFERENCE)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildQuickBunkTradeoffMatrix({
    required int currentHeld,
    required int currentAttended,
    required double targetPct,
    required bool isDark,
  }) {
    if (currentHeld <= 0) return const SizedBox.shrink();

    final testCases = [1, 2, 3, 5];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: U.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: U.border.withValues(alpha: 0.7),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.swap_horiz_rounded, size: 16, color: U.primary),
              const SizedBox(width: 6),
              Text(
                'QUICK BUNK ⇄ RECOVERY MATRIX',
                style: GoogleFonts.outfit(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: U.sub,
                ),
              ),
              const Spacer(),
              Text(
                'Target ${targetPct.toInt()}%',
                style: GoogleFonts.outfit(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: U.sub,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Tap any scenario below to instantly preview what it takes to bounce back:',
            style: GoogleFonts.outfit(
              fontSize: 11.5,
              color: U.sub,
            ),
          ),
          const SizedBox(height: 10),

          // Horizontal scrollable scenario cards
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: testCases.map((bunks) {
                final heldWithBunks = currentHeld + bunks;
                final attendedWithBunks = currentAttended;
                final recoveryNeeded = _calcClassesToRecover(
                  attendedWithBunks,
                  heldWithBunks,
                  targetPct,
                );
                final safeLeft = _calcSafeBunks(
                  attendedWithBunks,
                  heldWithBunks,
                  targetPct,
                );
                final isSelected = _bunkCount == bunks && _attendCount == 0;

                return GestureDetector(
                  onTap: () {
                    _haptic();
                    setState(() {
                      _bunkCount = bunks;
                      _attendCount = 0;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? U.primary.withValues(alpha: 0.15)
                          : U.surfaceContainerHigh.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? U.primary
                            : U.outlineVariant.withValues(alpha: 0.3),
                        width: isSelected ? 1.2 : 0.8,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Bunk $bunks ${bunks == 1 ? "class" : "classes"}',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFEF4444),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 11,
                              color: Color(0xFFEF4444),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          recoveryNeeded > 0
                              ? 'Attend $recoveryNeeded in a row'
                              : '$safeLeft safe bunks left',
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: recoveryNeeded > 0
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UI HELPERS (Steppers, Quick Pills, Modal Sheet)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStepperBtn({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled ? U.surfaceContainerHigh : U.surfaceContainerHigh.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled ? U.outlineVariant.withValues(alpha: 0.35) : Colors.transparent,
          ),
        ),
        child: Center(
          child: Icon(
            icon,
            size: 16,
            color: enabled ? U.text : U.sub.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickPill({
    required String label,
    required Color accentColor,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.22)
              : U.surfaceContainerHigh.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? accentColor.withValues(alpha: 0.65)
                : U.outlineVariant.withValues(alpha: 0.3),
            width: isSelected ? 1.1 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? accentColor : U.text,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SUBJECT PICKER BOTTOM SHEET
  // ─────────────────────────────────────────────────────────────────────────
  void _showSubjectPickerSheet({
    required BuildContext context,
    required List<Map<String, dynamic>> subjects,
    required double targetPct,
    required bool isDark,
  }) {
    final overallHeld = (widget.attendanceData?['totalClasses'] as num?)?.toInt() ?? _fallbackHeld;
    final overallAttended = (widget.attendanceData?['totalAttended'] as num?)?.toInt() ?? _fallbackAttended;
    final overallPct = overallHeld > 0 ? (overallAttended / overallHeld) * 100.0 : 0.0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final filteredSubjects = subjects.where((s) {
              if (searchQuery.trim().isEmpty) return true;
              final name = (s['subject'] ?? '').toString().toLowerCase();
              return name.contains(searchQuery.toLowerCase());
            }).toList();

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              decoration: BoxDecoration(
                color: U.card,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                border: Border.all(
                  color: U.border.withValues(alpha: 0.8),
                  width: 1.0,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag bar
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 8),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: U.sub.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Title bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 16, 10),
                    child: Row(
                      children: [
                        Text(
                          'Select Attendance Scope',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: U.text,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          color: U.sub,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),

                  // Search bar (if multiple subjects)
                  if (subjects.length > 4)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: U.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: U.outlineVariant.withValues(alpha: 0.3),
                          ),
                        ),
                        child: TextField(
                          onChanged: (val) => setSheetState(() => searchQuery = val),
                          style: GoogleFonts.outfit(fontSize: 13, color: U.text),
                          decoration: InputDecoration(
                            icon: Icon(Icons.search_rounded, size: 17, color: U.sub),
                            hintText: 'Search subjects...',
                            hintStyle: GoogleFonts.outfit(fontSize: 13, color: U.sub),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 9),
                          ),
                        ),
                      ),
                    ),

                  // Options list
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      children: [
                        // Pinned: Overall Attendance
                        _buildPickerOption(
                          title: 'Overall Attendance',
                          subtitle: '$overallAttended / $overallHeld total classes',
                          percentage: overallPct,
                          icon: Icons.pie_chart_rounded,
                          isSelected: _selectedScope == '__overall__',
                          onTap: () {
                            _haptic();
                            setState(() {
                              _selectedScope = '__overall__';
                              _bunkCount = 0;
                              _attendCount = 0;
                            });
                            Navigator.pop(ctx);
                          },
                        ),
                        const SizedBox(height: 8),

                        if (filteredSubjects.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            child: Text(
                              'SUBJECTS',
                              style: GoogleFonts.outfit(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                                color: U.sub,
                              ),
                            ),
                          ),
                          ...filteredSubjects.map((sub) {
                            final name = (sub['subject'] ?? 'Subject').toString();
                            final attended = (sub['attendedClasses'] as num?)?.toInt() ?? 0;
                            final held = (sub['totalClasses'] as num?)?.toInt() ?? 0;
                            final pct = (sub['percentage'] as num?)?.toDouble() ??
                                (held > 0 ? (attended / held) * 100.0 : 0.0);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: _buildPickerOption(
                                title: name,
                                subtitle: '$attended / $held attended',
                                percentage: pct,
                                icon: Icons.menu_book_rounded,
                                isSelected: _selectedScope == name,
                                onTap: () {
                                  _haptic();
                                  setState(() {
                                    _selectedScope = name;
                                    _bunkCount = 0;
                                    _attendCount = 0;
                                  });
                                  Navigator.pop(ctx);
                                },
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPickerOption({
    required String title,
    required String subtitle,
    required double percentage,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final Color col = _statusColor(percentage);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? U.primary.withValues(alpha: 0.12)
              : U.surfaceContainerHigh.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? U.primary.withValues(alpha: 0.5)
                : U.outlineVariant.withValues(alpha: 0.25),
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: col.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 16, color: col),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? U.primary : U.text,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: U.sub,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: col.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                '${percentage.toStringAsFixed(0)}%',
                style: GoogleFonts.robotoFlex(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: col,
                ),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Icon(Icons.check_rounded, size: 16, color: U.primary),
            ],
          ],
        ),
      ),
    );
  }
}
