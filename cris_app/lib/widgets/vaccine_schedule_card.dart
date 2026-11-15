import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme.dart';

class VaccineScheduleCard extends StatefulWidget {
  const VaccineScheduleCard({super.key});

  @override
  State<VaccineScheduleCard> createState() => _VaccineScheduleCardState();
}

class _VaccineScheduleCardState extends State<VaccineScheduleCard> {
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDate = _dateOnly(DateTime.now());
  Future<DocumentSnapshot<Map<String, dynamic>>>? _trackerFuture;

  DocumentReference<Map<String, dynamic>>? get _trackerRef {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return FirebaseFirestore.instance
        .collection('user-info')
        .doc(user.uid)
        .collection('treatment_trackers')
        .doc('current');
  }

  @override
  void initState() {
    super.initState();
    _trackerFuture = _trackerRef?.get();
  }

  List<_DoseVisit> _doseVisitsFromPlan(Map<String, dynamic>? plan) {
    final rawDoses = plan?['doses'];
    if (rawDoses is! List) return const [];
    return rawDoses
        .whereType<Map>()
        .map((raw) => _DoseVisit.fromMap(Map<String, dynamic>.from(raw)))
        .whereType<_DoseVisit>()
        .toList();
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  Color _statusColor(_DoseStatus status) {
    switch (status) {
      case _DoseStatus.completed:
        return Colors.green;
      case _DoseStatus.today:
        return AppColors.accent;
      case _DoseStatus.upcoming:
        return Colors.orange;
    }
  }

  _DoseVisit? _doseOn(List<_DoseVisit> visits, DateTime day) {
    final date = _dateOnly(day);
    for (final dose in visits) {
      if (_dateOnly(dose.date) == date) return dose;
    }
    return null;
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ref = _trackerRef;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ref == null
            ? _TreatmentTrackerBody(
                selectedDate: _selectedDate,
                visibleMonth: _visibleMonth,
                onDateSelected: (date) => setState(() => _selectedDate = date),
                onMonthChanged: _changeMonth,
                doseOn: (day) => null,
                statusColor: _statusColor,
              )
            : FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: _trackerFuture,
                builder: (context, snapshot) {
                  final plan =
                      snapshot.data?.exists == true ? snapshot.data!.data() : null;
                  final visits = _doseVisitsFromPlan(plan);
                  return _TreatmentTrackerBody(
                    selectedDate: _selectedDate,
                    visibleMonth: _visibleMonth,
                    onDateSelected: (date) {
                      setState(() => _selectedDate = date);
                    },
                    onMonthChanged: _changeMonth,
                    doseOn: (day) => _doseOn(visits, day),
                    statusColor: _statusColor,
                  );
                },
              ),
      ),
    );
  }
}

class _TreatmentTrackerBody extends StatelessWidget {
  const _TreatmentTrackerBody({
    required this.selectedDate,
    required this.visibleMonth,
    required this.onDateSelected,
    required this.onMonthChanged,
    required this.doseOn,
    required this.statusColor,
  });

  final DateTime selectedDate;
  final DateTime visibleMonth;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<int> onMonthChanged;
  final _DoseVisit? Function(DateTime date) doseOn;
  final Color Function(_DoseStatus status) statusColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Treatment Tracker',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        _LockedCalendarGrid(
          visibleMonth: visibleMonth,
          selectedDate: selectedDate,
          doseOn: doseOn,
          statusColor: statusColor,
          onMonthChanged: onMonthChanged,
          onDateSelected: onDateSelected,
        ),
      ],
    );
  }
}

class _DoseVisit {
  const _DoseVisit({
    required this.daysFromStart,
    required this.date,
  });

  final int daysFromStart;
  final DateTime date;

  String get day => 'Day $daysFromStart';

  static _DoseVisit? fromMap(Map<String, dynamic> map) {
    final rawDate = map['date'];
    final DateTime? date;
    if (rawDate is Timestamp) {
      date = rawDate.toDate();
    } else if (rawDate is DateTime) {
      date = rawDate;
    } else {
      date = DateTime.tryParse(rawDate as String? ?? '');
    }
    if (date == null) return null;
    return _DoseVisit(
      daysFromStart:
          map['daysFromStart'] as int? ?? map['offset'] as int? ?? 0,
      date: date,
    );
  }

  _DoseStatus get status {
    final today = _VaccineScheduleCardState._dateOnly(DateTime.now());
    final visitDate = _VaccineScheduleCardState._dateOnly(date);
    if (visitDate.isBefore(today)) return _DoseStatus.completed;
    if (visitDate == today) return _DoseStatus.today;
    return _DoseStatus.upcoming;
  }
}

enum _DoseStatus { completed, today, upcoming }

class _LockedCalendarGrid extends StatelessWidget {
  const _LockedCalendarGrid({
    required this.visibleMonth,
    required this.selectedDate,
    required this.doseOn,
    required this.statusColor,
    required this.onMonthChanged,
    required this.onDateSelected,
  });

  final DateTime visibleMonth;
  final DateTime selectedDate;
  final _DoseVisit? Function(DateTime date) doseOn;
  final Color Function(_DoseStatus status) statusColor;
  final ValueChanged<int> onMonthChanged;
  final ValueChanged<DateTime> onDateSelected;

  static const _weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(visibleMonth.year, visibleMonth.month);
    final totalDays = DateUtils.getDaysInMonth(
      visibleMonth.year,
      visibleMonth.month,
    );
    final leadingBlanks = firstDay.weekday % 7;
    final totalCells = ((leadingBlanks + totalDays) / 7).ceil() * 7;

    return Column(
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Previous month',
              onPressed: () => onMonthChanged(-1),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                '${_monthName(visibleMonth.month)} ${visibleMonth.year}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Next month',
              onPressed: () => onMonthChanged(1),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 4),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 7,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.6,
          ),
          itemBuilder: (context, index) => Center(
            child: Text(
              _weekdays[index],
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.black45,
              ),
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: totalCells,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final dayNumber = index - leadingBlanks + 1;
            if (dayNumber < 1 || dayNumber > totalDays) {
              return const SizedBox.shrink();
            }
            final day = DateTime(
              visibleMonth.year,
              visibleMonth.month,
              dayNumber,
            );
            final dose = doseOn(day);
            final isSelected =
                _VaccineScheduleCardState._dateOnly(day) == selectedDate;
            final color = dose == null ? null : statusColor(dose.status);

            return Padding(
              padding: const EdgeInsets.all(3),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => onDateSelected(
                  _VaccineScheduleCardState._dateOnly(day),
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.5)
                          : Colors.transparent,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '$dayNumber',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              dose == null ? FontWeight.w500 : FontWeight.w800,
                          color: dose == null ? Colors.black87 : color,
                        ),
                      ),
                      if (dose != null)
                        Positioned(
                          bottom: 5,
                          child: Tooltip(
                            message: '${dose.day} - locked clinic visit',
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        const Row(
          children: [
            _LegendDot(color: Colors.green, label: 'Completed'),
            SizedBox(width: 12),
            _LegendDot(color: Colors.orange, label: 'Upcoming'),
            SizedBox(width: 12),
            _LegendDot(color: AppColors.accent, label: 'Today'),
          ],
        ),
      ],
    );
  }

  String _monthName(int month) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[month - 1];
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
      ],
    );
  }
}
