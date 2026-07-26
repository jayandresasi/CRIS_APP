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
    // The treatment plan is only changed through this card, so a one-time
    // fetch avoids keeping a Firestore listener open while the dashboard is
    // displayed. The future is replaced after a successful save below.
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

  Future<void> _openAddTreatmentDialog() async {
    final ref = _trackerRef;
    if (ref == null) {
      _showSnackBar('Please sign in before adding a treatment tracker.');
      return;
    }
    final user = FirebaseAuth.instance.currentUser!;
    String defaultPatientName = '';
    try {
      final profileSnapshot = await FirebaseFirestore.instance
          .collection('user-info')
          .doc(user.uid)
          .get();
      defaultPatientName =
          (profileSnapshot.data()?['fullName'] as String? ?? '').trim();
    } catch (_) {
      defaultPatientName = '';
    }
    if (!mounted) return;

    final generated = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AddTreatmentDialog(defaultPatientName: defaultPatientName),
    );
    if (generated == null || !mounted) return;

    try {
      await ref.set({
        ...generated,
        'userId': user.uid,
        'storage': 'firebase',
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final startDate =
          DateTime.tryParse(generated['startDate'] as String? ?? '');
      setState(() {
        _trackerFuture = ref.get();
        if (startDate != null) {
          _selectedDate = _dateOnly(startDate);
          _visibleMonth = DateTime(startDate.year, startDate.month);
        }
      });
    } on FirebaseException catch (e) {
      _showSnackBar(e.message ?? 'Unable to save treatment tracker.');
    } catch (e) {
      _showSnackBar('Unable to save treatment tracker: $e');
    }
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
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

  IconData _statusIcon(_DoseStatus status) {
    switch (status) {
      case _DoseStatus.completed:
        return Icons.check_circle;
      case _DoseStatus.today:
        return Icons.event_available;
      case _DoseStatus.upcoming:
        return Icons.lock_clock_outlined;
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

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
                plan: null,
                visits: const [],
                selectedDate: _selectedDate,
                visibleMonth: _visibleMonth,
                isSignedIn: false,
                onAdd: _openAddTreatmentDialog,
                onDateSelected: (date) => setState(() => _selectedDate = date),
                onMonthChanged: _changeMonth,
                doseOn: (day) => null,
                statusColor: _statusColor,
                statusIcon: _statusIcon,
                formatDate: _formatDate,
              )
            : FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: _trackerFuture,
                builder: (context, snapshot) {
                  final plan =
                      snapshot.data?.exists == true ? snapshot.data!.data() : null;
                  final visits = _doseVisitsFromPlan(plan);
                  return _TreatmentTrackerBody(
                    plan: plan,
                    visits: visits,
                    selectedDate: _selectedDate,
                    visibleMonth: _visibleMonth,
                    isSignedIn: true,
                    isLoading: snapshot.connectionState ==
                            ConnectionState.waiting &&
                        !snapshot.hasData,
                    onAdd: _openAddTreatmentDialog,
                    onDateSelected: (date) {
                      setState(() => _selectedDate = date);
                    },
                    onMonthChanged: _changeMonth,
                    doseOn: (day) => _doseOn(visits, day),
                    statusColor: _statusColor,
                    statusIcon: _statusIcon,
                    formatDate: _formatDate,
                  );
                },
              ),
      ),
    );
  }
}

class _TreatmentTrackerBody extends StatelessWidget {
  const _TreatmentTrackerBody({
    required this.plan,
    required this.visits,
    required this.selectedDate,
    required this.visibleMonth,
    required this.isSignedIn,
    required this.onAdd,
    required this.onDateSelected,
    required this.onMonthChanged,
    required this.doseOn,
    required this.statusColor,
    required this.statusIcon,
    required this.formatDate,
    this.isLoading = false,
  });

  final Map<String, dynamic>? plan;
  final List<_DoseVisit> visits;
  final DateTime selectedDate;
  final DateTime visibleMonth;
  final bool isSignedIn;
  final bool isLoading;
  final VoidCallback onAdd;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<int> onMonthChanged;
  final _DoseVisit? Function(DateTime date) doseOn;
  final Color Function(_DoseStatus status) statusColor;
  final IconData Function(_DoseStatus status) statusIcon;
  final String Function(DateTime date) formatDate;

  @override
  Widget build(BuildContext context) {
    final patientName = plan?['patientName'] as String?;
    final category = plan?['category'];
    final route = plan?['route'] as String?;
    final protocolNote = plan?['protocolNote'] as String?;
    final statusText = plan?['statusText'] as String?;
    final requiresRIG =
        plan?['requiresRIG'] == true || plan?['rigRequired'] == true;
    final woundCareOnly = plan?['woundCareOnly'] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Treatment Tracker',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (plan == null)
              TextButton.icon(
                onPressed: isSignedIn ? onAdd : null,
                icon: const Icon(Icons.add_task_outlined, size: 16),
                label: const Text('Add Treatment'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              )
            else
              const Tooltip(
                message: 'Generated vaccine dates are locked in Firebase.',
                child: Icon(Icons.lock_outline, color: AppColors.primary),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (!isSignedIn)
          const _SignInRequiredNotice()
        else if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (plan == null)
          _EmptyTreatmentNotice(onAdd: onAdd)
        else ...[
          if (patientName != null && patientName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      patientName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (woundCareOnly)
            _WoundCareOnlyBanner(
              message:
                  statusText ?? 'Wound care only. No vaccine protocol required.',
            )
          else ...[
            if (requiresRIG) const _RigRequiredBanner(),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                [
                  if (category != null) 'Category $category',
                  if (route != null) '$route route',
                  if (protocolNote != null) protocolNote,
                ].join(' - '),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            _DoseChipRow(
              visits: visits,
              requiresRIG: requiresRIG,
              statusColor: statusColor,
              statusIcon: statusIcon,
            ),
          ],
        ],
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),
        _LockedCalendarGrid(
          visibleMonth: visibleMonth,
          selectedDate: selectedDate,
          doseOn: doseOn,
          statusColor: statusColor,
          onMonthChanged: onMonthChanged,
          onDateSelected: onDateSelected,
        ),
        const SizedBox(height: 8),
        Text(
          'Selected: ${formatDate(selectedDate)}',
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        if (plan != null) ...[
          const SizedBox(height: 12),
          const Text(
            'Protocol verified by ABTC medical personnel.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}

class _AddTreatmentDialog extends StatefulWidget {
  const _AddTreatmentDialog({required this.defaultPatientName});

  final String defaultPatientName;

  @override
  State<_AddTreatmentDialog> createState() => _AddTreatmentDialogState();
}

class _AddTreatmentDialogState extends State<_AddTreatmentDialog> {
  late final TextEditingController _patientNameController;
  DateTime _startDate = _VaccineScheduleCardState._dateOnly(DateTime.now());
  bool _medicalConfirmation = false;
  String? _patientType;
  String? _exposureType;
  String? _healthFacility;

  @override
  void initState() {
    super.initState();
    _patientNameController =
        TextEditingController(text: widget.defaultPatientName);
  }

  @override
  void dispose() {
    _patientNameController.dispose();
    super.dispose();
  }

  bool get _canGenerate {
    return _medicalConfirmation &&
        _patientNameController.text.trim().isNotEmpty &&
        _patientType != null &&
        _exposureType != null &&
        _healthFacility != null;
  }

  Future<void> _pickStartDate() async {
    if (!_medicalConfirmation) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      helpText: 'Select Day 0',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() => _startDate = _VaccineScheduleCardState._dateOnly(picked));
  }

  void _generate() {
    if (!_canGenerate) return;

    final timeline = calculateVaccineTimeline(_startDate);

    Navigator.pop(context, {
      'startDate': _formatDate(_startDate),
      'dayZero': Timestamp.fromDate(_startDate),
      'patientName': _patientNameController.text.trim(),
      'patientType': _patientType,
      'profile': _internalProfile,
      'exposureType': _exposureType,
      'category': _internalCategory,
      'healthFacility': _healthFacility,
      'route': _internalRoute,
      'requiresRIG': _requiresRIG,
      'rigRequired': _requiresRIG,
      'statusText': timeline.statusText,
      'protocolNote': timeline.protocolNote,
      'woundCareOnly': timeline.doses.isEmpty,
      'locked': true,
      'doses': timeline.doses,
    });
  }

  _VaccineTimeline calculateVaccineTimeline(DateTime dayZero) {
    final category = _internalCategory;
    if (category == 1) {
      return const _VaccineTimeline(
        statusText: 'Wound care only. No vaccine protocol required.',
        protocolNote: null,
        doses: [],
      );
    }

    final List<int> offsets;
    final String? protocolNote;
    if (_internalProfile == 'Booster') {
      offsets = const [0, 3];
      protocolNote = 'Accelerated Booster Protocol.';
    } else if (_internalRoute == 'ID') {
      offsets = const [0, 3, 7];
      protocolNote = null;
    } else {
      offsets = const [0, 3, 7, 21];
      protocolNote = null;
    }

    return _VaccineTimeline(
      statusText: null,
      protocolNote: protocolNote,
      doses: offsets.asMap().entries.map((entry) {
        final date = dayZero.add(Duration(days: entry.value));
        return {
          'doseNumber': entry.key + 1,
          'daysFromStart': entry.value,
          'date': Timestamp.fromDate(date),
          'status': 'Pending',
          'locked': true,
        };
      }).toList(),
    );
  }

  String get _internalProfile {
    return _patientType == _TreatmentOptions.boosterProfile ? 'Booster' : 'New';
  }

  int get _internalCategory {
    switch (_exposureType) {
      case _TreatmentOptions.exposureCategoryOne:
        return 1;
      case _TreatmentOptions.exposureCategoryTwo:
        return 2;
      case _TreatmentOptions.exposureCategoryThree:
        return 3;
      default:
        return 0;
    }
  }

  String get _internalRoute {
    return _healthFacility == _TreatmentOptions.publicFacility ? 'ID' : 'IM';
  }

  bool get _requiresRIG => _internalCategory == 3;

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    // Disabled controls use the shared disabled palette. Do not fade their
    // text, since the confirmation message and any retained values must stay
    // readable.
    const fieldOpacity = 1.0;

    return AlertDialog(
      title: const Text('Add Treatment Tracker'),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _CriticalNotice(),
              CheckboxListTile(
                value: _medicalConfirmation,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                  'I confirm that a medical professional at the ABTC has assessed my wound and assigned this specific treatment plan.',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                onChanged: (value) {
                  setState(() => _medicalConfirmation = value ?? false);
                },
              ),
              AnimatedOpacity(
                opacity: fieldOpacity,
                duration: const Duration(milliseconds: 180),
                child: IgnorePointer(
                  ignoring: !_medicalConfirmation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _patientNameController,
                        enabled: _medicalConfirmation,
                        decoration: const InputDecoration(
                          labelText: 'Family Member / Patient Name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        textCapitalization: TextCapitalization.words,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        readOnly: true,
                        enabled: _medicalConfirmation,
                        controller: TextEditingController(
                          text: _formatDate(_startDate),
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Day 0 Start Date',
                          suffixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                        onTap: _pickStartDate,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _patientType,
                        style: AppFormStyles.dropdownText,
                        dropdownColor: AppFormStyles.dropdownMenu,
                        focusColor: AppFormStyles.dropdownFocus,
                        iconEnabledColor: AppFormStyles.dropdownIcon,
                        iconDisabledColor: AppFormStyles.disabledDropdownIcon,
                        decoration: const InputDecoration(
                          labelText: 'Patient Profile',
                        ),
                        items: _TreatmentOptions.patientTypes
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(
                                  value,
                                  style: AppFormStyles.dropdownText,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() {
                          _patientType = value;
                        }),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _exposureType,
                        style: AppFormStyles.dropdownText,
                        dropdownColor: AppFormStyles.dropdownMenu,
                        focusColor: AppFormStyles.dropdownFocus,
                        iconEnabledColor: AppFormStyles.dropdownIcon,
                        iconDisabledColor: AppFormStyles.disabledDropdownIcon,
                        decoration: const InputDecoration(
                          labelText: 'Exposure Category',
                        ),
                        items: _TreatmentOptions.exposureTypes
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(
                                  value,
                                  style: AppFormStyles.dropdownText,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() {
                          _exposureType = value;
                        }),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _healthFacility,
                        style: AppFormStyles.dropdownText,
                        dropdownColor: AppFormStyles.dropdownMenu,
                        focusColor: AppFormStyles.dropdownFocus,
                        iconEnabledColor: AppFormStyles.dropdownIcon,
                        iconDisabledColor: AppFormStyles.disabledDropdownIcon,
                        decoration: const InputDecoration(
                          labelText: 'Health Facility',
                        ),
                        items: _TreatmentOptions.facilities
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(
                                  value,
                                  style: AppFormStyles.dropdownText,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() {
                          _healthFacility = value;
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _canGenerate ? _generate : null,
          icon: const Icon(Icons.health_and_safety_outlined),
          label: const Text('Generate Locked Schedule'),
        ),
      ],
    );
  }
}

class _TreatmentOptions {
  static const newProfile = 'New';
  static const boosterProfile = 'Booster';
  static const exposureCategoryOne = 'Category I';
  static const exposureCategoryTwo = 'Category II';
  static const exposureCategoryThree = 'Category III';
  static const publicFacility = 'Public ABTC / Government Hospital';
  static const privateFacility = 'Private Clinic / Hospital Emergency Room';

  static const patientTypes = [newProfile, boosterProfile];
  static const exposureTypes = [
    exposureCategoryOne,
    exposureCategoryTwo,
    exposureCategoryThree,
  ];
  static const facilities = [publicFacility, privateFacility];
}

class _VaccineTimeline {
  const _VaccineTimeline({
    required this.statusText,
    required this.protocolNote,
    required this.doses,
  });

  final String? statusText;
  final String? protocolNote;
  final List<Map<String, dynamic>> doses;
}

class _DoseVisit {
  const _DoseVisit({
    required this.doseNumber,
    required this.daysFromStart,
    required this.date,
    required this.statusText,
  });

  final int doseNumber;
  final int daysFromStart;
  final DateTime date;
  final String statusText;

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
      doseNumber: map['doseNumber'] as int? ?? 0,
      daysFromStart:
          map['daysFromStart'] as int? ?? map['offset'] as int? ?? 0,
      date: date,
      statusText: map['status'] as String? ?? 'Pending',
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

class _CriticalNotice extends StatelessWidget {
  const _CriticalNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE57373)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFC62828)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'CRITICAL NOTICE: Please ONLY add a schedule after you have physically visited an Animal Bite Treatment Center (ABTC). The category, severity, and vaccine protocol must be determined by qualified medical personnel. Do not guess your exposure category.',
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: Color(0xFF7F1D1D),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTreatmentNotice extends StatelessWidget {
  const _EmptyTreatmentNotice({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cream.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.secondary, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Add a treatment tracker only after an ABTC clinician assigns your rabies exposure category and vaccine protocol.',
              style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
            ),
          ),
          IconButton(
            tooltip: 'Add treatment tracker',
            onPressed: onAdd,
            icon: const Icon(Icons.add_circle_outline),
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _SignInRequiredNotice extends StatelessWidget {
  const _SignInRequiredNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cream.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_outline, color: AppColors.secondary, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Sign in to create and sync your treatment tracker in Firebase.',
              style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _WoundCareOnlyBanner extends StatelessWidget {
  const _WoundCareOnlyBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.sanitizer_outlined, color: Colors.green),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RigRequiredBanner extends StatelessWidget {
  const _RigRequiredBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
      ),
      child: const Row(
        children: [
          Icon(Icons.medical_information_outlined, color: Colors.red),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Rabies Immunoglobulin (RIG) infiltration required immediately at the clinic today!',
              style: TextStyle(
                fontSize: 13,
                color: Colors.black87,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoseChipRow extends StatelessWidget {
  const _DoseChipRow({
    required this.visits,
    required this.requiresRIG,
    required this.statusColor,
    required this.statusIcon,
  });

  final List<_DoseVisit> visits;
  final bool requiresRIG;
  final Color Function(_DoseStatus status) statusColor;
  final IconData Function(_DoseStatus status) statusIcon;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: visits.map((dose) {
          final color = statusColor(dose.status);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              constraints: const BoxConstraints(minWidth: 88),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: color.withValues(alpha: 0.1),
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon(dose.status), color: color, size: 20),
                  const SizedBox(height: 4),
                  Text(
                    'Dose ${dose.doseNumber}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: color,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${dose.day} - ${dose.date.month}/${dose.date.day}',
                    style: const TextStyle(fontSize: 11, color: Colors.black45),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dose.statusText,
                    style: const TextStyle(fontSize: 10, color: Colors.black45),
                  ),
                  if (requiresRIG && dose.daysFromStart == 0) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'RIG infiltration required immediately at the clinic today!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

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
