import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:material_ui/material_ui.dart';

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

  testWidgets('validates patient information before showing PHIC membership',
      (tester) async {
    await _pumpForm(tester);

    expect(find.text('Patient Information Â· Page 1 of 2'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Last name is required'), findsOneWidget);
    expect(find.text('First name is required'), findsOneWidget);
    expect(find.text('Birthday is required'), findsOneWidget);
    expect(find.text('Contact number is required'), findsOneWidget);
  });

  testWidgets('keeps patient data when returning from PHIC membership',
      (tester) async {
    await _pumpForm(tester);
    await _fillRequiredPatientFields(tester);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(
      find.text('PhilHealth (PHIC) Membership Â· Page 2 of 2'),
      findsOneWidget,
    );

    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Resident'), findsOneWidget);
  });

  testWidgets('requires Specify only while Others is selected', (tester) async {
    await _pumpForm(tester);
    await _fillRequiredPatientFields(tester);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Others'));
    await tester.pumpAndSettle();
    expect(_field('Specify'), findsOneWidget);

    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();
    expect(find.text('Specify is required'), findsOneWidget);

    await tester.tap(find.text('Others'));
    await tester.pumpAndSettle();
    expect(_field('Specify'), findsNothing);
  });
}

Future<void> _pumpForm(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(360, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(const MaterialApp(home: ReportingPage()));
  await tester.pumpAndSettle();
}

Future<void> _fillRequiredPatientFields(WidgetTester tester) async {
  await _enterField(tester, 'Last name', 'Test');
  await _enterField(tester, 'First name', 'Resident');
  await tester.tap(find.byType(DropdownButtonFormField<String>).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Male').last);
  await tester.pumpAndSettle();
  await _setReadOnlyField(tester, 'Birthday', '2000-01-01');
  await _setReadOnlyField(tester, 'Age', '26');
  await _enterField(tester, 'Contact number', '09171234567');
  await _enterField(tester, 'House no. / Street', '1 Main Street');
  await _enterField(tester, 'Barangay', 'Sample Barangay');
  await _enterField(tester, 'City / Municipality', 'Iloilo City');
  await _enterField(tester, 'Province', 'Iloilo');
}

Finder _field(String label) => find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.labelText == label,
      description: 'TextField labeled "$label"',
    );

Future<void> _enterField(
    WidgetTester tester, String label, String value) async {
  final finder = _field(label);
  await tester.ensureVisible(finder);
  await tester.enterText(finder, value);
  await tester.pumpAndSettle();
}

Future<void> _setReadOnlyField(
    WidgetTester tester, String label, String value) async {
  final field = tester.widget<TextField>(_field(label));
  field.controller!.text = value;
  await tester.pump();
}
