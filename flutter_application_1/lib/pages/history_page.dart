import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'View History',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Bite Reports'),
              Tab(text: 'SAB Reports'),
            ],
          ),
        ),
        body: currentUid == null
            ? const _EmptyState(message: 'Please sign in to view reports.')
            : TabBarView(
                children: [
                  _FirestoreReportsList(
                    collectionPath: 'bite_reports',
                    userId: currentUid,
                    emptyMessage: 'No bite reports found.',
                    icon: Icons.warning_amber_rounded,
                    iconColor: Color(0xFFEF5350),
                    iconBackground: Color(0xFFFFEBEB),
                    mapReport: _mapBiteReport,
                  ),
                  _FirestoreReportsList(
                    collectionPath: 'SAB_reports',
                    userId: currentUid,
                    emptyMessage: 'No suspicious animal behavior reports found.',
                    icon: Icons.shield_outlined,
                    iconColor: Color(0xFFFFA726),
                    iconBackground: Color(0xFFFFF3E0),
                    mapReport: _mapSABReport,
                  ),
                ],
              ),
      ),
    );
  }
}

class _FirestoreReportsList extends StatelessWidget {
  const _FirestoreReportsList({
    required this.collectionPath,
    required this.userId,
    required this.emptyMessage,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.mapReport,
  });

  final String collectionPath;
  final String userId;
  final String emptyMessage;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final _HistoryReport Function(QueryDocumentSnapshot<Map<String, dynamic>> doc)
      mapReport;

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection(collectionPath)
        .where('userId', isEqualTo: userId);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _EmptyState(
            message: 'Unable to load reports: ${snapshot.error}',
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = [...?snapshot.data?.docs];
        docs.sort((a, b) {
          final aTime = _timestampMillis(a.data()['createdAt']);
          final bTime = _timestampMillis(b.data()['createdAt']);
          return bTime.compareTo(aTime);
        });

        if (docs.isEmpty) return _EmptyState(message: emptyMessage);

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final report = mapReport(doc);
            return Dismissible(
              key: ValueKey('${collectionPath}_${doc.id}'),
              direction: DismissDirection.endToStart,
              confirmDismiss: (_) => _confirmDelete(context, report.title),
              onDismissed: (_) => doc.reference.delete(),
              background: _deleteBackground(),
              child: Card(
                elevation: 1,
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _showReportDetails(context, report),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: iconBackground,
                      child: Icon(icon, color: iconColor),
                    ),
                    title: Text(
                      report.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          report.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          report.date,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    trailing:
                        const Icon(Icons.chevron_right, color: Colors.grey),
                    isThreeLine: true,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

_HistoryReport _mapBiteReport(
  QueryDocumentSnapshot<Map<String, dynamic>> doc,
) {
  final data = doc.data();
  final patient = _mapValue(data['patient']);
  final incident = _mapValue(data['incident']);
  final animal = _mapValue(data['animal']);

  final patientName =
      _stringValue(patient['fullName'], fallback: data['fullName']);
  final animalSpecies =
      _stringValue(animal['species'], fallback: data['animalSpecies']);
  final exposureType =
      _stringValue(incident['exposureType'], fallback: data['exposureType']);
  final incidentDate =
      _stringValue(incident['date'], fallback: data['dateOfIncident']);
  final location =
      _stringValue(incident['location'], fallback: data['locationOfIncident']);
  final barangay = _stringValue(incident['barangay']);
  final municipality = _stringValue(incident['municipality']);

  return _HistoryReport(
    title: patientName.isEmpty ? 'Bite Report' : patientName,
    subtitle: [
      exposureType,
      animalSpecies,
    ].where((value) => value.isNotEmpty).join(' - '),
    location: _joinLocation(location, barangay, municipality),
    date: incidentDate.isEmpty ? 'No date provided' : incidentDate,
    details: {
      'Report Type': 'Bite Report',
      'Patient': patientName,
      'Exposure': exposureType,
      'Animal Species': animalSpecies,
      'Incident Date': incidentDate,
      'Location': _joinLocation(location, barangay, municipality),
      'Status': _stringValue(data['status']),
    },
  );
}

_HistoryReport _mapSABReport(
  QueryDocumentSnapshot<Map<String, dynamic>> doc,
) {
  final data = doc.data();
  final reporter = _stringValue(data['fullName']);
  final behavior = _stringValue(data['behaviorObserved']);
  final date = _stringValue(data['dateOfObservation']);
  final location = _stringValue(data['location']);
  final barangay = _stringValue(data['barangay']);
  final municipality = _stringValue(data['municipality']);

  return _HistoryReport(
    title: reporter.isEmpty ? 'SAB Report' : reporter,
    subtitle: behavior.isEmpty
        ? _stringValue(data['description'], fallback: 'Suspicious behavior')
        : behavior,
    location: _joinLocation(location, barangay, municipality),
    date: date.isEmpty ? 'No date provided' : date,
    details: {
      'Report Type': 'Suspicious Animal Behavior',
      'Reporter': reporter,
      'Behavior': behavior,
      'Observation Date': date,
      'Location': _joinLocation(location, barangay, municipality),
      'Latitude': _stringValue(data['latitude']),
      'Longitude': _stringValue(data['longitude']),
      'Status': _stringValue(data['reportStatus']),
    },
  );
}

Future<bool> _confirmDelete(BuildContext context, String name) async {
  return await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete Report'),
          content: Text('Remove "$name"? This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              child: const Text('Delete'),
            ),
          ],
        ),
      ) ??
      false;
}

void _showReportDetails(BuildContext context, _HistoryReport report) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (_) => SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        shrinkWrap: true,
        children: [
          Text(
            report.title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          ...report.details.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value.toString().trim().isEmpty
                          ? 'Not provided'
                          : entry.value.toString(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _deleteBackground() => Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: AppColors.danger,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delete_outline, color: Colors.white, size: 26),
          SizedBox(height: 4),
          Text(
            'Delete',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

Map<String, dynamic> _mapValue(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return {};
}

String _stringValue(Object? value, {Object? fallback}) {
  final actual = value ?? fallback;
  if (actual == null) return '';
  return actual.toString().trim();
}

String _joinLocation(String location, String barangay, String municipality) {
  return [
    location,
    barangay,
    municipality,
  ].where((value) => value.trim().isNotEmpty).join(', ');
}

int _timestampMillis(Object? value) {
  if (value is Timestamp) return value.millisecondsSinceEpoch;
  if (value is DateTime) return value.millisecondsSinceEpoch;
  return 0;
}

class _HistoryReport {
  const _HistoryReport({
    required this.title,
    required this.subtitle,
    required this.location,
    required this.date,
    required this.details,
  });

  final String title;
  final String subtitle;
  final String location;
  final String date;
  final Map<String, String> details;
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.folder_open_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
