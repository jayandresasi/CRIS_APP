import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:cris_app/models/report.dart';
import 'package:cris_app/pages/reporting_page.dart';

void main() {
  late Directory hiveTestDirectory;

  setUpAll(() async {
    // Keep Hive independent from the device-only path provider plugin.
    TestWidgetsFlutterBinding.ensureInitialized();
    hiveTestDirectory =
        await Directory.systemTemp.createTemp('cris_report_test_');
    Hive.init(hiveTestDirectory.path);
    Hive.registerAdapter(ReportAdapter());
    await Hive.openBox<Report>('reports');
  });

  tearDownAll(() async {
    await Hive.close();
    await hiveTestDirectory.delete(recursive: true);
  });

  testWidgets(
    'Reporting form shows validation errors when required fields empty',
    (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: ReportingPage()));
      await tester.pumpAndSettle();

      // Ensure page loaded
      expect(find.text('Animal Bite Report'), findsOneWidget);

      // The submit button is below the fold — scroll to it before tapping.
      final submitBtn = find.text('Review Information').last;
      await tester.scrollUntilVisible(
        submitBtn,
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Expect validation errors for required fields
      expect(find.text('Last Name is required'), findsOneWidget);
      expect(find.text('Mobile Number is required'), findsOneWidget);
      expect(find.text('Tell us what happened. is required'), findsOneWidget);
    },
  );
}
