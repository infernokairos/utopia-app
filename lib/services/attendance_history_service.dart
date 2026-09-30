import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubjectDelta {
  final String subjectName;
  final double previousPercentage;
  final double currentPercentage;
  final double deltaPercentage;
  final int previousAttended;
  final int currentAttended;
  final int attendedDelta;
  final int previousHeld;
  final int currentHeld;
  final int heldDelta;

  const SubjectDelta({
    required this.subjectName,
    required this.previousPercentage,
    required this.currentPercentage,
    required this.deltaPercentage,
    required this.previousAttended,
    required this.currentAttended,
    required this.attendedDelta,
    required this.previousHeld,
    required this.currentHeld,
    required this.heldDelta,
  });

  bool get hasChanged =>
      deltaPercentage.abs() > 0.01 || attendedDelta != 0 || heldDelta != 0;
}

class AttendanceComparison {
  final bool hasPrevious;
  final DateTime? previousTimestamp;
  final DateTime currentTimestamp;
  final double previousOverall;
  final double currentOverall;
  final double overallDelta;
  final int previousHeld;
  final int currentHeld;
  final int heldDelta;
  final int previousAttended;
  final int currentAttended;
  final int attendedDelta;
  final List<SubjectDelta> subjectDeltas;

  const AttendanceComparison({
    required this.hasPrevious,
    this.previousTimestamp,
    required this.currentTimestamp,
    required this.previousOverall,
    required this.currentOverall,
    required this.overallDelta,
    required this.previousHeld,
    required this.currentHeld,
    required this.heldDelta,
    required this.previousAttended,
    required this.currentAttended,
    required this.attendedDelta,
    required this.subjectDeltas,
  });

  factory AttendanceComparison.noPrevious({
    required DateTime currentTimestamp,
    required double currentOverall,
    required int currentHeld,
    required int currentAttended,
  }) {
    return AttendanceComparison(
      hasPrevious: false,
      previousTimestamp: null,
      currentTimestamp: currentTimestamp,
      previousOverall: currentOverall,
      currentOverall: currentOverall,
      overallDelta: 0.0,
      previousHeld: currentHeld,
      currentHeld: currentHeld,
      heldDelta: 0,
      previousAttended: currentAttended,
      currentAttended: currentAttended,
      attendedDelta: 0,
      subjectDeltas: const [],
    );
  }
}

class DailyAttendancePoint {
  final String id;
  final DateTime timestamp;
  final String dateKey; // YYYY-MM-DD
  final double overallPercentage;
  final int totalClasses;
  final int totalAttended;
  final double deltaOverall;
  final int deltaAttended;
  final int deltaHeld;
  final List<Map<String, dynamic>> subjects;

  const DailyAttendancePoint({
    required this.id,
    required this.timestamp,
    required this.dateKey,
    required this.overallPercentage,
    required this.totalClasses,
    required this.totalAttended,
    required this.deltaOverall,
    required this.deltaAttended,
    required this.deltaHeld,
    required this.subjects,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'dateKey': dateKey,
        'overallPercentage': overallPercentage,
        'totalClasses': totalClasses,
        'totalAttended': totalAttended,
        'deltaOverall': deltaOverall,
        'deltaAttended': deltaAttended,
        'deltaHeld': deltaHeld,
        'subjects': subjects,
      };

  factory DailyAttendancePoint.fromJson(Map<String, dynamic> json) {
    return DailyAttendancePoint(
      id: json['id'] as String? ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      dateKey: json['dateKey'] as String? ?? '',
      overallPercentage:
          (json['overallPercentage'] as num?)?.toDouble() ?? 0.0,
      totalClasses: (json['totalClasses'] as num?)?.toInt() ?? 0,
      totalAttended: (json['totalAttended'] as num?)?.toInt() ?? 0,
      deltaOverall: (json['deltaOverall'] as num?)?.toDouble() ?? 0.0,
      deltaAttended: (json['deltaAttended'] as num?)?.toInt() ?? 0,
      deltaHeld: (json['deltaHeld'] as num?)?.toInt() ?? 0,
      subjects: (json['subjects'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>(),
    );
  }

  String get timeFormatted {
    final hour12 = timestamp.hour % 12 == 0 ? 12 : timestamp.hour % 12;
    final minStr = timestamp.minute.toString().padLeft(2, '0');
    final ampm = timestamp.hour >= 12 ? 'PM' : 'AM';
    return '$hour12:$minStr $ampm';
  }
}

class AttendanceHistoryService {
  static String _currKey(String roll) =>
      'attendance_history_curr_${roll.trim().toUpperCase()}';
  static String _prevKey(String roll) =>
      'attendance_history_prev_${roll.trim().toUpperCase()}';
  static String _dailyPointsKey(String roll) =>
      'daily_attendance_bubbles_${roll.trim().toUpperCase()}';
  static String _dailyDateKey(String roll) =>
      'daily_attendance_date_${roll.trim().toUpperCase()}';

  static String _todayDateKey() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  /// Fetches today's saved bubble points.
  /// If stored points belong to a previous day (yesterday or older), clears them automatically!
  static Future<List<DailyAttendancePoint>> getTodayDailyPoints(
      String rollNumber) async {
    final roll = rollNumber.trim().toUpperCase();
    if (roll.isEmpty) return const [];

    try {
      final prefs = await SharedPreferences.getInstance();
      final storedDate = prefs.getString(_dailyDateKey(roll));
      final todayStr = _todayDateKey();

      // Refresh / wipe if stored date is NOT today!
      if (storedDate != todayStr) {
        await prefs.remove(_dailyPointsKey(roll));
        await prefs.setString(_dailyDateKey(roll), todayStr);
        return const [];
      }

      final rawJson = prefs.getString(_dailyPointsKey(roll));
      if (rawJson == null || rawJson.isEmpty) return const [];

      final List<dynamic> decoded = jsonDecode(rawJson);
      return decoded
          .map((item) => DailyAttendancePoint.fromJson(
              item as Map<String, dynamic>))
          .where((p) => p.dateKey == todayStr)
          .toList();
    } catch (e) {
      debugPrint('AttendanceHistoryService: getTodayDailyPoints error: $e');
      return const [];
    }
  }

  /// Records a new timed bubble point for today if scraping occurs.
  static Future<DailyAttendancePoint?> recordDailyPoint(
    String rollNumber,
    Map<String, dynamic> data,
  ) async {
    final roll = rollNumber.trim().toUpperCase();
    if (roll.isEmpty) return null;

    try {
      final prefs = await SharedPreferences.getInstance();
      final todayStr = _todayDateKey();
      final existingPoints = await getTodayDailyPoints(roll);

      final now = DateTime.now();
      final overall = (data['overallPercentage'] as num?)?.toDouble() ?? 0.0;
      final totalClasses = (data['totalClasses'] as num?)?.toInt() ?? 0;
      final totalAttended = (data['totalAttended'] as num?)?.toInt() ?? 0;

      if (overall <= 0 && totalClasses <= 0) return null;

      final subjectsList = (data['subjects'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>();

      double deltaOverall = 0.0;
      int deltaAttended = 0;
      int deltaHeld = 0;

      if (existingPoints.isNotEmpty) {
        final lastPoint = existingPoints.last;
        deltaOverall = overall - lastPoint.overallPercentage;
        deltaAttended = totalAttended - lastPoint.totalAttended;
        deltaHeld = totalClasses - lastPoint.totalClasses;

        // If recorded within last 30 seconds and values haven't changed, return last point
        if (now.difference(lastPoint.timestamp).inSeconds < 30 &&
            (deltaOverall.abs() < 0.001 && deltaAttended == 0 && deltaHeld == 0)) {
          return lastPoint;
        }
      }

      final newPoint = DailyAttendancePoint(
        id: '${now.millisecondsSinceEpoch}',
        timestamp: now,
        dateKey: todayStr,
        overallPercentage: overall,
        totalClasses: totalClasses,
        totalAttended: totalAttended,
        deltaOverall: deltaOverall,
        deltaAttended: deltaAttended,
        deltaHeld: deltaHeld,
        subjects: subjectsList
            .map((s) => {
                  'subject': (s['subject'] ?? '').toString(),
                  'totalClasses': (s['totalClasses'] as num?)?.toInt() ?? 0,
                  'attendedClasses':
                      (s['attendedClasses'] as num?)?.toInt() ?? 0,
                  'percentage': (s['percentage'] as num?)?.toDouble() ?? 0.0,
                })
            .toList(),
      );

      final updatedList = List<DailyAttendancePoint>.from(existingPoints)..add(newPoint);

      await prefs.setString(
          _dailyPointsKey(roll),
          jsonEncode(updatedList.map((p) => p.toJson()).toList()));
      await prefs.setString(_dailyDateKey(roll), todayStr);

      return newPoint;
    } catch (e) {
      debugPrint('AttendanceHistoryService: recordDailyPoint error: $e');
      return null;
    }
  }

  /// Clears stored daily bubble points for the roll number.
  static Future<void> clearDailyPoints(String rollNumber) async {
    final roll = rollNumber.trim().toUpperCase();
    if (roll.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_dailyPointsKey(roll));
      await prefs.remove(_dailyDateKey(roll));
    } catch (e) {
      debugPrint('AttendanceHistoryService: clearDailyPoints error: $e');
    }
  }

  /// Saves current snapshot and promotes earlier snapshot to previous snapshot if timestamp differs.
  static Future<void> recordSnapshot(
    String rollNumber,
    Map<String, dynamic> data,
  ) async {
    final roll = rollNumber.trim().toUpperCase();
    if (roll.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final currJson = prefs.getString(_currKey(roll));
      final now = DateTime.now();

      final subjectsList = (data['subjects'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>();

      final newSnapshot = {
        'timestamp': now.toIso8601String(),
        'overallPercentage':
            (data['overallPercentage'] as num?)?.toDouble() ?? 0.0,
        'totalClasses': (data['totalClasses'] as num?)?.toInt() ?? 0,
        'totalAttended': (data['totalAttended'] as num?)?.toInt() ?? 0,
        'subjects': subjectsList
            .map((s) => {
                  'subject': (s['subject'] ?? '').toString(),
                  'totalClasses': (s['totalClasses'] as num?)?.toInt() ?? 0,
                  'attendedClasses':
                      (s['attendedClasses'] as num?)?.toInt() ?? 0,
                  'percentage': (s['percentage'] as num?)?.toDouble() ?? 0.0,
                })
            .toList(),
      };

      if (currJson != null) {
        try {
          final Map<String, dynamic> oldCurr = jsonDecode(currJson);
          final oldTsStr = oldCurr['timestamp'] as String?;
          final oldTs = oldTsStr != null ? DateTime.tryParse(oldTsStr) : null;

          if (oldTs != null &&
              now.difference(oldTs).inMinutes >= 1) {
            await prefs.setString(_prevKey(roll), currJson);
          }
        } catch (e) {
          debugPrint('AttendanceHistoryService: parse old current failed: $e');
        }
      }

      await prefs.setString(_currKey(roll), jsonEncode(newSnapshot));
      await recordDailyPoint(roll, data);
    } catch (e) {
      debugPrint('AttendanceHistoryService: recordSnapshot failed: $e');
    }
  }

  /// Calculates comparison between current data and previous recorded snapshot.
  static Future<AttendanceComparison> getComparison(
    String rollNumber,
    Map<String, dynamic> currentData,
  ) async {
    final roll = rollNumber.trim().toUpperCase();
    final now = DateTime.now();

    final currentOverall =
        (currentData['overallPercentage'] as num?)?.toDouble() ?? 0.0;
    final currentHeld =
        (currentData['totalClasses'] as num?)?.toInt() ?? 0;
    final currentAttended =
        (currentData['totalAttended'] as num?)?.toInt() ?? 0;
    final currentSubjects =
        (currentData['subjects'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>();

    if (roll.isEmpty) {
      return AttendanceComparison.noPrevious(
        currentTimestamp: now,
        currentOverall: currentOverall,
        currentHeld: currentHeld,
        currentAttended: currentAttended,
      );
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      var prevJson = prefs.getString(_prevKey(roll));

      // If no prevKey stored yet, fallback to currKey if its timestamp is prior to current fetch
      if (prevJson == null) {
        final currJson = prefs.getString(_currKey(roll));
        if (currJson != null) {
          final Map<String, dynamic> currMap = jsonDecode(currJson);
          final tsStr = currMap['timestamp'] as String?;
          final ts = tsStr != null ? DateTime.tryParse(tsStr) : null;
          if (ts != null && now.difference(ts).inSeconds >= 30) {
            prevJson = currJson;
          }
        }
      }

      if (prevJson == null) {
        return AttendanceComparison.noPrevious(
          currentTimestamp: now,
          currentOverall: currentOverall,
          currentHeld: currentHeld,
          currentAttended: currentAttended,
        );
      }

      final Map<String, dynamic> prevMap = jsonDecode(prevJson);
      final prevTsStr = prevMap['timestamp'] as String?;
      final prevTs = prevTsStr != null ? DateTime.tryParse(prevTsStr) : null;
      final prevOverall =
          (prevMap['overallPercentage'] as num?)?.toDouble() ?? 0.0;
      final prevHeld = (prevMap['totalClasses'] as num?)?.toInt() ?? 0;
      final prevAttended = (prevMap['totalAttended'] as num?)?.toInt() ?? 0;
      final prevSubjectsList =
          (prevMap['subjects'] as List<dynamic>? ?? const [])
              .cast<Map<String, dynamic>>();

      final Map<String, Map<String, dynamic>> prevSubMap = {};
      for (final s in prevSubjectsList) {
        final name = (s['subject'] ?? '').toString().trim().toLowerCase();
        if (name.isNotEmpty) {
          prevSubMap[name] = s;
        }
      }

      final List<SubjectDelta> subjectDeltas = [];

      for (final curSub in currentSubjects) {
        final name = (curSub['subject'] ?? '').toString();
        final key = name.trim().toLowerCase();
        final curPct = (curSub['percentage'] as num?)?.toDouble() ?? 0.0;
        final curHeldSub = (curSub['totalClasses'] as num?)?.toInt() ?? 0;
        final curAttSub = (curSub['attendedClasses'] as num?)?.toInt() ?? 0;

        final prevSub = prevSubMap[key];
        final prevPct = prevSub != null
            ? (prevSub['percentage'] as num?)?.toDouble() ?? 0.0
            : curPct;
        final prevHeldSub = prevSub != null
            ? (prevSub['totalClasses'] as num?)?.toInt() ?? 0
            : curHeldSub;
        final prevAttSub = prevSub != null
            ? (prevSub['attendedClasses'] as num?)?.toInt() ?? 0
            : curAttSub;

        subjectDeltas.add(
          SubjectDelta(
            subjectName: name,
            previousPercentage: prevPct,
            currentPercentage: curPct,
            deltaPercentage: curPct - prevPct,
            previousAttended: prevAttSub,
            currentAttended: curAttSub,
            attendedDelta: curAttSub - prevAttSub,
            previousHeld: prevHeldSub,
            currentHeld: curHeldSub,
            heldDelta: curHeldSub - prevHeldSub,
          ),
        );
      }

      return AttendanceComparison(
        hasPrevious: true,
        previousTimestamp: prevTs,
        currentTimestamp: now,
        previousOverall: prevOverall,
        currentOverall: currentOverall,
        overallDelta: currentOverall - prevOverall,
        previousHeld: prevHeld,
        currentHeld: currentHeld,
        heldDelta: currentHeld - prevHeld,
        previousAttended: prevAttended,
        currentAttended: currentAttended,
        attendedDelta: currentAttended - prevAttended,
        subjectDeltas: subjectDeltas,
      );
    } catch (e) {
      debugPrint('AttendanceHistoryService: getComparison failed: $e');
      return AttendanceComparison.noPrevious(
        currentTimestamp: now,
        currentOverall: currentOverall,
        currentHeld: currentHeld,
        currentAttended: currentAttended,
      );
    }
  }

  /// Clears stored history snapshots for the roll number (on portal disconnect).
  static Future<void> clearHistory(String rollNumber) async {
    final roll = rollNumber.trim().toUpperCase();
    if (roll.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currKey(roll));
      await prefs.remove(_prevKey(roll));
    } catch (e) {
      debugPrint('AttendanceHistoryService: clearHistory failed: $e');
    }
  }

  /// Formats DateTime as dd-MM-yyyy hh:mm a (e.g. 13-08-2026 06:13 PM)
  static String formatTimestamp(DateTime? dt) {
    if (dt == null) return 'N/A';
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;

    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final hourStr = hour12.toString().padLeft(2, '0');
    final minStr = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';

    return '$day-$month-$year $hourStr:$minStr $ampm';
  }
}
