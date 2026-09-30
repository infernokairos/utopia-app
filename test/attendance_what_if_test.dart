import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utopia_app/screens/attendance_what_if_tab.dart';

void main() {
  final sampleData = {
    'totalClasses': 40,
    'totalAttended': 30,
    'percentage': 75.0,
    'subjects': [
      {
        'subject': 'Mathematics',
        'totalClasses': 20,
        'attendedClasses': 16,
        'percentage': 80.0,
      },
      {
        'subject': 'Physics',
        'totalClasses': 20,
        'attendedClasses': 14,
        'percentage': 70.0,
      },
    ],
  };

  testWidgets('AttendanceWhatIfTab renders and displays baseline metrics', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AttendanceWhatIfTab(
            attendanceData: sampleData,
            targetPercentage: 75,
            isColoredMode: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AttendanceWhatIfTab), findsOneWidget);
    expect(find.text('75.0%'), findsOneWidget);
    expect(find.text('30 / 40 classes'), findsOneWidget);
    expect(find.text('BUNK / SKIP CLASSES'), findsOneWidget);
    expect(find.text('ATTEND CLASSES'), findsOneWidget);
  });

  testWidgets('Bunking slider shows exact classes to attend in consequence banner', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AttendanceWhatIfTab(
            attendanceData: sampleData,
            targetPercentage: 75,
            isColoredMode: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap +1 bunk
    final plusOneBunk = find.widgetWithText(GestureDetector, '+1').first;
    await tester.tap(plusOneBunk);
    await tester.pumpAndSettle();

    // 30 / 41 is 73.2% (< 75%), so 3 classes needed to recover (33/44 = 75%)
    expect(find.textContaining('attend +3 classes in a row'), findsOneWidget);
  });

  testWidgets('Attending slider shows exact safe bunks unlocked in consequence banner', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AttendanceWhatIfTab(
            attendanceData: sampleData,
            targetPercentage: 75,
            isColoredMode: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap +5 attend
    final plusFiveAttend = find.widgetWithText(GestureDetector, '+5');
    await tester.tap(plusFiveAttend);
    await tester.pumpAndSettle();

    // 35 / 45 is 77.8% (>= 75%), safe bunks = floor((3500 - 75*45)/75) = floor(125/75) = 1
    expect(find.textContaining('Earns you +1 extra safe bunks'), findsOneWidget);
  });
}
