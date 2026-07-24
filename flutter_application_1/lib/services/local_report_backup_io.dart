import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Stores a raw copy of report boxes in the app documents directory.
/// The files remain local and are not uploaded anywhere.
Future<int> backupLocalReportFiles(List<String> boxNames) async {
  final appDirectory = await getApplicationDocumentsDirectory();
  final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
  final backupDirectory = Directory(
    '${appDirectory.path}${Platform.pathSeparator}cris_report_backups'
    '${Platform.pathSeparator}$timestamp',
  );

  var copiedFiles = 0;
  for (final boxName in boxNames) {
    final source = File(
      '${appDirectory.path}${Platform.pathSeparator}$boxName.hive',
    );
    if (!await source.exists()) continue;

    await backupDirectory.create(recursive: true);
    await source.copy(
      '${backupDirectory.path}${Platform.pathSeparator}$boxName.hive',
    );
    copiedFiles++;
  }
  return copiedFiles;
}
