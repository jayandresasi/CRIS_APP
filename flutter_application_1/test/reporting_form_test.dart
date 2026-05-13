import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/pages/reporting_page.dart';

void main() {
  testWidgets(
    'Reporting form shows validation errors when required fields empty',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: ReportingPage()));

      // Ensure page loaded
      expect(find.text('Report Incident'), findsOneWidget);

      // Tap submit without filling required fields
      await tester.tap(find.text('Submit Report'));
      await tester.pumpAndSettle();

      // Expect validation errors for required fields
      expect(find.text('Please enter contact person'), findsWidgets);
      expect(find.text('Please enter contact number'), findsOneWidget);
      expect(find.text('Please enter a location'), findsOneWidget);
      expect(find.text('Please enter a description'), findsOneWidget);
    },
  );
}
