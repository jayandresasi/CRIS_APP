import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../theme.dart';

class VaccineScheduleCard extends StatefulWidget {
  const VaccineScheduleCard({super.key});

  @override
  State<VaccineScheduleCard> createState() => _VaccineScheduleCardState();
}

class _VaccineScheduleCardState extends State<VaccineScheduleCard> {
  DateTime _selectedDate = DateTime.now();
  bool _calendarReady = false;

  // Standard anti-rabies PEP schedule offsets
  static const _doseOffsets = [0, 3, 7, 14, 28];

  DateTime? get _startDate {
    final raw = Hive.box('settings').get('vaccine_start_date') as String?;
    return raw != null ? DateTime.tryParse(raw) : null;
  }

  List<Map<String, dynamic>> get _schedule {
    final start = _startDate;
    if (start == null) return [];
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    return _doseOffsets.map((offset) {
      final doseDate = start.add(Duration(days: offset));
      final doseDateOnly = DateTime(
        doseDate.year,
        doseDate.month,
        doseDate.day,
      );
      final String status;
      if (doseDateOnly.isBefore(today)) {
        status = 'completed';
      } else if (doseDateOnly == today) {
        status = 'today';
      } else {
        status = 'upcoming';
      }
      return {'day': 'Day $offset', 'date': doseDate, 'status': status};
    }).toList();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'today':
        return AppColors.accent;
      default:
        return AppColors.secondary;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'today':
        return Icons.today;
      default:
        return Icons.calendar_today;
    }
  }

  Future<void> _setStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Select Day 0 — date of first dose',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      await Hive.box(
        'settings',
      ).put('vaccine_start_date', picked.toIso8601String().split('T').first);
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    // Defer heavy CalendarDatePicker off the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _calendarReady = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final start = _startDate;
    final schedule = _schedule;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Vaccine Schedule',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _setStartDate,
                  icon: const Icon(
                    Icons.edit_calendar_outlined,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    start == null ? 'Set Start Date' : 'Change',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),

            // ── No start date set ────────────────────────────────
            if (start == null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.cream.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.accent.withOpacity(0.4)),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.secondary,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tap "Set Start Date" to enter your Day 0 '
                        'vaccine date and track your schedule.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // ── Dose chips ──────────────────────────────────────
              const SizedBox(height: 4),
              Text(
                'Day 0: ${start.year}-'
                '${start.month.toString().padLeft(2, '0')}-'
                '${start.day.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: schedule.map((dose) {
                    final status = dose['status'] as String;
                    final date = dose['date'] as DateTime;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 14,
                        ),
                        constraints: const BoxConstraints(minWidth: 88),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: _statusColor(status).withOpacity(0.1),
                          border: Border.all(
                            color: _statusColor(status).withOpacity(0.4),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _statusIcon(status),
                              color: _statusColor(status),
                              size: 20,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dose['day'] as String,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: _statusColor(status),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${date.month}/${date.day}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // ── Calendar ─────────────────────────────────────────
            SizedBox(
              height: 320,
              child: _calendarReady
                  ? CalendarDatePicker(
                      initialDate: _selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      onDateChanged: (d) => setState(() => _selectedDate = d),
                    )
                  : const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2,
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              'Selected: ${_selectedDate.year}-'
              '${_selectedDate.month.toString().padLeft(2, '0')}-'
              '${_selectedDate.day.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}