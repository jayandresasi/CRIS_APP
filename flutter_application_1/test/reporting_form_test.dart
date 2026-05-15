import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:cris_app/models/report.dart';
import 'package:cris_app/pages/reporting_page.dart';

void main() {
  setUpAll(() async {
    // Flutter binding must be initialized before Hive in a test environment.
    TestWidgetsFlutterBinding.ensureInitialized();
    await Hive.initFlutter();
    Hive.registerAdapter(ReportAdapter());
    await Hive.openBox<Report>('reports');
  });

  tearDownAll(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
  });

  testWidgets(
    'Reporting form shows validation errors when required fields empty',
    (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: ReportingPage()));
      await tester.pumpAndSettle();

      // Ensure page loaded
      expect(find.text('Report Bite Incident'), findsOneWidget);

      // The submit button is below the fold — scroll to it before tapping.
      final submitBtn = find.text('Submit Report');
      await tester.scrollUntilVisible(submitBtn, 100);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Expect validation errors for required fields
      expect(find.text('Please enter contact person'), findsWidgets);
      expect(find.text('Please enter contact number'), findsOneWidget);
      expect(find.text('Please enter a location'), findsOneWidget);
      expect(find.text('Please enter a description'), findsOneWidget);
    },
  );
}
