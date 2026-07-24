import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'models/report.dart';
import 'models/sab_report.dart';
import 'pages/dashboard_page.dart';
import 'pages/local_data_recovery_page.dart';
import 'pages/login_page.dart';
import 'providers/notifications_notifier.dart';
import 'providers/profile_notifier.dart';
import 'services/local_report_backup.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await _initializeApp();
  } on LocalDataOpenException catch (error, stackTrace) {
    debugPrint('Unable to open local data: $error\n$stackTrace');
    runApp(
      LocalDataRecoveryApp(
        failedBoxName: error.boxName,
        canBackUpReports: !kIsWeb,
        onTryAgain: _retryStartup,
        onResetReports: _resetLocalReports,
        onContinue: () => runApp(const MyApp()),
      ),
    );
    return;
  }

  runApp(const MyApp());
}

Future<void> _initializeApp() async {
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(ReportAdapter().typeId)) {
    Hive.registerAdapter(ReportAdapter());
  }
  if (!Hive.isAdapterRegistered(SABReportAdapter().typeId)) {
    Hive.registerAdapter(SABReportAdapter());
  }

  await _openBox<Report>('reports');
  await _openBox<SABReport>('sab_reports');
  await _openBox<dynamic>('settings');

  // Web requires explicit FirebaseOptions, while native platforms use their
  // platform configuration files.
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyDpsbDo_tiB9rTeuturAeUzIGJ5x2Mdtas',
        authDomain: 'cris-database-da989.firebaseapp.com',
        projectId: 'cris-database-da989',
        storageBucket: 'cris-database-da989.firebasestorage.app',
        messagingSenderId: '627885439681',
        appId: '1:627885439681:android:05759fba51074480913240',
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
}

/// Opens a Hive box without changing its contents if opening fails.
Future<void> _openBox<T>(String name) async {
  try {
    await Hive.openBox<T>(name);
  } catch (error, stackTrace) {
    throw LocalDataOpenException(name, error, stackTrace);
  }
}

/// Backs up raw report files, then resets only report boxes after the user
/// explicitly confirms the action on the recovery screen.
Future<int> _resetLocalReports() async {
  await Hive.close();
  final copiedFiles = await backupLocalReportFiles(const [
    'reports',
    'sab_reports',
  ]);

  await Hive.deleteBoxFromDisk('reports');
  await Hive.deleteBoxFromDisk('sab_reports');
  await _initializeApp();
  return copiedFiles;
}

Future<void> _retryStartup() async {
  await Hive.close();
  await _initializeApp();
}

class LocalDataOpenException implements Exception {
  const LocalDataOpenException(this.boxName, this.cause, this.stackTrace);

  final String boxName;
  final Object cause;
  final StackTrace stackTrace;

  @override
  String toString() => 'Unable to open Hive box "$boxName": $cause';
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProfileNotifier()..load()),
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
