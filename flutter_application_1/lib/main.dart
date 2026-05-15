import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'models/report.dart';
import 'models/sab_report.dart';
import 'pages/login_page.dart';
import 'pages/dashboard_page.dart';
import 'providers/profile_notifier.dart';
import 'providers/notifications_notifier.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local data persistence
  await Hive.initFlutter();
  Hive.registerAdapter(ReportAdapter());
  Hive.registerAdapter(SABReportAdapter());

  await _openBoxSafely<Report>('reports');
  await _openBoxSafely<SABReport>('sab_reports');

  runApp(const MyApp());
}

/// Opens a Hive box safely. If existing records were written with an older
/// adapter format (e.g. after a schema change), reading them throws a
/// "not enough bytes" error. In that case we delete the corrupted box and
/// reopen it empty so the app can start cleanly.
Future<void> _openBoxSafely<T>(String name) async {
  try {
    final box = await Hive.openBox<T>(name);
    // Force-read every record to surface any corruption before the UI starts
    box.values.toList();
  } catch (e) {
    debugPrint('[$name] Box corrupted or schema changed — clearing: $e');
    await Hive.deleteBoxFromDisk(name);
    await Hive.openBox<T>(name);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProfileNotifier()),
        ChangeNotifierProvider(create: (_) => NotificationsNotifier()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'CRIS App',
        theme: AppTheme.lightTheme(),
        home: const LoginPage(),
        routes: {'/dashboard': (context) => const DashboardPage()},
      ),
    );
  }
}
