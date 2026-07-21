import 'dart:html' as html;

import 'csv_file.dart';

Future<SelectedCsvFile?> chooseCsv() async {
  final input = html.FileUploadInputElement()..accept = '.csv,text/csv';
  input.click();
  await input.onChange.first;
  final files = input.files;
  final file = files != null && files.length > 0 ? files[0] : null;
  if (file == null) return null;

  final reader = html.FileReader()..readAsText(file);
  await reader.onLoad.first;
  return SelectedCsvFile(name: file.name, text: reader.result as String);
}
