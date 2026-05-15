import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/sab_report.dart';
import '../theme.dart';

class SABReportingPage extends StatefulWidget {
  const SABReportingPage({super.key});

  @override
  State<SABReportingPage> createState() => _SABReportingPageState();
}

class _SABReportingPageState extends State<SABReportingPage> {
  final _formKey = GlobalKey<FormState>();

  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _middleInitialController = TextEditingController();
  final _suffixController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _behaviorObserved;
  DateTime? _dateOfObservation;
  TimeOfDay? _timeOfObservation;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _lastNameController.dispose();
    _firstNameController.dispose();
    _middleInitialController.dispose();
    _suffixController.dispose();
    _contactNumberController.dispose();
    _addressController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfObservation ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dateOfObservation = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _timeOfObservation ?? TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _timeOfObservation = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final now = DateTime.now();
      final report = SABReport(
        lastName: _lastNameController.text.trim(),
        firstName: _firstNameController.text.trim(),
        middleInitial: _middleInitialController.text.trim(),
        suffix: _suffixController.text.trim(),
        contactNumber: _contactNumberController.text.trim(),
        address: _addressController.text.trim(),
        dateOfObservation: _dateOfObservation != null
            ? '${_dateOfObservation!.year}-${_dateOfObservation!.month.toString().padLeft(2, '0')}-${_dateOfObservation!.day.toString().padLeft(2, '0')}'
            : now.toIso8601String().split('T').first,
        timeOfObservation:
            _timeOfObservation?.format(context) ??
            TimeOfDay.now().format(context),
        location: _locationController.text.trim(),
        behaviorObserved: _behaviorObserved ?? '',
        description: _descriptionController.text.trim(),
        photoPath: '',
        reportedAt: now,
      );

      await Hive.box<SABReport>('sab_reports').add(report);

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
    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
    final dateLabel = _dateOfObservation != null
        ? '${_dateOfObservation!.year}-${_dateOfObservation!.month.toString().padLeft(2, '0')}-${_dateOfObservation!.day.toString().padLeft(2, '0')}'
        : null;
    final timeLabel = _timeOfObservation?.format(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Report Suspicious Animal Behavior',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
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
              // ── Reporter Information ──────────────────────────────
              _sectionHeader('Reporter Information'),
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
                        buildCounter:
                            (
                              _, {
                              required currentLength,
                              required isFocused,
                              maxLength,
                            }) => const SizedBox.shrink(),
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
                // Date of Observation
                GestureDetector(
                  onTap: _pickDate,
                  child: AbsorbPointer(
                    child: TextFormField(
                      style: _fieldStyle,
                      decoration: _dec(
                        dateLabel ?? 'Date of Observation',
                        suffix: const Icon(
                          Icons.calendar_today_outlined,
                          color: Colors.grey,
                        ),
                      ),
                      validator: (_) => _dateOfObservation == null
                          ? 'Please select a date'
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Time of Observation
                GestureDetector(
                  onTap: _pickTime,
                  child: AbsorbPointer(
                    child: TextFormField(
                      style: _fieldStyle,
                      decoration: _dec(
                        timeLabel ?? 'Time of Observation',
                        suffix: const Icon(
                          Icons.access_time_outlined,
                          color: Colors.grey,
                        ),
                      ),
                      validator: (_) => _timeOfObservation == null
                          ? 'Please select a time'
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _locationController,
                  style: _fieldStyle,
                  decoration: _dec('Location'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please enter a location'
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _behaviorObserved,
                  style: _fieldStyle,
                  decoration: _dec('Behavior Observed'),
                  items:
                      [
                            'Aggression',
                            'Excessive drooling',
                            'Staggering / Disoriented',
                            'Unprovoked biting',
                            'Hiding / Fearfulness',
                            'Other',
                          ]
                          .map(
                            (b) => DropdownMenuItem(value: b, child: Text(b)),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => _behaviorObserved = v),
                  validator: (v) => v == null ? 'Required' : null,
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
