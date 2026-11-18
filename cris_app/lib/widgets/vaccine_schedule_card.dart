import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

import '../theme.dart';

class VaccineScheduleCard extends StatefulWidget {
  const VaccineScheduleCard({super.key});

  @override
  State<VaccineScheduleCard> createState() => _VaccineScheduleCardState();
}

class _VaccineScheduleCardState extends State<VaccineScheduleCard> {
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDate = _dateOnly(DateTime.now());
  List<_DoseVisit> _visits = const [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _patientsSubscription;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
      _listenForPatientSchedules,
    );
  }

  void _listenForPatientSchedules(User? user) {
    _patientsSubscription?.cancel();
    if (user == null) {
      if (mounted) setState(() => _visits = const []);
      return;
    }
    final userId = user.uid;
    _patientsSubscription = FirebaseFirestore.instance
        .collection('patients')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen(
      (snapshot) {
        if (FirebaseAuth.instance.currentUser?.uid != userId) return;
        final visits = snapshot.docs
            .expand(
              (document) => _DoseVisit.fromPatient(
                document.data(),
                document.id,
              ),
            )
            .toList();
        if (mounted) setState(() => _visits = visits);
      },
      onError: (_) {
        if (mounted) setState(() => _visits = const []);
      },
    );
  }

  @override
  void dispose() {
    _patientsSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  Color _statusColor(_DoseStatus status) {
    switch (status) {
      case _DoseStatus.completed:
        return Colors.green;
      case _DoseStatus.scheduled:
        return AppColors.accent;
      case _DoseStatus.overdue:
        return Colors.red;
    }
  }

  List<_DoseVisit> _dosesOn(List<_DoseVisit> visits, DateTime day) {
    final date = _dateOnly(day);
    return visits.where((dose) => _dateOnly(dose.date) == date).toList();
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    final monthDoses = _visits
        .where(
          (dose) =>
              dose.date.year == _visibleMonth.year &&
              dose.date.month == _visibleMonth.month,
        )
        .toList()
      ..sort((first, second) => first.date.compareTo(second.date));
    final showPatientNames = _visits.map((dose) => dose.patientName).toSet().length > 1;

    return Column(
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: _TreatmentTrackerBody(
              selectedDate: _selectedDate,
              visibleMonth: _visibleMonth,
              monthDoses: monthDoses,
              showPatientNames: showPatientNames,
              onDateSelected: (date) => setState(() => _selectedDate = date),
              onMonthChanged: _changeMonth,
              dosesOn: (day) => _dosesOn(_visits, day),
              statusColor: _statusColor,
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _TreatmentTrackerBody extends StatelessWidget {
  const _TreatmentTrackerBody({
    required this.selectedDate,
    required this.visibleMonth,
    required this.monthDoses,
    required this.showPatientNames,
    required this.onDateSelected,
    required this.onMonthChanged,
    required this.dosesOn,
    required this.statusColor,
  });

  final DateTime selectedDate;
  final DateTime visibleMonth;
  final List<_DoseVisit> monthDoses;
  final bool showPatientNames;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<int> onMonthChanged;
  final List<_DoseVisit> Function(DateTime date) dosesOn;
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
          monthDoses: monthDoses,
          showPatientNames: showPatientNames,
          dosesOn: dosesOn,
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
    required this.doseNumber,
    required this.date,
    required this.patientName,
    required this.isCompleted,
  });

  final int doseNumber;
  final DateTime date;
  final String patientName;
  final bool isCompleted;

  String get day => 'Day $doseNumber';

  static List<_DoseVisit> fromPatient(
    Map<String, dynamic> patient,
    String documentId,
  ) {
    final rawSchedule = patient['pepScheduleDates'];
    if (rawSchedule is! Map) return const [];
    final scheduledDates = <int, DateTime>{};
    for (final entry in rawSchedule.entries) {
      final doseNumber = _doseNumber(entry.key);
      final date = _date(entry.value);
      if (doseNumber != null && date != null) scheduledDates[doseNumber] = date;
    }
    if (scheduledDates.isEmpty) return const [];

    final completedDoses = <int>{};
    final rawCompleted = patient['completedDoses'];
    if (rawCompleted is List) {
      for (final value in rawCompleted) {
        final doseNumber = _doseNumber(value);
        if (doseNumber != null && scheduledDates.containsKey(doseNumber)) {
          completedDoses.add(doseNumber);
        }
      }
    }

    final rawPatient = patient['patient'];
    final patientMap = rawPatient is Map
        ? Map<String, dynamic>.from(rawPatient)
        : const <String, dynamic>{};
    final patientName = (patientMap['fullName'] ??
            patient['fullName'] ??
            patient['name'] ??
            documentId)
        .toString();
    final visits = scheduledDates.entries
        .map(
          (entry) => _DoseVisit(
            doseNumber: entry.key,
            date: entry.value,
            patientName: patientName,
            isCompleted: completedDoses.contains(entry.key),
          ),
        )
        .toList()
      ..sort((first, second) => first.doseNumber.compareTo(second.doseNumber));
    return visits;
  }

  static int? _doseNumber(Object? value) {
    if (value is! String) return null;
    final normalized = value.toLowerCase().replaceAll(
          RegExp(r'[^a-z0-9]'),
          '',
        );
    final match = RegExp(r'^day(\d+)$').firstMatch(normalized);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  static DateTime? _date(Object? value) {
    if (value is! String ||
        !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      return null;
    }
    final parts = value.split('-').map(int.tryParse).toList();
    if (parts.any((part) => part == null)) return null;
    final date = DateTime(parts[0]!, parts[1]!, parts[2]!);
    return date.year == parts[0] && date.month == parts[1] && date.day == parts[2]
        ? date
        : null;
  }

  _DoseStatus get status {
    final today = _VaccineScheduleCardState._dateOnly(DateTime.now());
    final visitDate = _VaccineScheduleCardState._dateOnly(date);
    if (isCompleted) return _DoseStatus.completed;
    if (visitDate.isBefore(today)) return _DoseStatus.overdue;
    return _DoseStatus.scheduled;
  }
}

enum _DoseStatus { completed, scheduled, overdue }

class _LockedCalendarGrid extends StatelessWidget {
  const _LockedCalendarGrid({
    required this.visibleMonth,
    required this.selectedDate,
    required this.monthDoses,
    required this.showPatientNames,
    required this.dosesOn,
    required this.statusColor,
    required this.onMonthChanged,
    required this.onDateSelected,
  });

  final DateTime visibleMonth;
  final DateTime selectedDate;
  final List<_DoseVisit> monthDoses;
  final bool showPatientNames;
  final List<_DoseVisit> Function(DateTime date) dosesOn;
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
            final doses = dosesOn(day);
            final isSelected =
                _VaccineScheduleCardState._dateOnly(day) == selectedDate;
            final color =
                doses.isEmpty ? null : statusColor(doses.first.status);

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
                  child: Semantics(
                    label: doses.isEmpty
                        ? '$dayNumber'
                        : '$dayNumber, ${doses.map(_doseDescription).join(', ')}',
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$dayNumber',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                doses.isEmpty ? FontWeight.w500 : FontWeight.w800,
                            color: doses.isEmpty ? Colors.black87 : color,
                          ),
                        ),
                        if (doses.isNotEmpty) ...[
                          const SizedBox(height: 1),
                          Tooltip(
                            message: doses.map(_doseDescription).join('\n'),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _doseTag(doses.first),
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        const Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _LegendDot(color: Colors.green, label: 'Done'),
            _LegendDot(color: AppColors.accent, label: 'Upcoming'),
            _LegendDot(color: Colors.red, label: 'Overdue'),
          ],
        ),
        _DoseDetails(
          doses: dosesOn(selectedDate),
          showPatientNames: showPatientNames,
        ),
        _MonthDoseList(
          doses: monthDoses,
          showPatientNames: showPatientNames,
          statusColor: statusColor,
        ),
      ],
    );
  }

  static String _doseTag(_DoseVisit dose) => 'D${dose.doseNumber}';

  static String _doseDescription(_DoseVisit dose) =>
      '${dose.day}, ${_doseStatusLabel(dose)}';

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

class _DoseDetails extends StatelessWidget {
  const _DoseDetails({required this.doses, required this.showPatientNames});

  final List<_DoseVisit> doses;
  final bool showPatientNames;

  @override
  Widget build(BuildContext context) {
    if (doses.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selected date',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          ...doses.map(
            (dose) => _DoseListRow(
              dose: dose,
              showPatientName: showPatientNames,
              showDate: false,
              statusColor: _statusColorFor(dose.status),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthDoseList extends StatelessWidget {
  const _MonthDoseList({
    required this.doses,
    required this.showPatientNames,
    required this.statusColor,
  });

  final List<_DoseVisit> doses;
  final bool showPatientNames;
  final Color Function(_DoseStatus status) statusColor;

  @override
  Widget build(BuildContext context) {
    if (doses.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Doses this month',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          ...doses.map(
            (dose) => _DoseListRow(
              dose: dose,
              showPatientName: showPatientNames,
              showDate: true,
              statusColor: statusColor(dose.status),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoseListRow extends StatelessWidget {
  const _DoseListRow({
    required this.dose,
    required this.showPatientName,
    required this.showDate,
    required this.statusColor,
  });

  final _DoseVisit dose;
  final bool showPatientName;
  final bool showDate;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final dateText = '${_monthShortName(dose.date.month)} ${dose.date.day}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              [
                if (showDate) dateText,
                dose.day,
                if (showPatientName) dose.patientName,
                _doseStatusLabel(dose),
              ].join(' · '),
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

Color _statusColorFor(_DoseStatus status) {
  switch (status) {
    case _DoseStatus.completed:
      return Colors.green;
    case _DoseStatus.scheduled:
      return AppColors.accent;
    case _DoseStatus.overdue:
      return Colors.red;
  }
}

String _doseStatusLabel(_DoseVisit dose) {
  final today = _VaccineScheduleCardState._dateOnly(DateTime.now());
  final labels = <String>[
    switch (dose.status) {
      _DoseStatus.completed => 'Done',
      _DoseStatus.scheduled => 'Upcoming',
      _DoseStatus.overdue => 'Overdue',
    },
  ];
  if (_VaccineScheduleCardState._dateOnly(dose.date) == today) {
    labels.add('Today');
  }
  return labels.join(' · ');
}

String _monthShortName(int month) {
  const names = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return names[month - 1];
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
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.black87),
        ),
      ],
    );
  }
}
