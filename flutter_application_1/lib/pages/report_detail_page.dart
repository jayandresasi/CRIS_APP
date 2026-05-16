import 'dart:io';
import 'package:flutter/material.dart';
import '../models/report.dart';
import '../models/sab_report.dart';
import '../theme.dart';

// ── Entry points ──────────────────────────────────────────────────────────────

class BiteReportDetailPage extends StatelessWidget {
  final Report report;
  const BiteReportDetailPage({super.key, required this.report});

  @override
  Widget build(BuildContext context) => _DetailScaffold(
        title: 'Bite Report',
        accentColor: const Color(0xFFEF5350),
        iconData: Icons.warning_amber_rounded,
        headerTitle: report.fullName,
        headerSubtitle: '${report.exposureType} — ${report.animalSpecies}',
        reportedAt: report.reportedAt,
        sections: [
          _Section('Patient Information', [
            _Field('Last Name', report.lastName),
            _Field('First Name', report.firstName),
            if (report.middleInitial.isNotEmpty)
              _Field('Middle Initial', report.middleInitial),
            if (report.suffix.isNotEmpty) _Field('Suffix', report.suffix),
            _Field('Age', report.age),
            _Field('Gender', report.gender),
            _Field('Contact Number', report.contactNumber),
            _Field('Address', report.address),
          ]),
          _Section('Incident Details', [
            _Field('Date of Incident', report.dateOfIncident),
            _Field('Time of Incident', report.timeOfIncident),
            _Field('Location', report.locationOfIncident),
            _Field('Type of Exposure', report.exposureType),
            _Field('Animal Species', report.animalSpecies),
            _Field('Animal Ownership', report.animalOwnership),
            _Field('Animal Vaccination Status', report.animalVaccinationStatus),
            _Field('Description', report.incidentDescription, multiline: true),
          ]),
          _Section('Medical Information', [
            _Field('First Aid Given', report.firstAidGiven),
            _Field(
                'Patient Vaccination Status', report.patientVaccinationStatus),
          ]),
        ],
      );
}

class SABReportDetailPage extends StatelessWidget {
  final SABReport report;
  const SABReportDetailPage({super.key, required this.report});

  @override
  Widget build(BuildContext context) => _DetailScaffold(
        title: 'SAB Report',
        accentColor: const Color(0xFFFFA726),
        iconData: Icons.shield_outlined,
        headerTitle: report.fullName,
        headerSubtitle: report.behaviorObserved,
        reportedAt: report.reportedAt,
        photoPath: report.photoPath.isNotEmpty ? report.photoPath : null,
        sections: [
          _Section('Reporter Information', [
            _Field('Last Name', report.lastName),
            _Field('First Name', report.firstName),
            if (report.middleInitial.isNotEmpty)
              _Field('Middle Initial', report.middleInitial),
            if (report.suffix.isNotEmpty) _Field('Suffix', report.suffix),
            _Field('Contact Number', report.contactNumber),
            _Field('Address', report.address),
          ]),
          _Section('Observation Details', [
            _Field('Date of Observation', report.dateOfObservation),
            _Field('Time of Observation', report.timeOfObservation),
            _Field('Location', report.location),
            _Field('Behavior Observed', report.behaviorObserved),
            _Field('Description', report.description, multiline: true),
            if (report.latitude != null && report.longitude != null)
              _Field(
                'GPS Coordinates',
                '${report.latitude!.toStringAsFixed(6)}, ${report.longitude!.toStringAsFixed(6)}',
              ),
          ]),
        ],
      );
}

// ── Internal data models ──────────────────────────────────────────────────────

class _Section {
  final String title;
  final List<_Field> fields;
  const _Section(this.title, this.fields);
}

class _Field {
  final String label;
  final String value;
  final bool multiline;
  const _Field(this.label, this.value, {this.multiline = false});
}

// ── Shared scaffold ───────────────────────────────────────────────────────────

class _DetailScaffold extends StatelessWidget {
  final String title;
  final Color accentColor;
  final IconData iconData;
  final String headerTitle;
  final String headerSubtitle;
  final DateTime reportedAt;
  final String? photoPath;
  final List<_Section> sections;

  const _DetailScaffold({
    required this.title,
    required this.accentColor,
    required this.iconData,
    required this.headerTitle,
    required this.headerSubtitle,
    required this.reportedAt,
    required this.sections,
    this.photoPath,
  });

  String _formatReportedAt() {
    final d = reportedAt;
    final date =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final hour = d.hour > 12
        ? d.hour - 12
        : d.hour == 0
            ? 12
            : d.hour;
    final minute = d.minute.toString().padLeft(2, '0');
    final period = d.hour >= 12 ? 'PM' : 'AM';
    return '$date  $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // ── Header card ───────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8ECF0)),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: accentColor.withOpacity(0.12),
                  child: Icon(iconData, color: accentColor, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        headerTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        headerSubtitle,
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_outlined,
                            size: 12,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Submitted ${_formatReportedAt()}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Photo (SAB only) ──────────────────────────────────────
          if (photoPath != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(photoPath!),
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F6F8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image_outlined,
                          size: 40, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Photo unavailable',
                          style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
          ],

          // ── Sections ──────────────────────────────────────────────
          ...sections.map((section) => _SectionCard(section: section)),
        ],
      ),
    );
  }
}

// ── Section card ──────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final _Section section;
  const _SectionCard({required this.section});

  @override
  Widget build(BuildContext context) {
    // Filter out empty fields
    final fields =
        section.fields.where((f) => f.value.trim().isNotEmpty).toList();
    if (fields.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 20, 0, 10),
          child: Text(
            section.title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: 0.4,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8ECF0)),
          ),
          child: Column(
            children: [
              for (int i = 0; i < fields.length; i++) ...[
                _FieldRow(field: fields[i]),
                if (i < fields.length - 1)
                  const Divider(height: 1, indent: 16, endIndent: 16),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ── Field row ─────────────────────────────────────────────────────────────────

class _FieldRow extends StatelessWidget {
  final _Field field;
  const _FieldRow({required this.field});

  @override
  Widget build(BuildContext context) {
    if (field.multiline) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              field.label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              field.value,
              style: const TextStyle(
                  fontSize: 14, color: Colors.black87, height: 1.5),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              field.label,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              field.value,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
