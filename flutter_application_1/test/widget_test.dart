import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'package:cris_app/pages/login_page.dart';
import 'package:cris_app/providers/profile_notifier.dart';
import 'package:cris_app/providers/notifications_notifier.dart';
import 'package:cris_app/theme.dart';

void main() {
  setUpAll(() async {
    // Flutter binding must be initialized before Hive in a test environment.
    TestWidgetsFlutterBinding.ensureInitialized();
    await Hive.initFlutter();
    await Hive.openBox('settings');
  });

  tearDownAll(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
  });

  testWidgets('App loads login page', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ProfileNotifier()..load()),
          ChangeNotifierProvider(create: (_) => NotificationsNotifier()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'CRIS App',
          theme: AppTheme.lightTheme(),
          home: const LoginPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Rabies Monitoring & Response System'), findsOneWidget);
    expect(find.text('Report. Locate. Get Treated.'), findsOneWidget);
  });
}