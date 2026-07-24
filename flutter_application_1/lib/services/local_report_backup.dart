import 'local_report_backup_stub.dart'
    if (dart.library.io) 'local_report_backup_io.dart' as platform;

/// Copies raw Hive report files before an explicit local-data reset.
///
/// On web, Hive is backed by browser storage and cannot be copied as files, so
/// the platform implementation returns zero copied files.
Future<int> backupLocalReportFiles(List<String> boxNames) =>
    platform.backupLocalReportFiles(boxNames);
