import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/report.dart';
import '../theme.dart';

/// Bite incident reporting form
class ReportingPage extends StatefulWidget {
  const ReportingPage({super.key});

  @override
  State<ReportingPage> createState() => _ReportingPageState();
}

class _ReportingPageState extends State<ReportingPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
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

  String _gender = 'Male';
  String _exposureType = 'Bite';
  String _animalOwnership = 'Stray';
  String _animalVaccinationStatus = 'Unknown';
  String _firstAidGiven = 'None';
  String _patientVaccinationStatus = 'Not vaccinated';

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

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final report = Report(
        lastName: _lastNameController.text.trim(),
        firstName: _firstNameController.text.trim(),
        middleInitial: _middleInitialController.text.trim(),
        suffix: _suffixController.text.trim(),
        age: _ageController.text.trim(),
        gender: _gender,
        contactNumber: _contactNumberController.text.trim(),
        address: _addressController.text.trim(),
        dateOfIncident: DateTime.now().toIso8601String().split('T').first,
        timeOfIncident: TimeOfDay.now().format(context),
        locationOfIncident: _locationController.text.trim(),
        exposureType: _exposureType,
        animalSpecies: _animalSpeciesController.text.trim(),
        animalOwnership: _animalOwnership,
        animalVaccinationStatus: _animalVaccinationStatus,
        incidentDescription: _descriptionController.text.trim(),
        firstAidGiven: _firstAidGiven,
        patientVaccinationStatus: _patientVaccinationStatus,
        reportedAt: DateTime.now(),
      );

      final box = Hive.box<Report>('reports');
      await box.add(report);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report submitted successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to submit report: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Incident')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Personal Information ──────────────────────────────
              _sectionHeader('Personal Information'),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _lastNameController,
                      decoration: _inputDecoration('Last Name'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please enter contact person'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _firstNameController,
                      decoration: _inputDecoration('First Name'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please enter contact person'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _middleInitialController,
                      decoration: _inputDecoration('M.I.'),
                      maxLength: 2,
                      buildCounter:
                          (
                            _, {
                            required currentLength,
                            required isFocused,
                            maxLength,
                          }) => const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _suffixController,
                      decoration: _inputDecoration('Suffix (optional)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _ageController,
                      decoration: _inputDecoration('Age'),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _gender,
                      decoration: _inputDecoration('Gender'),
                      items: ['Male', 'Female', 'Other']
                          .map(
                            (g) => DropdownMenuItem(value: g, child: Text(g)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _gender = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contactNumberController,
                decoration: _inputDecoration('Contact Number'),
                keyboardType: TextInputType.phone,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter contact number'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: _inputDecoration('Home Address'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),

              // ── Incident Details ──────────────────────────────────
              _sectionHeader('Incident Details'),
              TextFormField(
                controller: _locationController,
                decoration: _inputDecoration('Location of Incident'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter a location'
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _exposureType,
                decoration: _inputDecoration('Exposure Type'),
                items: ['Bite', 'Scratch', 'Lick on wound', 'Other']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _exposureType = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _animalSpeciesController,
                decoration: _inputDecoration('Animal Species (e.g. Dog, Cat)'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _animalOwnership,
                decoration: _inputDecoration('Animal Ownership'),
                items: ['Stray', 'Owned', 'Unknown']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _animalOwnership = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _animalVaccinationStatus,
                decoration: _inputDecoration('Animal Vaccination Status'),
                items: ['Vaccinated', 'Not vaccinated', 'Unknown']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _animalVaccinationStatus = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: _inputDecoration('Describe the Incident'),
                maxLines: 4,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter a description'
                    : null,
              ),

              // ── Medical Information ───────────────────────────────
              _sectionHeader('Medical Information'),
              DropdownButtonFormField<String>(
                value: _firstAidGiven,
                decoration: _inputDecoration('First Aid Given'),
                items: ['None', 'Wound washed', 'Antiseptic applied', 'Other']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _firstAidGiven = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _patientVaccinationStatus,
                decoration: _inputDecoration('Patient Vaccination Status'),
                items:
                    [
                          'Not vaccinated',
                          'Partially vaccinated',
                          'Fully vaccinated',
                        ]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                onChanged: (v) =>
                    setState(() => _patientVaccinationStatus = v!),
              ),

              const SizedBox(height: 28),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReport,
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
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
