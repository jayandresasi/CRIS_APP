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
  await Hive.openBox<Report>('reports');
  await Hive.openBox<SABReport>('sab_reports');

  runApp(const MyApp());
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
        routes: {
          '/dashboard': (context) => const DashboardPage(),
        },
      ),
    );
  }
}
