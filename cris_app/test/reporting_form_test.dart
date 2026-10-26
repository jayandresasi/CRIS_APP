import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:cris_app/models/report.dart';
import 'package:cris_app/pages/reporting_page.dart';

void main() {
  late Directory hiveTestDirectory;

  setUpAll(() async {
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

  testWidgets('report form validates one page at a time', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ReportingPage()));
    await tester.pumpAndSettle();

    expect(find.text('Step 1 of 6'), findsOneWidget);
    expect(find.text('Page 1 - Patient Information'), findsOneWidget);
    expect(find.text('Page 2 - Animal Information'), findsNothing);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Last Name is required'), findsOneWidget);
    expect(find.text('Mobile Number is required'), findsOneWidget);
    expect(find.text('Tell us what happened. is required'), findsNothing);
  });

  testWidgets('six-step flow preserves data and supports section edits',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ReportingPage()));
    await tester.pumpAndSettle();

    await _enterField(tester, 'Last Name', 'Test');
    await _enterField(tester, 'First Name', 'Resident');
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Male').last);
    await tester.pumpAndSettle();
    await _pickDate(tester, 'Date of Birth');
    await _enterField(tester, 'Mobile Number', '09171234567');
    await _selectMunicipality(tester, 'Municipality/City', 'Iloilo City');
    await _enterField(tester, 'Barangay', 'Sample Barangay');
    await _enterField(tester, 'House Number / Street / Purok', '1 Main Street');
    await _tapButton(tester, 'Next');

    expect(find.text('Step 2 of 6'), findsOneWidget);
    expect(find.text('Page 2 - Animal Information'), findsOneWidget);
    await _tapButton(tester, 'Next');

    expect(find.text('Step 3 of 6'), findsOneWidget);
    await _pickDate(tester, 'Date of Exposure');
    await _pickTime(tester);
    await _enterField(tester, 'Province', 'Iloilo');
    await _selectMunicipality(tester, 'City / Municipality', 'Iloilo City');
    await _enterField(tester, 'Barangay', 'Incident Barangay');
    await _enterField(tester, 'Tell us what happened.', 'A dog bit my arm.');
    await _tapButton(tester, 'Next');

    expect(find.text('Step 4 of 6'), findsOneWidget);
    expect(find.text('Symptoms after the incident (select all that apply)'),
        findsOneWidget);
    expect(find.text('Type of Wound (select all that apply)'), findsOneWidget);
    expect(find.byType(Image), findsWidgets);
    await _enterField(tester, 'Number of Bite/Scratch Wounds', '1');
    await tester.tap(find.byType(RadioListTile<String>).at(0));
    await tester.tap(find.byType(RadioListTile<String>).at(3));
    await tester.tap(find.byTooltip('Head / Scalp'));
    await tester.pumpAndSettle();
    await _tapButton(tester, 'Review');

    expect(find.text('Step 5 of 6'), findsOneWidget);
    await _enterField(tester, 'Current medications (optional)', 'Vitamin C');
    await _tapButton(tester, 'Review');

    expect(find.text('Step 6 of 6'), findsOneWidget);
    expect(find.text('Relevant Medical History'), findsWidgets);
    expect(find.text('Vitamin C'), findsOneWidget);
    expect(find.textContaining('does not confirm a diagnosis or treatment'),
        findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Edit').last);
    await tester.pumpAndSettle();
    expect(find.text('Step 5 of 6'), findsOneWidget);
    expect(find.text('Vitamin C'), findsOneWidget);
  });
}

Finder _field(String label) => find.byWidgetPredicate(
      (widget) =>
          widget is TextFormField && widget.decoration.labelText == label,
      description: 'TextFormField labeled "$label"',
    );

Future<void> _enterField(
    WidgetTester tester, String label, String value) async {
  final finder = _field(label);
  await tester.ensureVisible(finder);
  await tester.enterText(finder, value);
  await tester.pumpAndSettle();
}

Future<void> _selectMunicipality(
    WidgetTester tester, String label, String municipality) async {
  final finder = _field(label);
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.enterText(finder, municipality);
  await tester.pumpAndSettle();
  await tester.tap(find.text(municipality).last);
  await tester.pumpAndSettle();
}

Future<void> _pickDate(WidgetTester tester, String label) async {
  final finder = _field(label);
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK').last);
  await tester.pumpAndSettle();
}

Future<void> _pickTime(WidgetTester tester) async {
  final finder = _field('Est. Time of Exposure');
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK').last);
  await tester.pumpAndSettle();
}

Future<void> _tapButton(WidgetTester tester, String label) async {
  final finder = find.text(label).last;
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
