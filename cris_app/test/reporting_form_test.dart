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
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: ReportingPage()));
    await tester.pumpAndSettle();

    _expectFormPage(tester, 'Patient Information', 1);
    expect(find.text('Animal Information · Page 2 of 7'), findsNothing);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Last Name is required'), findsOneWidget);
    expect(find.text('Mobile Number is required'), findsOneWidget);
    expect(find.text('Tell us what happened. is required'), findsNothing);
  });

  testWidgets('seven-page flow preserves data and retains review navigation',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: ReportingPage()));
    await tester.pumpAndSettle();

    await _enterField(tester, 'Last Name', 'Test');
    await _enterField(tester, 'First Name', 'Resident');
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Male').last);
    await tester.pumpAndSettle();
    await _setReadOnlyField(tester, 'Date of Birth', '01/01/2000');
    await _setReadOnlyField(tester, 'Age', '26');
    await _enterField(tester, 'Mobile Number', '09171234567');
    await _enterField(tester, 'Province', 'Iloilo');
    await _selectMunicipality(tester, 'Municipality/City', 'Iloilo City');
    await _enterField(tester, 'Barangay', 'Sample Barangay');
    await _enterField(tester, 'House Number / Street / Purok', '1 Main Street');
    await _tapButton(tester, 'Next');

    _expectFormPage(tester, 'Animal Information', 2);
    await _tapButton(tester, 'Next');

    _expectFormPage(tester, 'Suspicious Animal Behavior', 3);
    expect(find.text('Upload Photo of the Animal (Optional)'), findsOneWidget);
    expect(
      tester.getBottomLeft(find.text('Upload Photo of the Animal (Optional)'))
          .dy,
      lessThan(tester.getTopLeft(find.widgetWithText(FilledButton, 'Next')).dy),
    );
    await _tapButton(tester, 'Next');

    _expectFormPage(tester, 'Bite Incident Information', 4);
    await _setReadOnlyField(tester, 'Date of Exposure', '11/03/2026');
    await _setReadOnlyField(tester, 'Est. Time of Exposure', '10:00 AM');
    await _enterField(tester, 'Province', 'Iloilo');
    await _selectMunicipality(tester, 'City / Municipality', 'Iloilo City');
    await _enterField(tester, 'Barangay', 'Incident Barangay');
    await _enterField(tester, 'Tell us what happened.', 'A dog bit my arm.');
    await _tapButton(tester, 'Next');

    _expectFormPage(tester, 'Symptoms and Wound Information', 5);
    expect(find.text('Symptoms after the incident (select all that apply)'),
        findsOneWidget);
    expect(find.text('Type of Wound (select all that apply)'), findsOneWidget);
    expect(find.text('Number of Bite/Scratch Wounds'), findsNothing);
    final bleedingAnswer = find.byType(SegmentedButton<String>);
    await tester.tap(find.descendant(
      of: bleedingAnswer,
      matching: find.text('Yes'),
    ));
    await tester.pumpAndSettle();
    await _tapButton(tester, 'Next');

    _expectFormPage(tester, 'Site of Bite', 6);
    expect(find.byType(Image), findsWidgets);
    await _tapDiagramAt(tester, .25, .09);
    expect(find.text('Head / Scalp'), findsOneWidget);
    await _tapDiagramAt(tester, .25, .19);
    expect(find.text('Neck'), findsOneWidget);
    await _tapDiagramAt(tester, .32, .50);
    expect(find.text('Left Hip'), findsOneWidget);
    await _tapDiagramAt(tester, .18, .50);
    expect(find.text('Right Hip'), findsOneWidget);
    await _tapDiagramAt(tester, .40, .38);
    expect(find.text('Left Elbow'), findsOneWidget);
    await _tapDiagramAt(tester, .10, .38);
    expect(find.text('Right Elbow'), findsOneWidget);
    await _tapDiagramAt(tester, .25, .32);
    expect(find.text('Chest'), findsOneWidget);
    await _tapDiagramAt(tester, .25, .44);
    expect(find.text('Abdomen'), findsOneWidget);
    await _tapDiagramAt(tester, .30, .64);
    expect(find.text('Left Thigh'), findsOneWidget);
    await _tapDiagramAt(tester, .20, .74);
    expect(find.text('Right Knee'), findsOneWidget);
    await _tapDiagramAt(tester, .46, .56);
    expect(find.text('Left Hand'), findsOneWidget);
    await _tapDiagramAt(tester, .18, .92);
    expect(find.text('Right Foot'), findsOneWidget);
    await tester.binding.setSurfaceSize(const Size(250, 844));
    await tester.pumpAndSettle();
    await _tapDiagramAt(tester, .32, .50);
    expect(find.text('Left Hip'), findsOneWidget);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Back').first);
    await tester.pumpAndSettle();
    await _tapDiagramAt(tester, .74, .19);
    expect(find.text('Neck'), findsOneWidget);
    await _tapDiagramAt(tester, .74, .32);
    expect(find.text('Upper Back'), findsOneWidget);
    await _tapDiagramAt(tester, .68, .64);
    expect(find.text('Left Thigh'), findsOneWidget);
    await _tapDiagramAt(tester, .89, .38);
    expect(find.text('Right Elbow'), findsOneWidget);
    await _tapButton(tester, 'Next');

    _expectFormPage(tester, 'Remaining Information', 7);
    final washAnswer = find.byType(SegmentedButton<String>);
    await tester.tap(find.descendant(
      of: washAnswer,
      matching: find.text('No'),
    ));
    await tester.pumpAndSettle();
    await _enterField(tester, 'Current medications', 'Vitamin C');
    await _tapButton(tester, 'Submit');
    expect(find.textContaining('Review and Submit · Page'), findsOneWidget);
    await tester.tap(find.text('Back').last);
    await tester.pumpAndSettle();
    _expectFormPage(tester, 'Remaining Information', 7);
    expect(find.text('Vitamin C'), findsOneWidget);
  });
}

void _expectFormPage(WidgetTester tester, String title, int page) {
  expect(find.text('$title · Page $page of 7'), findsOneWidget);
  expect(find.byType(SingleChildScrollView), findsNothing);
  expect(find.byType(ListView), findsNothing);
  final button = page == 7 ? 'Submit' : 'Next';
  expect(
    tester.getBottomLeft(find.widgetWithText(FilledButton, button)).dy,
    greaterThan(760),
  );
}

Finder _field(String label) => find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.decoration?.labelText == label,
      description: 'TextField labeled "$label"',
    );

Future<void> _enterField(
    WidgetTester tester, String label, String value) async {
  final finder = _field(label);
  await tester.ensureVisible(finder);
  await tester.enterText(finder, value);
  await tester.pumpAndSettle();
}

Future<void> _tapDiagramAt(
  WidgetTester tester,
  double normalizedX,
  double normalizedY,
) async {
  final rect =
      tester.getRect(find.byKey(const ValueKey('body-diagram-surface')));
  await tester.tapAt(
    Offset(
      rect.left + rect.width * normalizedX,
      rect.top + rect.height * normalizedY,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _selectMunicipality(
    WidgetTester tester, String label, String municipality) async {
  final finder = _field(label);
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.enterText(finder, municipality);
  await tester.pumpAndSettle();
}

Future<void> _setReadOnlyField(
    WidgetTester tester, String label, String value) async {
  final field = tester.widget<TextField>(_field(label));
  field.controller!.text = value;
  await tester.pump();
}

Future<void> _tapButton(WidgetTester tester, String label) async {
  final finder = find.text(label).last;
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
