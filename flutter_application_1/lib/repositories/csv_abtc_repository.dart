import 'package:flutter/services.dart';

import '../models/abtc_model.dart';
import 'abtc_repository.dart';

typedef AssetStringLoader = Future<String> Function(String assetPath);

/// Loads bundled ABTC/ABC locations without requiring a network connection.
class CsvABTCRepository implements ABTCRepository {
  CsvABTCRepository({
    this.assetPath = _defaultAssetPath,
    AssetStringLoader? loadString,
  }) : _loadString = loadString ?? rootBundle.loadString;

  static const _defaultAssetPath = 'assets/documents/ABTC_ABC-Coordinates.csv';
  static const _requiredHeaders = {'name', 'latitude', 'longitude'};

  final String assetPath;
  final AssetStringLoader _loadString;

  @override
  Future<List<ABTCModel>> fetchABTCs() async {
    final rows = _parseCsv(await _loadString(assetPath));
    if (rows.isEmpty) return const [];

    final headers = rows.first.map(_normaliseHeader).toList(growable: false);
    final missingHeaders =
        _requiredHeaders.where((header) => !headers.contains(header)).toList();
    if (missingHeaders.isNotEmpty) {
      throw FormatException(
        'The ABTC CSV is missing required column(s): ${missingHeaders.join(', ')}.',
      );
    }

    final locations = <ABTCModel>[];
    for (var rowIndex = 1; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];
      final values = <String, String>{
        for (var column = 0; column < headers.length; column++)
          headers[column]: column < row.length ? row[column].trim() : '',
      };
      final location = ABTCModel.fromCsv(values, rowIndex + 1);
      if (values['name']!.isEmpty || !location.hasCoordinates) continue;
      locations.add(location);
    }
    return locations;
  }

  String _normaliseHeader(String header) =>
      header.replaceFirst('\uFEFF', '').trim().toLowerCase();

  List<List<String>> _parseCsv(String source) {
    final rows = <List<String>>[];
    var row = <String>[];
    var field = StringBuffer();
    var quoted = false;

    for (var index = 0; index < source.length; index++) {
      final character = source[index];
      if (character == '"') {
        if (quoted && index + 1 < source.length && source[index + 1] == '"') {
          field.write('"');
          index++;
        } else {
          quoted = !quoted;
        }
      } else if (character == ',' && !quoted) {
        row.add(field.toString());
        field = StringBuffer();
      } else if ((character == '\n' || character == '\r') && !quoted) {
        if (character == '\r' &&
            index + 1 < source.length &&
            source[index + 1] == '\n') {
          index++;
        }
        row.add(field.toString());
        rows.add(row);
        row = <String>[];
        field = StringBuffer();
      } else {
        field.write(character);
      }
    }

    if (quoted) {
      throw const FormatException('The ABTC CSV has an unclosed quoted value.');
    }
    if (field.isNotEmpty || row.isNotEmpty) {
      row.add(field.toString());
      rows.add(row);
    }
    return rows;
  }
}
