// Run manually for a one-time import only:
// flutter run -d chrome -t tool/import_abtcs_web.dart
//
// This is intentionally not imported by the mobile application. It uses the
// existing Firebase web configuration and writes only after user confirmation.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'src/csv_picker_stub.dart'
    if (dart.library.html) 'src/csv_picker_web.dart' as csv_picker;

const _requiredColumns = <String>[
  'Name',
  'Tel_No',
  'Email',
  'Street',
  'Municipality',
  'Latitude',
  'Longitude',
  'Availability',
  'Done',
];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    runApp(const _WebOnlyApp());
    return;
  }
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
  runApp(const _AbtcImporterApp());
}

class _WebOnlyApp extends StatelessWidget {
  const _WebOnlyApp();

  @override
  Widget build(BuildContext context) => const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'This one-time importer must be run in Chrome:\n\n'
                'flutter run -d chrome -t tool/import_abtcs_web.dart',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
}

class _AbtcImporterApp extends StatelessWidget {
  const _AbtcImporterApp();

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ABTC CSV Importer',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFEA6113)),
          useMaterial3: true,
        ),
        home: const _AbtcImporterPage(),
      );
}

class _AbtcImporterPage extends StatefulWidget {
  const _AbtcImporterPage();

  @override
  State<_AbtcImporterPage> createState() => _AbtcImporterPageState();
}

class _AbtcImporterPageState extends State<_AbtcImporterPage> {
  final _firestore = FirebaseFirestore.instance;
  final _email = TextEditingController();
  final _password = TextEditingController();
  List<_AbtcRecord> _records = const [];
  List<String> _invalidRows = const [];
  _ImportSummary? _summary;
  String? _fileName;
  String? _error;
  bool _preparing = false;
  bool _uploading = false;
  bool _signingIn = false;
  String? _success;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _signingIn = true;
      _error = null;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
      if (mounted) setState(() {});
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _error = 'Sign in failed: ${error.message ?? error.code}');
    } finally {
      if (mounted) setState(() => _signingIn = false);
    }
  }

  Future<void> _chooseCsv() async {
    if (!kIsWeb) {
      setState(() {
        _error = 'This one-time importer must be run in Chrome. Use: '
            'flutter run -d chrome -t tool/import_abtcs_web.dart';
      });
      return;
    }
    final file = await csv_picker.chooseCsv();
    if (file == null) return;

    setState(() {
      _preparing = true;
      _records = const [];
      _invalidRows = const [];
      _summary = null;
      _fileName = file.name;
      _error = null;
      _success = null;
    });

    try {
      final parsed = _parseImport(file.text);
      if (!mounted) return;
      setState(() {
        _records = parsed.records;
        _invalidRows = parsed.invalidRows;
      });
      final existing = await Future.wait(
        parsed.records.map(
          (record) => _firestore.collection('abtcs').doc(record.documentId).get(),
        ),
      );
      if (!mounted) return;
      setState(() {
        _summary = _ImportSummary(
          totalRows: parsed.totalRows,
          validRows: parsed.records.length,
          invalidRows: parsed.invalidRows.length,
          existingDocuments: existing.where((document) => document.exists).length,
        );
      });
    } on FormatException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Unable to prepare the import: $error');
    } finally {
      if (mounted) setState(() => _preparing = false);
    }
  }

  Future<void> _confirmAndUpload() async {
    final summary = _summary;
    if (summary == null || _records.isEmpty || _uploading) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Firestore import'),
        content: Text(
          'This will write ${summary.validRows} real CSV records to the existing '
          '`abtcs` collection. ${summary.existingDocuments} document(s) will be '
          'updated and ${summary.newDocuments} new document(s) will be created. '
          'Invalid rows will not be uploaded.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Upload real records'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _uploading = true;
      _error = null;
      _success = null;
    });
    try {
      // Firestore batches support up to 500 operations. This also keeps the
      // utility safe if a later CSV contains more real records.
      for (var start = 0; start < _records.length; start += 450) {
        final end = start + 450 > _records.length ? _records.length : start + 450;
        final batch = _firestore.batch();
        for (final record in _records.sublist(start, end)) {
          batch.set(
            _firestore.collection('abtcs').doc(record.documentId),
            record.toFirestore(),
            SetOptions(merge: true),
          );
        }
        await batch.commit();
      }
      if (!mounted) return;
      setState(() {
        _success = 'Import complete: ${_records.length} valid CSV rows were written '
            'to `abtcs`. ${_invalidRows.length} invalid row(s) were skipped.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Import failed: $error');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('One-time ABTC/ABC CSV Importer')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (FirebaseAuth.instance.currentUser == null) ...[
                const Text(
                  'Sign in with an existing authorized CRIS account before reading '
                  'or writing the existing Firestore collection.',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email address'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _signingIn ? null : _signIn,
                  child: Text(_signingIn ? 'Signing in...' : 'Sign in'),
                ),
              ] else ...[
                Text('Signed in as ${FirebaseAuth.instance.currentUser!.email ?? 'authorized user'}'),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (mounted) setState(() {});
                    },
                    child: const Text('Sign out'),
                  ),
                ),
              const Text(
                'Choose the real ABTC/ABC CSV. Nothing is uploaded until you review '
                'the Firestore summary and confirm the import.',
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _preparing || _uploading ? null : _chooseCsv,
                icon: const Icon(Icons.upload_file_outlined),
                label: Text(_preparing ? 'Preparing summary...' : 'Choose CSV file'),
              ),
              if (_fileName != null) ...[
                const SizedBox(height: 16),
                Text('Selected file: $_fileName'),
              ],
              if (_summary != null) ...[
                const SizedBox(height: 20),
                _SummaryCard(summary: _summary!),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _uploading ? null : _confirmAndUpload,
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: Text(_uploading ? 'Uploading...' : 'Review and confirm upload'),
                ),
              ],
              if (_invalidRows.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text('Skipped invalid rows', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ..._invalidRows.map((message) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(message),
                    )),
              ],
              if (_success != null) ...[
                const SizedBox(height: 20),
                Text(_success!, style: const TextStyle(color: Colors.green)),
              ],
              ],
              if (_error != null) ...[
                const SizedBox(height: 20),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
            ],
          ),
        ),
      );
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final _ImportSummary summary;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Import summary', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              _line('Total CSV rows', summary.totalRows),
              _line('Valid rows', summary.validRows),
              _line('Invalid rows (skipped)', summary.invalidRows),
              _line('Rows to upload', summary.validRows),
              _line('Existing documents to update', summary.existingDocuments),
              _line('New documents to create', summary.newDocuments),
            ],
          ),
        ),
      );

  Widget _line(String label, int value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text('$label: $value'),
      );
}

class _ImportSummary {
  const _ImportSummary({
    required this.totalRows,
    required this.validRows,
    required this.invalidRows,
    required this.existingDocuments,
  });

  final int totalRows;
  final int validRows;
  final int invalidRows;
  final int existingDocuments;
  int get newDocuments => validRows - existingDocuments;
}

class _ParsedImport {
  const _ParsedImport({
    required this.totalRows,
    required this.records,
    required this.invalidRows,
  });

  final int totalRows;
  final List<_AbtcRecord> records;
  final List<String> invalidRows;
}

class _Candidate {
  const _Candidate({
    required this.csvRow,
    required this.name,
    required this.telNo,
    required this.email,
    required this.street,
    required this.municipality,
    required this.latitude,
    required this.longitude,
    required this.availability,
  });

  final int csvRow;
  final String name;
  final String telNo;
  final String email;
  final String street;
  final String municipality;
  final double latitude;
  final double longitude;
  final String availability;
}

class _AbtcRecord extends _Candidate {
  const _AbtcRecord({
    required super.csvRow,
    required super.name,
    required super.telNo,
    required super.email,
    required super.street,
    required super.municipality,
    required super.latitude,
    required super.longitude,
    required super.availability,
    required this.documentId,
  });

  final String documentId;

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'telNo': telNo,
        'email': email,
        'street': street,
        'municipality': municipality,
        'latitude': latitude,
        'longitude': longitude,
        'availability': availability,
      };
}

_ParsedImport _parseImport(String source) {
  final rows = _parseCsv(source);
  if (rows.isEmpty) throw const FormatException('The CSV file is empty.');

  final headers = rows.first;
  if (headers.isNotEmpty) headers[0] = headers.first.replaceFirst('\uFEFF', '');
  final missing = _requiredColumns.where((column) => !headers.contains(column)).toList();
  if (missing.isNotEmpty) {
    throw FormatException('CSV is missing required column(s): ${missing.join(', ')}.');
  }
  final index = {for (var i = 0; i < headers.length; i++) headers[i]: i};
  String value(List<String> row, String column) {
    final columnIndex = index[column]!;
    return columnIndex < row.length ? row[columnIndex] : '';
  }

  final invalidRows = <String>[];
  final candidates = <_Candidate>[];
  for (var rowIndex = 1; rowIndex < rows.length; rowIndex++) {
    final row = rows[rowIndex];
    final csvRow = rowIndex + 1;
    final name = value(row, 'Name');
    final latitudeText = value(row, 'Latitude');
    final longitudeText = value(row, 'Longitude');
    final latitude = double.tryParse(latitudeText.trim());
    final longitude = double.tryParse(longitudeText.trim());
    final errors = <String>[];
    if (name.trim().isEmpty) errors.add('Name is missing');
    if (latitude == null || !latitude.isFinite) {
      errors.add('Latitude is not a valid numeric value: "$latitudeText"');
    }
    if (longitude == null || !longitude.isFinite) {
      errors.add('Longitude is not a valid numeric value: "$longitudeText"');
    }
    if (errors.isNotEmpty) {
      invalidRows.add('CSV row $csvRow: ${errors.join('; ')}.');
      continue;
    }
    final validLatitude = latitude!;
    final validLongitude = longitude!;
    candidates.add(_Candidate(
      csvRow: csvRow,
      name: name,
      telNo: value(row, 'Tel_No'),
      email: value(row, 'Email'),
      street: value(row, 'Street'),
      municipality: value(row, 'Municipality'),
      latitude: validLatitude,
      longitude: validLongitude,
      availability: value(row, 'Availability'),
    ));
  }

  final nameCounts = <String, int>{};
  for (final candidate in candidates) {
    final baseId = _slug(candidate.name);
    if (baseId.isNotEmpty) nameCounts[baseId] = (nameCounts[baseId] ?? 0) + 1;
  }
  final records = <_AbtcRecord>[];
  for (final candidate in candidates) {
    final baseId = _slug(candidate.name);
    if (baseId.isEmpty) {
      invalidRows.add('CSV row ${candidate.csvRow}: Name cannot form a document ID.');
      continue;
    }
    final documentId = nameCounts[baseId] == 1
        ? baseId
        : '$baseId--${_slug(candidate.municipality)}--${_slug(candidate.street)}'
            '--${_coordinateToken(candidate.latitude)}-${_coordinateToken(candidate.longitude)}';
    records.add(_AbtcRecord(
      csvRow: candidate.csvRow,
      name: candidate.name,
      telNo: candidate.telNo,
      email: candidate.email,
      street: candidate.street,
      municipality: candidate.municipality,
      latitude: candidate.latitude,
      longitude: candidate.longitude,
      availability: candidate.availability,
      documentId: documentId,
    ));
  }
  return _ParsedImport(
    totalRows: rows.length - 1,
    records: records,
    invalidRows: invalidRows,
  );
}

String _slug(String value) {
  final buffer = StringBuffer();
  var previousWasDash = false;
  for (final codeUnit in value.trim().toLowerCase().codeUnits) {
    final isLetter = codeUnit >= 97 && codeUnit <= 122;
    final isDigit = codeUnit >= 48 && codeUnit <= 57;
    if (isLetter || isDigit) {
      buffer.writeCharCode(codeUnit);
      previousWasDash = false;
    } else if (!previousWasDash && buffer.length > 0) {
      buffer.write('-');
      previousWasDash = true;
    }
  }
  return buffer.toString().replaceFirst(RegExp(r'-$'), '');
}

String _coordinateToken(double value) => value
    .toString()
    .replaceAll('-', 'negative-')
    .replaceAll('.', 'point-');

List<List<String>> _parseCsv(String source) {
  final rows = <List<String>>[];
  var row = <String>[];
  var field = StringBuffer();
  var quoted = false;
  for (var i = 0; i < source.length; i++) {
    final char = source[i];
    if (char == '"') {
      if (quoted && i + 1 < source.length && source[i + 1] == '"') {
        field.write('"');
        i++;
      } else {
        quoted = !quoted;
      }
    } else if (char == ',' && !quoted) {
      row.add(field.toString());
      field = StringBuffer();
    } else if ((char == '\n' || char == '\r') && !quoted) {
      if (char == '\r' && i + 1 < source.length && source[i + 1] == '\n') i++;
      row.add(field.toString());
      rows.add(row);
      row = <String>[];
      field = StringBuffer();
    } else {
      field.write(char);
    }
  }
  if (field.length > 0 || row.isNotEmpty) {
    row.add(field.toString());
    rows.add(row);
  }
  if (quoted) throw const FormatException('CSV contains an unclosed quoted value.');
  return rows;
}
