// lib/screens/attendance_what_if_tab.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../main.dart';

/// Clean Interceptor-styled What-If attendance simulator.
/// Real-time bidirectional projections keeping status colors intact.
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
  String _selectedScope = '__overall__';

  int _bunkCount = 0;
  int _attendCount = 0;

  static const int _maxSliderVal = 30;
  static const int _fallbackHeld = 40;
  static const int _fallbackAttended = 32;

  static const Color _emerald = Color(0xFF10B981);
  static const Color _amber = Color(0xFFF59E0B);
  static const Color _coralRed = Color(0xFFEF4444);

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

  void _haptic() => HapticFeedback.selectionClick();

  void _reset() {
    _haptic();
    setState(() {
      _bunkCount = 0;
      _attendCount = 0;
    });
  }

  Color _statusColor(double pct) {
    if (widget.isColoredMode) {
      if (pct < 65) return _coralRed;
      if (pct < widget.targetPercentage) return _amber;
      return _emerald;
    }
    return pct >= widget.targetPercentage ? U.primary : _coralRed;
  }

  int _calcClassesToRecover(int attended, int held, double targetPct) {
    if (held <= 0 || targetPct >= 100) return 0;
    final currentPct = (attended / held) * 100.0;
    if (currentPct >= targetPct) return 0;
    final needed =
        ((targetPct * held - attended * 100.0) / (100.0 - targetPct)).ceil();
    return math.max(0, needed);
  }

  int _calcSafeBunks(int attended, int held, double targetPct) {
    if (held <= 0 || targetPct <= 0) return 0;
    final currentPct = (attended / held) * 100.0;
    if (currentPct < targetPct) return 0;
    final safe = ((attended * 100.0 - targetPct * held) / targetPct).floor();
    return math.max(0, safe);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final subjects = _getSubjectList();
    final double targetPct = widget.targetPercentage.toDouble();

    int currentHeld = 0;
    int currentAttended = 0;
    String scopeTitle = 'Overall';

    if (widget.attendanceData != null && widget.attendanceData!.isNotEmpty) {
      if (_selectedScope == '__overall__') {
        currentHeld =
            (widget.attendanceData!['totalClasses'] as num?)?.toInt() ?? 0;
        currentAttended =
            (widget.attendanceData!['totalAttended'] as num?)?.toInt() ?? 0;
        scopeTitle = 'Overall';
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
      scopeTitle = 'Simulator';
    }

    final double currentPct =
        currentHeld > 0 ? ((currentAttended / currentHeld) * 100.0) : 0.0;

    final int projectedHeld = currentHeld + _bunkCount + _attendCount;
    final int projectedAttended = currentAttended + _attendCount;
    final double projectedPct = projectedHeld > 0
        ? ((projectedAttended / projectedHeld) * 100.0)
        : 0.0;

    final double deltaPct = projectedPct - currentPct;
    final bool isModified = _bunkCount > 0 || _attendCount > 0;
    final Color projectedColor = _statusColor(projectedPct);
    final bool isSafe = projectedPct >= targetPct;

    final int baselineSafeBunks =
        _calcSafeBunks(currentAttended, currentHeld, targetPct);
    final int baselineRecoveryNeeded =
        _calcClassesToRecover(currentAttended, currentHeld, targetPct);

    final int projectedSafeBunks =
        _calcSafeBunks(projectedAttended, projectedHeld, targetPct);
    final int projectedRecoveryNeeded =
        _calcClassesToRecover(projectedAttended, projectedHeld, targetPct);

    final int heldAfterBunkOnly = currentHeld + _bunkCount;
    final int recoveryNeededForBunkOnly =
        _calcClassesToRecover(currentAttended, heldAfterBunkOnly, targetPct);
    final int safeBunksLeftAfterBunkOnly =
        _calcSafeBunks(currentAttended, heldAfterBunkOnly, targetPct);

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
    final int extraSafeBunksEarned =
        math.max(0, safeBunksAfterAttendOnly - baselineSafeBunks);

    return RefreshIndicator(
      color: cs.primary,
      backgroundColor: cs.surfaceContainer,
      onRefresh: () async => widget.onRefresh?.call(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          // 1. Scope & Target Controls
          _buildTopBar(
            cs: cs,
            subjects: subjects,
            currentPct: currentPct,
            scopeTitle: scopeTitle,
            targetPct: targetPct,
            isModified: isModified,
          ),
          const SizedBox(height: 14),

          // 2. Projected Hero Card
          _buildHeroCard(
            cs: cs,
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
          ),
          const SizedBox(height: 14),

          // 3. Bunk Slider Card
          _buildBunkSliderCard(
            cs: cs,
            baselineSafeBunks: baselineSafeBunks,
            bunkCount: _bunkCount,
            recoveryNeeded: recoveryNeededForBunkOnly,
            safeBunksRemaining: safeBunksLeftAfterBunkOnly,
            targetPct: targetPct,
          ),
          const SizedBox(height: 14),

          // 4. Attend Slider Card
          _buildAttendSliderCard(
            cs: cs,
            attendCount: _attendCount,
            baselineRecoveryNeeded: baselineRecoveryNeeded,
            recoveryNeededNow: recoveryNeededAfterAttendOnly,
            safeBunksUnlocked: safeBunksAfterAttendOnly,
            extraBunksEarned: extraSafeBunksEarned,
            targetPct: targetPct,
          ),
          const SizedBox(height: 14),

          // 5. Quick Scenarios
          _buildQuickScenarios(
            cs: cs,
            currentHeld: currentHeld,
            currentAttended: currentAttended,
            targetPct: targetPct,
          ),
        ]
            .animate(interval: 35.ms)
            .fadeIn(duration: 240.ms, curve: Curves.easeOut),
      ),
    );
  }

  Widget _buildTopBar({
    required ColorScheme cs,
    required List<Map<String, dynamic>> subjects,
    required double currentPct,
    required String scopeTitle,
    required double targetPct,
    required bool isModified,
  }) {
    final bool isOverall = _selectedScope == '__overall__';
    final Color scopeCol = _statusColor(currentPct);

    return Row(
      children: [
        Expanded(
          child: Material(
            color: cs.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () {
                _haptic();
                _showSubjectPickerSheet(context: context, subjects: subjects);
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                child: Row(
                  children: [
                    Icon(
                      isOverall
                          ? Icons.pie_chart_outline_rounded
                          : Icons.menu_book_outlined,
                      size: 18,
                      color: isOverall ? cs.primary : scopeCol,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        scopeTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${currentPct.toStringAsFixed(0)}%',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: scopeCol,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: cs.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Target Toggle (75% / 65%)
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: cs.surfaceContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTargetOption(
                cs: cs,
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
                cs: cs,
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

        if (isModified) ...[
          const SizedBox(width: 8),
          Material(
            color: cs.surfaceContainer,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: _reset,
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  Icons.restart_alt_rounded,
                  size: 19,
                  color: cs.primary,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTargetOption({
    required ColorScheme cs,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? cs.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard({
    required ColorScheme cs,
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
  }) {
    final summary = !isSafe
        ? 'Attend $projectedRecoveryNeeded consecutive ${projectedRecoveryNeeded == 1 ? "class" : "classes"} to hit ${targetPct.toInt()}%.'
        : (projectedSafeBunks > 0
            ? 'Can safely miss $projectedSafeBunks more ${projectedSafeBunks == 1 ? "class" : "classes"}.'
            : 'Right at ${targetPct.toInt()}% — missing the next class drops below target.');

    return Container(
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
              Text(
                isModified ? 'Projected' : 'Current',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                isSafe
                    ? 'Safe (≥${targetPct.toInt()}%)'
                    : 'Below ${targetPct.toInt()}%',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: projectedColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${projectedPct.toStringAsFixed(1)}%',
                style: GoogleFonts.inter(
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                  color: projectedColor,
                  letterSpacing: -1.4,
                  height: 1.0,
                ),
              ),
              if (isModified) ...[
                const SizedBox(width: 10),
                Text(
                  '${deltaPct >= 0 ? '+' : ''}${deltaPct.toStringAsFixed(1)}%',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: deltaPct >= 0 ? _emerald : _coralRed,
                  ),
                ),
              ],
              const Spacer(),
              Text(
                '$projectedAttended / $projectedHeld',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _buildMilestoneProgressBar(
            cs: cs,
            projectedPct: projectedPct,
            targetPct: targetPct,
            projectedColor: projectedColor,
          ),
          const SizedBox(height: 14),

          Text(
            summary,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: cs.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneProgressBar({
    required ColorScheme cs,
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
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 6,
                child: Stack(
                  children: [
                    Container(color: cs.surfaceContainerHighest),
                    FractionallySizedBox(
                      widthFactor: (projectedPct / 100.0).clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: projectedColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: (targetPosition - 1).clamp(0.0, totalWidth - 2),
              top: -3,
              child: Container(
                width: 2,
                height: 12,
                decoration: BoxDecoration(
                  color: cs.onSurface,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBunkSliderCard({
    required ColorScheme cs,
    required int baselineSafeBunks,
    required int bunkCount,
    required int recoveryNeeded,
    required int safeBunksRemaining,
    required double targetPct,
  }) {
    final bool causingDeficit = recoveryNeeded > 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Bunk classes',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                '$bunkCount ${bunkCount == 1 ? "class" : "classes"}',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: bunkCount > 0 ? _coralRed : cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              _buildStepperBtn(
                cs: cs,
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
                    trackHeight: 4,
                    activeTrackColor: _coralRed,
                    inactiveTrackColor: cs.surfaceContainerHighest,
                    thumbColor: _coralRed,
                    overlayColor: _coralRed.withValues(alpha: 0.14),
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 7,
                      elevation: 0,
                    ),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 14),
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
                cs: cs,
                icon: Icons.add_rounded,
                enabled: bunkCount < _maxSliderVal,
                onTap: () {
                  _haptic();
                  setState(
                    () => _bunkCount = math.min(_maxSliderVal, _bunkCount + 1),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 6),

          Row(
            children: [
              _buildQuickPill(
                cs: cs,
                label: '+1',
                onTap: () {
                  _haptic();
                  setState(
                    () => _bunkCount = math.min(_maxSliderVal, _bunkCount + 1),
                  );
                },
              ),
              const SizedBox(width: 6),
              _buildQuickPill(
                cs: cs,
                label: '+2',
                onTap: () {
                  _haptic();
                  setState(
                    () => _bunkCount = math.min(_maxSliderVal, _bunkCount + 2),
                  );
                },
              ),
              const SizedBox(width: 6),
              _buildQuickPill(
                cs: cs,
                label: '+3',
                onTap: () {
                  _haptic();
                  setState(
                    () => _bunkCount = math.min(_maxSliderVal, _bunkCount + 3),
                  );
                },
              ),
              if (baselineSafeBunks > 0) ...[
                const SizedBox(width: 6),
                _buildQuickPill(
                  cs: cs,
                  label: 'Max safe ($baselineSafeBunks)',
                  accentColor: _emerald,
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
                  child: Text(
                    'Clear',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          Text.rich(
            TextSpan(
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: cs.onSurfaceVariant,
                height: 1.35,
              ),
              children: causingDeficit
                  ? [
                      const TextSpan(text: 'Recovery needed: attend '),
                      TextSpan(
                        text: '+$recoveryNeeded in a row',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: _coralRed,
                        ),
                      ),
                      TextSpan(text: ' to reach ${targetPct.toInt()}%.'),
                    ]
                  : [
                      TextSpan(
                        text: '$safeBunksRemaining safe bunks left',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: _emerald,
                        ),
                      ),
                      TextSpan(text: ' before dropping below ${targetPct.toInt()}%.'),
                    ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendSliderCard({
    required ColorScheme cs,
    required int attendCount,
    required int baselineRecoveryNeeded,
    required int recoveryNeededNow,
    required int safeBunksUnlocked,
    required int extraBunksEarned,
    required double targetPct,
  }) {
    final bool recoveringDeficit = baselineRecoveryNeeded > 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Attend classes',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                '+$attendCount ${attendCount == 1 ? "class" : "classes"}',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: attendCount > 0 ? _emerald : cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              _buildStepperBtn(
                cs: cs,
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
                    trackHeight: 4,
                    activeTrackColor: _emerald,
                    inactiveTrackColor: cs.surfaceContainerHighest,
                    thumbColor: _emerald,
                    overlayColor: _emerald.withValues(alpha: 0.14),
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 7,
                      elevation: 0,
                    ),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 14),
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
                cs: cs,
                icon: Icons.add_rounded,
                enabled: attendCount < _maxSliderVal,
                onTap: () {
                  _haptic();
                  setState(
                    () => _attendCount =
                        math.min(_maxSliderVal, _attendCount + 1),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 6),

          Row(
            children: [
              for (final step in const [1, 3, 5, 10]) ...[
                _buildQuickPill(
                  cs: cs,
                  label: '+$step',
                  onTap: () {
                    _haptic();
                    setState(
                      () => _attendCount =
                          math.min(_maxSliderVal, _attendCount + step),
                    );
                  },
                ),
                const SizedBox(width: 6),
              ],
              const Spacer(),
              if (attendCount > 0)
                GestureDetector(
                  onTap: () {
                    _haptic();
                    setState(() => _attendCount = 0);
                  },
                  child: Text(
                    'Clear',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          Text.rich(
            TextSpan(
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: cs.onSurfaceVariant,
                height: 1.35,
              ),
              children: _buildAttendInsightSpans(
                attendCount: attendCount,
                recoveringDeficit: recoveringDeficit,
                recoveryNeededNow: recoveryNeededNow,
                safeBunksUnlocked: safeBunksUnlocked,
                extraBunksEarned: extraBunksEarned,
                targetPct: targetPct,
              ),
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
  }) {
    if (recoveringDeficit) {
      if (recoveryNeededNow > 0) {
        return [
          const TextSpan(text: 'Still need '),
          TextSpan(
            text: '$recoveryNeededNow more',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color: _amber,
            ),
          ),
          TextSpan(text: ' to reach ${targetPct.toInt()}%.'),
        ];
      }
      return [
        const TextSpan(text: 'Target reached — unlocks '),
        TextSpan(
          text: '$safeBunksUnlocked safe bunks',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: _emerald,
          ),
        ),
        const TextSpan(text: '.'),
      ];
    }

    if (attendCount > 0) {
      return [
        const TextSpan(text: 'Earns '),
        TextSpan(
          text: '+$extraBunksEarned extra bunks',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: _emerald,
          ),
        ),
        TextSpan(text: ' ($safeBunksUnlocked total cushion).'),
      ];
    }

    return [
      const TextSpan(text: 'Attending upcoming classes builds extra safe bunks.'),
    ];
  }

  Widget _buildQuickScenarios({
    required ColorScheme cs,
    required int currentHeld,
    required int currentAttended,
    required double targetPct,
  }) {
    if (currentHeld <= 0) return const SizedBox.shrink();
    const testCases = [1, 2, 3, 5];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Quick scenarios',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                'Target ${targetPct.toInt()}%',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: testCases.map((bunks) {
                final heldWithBunks = currentHeld + bunks;
                final recoveryNeeded = _calcClassesToRecover(
                  currentAttended,
                  heldWithBunks,
                  targetPct,
                );
                final safeLeft = _calcSafeBunks(
                  currentAttended,
                  heldWithBunks,
                  targetPct,
                );
                final isSelected = _bunkCount == bunks && _attendCount == 0;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: isSelected
                        ? cs.primaryContainer
                        : cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: () {
                        _haptic();
                        setState(() {
                          _bunkCount = bunks;
                          _attendCount = 0;
                        });
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Bunk $bunks',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? cs.onPrimaryContainer
                                    : _coralRed,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              recoveryNeeded > 0
                                  ? 'Attend $recoveryNeeded'
                                  : '$safeLeft safe left',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? cs.onPrimaryContainer
                                        .withValues(alpha: 0.85)
                                    : (recoveryNeeded > 0 ? _amber : _emerald),
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildStepperBtn({
    required ColorScheme cs,
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: enabled
          ? cs.surfaceContainerHigh
          : cs.surfaceContainerHigh.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(
            icon,
            size: 16,
            color: enabled
                ? cs.onSurface
                : cs.onSurfaceVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickPill({
    required ColorScheme cs,
    required String label,
    required VoidCallback onTap,
    Color? accentColor,
    bool isSelected = false,
  }) {
    return Material(
      color: isSelected
          ? (accentColor ?? cs.primary).withValues(alpha: 0.16)
          : cs.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? (accentColor ?? cs.primary)
                  : cs.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  void _showSubjectPickerSheet({
    required BuildContext context,
    required List<Map<String, dynamic>> subjects,
  }) {
    final cs = Theme.of(context).colorScheme;
    final overallHeld =
        (widget.attendanceData?['totalClasses'] as num?)?.toInt() ??
            _fallbackHeld;
    final overallAttended =
        (widget.attendanceData?['totalAttended'] as num?)?.toInt() ??
            _fallbackAttended;
    final overallPct =
        overallHeld > 0 ? (overallAttended / overallHeld) * 100.0 : 0.0;

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
                maxHeight: MediaQuery.sizeOf(context).height * 0.75,
              ),
              decoration: BoxDecoration(
                color: cs.surfaceContainer,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 10),
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 12, 12),
                      child: Row(
                        children: [
                          Text(
                            'Select scope',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            color: cs.onSurfaceVariant,
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),
                    if (subjects.length > 4)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: TextField(
                            onChanged: (val) =>
                                setSheetState(() => searchQuery = val),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: cs.onSurface,
                            ),
                            decoration: InputDecoration(
                              icon: Icon(
                                Icons.search_rounded,
                                size: 18,
                                color: cs.onSurfaceVariant,
                              ),
                              hintText: 'Search subjects',
                              hintStyle: GoogleFonts.inter(
                                fontSize: 14,
                                color: cs.onSurfaceVariant
                                    .withValues(alpha: 0.7),
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              isDense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 11),
                            ),
                          ),
                        ),
                      ),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                        children: [
                          _buildPickerOption(
                            cs: cs,
                            title: 'Overall Attendance',
                            subtitle: '$overallAttended / $overallHeld classes',
                            percentage: overallPct,
                            icon: Icons.pie_chart_outline_rounded,
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
                          if (filteredSubjects.isNotEmpty) ...[
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(6, 14, 6, 8),
                              child: Text(
                                'Subjects',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                            ...filteredSubjects.map((sub) {
                              final name =
                                  (sub['subject'] ?? 'Subject').toString();
                              final attended =
                                  (sub['attendedClasses'] as num?)?.toInt() ??
                                      0;
                              final held =
                                  (sub['totalClasses'] as num?)?.toInt() ?? 0;
                              final pct =
                                  (sub['percentage'] as num?)?.toDouble() ??
                                      (held > 0
                                          ? (attended / held) * 100.0
                                          : 0.0);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: _buildPickerOption(
                                  cs: cs,
                                  title: name,
                                  subtitle: '$attended / $held classes',
                                  percentage: pct,
                                  icon: Icons.menu_book_outlined,
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
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPickerOption({
    required ColorScheme cs,
    required String title,
    required String subtitle,
    required double percentage,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final Color col = _statusColor(percentage);

    return Material(
      color: isSelected
          ? cs.primaryContainer.withValues(alpha: 0.5)
          : cs.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 18, color: col),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: col,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 8),
                Icon(Icons.check_rounded, size: 18, color: cs.primary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
