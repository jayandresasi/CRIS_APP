import 'package:cris_app/pages/reporting_page.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('pagination uses the full mobile viewport without vertical scroll',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(
      home: ReportingPage(
        facilityId: 'test-facility',
        facilityAcronym: 'TEST-001',
        facilityName: 'Test Facility',
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(find.byType(ListView), findsNothing);

    final next = find.widgetWithText(FilledButton, 'Next');
    expect(next, findsOneWidget);
    expect(tester.getBottomLeft(next).dy, greaterThan(760));

    await tester.tap(next);
    await tester.pumpAndSettle();

    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(tester.getBottomLeft(find.widgetWithText(FilledButton, 'Next')).dy,
        greaterThan(760));
  });
}
