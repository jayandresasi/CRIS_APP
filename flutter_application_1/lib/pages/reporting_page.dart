import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/report.dart';
import '../theme.dart';

class ReportingPage extends StatefulWidget {
  const ReportingPage({super.key});

  @override
  State<ReportingPage> createState() => _ReportingPageState();
}

class _ReportingPageState extends State<ReportingPage> {
  final _formKey = GlobalKey<FormState>();

  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _middleInitialController = TextEditingController();
  final _suffixController = TextEditingController();
  final _ageController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _animalSpeciesController = TextEditingController();

  String? _gender;
  String? _exposureType;
  String _animalOwnership = 'Stray';
  String _animalVaccinationStatus = 'Unknown';
  String _firstAidGiven = 'None';
  String _patientVaccinationStatus = 'Not vaccinated';

  DateTime? _dateOfIncident;
  TimeOfDay? _timeOfIncident;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _lastNameController.dispose();
    _firstNameController.dispose();
    _middleInitialController.dispose();
    _suffixController.dispose();
    _ageController.dispose();
    _contactNumberController.dispose();
    _addressController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _animalSpeciesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfIncident ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dateOfIncident = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _timeOfIncident ?? TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _timeOfIncident = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final report = Report(
        lastName: _lastNameController.text.trim(),
        firstName: _firstNameController.text.trim(),
        middleInitial: _middleInitialController.text.trim(),
        suffix: _suffixController.text.trim(),
        age: _ageController.text.trim(),
        gender: _gender ?? '',
        contactNumber: _contactNumberController.text.trim(),
        address: _addressController.text.trim(),
        dateOfIncident: _dateOfIncident != null
            ? '${_dateOfIncident!.year}-${_dateOfIncident!.month.toString().padLeft(2, '0')}-${_dateOfIncident!.day.toString().padLeft(2, '0')}'
            : DateTime.now().toIso8601String().split('T').first,
        timeOfIncident:
            _timeOfIncident?.format(context) ?? TimeOfDay.now().format(context),
        locationOfIncident: _locationController.text.trim(),
        exposureType: _exposureType ?? '',
        animalSpecies: _animalSpeciesController.text.trim(),
        animalOwnership: _animalOwnership,
        animalVaccinationStatus: _animalVaccinationStatus,
        incidentDescription: _descriptionController.text.trim(),
        firstAidGiven: _firstAidGiven,
        patientVaccinationStatus: _patientVaccinationStatus,
        reportedAt: DateTime.now(),
      );

      await Hive.box<Report>('reports').add(report);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report submitted successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to submit: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // Explicit text style applied to every field so typed text is always visible
  static const _fieldStyle = TextStyle(color: Colors.black87, fontSize: 14);

  InputDecoration _dec(String label, {Widget? suffix}) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54),
        hintStyle: const TextStyle(color: Colors.black38),
        suffixIcon: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCDD5DF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      );

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 20, 0, 12),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      );

  Widget _card(List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8ECF0)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final dateLabel = _dateOfIncident != null
        ? '${_dateOfIncident!.year}-${_dateOfIncident!.month.toString().padLeft(2, '0')}-${_dateOfIncident!.day.toString().padLeft(2, '0')}'
        : null;
    final timeLabel = _timeOfIncident?.format(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Report Bite Incident',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Patient Information ───────────────────────────────
              _sectionHeader('Patient Information'),
              _card([
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _lastNameController,
                        style: _fieldStyle,
                        decoration: _dec('Last Name'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter contact person'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _firstNameController,
                        style: _fieldStyle,
                        decoration: _dec('First Name'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter contact person'
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _middleInitialController,
                        style: _fieldStyle,
                        decoration: _dec('Middle Initial'),
                        maxLength: 3,
                        buildCounter: (
                          _, {
                          required currentLength,
                          required isFocused,
                          maxLength,
                        }) =>
                            const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _suffixController,
                        style: _fieldStyle,
                        decoration: _dec('Suffix'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _ageController,
                  style: _fieldStyle,
                  decoration: _dec('Age'),
                  keyboardType: TextInputType.number,
                  maxLength: 3,
                  buildCounter: (_,
                          {required currentLength,
                          required isFocused,
                          maxLength}) =>
                      const SizedBox.shrink(),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Age is required';
                    final age = int.tryParse(v.trim());
                    if (age == null) return 'Age must be a number';
                    if (age < 1 || age > 120)
                      return 'Age must be between 1 and 120';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _gender,
                  style: _fieldStyle,
                  decoration: _dec('Gender'),
                  items: ['Male', 'Female', 'Other']
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) => setState(() => _gender = v),
                  validator: (v) => v == null ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _contactNumberController,
                  style: _fieldStyle,
                  decoration: _dec('Contact Number'),
                  keyboardType: TextInputType.phone,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please enter contact number'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  style: _fieldStyle,
                  decoration: _dec('Address'),
                  maxLines: 2,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ]),

              // ── Incident Details ──────────────────────────────────
              _sectionHeader('Incident Details'),
              _card([
                // Date of Incident
                GestureDetector(
                  onTap: _pickDate,
                  child: AbsorbPointer(
                    child: TextFormField(
                      style: _fieldStyle,
                      decoration: _dec(
                        dateLabel ?? 'Date of Incident',
                        suffix: const Icon(
                          Icons.calendar_today_outlined,
                          color: Colors.grey,
                        ),
                      ),
                      validator: (_) => _dateOfIncident == null
                          ? 'Please select a date'
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Time of Incident
                GestureDetector(
                  onTap: _pickTime,
                  child: AbsorbPointer(
                    child: TextFormField(
                      style: _fieldStyle,
                      decoration: _dec(
                        timeLabel ?? 'Time of Incident',
                        suffix: const Icon(
                          Icons.access_time_outlined,
                          color: Colors.grey,
                        ),
                      ),
                      validator: (_) => _timeOfIncident == null
                          ? 'Please select a time'
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _locationController,
                  style: _fieldStyle,
                  decoration: _dec('Location of Incident'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please enter a location'
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _exposureType,
                  style: _fieldStyle,
                  decoration: _dec('Type of Exposure'),
                  items: ['Bite', 'Scratch', 'Lick on wound', 'Other']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _exposureType = v),
                  validator: (v) => v == null ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _animalSpeciesController,
                  style: _fieldStyle,
                  decoration: _dec('Animal Species (e.g. Dog, Cat)'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _animalOwnership,
                  style: _fieldStyle,
                  decoration: _dec('Animal Ownership'),
                  items: ['Stray', 'Owned', 'Unknown']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _animalOwnership = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _animalVaccinationStatus,
                  style: _fieldStyle,
                  decoration: _dec('Animal Vaccination Status'),
                  items: ['Vaccinated', 'Not vaccinated', 'Unknown']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _animalVaccinationStatus = v!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  style: _fieldStyle,
                  decoration: _dec('Description of Incident'),
                  maxLines: 4,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please enter a description'
                      : null,
                ),
              ]),

              // ── Medical Information ───────────────────────────────
              _sectionHeader('Medical Information'),
              _card([
                DropdownButtonFormField<String>(
                  value: _firstAidGiven,
                  style: _fieldStyle,
                  decoration: _dec('First Aid Given'),
                  items: ['None', 'Wound washed', 'Antiseptic applied', 'Other']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _firstAidGiven = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _patientVaccinationStatus,
                  style: _fieldStyle,
                  decoration: _dec('Patient Vaccination Status'),
                  items: [
                    'Not vaccinated',
                    'Partially vaccinated',
                    'Fully vaccinated',
                  ]
                      .map(
                        (e) => DropdownMenuItem(value: e, child: Text(e)),
                      )
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _patientVaccinationStatus = v!),
                ),
              ]),

              const SizedBox(height: 28),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Submit Report',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
