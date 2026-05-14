import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/report.dart';
import '../models/sab_report.dart';
import '../theme.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
        body: TabBarView(children: [_BiteReportsList(), _SABReportsList()]),
      ),
    );
  }
}

class _BiteReportsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Report>('reports').listenable(),
      builder: (_, Box<Report> box, __) {
        if (box.isEmpty) {
          return const _EmptyState(message: 'No bite reports submitted yet.');
        }
        final reports = box.values.toList().reversed.toList();
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: reports.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final r = reports[i];
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFEBEB),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFEF5350),
                  ),
                ),
                title: Text(
                  r.fullName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${r.exposureType} — ${r.animalSpecies}'),
                    Text(
                      r.locationOfIncident,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      r.dateOfIncident,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }
}

class _SABReportsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<SABReport>('sab_reports').listenable(),
      builder: (_, Box<SABReport> box, __) {
        if (box.isEmpty) {
          return const _EmptyState(
            message: 'No suspicious animal behavior reports yet.',
          );
        }
        final reports = box.values.toList().reversed.toList();
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: reports.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final r = reports[i];
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFF3E0),
                  child: Icon(Icons.shield_outlined, color: Color(0xFFFFA726)),
                ),
                title: Text(
                  r.fullName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.behaviorObserved),
                    Text(
                      r.location,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      r.dateOfObservation,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.folder_open_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
