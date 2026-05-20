import 'package:flutter/material.dart';

import '../theme.dart';

class DoseMilestone {
  const DoseMilestone({
    required this.doseNumber,
    required this.daysFromStart,
    required this.targetDate,
    this.status = 'Pending',
  });

  final int doseNumber;
  final int daysFromStart;
  final DateTime targetDate;
  final String status;
}

class TreatmentProfile {
  const TreatmentProfile({
    required this.patientName,
    required this.profileType,
    required this.chosenCategory,
    required this.route,
    required this.requiresRIG,
    required this.startDate,
    required this.doses,
    required this.isWoundCareOnly,
  });

  final String patientName;
  final String profileType;
  final int chosenCategory;
  final String route;
  final bool requiresRIG;
  final DateTime startDate;
  final List<DoseMilestone> doses;
  final bool isWoundCareOnly;
}

class TreatmentTrackerPage extends StatefulWidget {
  const TreatmentTrackerPage({super.key});

  @override
  State<TreatmentTrackerPage> createState() => _TreatmentTrackerPageState();
}

class _TreatmentTrackerPageState extends State<TreatmentTrackerPage> {
  final List<TreatmentProfile> _profiles = [];

  Future<void> _showAddTreatmentDialog() async {
    final profile = await showDialog<TreatmentProfile>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _AddTreatmentProfileDialog(),
    );

    if (profile == null) return;
    setState(() => _profiles.add(profile));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Treatment Tracker'),
        actions: [
          IconButton(
            tooltip: 'Add treatment profile',
            onPressed: _showAddTreatmentDialog,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: _profiles.isEmpty
            ? _EmptyTreatmentState(onAdd: _showAddTreatmentDialog)
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _profiles.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _TreatmentProfileCard(profile: _profiles[index]);
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTreatmentDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _AddTreatmentProfileDialog extends StatefulWidget {
  const _AddTreatmentProfileDialog();

  @override
  State<_AddTreatmentProfileDialog> createState() =>
      _AddTreatmentProfileDialogState();
}

class _AddTreatmentProfileDialogState
    extends State<_AddTreatmentProfileDialog> {
  final _patientNameController = TextEditingController();

  bool _confirmedByAbtc = false;
  String? _selectedProfileType;
  int? _selectedCategory;
  String? _selectedFacility;
  DateTime _startDate = DateTime.now();

  bool get _fieldsEnabled => _confirmedByAbtc;

  bool get _canGenerate {
    return _confirmedByAbtc &&
        _patientNameController.text.trim().isNotEmpty &&
        _selectedProfileType != null &&
        _selectedCategory != null &&
        _selectedFacility != null;
  }

  @override
  void dispose() {
    _patientNameController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    if (!_fieldsEnabled) return;

    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
      helpText: 'Select Day 0',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );

    if (picked == null) return;
    setState(() => _startDate = _dateOnly(picked));
  }

  void _generateTracker() {
    if (!_canGenerate) return;

    final profileType = _selectedProfileType == _ProfileOption.boosterLabel
        ? 'Booster'
        : 'New';
    final route = _selectedFacility == _FacilityOption.publicLabel ? 'ID' : 'IM';
    final category = _selectedCategory!;
    final requiresRIG = category == 3;
    final doses = _calculateDoseMilestones(
      profileType: profileType,
      category: category,
      route: route,
      startDate: _dateOnly(_startDate),
    );

    Navigator.pop(
      context,
      TreatmentProfile(
        patientName: _patientNameController.text.trim(),
        profileType: profileType,
        chosenCategory: category,
        route: route,
        requiresRIG: requiresRIG,
        startDate: _dateOnly(_startDate),
        doses: doses,
        isWoundCareOnly: category == 1,
      ),
    );
  }

  List<DoseMilestone> _calculateDoseMilestones({
    required String profileType,
    required int category,
    required String route,
    required DateTime startDate,
  }) {
    if (category == 1) return const [];

    final List<int> doseDays;
    if (profileType == 'Booster' && (category == 2 || category == 3)) {
      doseDays = const [0, 3];
    } else if (profileType == 'New' && route == 'ID') {
      doseDays = const [0, 3, 7];
    } else {
      doseDays = const [0, 3, 7, 21];
    }

    return doseDays.asMap().entries.map((entry) {
      return DoseMilestone(
        doseNumber: entry.key + 1,
        daysFromStart: entry.value,
        targetDate: startDate.add(Duration(days: entry.value)),
        status: 'Pending',
      );
    }).toList();
  }

  String _formatFullDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Treatment Profile'),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _CriticalSafetyNotice(),
              CheckboxListTile(
                value: _confirmedByAbtc,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                  'I confirm that a medical professional at the ABTC has assessed my wound and assigned this specific treatment plan.',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                onChanged: (value) {
                  setState(() => _confirmedByAbtc = value ?? false);
                },
              ),
              AnimatedOpacity(
                opacity: _fieldsEnabled ? 1 : 0.45,
                duration: const Duration(milliseconds: 180),
                child: IgnorePointer(
                  ignoring: !_fieldsEnabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 6),
                      TextField(
                        controller: _patientNameController,
                        enabled: _fieldsEnabled,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Patient Name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedProfileType,
                        decoration: const InputDecoration(
                          labelText: 'Patient Profile',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        items: _ProfileOption.labels
                            .map(
                              (label) => DropdownMenuItem(
                                value: label,
                                child: Text(label),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() => _selectedProfileType = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Exposure Category Assigned by ABTC',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _CategorySelector(
                        selectedCategory: _selectedCategory,
                        enabled: _fieldsEnabled,
                        onSelected: (category) {
                          setState(() => _selectedCategory = category);
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedFacility,
                        decoration: const InputDecoration(
                          labelText: 'Health Facility',
                          prefixIcon: Icon(Icons.local_hospital_outlined),
                        ),
                        items: _FacilityOption.labels
                            .map(
                              (label) => DropdownMenuItem(
                                value: label,
                                child: Text(label),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() => _selectedFacility = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        readOnly: true,
                        enabled: _fieldsEnabled,
                        decoration: const InputDecoration(
                          labelText: 'Day 0 Start Date',
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                        controller: TextEditingController(
                          text: _formatFullDate(_startDate),
                        ),
                        onTap: _pickStartDate,
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
          onPressed: _canGenerate ? _generateTracker : null,
          icon: const Icon(Icons.lock_outline),
          label: const Text('Generate Tracker'),
        ),
      ],
    );
  }
}

class _TreatmentProfileCard extends StatelessWidget {
  const _TreatmentProfileCard({required this.profile});

  final TreatmentProfile profile;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.health_and_safety_outlined,
                    color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Treatment Tracker: ${profile.patientName}'s Schedule",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const Tooltip(
                  message: 'Protocol dates are locked.',
                  child: Icon(Icons.lock_outline, color: Colors.black45),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Profile: ${profile.profileType} - Category ${profile.chosenCategory} - ${profile.route} route',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (profile.requiresRIG) ...[
              const SizedBox(height: 12),
              const _RigAlertBanner(),
            ],
            const SizedBox(height: 12),
            if (profile.isWoundCareOnly)
              const _WoundCareOnlyBlock()
            else
              _DoseMilestoneGrid(doses: profile.doses),
            const SizedBox(height: 12),
            const Text(
              '*Protocol verified by ABTC medical personnel.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black54,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoseMilestoneGrid extends StatelessWidget {
  const _DoseMilestoneGrid({required this.doses});

  final List<DoseMilestone> doses;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: doses.map((dose) {
        return Container(
          width: 112,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.cream.withValues(alpha: 0.32),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 18, color: AppColors.primary),
              const SizedBox(height: 6),
              Text(
                'Dose ${dose.doseNumber}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Day ${dose.daysFromStart}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatShortDate(dose.targetDate),
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 4),
              Text(
                dose.status,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black45,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatShortDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$month/$day';
  }
}

class _CategorySelector extends StatelessWidget {
  const _CategorySelector({
    required this.selectedCategory,
    required this.enabled,
    required this.onSelected,
  });

  final int? selectedCategory;
  final bool enabled;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    const options = [
      _CategoryChoice(
          category: 1,
          title: 'Category I',
          description:
              'Exposed Skin: Touching, feeding, or licks on healthy, unbroken skin',
        ),
      _CategoryChoice(
          category: 2,
          title: 'Category II',
          description:
              'Minor Exposure: Minor scratch, abrasion, or nip with NO bleeding',
        ),
      _CategoryChoice(
          category: 3,
          title: 'Category III',
          description:
              'Severe Exposure: Deep bite, puncture marks, bleeding wound, or any lick on broken skin',
        ),
    ];

    return Column(
      children: [
        for (var index = 0; index < options.length; index++) ...[
          _SelectableCategoryOption(
            option: options[index],
            selected: selectedCategory == options[index].category,
            enabled: enabled,
            onTap: () => onSelected(options[index].category),
          ),
          if (index != options.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _CategoryChoice {
  const _CategoryChoice({
    required this.category,
    required this.title,
    required this.description,
  });

  final int category;
  final String title;
  final String description;
}

class _SelectableCategoryOption extends StatelessWidget {
  const _SelectableCategoryOption({
    required this.option,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final _CategoryChoice option;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primary : const Color(0xFFCDD5DF),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.primary : Colors.black38,
                  width: selected ? 6 : 1.5,
                ),
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      option.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        height: 1.3,
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
}

class _CriticalSafetyNotice extends StatelessWidget {
  const _CriticalSafetyNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFB74D)),
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

class _RigAlertBanner extends StatelessWidget {
  const _RigAlertBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.danger, width: 1.4),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.emergency_outlined, color: AppColors.danger),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Rabies Immunoglobulin (RIG) injection required at the clinic on Day 0!',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WoundCareOnlyBlock extends StatelessWidget {
  const _WoundCareOnlyBlock();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.45)),
      ),
      child: const Row(
        children: [
          Icon(Icons.sanitizer_outlined, color: AppColors.success),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Wound care only. No vaccine protocol required.',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTreatmentState extends StatelessWidget {
  const _EmptyTreatmentState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              size: 54,
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            const Text(
              'No treatment profiles yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add a tracker only after an ABTC clinician assigns the exact exposure category and treatment plan.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, height: 1.35),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add Treatment Profile'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileOption {
  static const newLabel = 'New Profile (Never had shots)';
  static const boosterLabel = 'Booster Profile (Had shots before)';
  static const labels = [newLabel, boosterLabel];
}

class _FacilityOption {
  static const publicLabel = 'Public ABTC / Government Hospital';
  static const privateLabel = 'Private Clinic / Hospital Emergency Room';
  static const labels = [publicLabel, privateLabel];
}
