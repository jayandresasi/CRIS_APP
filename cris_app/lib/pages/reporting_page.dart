import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../models/report.dart';
import '../theme.dart';
import '../widgets/report_form_ui.dart';
import 'login_page.dart';

const List<String> iloiloMunicipalities = [
  'Ajuy',
  'Alimodian',
  'Anilao',
  'Badiangan',
  'Balasan',
  'Banate',
  'Barotac Nuevo',
  'Barotac Viejo',
  'Batad',
  'Bingawan',
  'Cabatuan',
  'Calinog',
  'Carles',
  'Concepcion',
  'Dingle',
  'Duenas',
  'Dumangas',
  'Estancia',
  'Guimbal',
  'Igbaras',
  'Iloilo City',
  'Janiuay',
  'Lambunao',
  'Leganes',
  'Lemery',
  'Leon',
  'Maasin',
  'Miagao',
  'Mina',
  'New Lucena',
  'Oton',
  'Passi City',
  'Pavia',
  'Pototan',
  'San Dionisio',
  'San Enrique',
  'San Joaquin',
  'San Miguel',
  'San Rafael',
  'Santa Barbara',
  'Sara',
  'Tigbauan',
  'Tubungan',
  'Zarraga',
];

const List<String> _suspiciousBehaviors = [
  'Excessive salivation',
  'Aggressive behavior',
  'Unusual biting behavior',
  'Restlessness',
  'Paralysis',
  'Difficulty swallowing',
  'Wandering aimlessly',
  'Unusual vocalization',
  'Seizures',
  'No suspicious behavior observed',
  'Unknown',
];

class ReportingPage extends StatefulWidget {
  const ReportingPage({
    super.key,
    this.reportingForSelf = false,
    this.facilityId,
    this.facilityName,
    this.facilityCode,
  });

  final bool reportingForSelf;

  /// Facility (ABTC) info passed from the dashboard after scanning the QR code.
  final String? facilityId;
  final String? facilityName;
  final String? facilityCode;

  @override
  State<ReportingPage> createState() => _ReportingPageState();
}

class _ReportingPageState extends State<ReportingPage> {
  final _formKey = GlobalKey<FormState>();
  final _formScrollController = ScrollController();
  final _picker = ImagePicker();

  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _suffixController = TextEditingController();
  final _dobController = TextEditingController();
  final _ageController = TextEditingController();
  final _civilStatusController = TextEditingController();
  final _guardianNameController = TextEditingController();
  final _guardianContactController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _provinceController = TextEditingController(text: 'Iloilo');
  final _municipalityController = TextEditingController();
  final _barangayController = TextEditingController();
  final _streetController = TextEditingController();
  final _allergyDetailsController = TextEditingController();
  final _medicalProblemsController = TextEditingController();
  final _currentMedicationsController = TextEditingController();
  final _otherMedicalInfoController = TextEditingController();
  final _previousVaccinationDetailsController = TextEditingController();
  final _otherAnimalController = TextEditingController();
  final _breedController = TextEditingController();
  final _colorController = TextEditingController();
  final _animalAgeController = TextEditingController();
  final _washMinutesController = TextEditingController();
  final _otherSubstanceController = TextEditingController();

  DateTime? _dateOfBirth;
  String? _sex;
  String? _patientVaccinated;
  String? _allergiesKnown;
  String _animalType = 'Dog';
  String _ownership = 'Stray';
  String _animalSex = 'Unknown';
  String _animalAlive = 'Unknown';
  String _animalAvailable = 'Unknown';
  String? _animalVaccinated;
  String? _washedWound;
  String _substance = 'None';
  bool _certified = false;
  bool _reviewing = false;
  int _reviewPage = 0;
  bool _isSubmitting = false;
  bool _showPageErrors = false;
  bool _isLoadingProfile = false;
  bool _reportingForSelf = false;
  File? _animalPhoto;
  final Set<String> _behaviors = {};

  bool get _patientFieldsReadOnly => _reportingForSelf || _isLoadingProfile;
  bool get _isMinor => (int.tryParse(_ageController.text.trim()) ?? 18) < 18;

  @override
  void initState() {
    super.initState();
    _reportingForSelf = widget.reportingForSelf;
    if (_reportingForSelf) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadCurrentUserProfile();
      });
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _lastNameController,
      _firstNameController,
      _middleNameController,
      _suffixController,
      _dobController,
      _ageController,
      _civilStatusController,
      _guardianNameController,
      _guardianContactController,
      _mobileController,
      _emailController,
      _provinceController,
      _municipalityController,
      _barangayController,
      _streetController,
      _allergyDetailsController,
      _medicalProblemsController,
      _currentMedicationsController,
      _otherMedicalInfoController,
      _previousVaccinationDetailsController,
      _otherAnimalController,
      _breedController,
      _colorController,
      _animalAgeController,
      _washMinutesController,
      _otherSubstanceController,
    ]) {
      controller.dispose();
    }
    _formScrollController.dispose();
    super.dispose();
  }

  Future<void> _setReportingForSelf(bool value) async {
    if (value == _reportingForSelf) return;
    setState(() => _reportingForSelf = value);
    if (value) {
      await _loadCurrentUserProfile();
    } else {
      _clearPatientFields();
    }
  }

  Future<void> _loadCurrentUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar('Please sign in to use your profile.');
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      return;
    }

    setState(() => _isLoadingProfile = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('user-info')
          .doc(user.uid)
          .get();
      if (!mounted) return;
      final data = snapshot.data();
      if (data == null) {
        setState(() => _reportingForSelf = false);
        _showSnackBar('No saved profile found. Please set up your profile.');
        return;
      }

      final fullName = (data['fullName'] ?? '') as String;
      final parts = fullName.trim().split(RegExp(r'\s+'));
      final dob = (data['dob'] ?? data['birthDate'] ?? '') as String;
      final parsedDob = DateTime.tryParse(dob);
      final civilStatus = data['civilStatus'];
      setState(() {
        _firstNameController.text = parts.isNotEmpty ? parts.first : '';
        _lastNameController.text =
            parts.length > 1 ? parts.sublist(1).join(' ') : '';
        _dateOfBirth = parsedDob;
        _dobController.text = parsedDob == null ? '' : _formatDate(parsedDob);
        _ageController.text = _calculateAge(parsedDob)?.toString() ?? '';
        _sex = _normalizedSex((data['sex'] ?? data['gender'] ?? '') as String);
        _civilStatusController.text = civilStatus is String
            ? _normalizedCivilStatus(civilStatus) ?? ''
            : '';
        _mobileController.text =
            (data['contactNumber'] ?? data['contact_number'] ?? '') as String;
        _emailController.text = (data['email'] ?? user.email ?? '') as String;
        _streetController.text = (data['address'] ?? '') as String;
        _barangayController.text =
            (data['barangay'] ?? data['brgy'] ?? '') as String;
        _municipalityController.text = (data['municipality'] ?? '') as String;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _reportingForSelf = false);
      _showSnackBar('Unable to load your profile: $e');
    } finally {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  void _clearPatientFields() {
    setState(() {
      _lastNameController.clear();
      _firstNameController.clear();
      _middleNameController.clear();
      _suffixController.clear();
      _dobController.clear();
      _ageController.clear();
      _civilStatusController.clear();
      _guardianNameController.clear();
      _guardianContactController.clear();
      _patientVaccinated = null;
      _previousVaccinationDetailsController.clear();
      _allergiesKnown = null;
      _allergyDetailsController.clear();
      _medicalProblemsController.clear();
      _currentMedicationsController.clear();
      _otherMedicalInfoController.clear();
      _mobileController.clear();
      _emailController.clear();
      _municipalityController.clear();
      _barangayController.clear();
      _streetController.clear();
      _dateOfBirth = null;
      _sex = null;
    });
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() {
      _dateOfBirth = picked;
      _dobController.text = _formatDate(picked);
      _ageController.text = _calculateAge(picked).toString();
      if ((_calculateAge(picked) ?? 18) >= 18) {
        _guardianNameController.clear();
        _guardianContactController.clear();
      }
    });
  }

  Future<void> _pickPhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (picked == null) return;
    setState(() => _animalPhoto = File(picked.path));
  }

  void _continueToReview() {
    setState(() => _showPageErrors = true);
    if (!_formKey.currentState!.validate()) return;
    if (_washedWound == null) {
      _showSnackBar('Please indicate if the wound was washed.');
      return;
    }
    setState(() {
      _reviewPage = 0;
      _reviewing = true;
    });
  }

  Future<void> _confirmAndSubmit() async {
    if (_isSubmitting) return;
    if (!_certified) {
      _showSnackBar('Please certify that the information is true and correct.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Submit animal bite report?'),
        content: const Text(
          'Your report will be sent to the appropriate ABTC for review. This submission does not confirm a diagnosis or treatment.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm submission'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) await _submit();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar('Please sign in to submit a report.');
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      return;
    }
    if (!_certified) {
      _showSnackBar('Please certify that the information is true and correct.');
      return;
    }

    setState(() => _isSubmitting = true);
    final submittedAt = DateTime.now();
    final caseId =
        'CRIS-${submittedAt.year}${submittedAt.month.toString().padLeft(2, '0')}${submittedAt.day.toString().padLeft(2, '0')}-${submittedAt.millisecondsSinceEpoch}';
    const status = 'Pending ABTC Claim';

    try {
      final report = Report(
        lastName: _lastNameController.text.trim(),
        firstName: _firstNameController.text.trim(),
        middleInitial: _middleNameController.text.trim(),
        suffix: _suffixController.text.trim(),
        age: _ageController.text.trim(),
        gender: _sex ?? '',
        contactNumber: _mobileController.text.trim(),
        address: _addressSummary,
        dateOfIncident: '',
        timeOfIncident: '',
        locationOfIncident: '',
        exposureType: '',
        animalSpecies: _selectedAnimalType,
        animalOwnership: _ownership,
        animalVaccinationStatus: _animalVaccinated ?? '',
        incidentDescription: '',
        firstAidGiven: _firstAidSummary,
        patientVaccinationStatus: _patientVaccinated ?? '',
        reportedAt: submittedAt,
      );
      await Hive.box<Report>('reports').add(report);

      final evidenceUrls = await _uploadEvidence(user.uid, caseId);
      await FirebaseFirestore.instance.collection('patients').doc(caseId).set({
        'caseId': caseId,
        'userId': user.uid,
        'reportingForSelf': _reportingForSelf,
        'submittedBy': user.uid,
        'facility': {
          'id': widget.facilityId,
          'name': widget.facilityName,
          'code': widget.facilityCode,
        },
        'patient': {
          'lastName': _lastNameController.text.trim(),
          'firstName': _firstNameController.text.trim(),
          'middleName': _middleNameController.text.trim(),
          'suffix': _suffixController.text.trim(),
          'sex': _sex,
          'rabiesVaccinationStatus': _patientVaccinated,
          'dateOfBirth': _dobController.text.trim(),
          'age': int.tryParse(_ageController.text.trim()),
          'civilStatus': _civilStatusController.text.trim(),
          'mobileNumber': _mobileController.text.trim(),
          'emailAddress': _emailController.text.trim(),
          'province': _provinceController.text.trim(),
          'municipality': _municipalityController.text.trim(),
          'barangay': _barangayController.text.trim(),
          'streetAddress': _streetController.text.trim(),
          'fullName': _patientName,
          'guardianName': _guardianNameController.text.trim(),
          'guardianContactNumber': _guardianContactController.text.trim(),
        },
        'animal': {
          'type': _selectedAnimalType,
          'species': _selectedAnimalType,
          'ownership': _ownership,
          'sex': _animalSex,
          'breed': _breedController.text.trim(),
          'color': _colorController.text.trim(),
          'approximateAge': _animalAgeController.text.trim(),
          'isAlive': _animalAlive,
          'availableForObservation': _animalAvailable,
          'vaccinatedAgainstRabies': _animalVaccinated,
          'suspiciousBehaviors': _behaviors.toList()..sort(),
        },
        'firstAid': {
          'washedWithSoapAndWater': _washedWound,
          'washMinutes': int.tryParse(_washMinutesController.text.trim()),
          'substanceApplied': _selectedSubstance,
        },
        'medicalHistory': {
          'residentReported': true,
          'previousVaccinationDetails':
              _previousVaccinationDetailsController.text.trim(),
          'knownAllergies': _allergiesKnown,
          'allergyDetails': _allergyDetailsController.text.trim(),
          'medicalProblems': _medicalProblemsController.text.trim(),
          'currentMedications': _currentMedicationsController.text.trim(),
          'otherInformation': _otherMedicalInfoController.text.trim(),
        },
        'evidence': evidenceUrls,
        'status': status,
        'claimedByAbtc': false,
        'claimedByAbtcId': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'submittedAt': submittedAt.toIso8601String(),
      });

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => _ReportSuccessPage(
            caseId: caseId,
            status: status,
            submittedAt: submittedAt,
          ),
        ),
      );
    } catch (e) {
      _showSnackBar('Unable to submit bite report: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<Map<String, String>> _uploadEvidence(
      String userId, String caseId) async {
    final evidence = <String, String>{};
    final storage =
        FirebaseStorage.instance.ref('bite_reports/$userId/$caseId');
    if (_animalPhoto != null) {
      final ref = storage.child('animal.jpg');
      await ref.putFile(_animalPhoto!);
      evidence['animalPhotoUrl'] = await ref.getDownloadURL();
    }
    return evidence;
  }

  String get _patientName => [
        _lastNameController.text.trim(),
        _firstNameController.text.trim(),
        _middleNameController.text.trim(),
        _suffixController.text.trim(),
      ].where((value) => value.isNotEmpty).join(', ');

  String get _addressSummary => [
        _streetController.text.trim(),
        _barangayController.text.trim(),
        _municipalityController.text.trim(),
        _provinceController.text.trim(),
      ].where((value) => value.isNotEmpty).join(', ');

  String get _selectedAnimalType => _animalType == 'Others'
      ? _otherAnimalController.text.trim()
      : _animalType;

  String get _selectedSubstance => _substance == 'Other'
      ? _otherSubstanceController.text.trim()
      : _substance;

  String get _firstAidSummary {
    final wash = _washedWound == 'Yes'
        ? 'Washed for ${_washMinutesController.text.trim()} minutes'
        : 'Not washed with soap and water';
    return '$wash; Substance applied: $_selectedSubstance';
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    return null;
  }

  String? _numberRequired(String? value, String label) {
    final message = _required(value, label);
    if (message != null) return message;
    final number = int.tryParse(value!.trim());
    if (number == null || number < 0) return '$label must be a valid number';
    return null;
  }

  String? _optionalEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    return text.contains('@') ? null : 'Enter a valid email address';
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  int? _calculateAge(DateTime? dob) {
    if (dob == null) return null;
    final now = DateTime.now();
    var age = now.year - dob.year;
    final hadBirthday =
        now.month > dob.month || (now.month == dob.month && now.day >= dob.day);
    if (!hadBirthday) age--;
    return age;
  }

  String? _normalizedSex(String value) {
    if (value == 'Male' || value == 'Female') return value;
    return null;
  }

  String? _normalizedCivilStatus(String value) {
    if (value == 'Single' || value == 'Married' || value == 'Divorced') {
      return value;
    }
    return null;
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 6),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _municipalityField({
    required TextEditingController controller,
    required String label,
    bool enabled = true,
    TextEditingController? dependentBarangayController,
  }) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: controller.text),
      optionsBuilder: (value) {
        final query = value.text.trim().toLowerCase();
        if (query.isEmpty) return iloiloMunicipalities;
        return iloiloMunicipalities.where(
          (municipality) => municipality.toLowerCase().contains(query),
        );
      },
      onSelected: (value) {
        if (controller.text != value) dependentBarangayController?.clear();
        controller.text = value;
      },
      fieldViewBuilder: (context, textController, focusNode, onSubmitted) {
        if (textController.text != controller.text) {
          textController.text = controller.text;
        }
        return TextFormField(
          controller: textController,
          focusNode: focusNode,
          enabled: enabled,
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: const Icon(Icons.search),
          ),
          textCapitalization: TextCapitalization.words,
          onChanged: (value) {
            if (controller.text != value &&
                dependentBarangayController != null) {
              dependentBarangayController.clear();
            }
            controller.text = value;
          },
          validator: (value) => _required(value, label),
        );
      },
    );
  }

  Widget _choiceChips({
    required List<String> values,
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values
          .map(
            (value) => ChoiceChip(
              label: Text(value),
              selected: selected == value,
              onSelected: (_) => setState(() => onSelected(value)),
            ),
          )
          .toList(),
    );
  }

  Widget _yesNoUnknown({
    required String label,
    required String selected,
    required ValueChanged<String> onSelected,
    List<String> values = const ['Yes', 'No', 'Unknown'],
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        _choiceChips(
          values: values,
          selected: selected,
          onSelected: onSelected,
        ),
      ],
    );
  }

  Widget _radioLine({
    required String label,
    required String? groupValue,
    required List<String> values,
    required ValueChanged<String?> onChanged,
  }) {
    return FormField<String>(
      initialValue: groupValue,
      validator: (value) => value == null ? '$label is required' : null,
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: field.hasError
                      ? Border.all(color: AppColors.danger)
                      : null,
                ),
                child: SegmentedButton<String>(
                  segments: values
                      .map((value) =>
                          ButtonSegment(value: value, label: Text(value)))
                      .toList(),
                  selected: groupValue == null ? <String>{} : {groupValue},
                  emptySelectionAllowed: true,
                  onSelectionChanged: (next) {
                    if (next.isEmpty) return;
                    final value = next.first;
                    onChanged(value);
                    field.didChange(value);
                  },
                ),
              ),
            ],
          ),
          if (field.hasError)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                field.errorText!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _photoPicker(String label, File? file) {
    return OutlinedButton.icon(
      onPressed: _pickPhoto,
      icon:
          Icon(file == null ? Icons.add_photo_alternate_outlined : Icons.check),
      label: Text(file == null ? label : '$label selected'),
    );
  }

  List<_SummarySection> get _summarySections => [
        _SummarySection('Patient Information', 0, [
          _SummaryItem('Patient Name', _patientName),
          _SummaryItem('Sex', _sex ?? ''),
          _SummaryItem('Date of Birth', _dobController.text),
          _SummaryItem('Age', _ageController.text),
          _SummaryItem('Civil Status', _civilStatusController.text),
          _SummaryItem('Mobile Number', _mobileController.text),
          _SummaryItem('Email Address', _emailController.text),
          _SummaryItem('Residential Address', _addressSummary),
          if (_isMinor) ...[
            _SummaryItem('Parent / Guardian', _guardianNameController.text),
            _SummaryItem('Guardian Contact', _guardianContactController.text),
          ],
        ]),
        _SummarySection('Animal Information', 1, [
          _SummaryItem('Species', _selectedAnimalType),
          _SummaryItem('Ownership', _ownership),
          _SummaryItem('Animal Sex', _animalSex),
          _SummaryItem('Breed', _breedController.text),
          _SummaryItem('Color', _colorController.text),
          _SummaryItem('Approximate Age', _animalAgeController.text),
          _SummaryItem('Animal Status', _animalAlive),
          _SummaryItem('Available for Observation', _animalAvailable),
          _SummaryItem(
              'Animal Rabies Vaccination Status', _animalVaccinated ?? ''),
          _SummaryItem('Observed Behavior', _behaviors.join(', ')),
          _SummaryItem('Animal Photo', _animalPhoto == null ? '' : 'Selected'),
        ]),
        _SummarySection('First Aid Performed', 3, [
          _SummaryItem('Washed with Soap and Water', _washedWound ?? ''),
          _SummaryItem('Wash Minutes', _washMinutesController.text),
          _SummaryItem('Substance Applied', _selectedSubstance),
        ]),
        _SummarySection('Relevant Medical History', 3, [
          _SummaryItem(
              'Patient Rabies Vaccination Status', _patientVaccinated ?? ''),
          _SummaryItem('Previous Vaccination Details',
              _previousVaccinationDetailsController.text),
          _SummaryItem('Known Allergies', _allergiesKnown ?? ''),
          _SummaryItem('Allergy Details', _allergyDetailsController.text),
          _SummaryItem('Medical Problems', _medicalProblemsController.text),
          _SummaryItem(
              'Current Medications', _currentMedicationsController.text),
          _SummaryItem(
              'Other Medical Information', _otherMedicalInfoController.text),
        ]),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        toolbarHeight: 56,
        title: const Text('Animal Bite Report',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _reviewing
                  ? _buildReview()
                  : Theme(
                      data: Theme.of(context).copyWith(
                        inputDecorationTheme:
                            Theme.of(context).inputDecorationTheme.copyWith(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 12,
                                  ),
                                ),
                      ),
                      child: _buildForm(),
                    ),
            ),
            _reviewing ? _buildReviewNavigation() : _buildFormNavigation(),
          ],
        ),
      ),
    );
  }

  List<Widget> _patientFields() => _withGaps([
        SwitchListTile(
          value: _reportingForSelf,
          onChanged: _isLoadingProfile ? null : _setReportingForSelf,
          title: const Text('Reporting for self?'),
          subtitle: const Text('Use saved profile details'),
          secondary: _isLoadingProfile
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.person_outline),
          contentPadding: EdgeInsets.zero,
          dense: true,
          visualDensity: const VisualDensity(vertical: -2),
        ),
        _sectionTitle('Patient Information', Icons.person_outline),
        Row(children: [
          Expanded(child: _patientLastNameField()),
          const SizedBox(width: 10),
          Expanded(child: _patientSuffixField()),
        ]),
        _patientNameFields(),
        Row(children: [
          Expanded(child: _patientSexField()),
          const SizedBox(width: 10),
          Expanded(child: _patientCivilStatusField()),
        ]),
        Row(children: [
          Expanded(child: _patientDobField()),
          const SizedBox(width: 10),
          Expanded(child: _patientAgeField()),
        ]),
        Row(children: [
          Expanded(child: _patientMobileField()),
          const SizedBox(width: 10),
          Expanded(child: _patientEmailField()),
        ]),
        Row(children: [
          Expanded(child: _patientProvinceField()),
          const SizedBox(width: 10),
          Expanded(child: _patientMunicipalityField()),
        ]),
        if (_isMinor) ...[
          Row(children: [
            Expanded(child: _guardianNameField()),
            const SizedBox(width: 10),
            Expanded(child: _guardianContactField()),
          ]),
        ],
        Row(children: [
          Expanded(child: _patientBarangayField()),
          const SizedBox(width: 10),
          Expanded(child: _patientStreetField()),
        ]),
      ], gap: 10);

  List<Widget> _withGaps(List<Widget> fields, {double gap = 8}) => [
        for (var i = 0; i < fields.length; i++) ...[
          if (i > 0) SizedBox(height: gap),
          fields[i],
        ],
      ];

  Widget _patientLastNameField() => TextFormField(
        controller: _lastNameController,
        readOnly: _patientFieldsReadOnly,
        decoration: const InputDecoration(labelText: 'Last Name'),
        textCapitalization: TextCapitalization.words,
        validator: (value) => _required(value, 'Last Name'),
      );

  Widget _patientSuffixField() => TextFormField(
        controller: _suffixController,
        readOnly: _patientFieldsReadOnly,
        decoration: const InputDecoration(labelText: 'Suffix (Optional)'),
        textCapitalization: TextCapitalization.words,
      );

  Widget _patientSexField() => DropdownButtonFormField<String>(
        initialValue: _sex,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Sex'),
        items: const [
          DropdownMenuItem(value: 'Male', child: Text('Male')),
          DropdownMenuItem(value: 'Female', child: Text('Female')),
        ],
        onChanged: _patientFieldsReadOnly
            ? null
            : (value) => setState(() => _sex = value),
        validator: (value) => value == null ? 'Sex is required' : null,
      );

  Widget _patientCivilStatusField() => DropdownButtonFormField<String>(
        initialValue: _normalizedCivilStatus(_civilStatusController.text),
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Civil Status'),
        items: const [
          DropdownMenuItem(value: 'Single', child: Text('Single')),
          DropdownMenuItem(value: 'Married', child: Text('Married')),
          DropdownMenuItem(value: 'Divorced', child: Text('Divorced')),
        ],
        onChanged: _patientFieldsReadOnly
            ? null
            : (value) => setState(
                  () => _civilStatusController.text = value ?? '',
                ),
      );

  Widget _patientDobField() => TextFormField(
        controller: _dobController,
        readOnly: true,
        decoration: const InputDecoration(
          labelText: 'Date of Birth',
          suffixIcon: Icon(Icons.calendar_today_outlined),
        ),
        onTap: _patientFieldsReadOnly ? null : _pickBirthDate,
        validator: (value) => _required(value, 'Date of Birth'),
      );

  Widget _patientAgeField() => TextFormField(
        controller: _ageController,
        readOnly: true,
        decoration: const InputDecoration(labelText: 'Age'),
        validator: (value) => _required(value, 'Age'),
      );

  Widget _patientMobileField() => TextFormField(
        controller: _mobileController,
        readOnly: _patientFieldsReadOnly,
        decoration: const InputDecoration(labelText: 'Mobile Number'),
        keyboardType: TextInputType.phone,
        validator: (value) => _required(value, 'Mobile Number'),
      );

  Widget _patientEmailField() => TextFormField(
        controller: _emailController,
        readOnly: _patientFieldsReadOnly,
        decoration: const InputDecoration(labelText: 'Email Address'),
        keyboardType: TextInputType.emailAddress,
        validator: _optionalEmail,
      );

  Widget _patientProvinceField() => TextFormField(
        controller: _provinceController,
        readOnly: _patientFieldsReadOnly,
        decoration: const InputDecoration(labelText: 'Province'),
        validator: (value) => _required(value, 'Province'),
      );

  Widget _patientMunicipalityField() => _municipalityField(
        controller: _municipalityController,
        label: 'Municipality/City',
        enabled: !_patientFieldsReadOnly,
        dependentBarangayController: _barangayController,
      );

  Widget _guardianNameField() => TextFormField(
        controller: _guardianNameController,
        decoration: const InputDecoration(labelText: 'Parent / Guardian'),
        textCapitalization: TextCapitalization.words,
        validator: (value) => _required(value, 'Parent / Guardian Name'),
      );

  Widget _guardianContactField() => TextFormField(
        controller: _guardianContactController,
        decoration: const InputDecoration(labelText: 'Guardian Contact'),
        keyboardType: TextInputType.phone,
        validator: (value) =>
            _required(value, 'Parent / Guardian Contact Number'),
      );

  Widget _patientBarangayField() => TextFormField(
        controller: _barangayController,
        readOnly: _patientFieldsReadOnly,
        decoration: const InputDecoration(labelText: 'Barangay'),
        textCapitalization: TextCapitalization.words,
        validator: (value) => _required(value, 'Barangay'),
      );

  Widget _patientStreetField() => TextFormField(
        controller: _streetController,
        readOnly: _patientFieldsReadOnly,
        decoration:
            const InputDecoration(labelText: 'House Number / Street / Purok'),
        textCapitalization: TextCapitalization.sentences,
        validator: (value) => _required(value, 'Street Address'),
      );

  Widget _patientNameFields() {
    final firstName = TextFormField(
      controller: _firstNameController,
      readOnly: _patientFieldsReadOnly,
      decoration: const InputDecoration(labelText: 'First Name'),
      textCapitalization: TextCapitalization.words,
      validator: (value) => _required(value, 'First Name'),
    );
    final middleName = TextFormField(
      controller: _middleNameController,
      readOnly: _patientFieldsReadOnly,
      decoration: const InputDecoration(labelText: 'Middle Name'),
      textCapitalization: TextCapitalization.words,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 340) {
          return Column(
            children: [firstName, const SizedBox(height: 10), middleName],
          );
        }
        return Row(
          children: [
            Expanded(child: firstName),
            const SizedBox(width: 8),
            Expanded(child: middleName),
          ],
        );
      },
    );
  }

  List<Widget> _animalFields() => [
        _sectionTitle('Animal Information', Icons.pets_outlined),
        _choiceChips(
          values: const ['Dog', 'Cat', 'Others'],
          selected: _animalType,
          onSelected: (value) => _animalType = value,
        ),
        if (_animalType == 'Others') ...[
          const SizedBox(height: 10),
          TextFormField(
            controller: _otherAnimalController,
            decoration: const InputDecoration(labelText: 'Others (Specify)'),
            validator: (value) => _required(value, 'Animal type'),
          ),
        ],
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _ownership,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Ownership'),
          items: const [
            DropdownMenuItem(
                value: 'Owned (Caged)', child: Text('Owned (Caged)')),
            DropdownMenuItem(
                value: 'Owned (Allowed to Roam)',
                child: Text('Owned (Allowed to Roam)')),
            DropdownMenuItem(value: 'Stray', child: Text('Stray')),
            DropdownMenuItem(value: 'Unknown', child: Text('Unknown')),
          ],
          onChanged: (value) => setState(() => _ownership = value ?? 'Stray'),
        ),
        const SizedBox(height: 10),
        _choiceChips(
          values: const ['Male', 'Female', 'Unknown'],
          selected: _animalSex,
          onSelected: (value) => _animalSex = value,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _breedController,
                decoration: const InputDecoration(labelText: 'Breed'),
                textCapitalization: TextCapitalization.words,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _colorController,
                decoration: const InputDecoration(labelText: 'Color'),
                textCapitalization: TextCapitalization.words,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _animalAgeController,
          decoration:
              const InputDecoration(labelText: 'Approximate Age (Optional)'),
        ),
        const SizedBox(height: 12),
        _yesNoUnknown(
          label: 'Is the animal alive?',
          selected: _animalAlive,
          onSelected: (value) => _animalAlive = value,
        ),
        const SizedBox(height: 12),
        _yesNoUnknown(
          label: 'Is the animal available for observation?',
          selected: _animalAvailable,
          onSelected: (value) => _animalAvailable = value,
        ),
        const SizedBox(height: 12),
        _yesNoUnknown(
          label: 'Animal Rabies Vaccination Status',
          selected: _animalVaccinated ?? '',
          onSelected: (value) => setState(() => _animalVaccinated = value),
        ),
      ];

  List<Widget> _animalBehaviorFields() => [
        _sectionTitle(
            'Suspicious Animal Behavior', Icons.warning_amber_outlined),
        ..._suspiciousBehaviors.map(
          (behavior) => CheckboxListTile(
            value: _behaviors.contains(behavior),
            dense: true,
            visualDensity: const VisualDensity(vertical: -1),
            contentPadding: EdgeInsets.zero,
            title: Text(behavior),
            onChanged: (checked) => setState(() {
              if (checked ?? false) {
                if (behavior == 'No suspicious behavior observed' ||
                    behavior == 'Unknown') {
                  _behaviors.clear();
                } else {
                  _behaviors.remove('No suspicious behavior observed');
                  _behaviors.remove('Unknown');
                }
                _behaviors.add(behavior);
              } else {
                _behaviors.remove(behavior);
              }
            }),
          ),
        ),
        const SizedBox(height: 10),
        _photoPicker('Upload Photo of the Animal (Optional)', _animalPhoto),
      ];

  List<Widget> _firstAidFields() => [
        _sectionTitle('First Aid Performed', Icons.medical_services_outlined),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: _radioLine(
              label: 'Was the wound washed?',
              groupValue: _washedWound,
              values: const ['Yes', 'No'],
              onChanged: (value) => setState(() => _washedWound = value),
            ),
          ),
          if (_washedWound == 'Yes') ...[
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _washMinutesController,
                decoration:
                    const InputDecoration(labelText: 'Wash time (minutes)'),
                keyboardType: TextInputType.number,
                validator: (value) => _numberRequired(value, 'Wash minutes'),
              ),
            ),
          ],
        ]),
        if (_substance == 'Other')
          Row(children: [
            Expanded(child: _substanceField()),
            const SizedBox(width: 10),
            Expanded(child: _otherSubstanceField()),
          ])
        else
          _substanceField(),
      ];

  Widget _substanceField() => DropdownButtonFormField<String>(
        initialValue: _substance,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Substance applied'),
        items: const [
          DropdownMenuItem(value: 'None', child: Text('None')),
          DropdownMenuItem(value: 'Alcohol', child: Text('Alcohol')),
          DropdownMenuItem(value: 'Betadine', child: Text('Betadine')),
          DropdownMenuItem(
              value: 'Herbal Remedy', child: Text('Herbal Remedy')),
          DropdownMenuItem(value: 'Other', child: Text('Other')),
        ],
        onChanged: (value) => setState(() => _substance = value ?? 'None'),
      );

  Widget _otherSubstanceField() => TextFormField(
        controller: _otherSubstanceController,
        decoration: const InputDecoration(labelText: 'Other Specify'),
        validator: (value) => _required(value, 'Substance applied'),
      );

  List<Widget> _medicalHistoryFields() => [
        _sectionTitle(
            'Relevant Medical History', Icons.health_and_safety_outlined),
        const Text(
            'Resident-reported information; this does not confirm diagnosis or treatment.'),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: _yesNoUnknown(
              label: 'Patient Rabies Vaccination',
              selected: _patientVaccinated ?? '',
              onSelected: (value) => setState(() {
                _patientVaccinated = value;
                if (value == 'No') {
                  _previousVaccinationDetailsController.clear();
                }
              }),
              values: const ['Yes', 'No', 'Unsure'],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _yesNoUnknown(
              label: 'Known Allergies',
              selected: _allergiesKnown ?? '',
              onSelected: (value) => setState(() {
                _allergiesKnown = value;
                if (value != 'Yes') _allergyDetailsController.clear();
              }),
              values: const ['Yes', 'No', 'Unsure'],
            ),
          ),
        ]),
        if (_patientVaccinated == 'Yes' ||
            _patientVaccinated == 'Unsure' ||
            _patientVaccinated == 'Unknown' ||
            _allergiesKnown == 'Yes')
          Row(children: [
            if (_patientVaccinated == 'Yes' ||
                _patientVaccinated == 'Unsure' ||
                _patientVaccinated == 'Unknown')
              Expanded(
                child: TextFormField(
                  controller: _previousVaccinationDetailsController,
                  decoration: const InputDecoration(
                      labelText: 'Previous vaccination details'),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 1,
                ),
              ),
            if ((_patientVaccinated == 'Yes' ||
                    _patientVaccinated == 'Unsure' ||
                    _patientVaccinated == 'Unknown') &&
                _allergiesKnown == 'Yes')
              const SizedBox(width: 10),
            if (_allergiesKnown == 'Yes')
              Expanded(
                child: TextFormField(
                  controller: _allergyDetailsController,
                  decoration:
                      const InputDecoration(labelText: 'Allergy details'),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 1,
                ),
              ),
          ]),
        Row(children: [
          Expanded(
            child: TextFormField(
              controller: _medicalProblemsController,
              decoration: const InputDecoration(labelText: 'Medical problems'),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              controller: _currentMedicationsController,
              decoration:
                  const InputDecoration(labelText: 'Current medications'),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 1,
            ),
          ),
        ]),
        TextFormField(
          controller: _otherMedicalInfoController,
          decoration: const InputDecoration(
              labelText: 'Other relevant medical information'),
          textCapitalization: TextCapitalization.sentences,
          maxLines: 1,
        ),
      ];

  List<Widget> _remainingFields() => _withGaps([
        _sectionTitle('Remaining Information', Icons.assignment_outlined),
        ..._firstAidFields(),
        ..._medicalHistoryFields(),
      ], gap: 6);

  int _currentPage = 0;

  List<_FormPage> get _formPages => [
        _FormPage('Patient Information', _patientFields()),
        _FormPage('Animal Information', _animalFields()),
        _FormPage('Suspicious Animal Behavior', _animalBehaviorFields()),
        _FormPage('Remaining Information', _remainingFields()),
      ];

  void _goToNextPage() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_currentPage == _formPages.length - 1) {
      _continueToReview();
      return;
    }
    setState(() => _showPageErrors = true);
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _currentPage++;
      _showPageErrors = false;
    });
    _formScrollController.jumpTo(0);
  }

  int _firstPageForSection(String title) {
    final sectionTitle = switch (title) {
      'Relevant Medical History' ||
      'First Aid Performed' =>
        'Remaining Information',
      _ => title,
    };
    final pageIndex =
        _formPages.indexWhere((page) => page.title == sectionTitle);
    return pageIndex < 0 ? 0 : pageIndex;
  }

  Widget _buildForm() {
    final pages = _formPages;
    final step = _currentPage + 1;
    final page = pages[_currentPage];
    return Form(
      key: _formKey,
      autovalidateMode: _showPageErrors
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ReportFormProgressHeader(
                  pageTitle: page.title,
                  currentPage: step,
                  totalPages: pages.length,
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _formScrollController,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...page.fields,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormNavigation() => ReportFormNavigation(
        onBack: _currentPage > 0
            ? () {
                FocusManager.instance.primaryFocus?.unfocus();
                setState(() => _currentPage--);
                _formScrollController.jumpTo(0);
              }
            : null,
        onNext: _goToNextPage,
        nextLabel: _currentPage == _formPages.length - 1 ? 'Submit' : 'Next',
        nextIcon: _currentPage == _formPages.length - 1
            ? Icons.fact_check_outlined
            : Icons.arrow_forward,
      );

  Widget _buildReview() {
    final pages = _reviewPages;
    final isCertification = _reviewPage == pages.length;
    final page = isCertification ? null : pages[_reviewPage];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                  'Review and Submit · Page ${_reviewPage + 1} of ${pages.length + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                  value: (_reviewPage + 1) / (pages.length + 1)),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: isCertification
                ? _reviewCertification()
                : Card(
                    color: Colors.white,
                    margin: EdgeInsets.zero,
                    child: Column(
                      children: [
                        ListTile(
                          title: Text(page!.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          trailing: TextButton.icon(
                            onPressed: () => setState(() {
                              _reviewing = false;
                              _currentPage = _firstPageForSection(page.title);
                            }),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Edit'),
                          ),
                        ),
                        for (final item in page.items) _SummaryRow(item: item),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewNavigation() {
    final isCertification = _reviewPage == _reviewPages.length;
    return ReportFormNavigation(
      onBack: () => setState(() {
        if (_reviewPage == 0) {
          _reviewing = false;
          _currentPage = _formPages.length - 1;
        } else {
          _reviewPage--;
        }
      }),
      onNext: isCertification
          ? _confirmAndSubmit
          : () => setState(() => _reviewPage++),
      nextLabel: isCertification ? 'Submit' : 'Next',
      nextIcon:
          isCertification ? Icons.fact_check_outlined : Icons.arrow_forward,
      nextEnabled: !isCertification || !_isSubmitting,
    );
  }

  List<_ReviewPage> get _reviewPages => [
        for (final section in _summarySections)
          for (var start = 0; start < section.items.length; start += 4)
            _ReviewPage(
              section.title,
              section.items.skip(start).take(4).toList(),
            ),
      ];

  Widget _reviewCertification() => Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle('Review complete', Icons.assignment_turned_in_outlined),
          const Text(
            'Your report will be reviewed by the appropriate ABTC. Submitting this report does not confirm a diagnosis or treatment.',
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            value: _certified,
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'I certify that the information provided is true and correct to the best of my knowledge.',
            ),
            onChanged: (value) => setState(() => _certified = value ?? false),
          ),
        ],
      );
}

class _FormPage {
  const _FormPage(this.title, this.fields);

  final String title;
  final List<Widget> fields;
}

class _ReviewPage {
  const _ReviewPage(this.title, this.items);

  final String title;
  final List<_SummaryItem> items;
}

class _SummarySection {
  const _SummarySection(this.title, this.page, this.items);

  final String title;
  final int page;
  final List<_SummaryItem> items;
}

class _SummaryItem {
  const _SummaryItem(this.label, this.value);

  final String label;
  final String value;
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.item});

  final _SummaryItem item;

  @override
  Widget build(BuildContext context) {
    final value =
        item.value.trim().isEmpty ? 'Not provided' : item.value.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 138,
            child: Text(
              item.label,
              style: const TextStyle(
                  color: Colors.black54, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportSuccessPage extends StatelessWidget {
  const _ReportSuccessPage({
    required this.caseId,
    required this.status,
    required this.submittedAt,
  });

  final String caseId;
  final String status;
  final DateTime submittedAt;

  String get _submittedAtText {
    final date =
        '${submittedAt.year}-${submittedAt.month.toString().padLeft(2, '0')}-${submittedAt.day.toString().padLeft(2, '0')}';
    final hour = submittedAt.hour > 12
        ? submittedAt.hour - 12
        : submittedAt.hour == 0
            ? 12
            : submittedAt.hour;
    final minute = submittedAt.minute.toString().padLeft(2, '0');
    final period = submittedAt.hour >= 12 ? 'PM' : 'AM';
    return '$date $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Report Submitted')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.check_circle,
                  color: AppColors.primary, size: 72),
              const SizedBox(height: 18),
              Text(
                'Animal Bite Report Submitted',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 24),
              _SuccessLine(label: 'Case ID', value: caseId),
              _SuccessLine(label: 'Report Status', value: status),
              _SuccessLine(
                  label: 'Submission Date and Time', value: _submittedAtText),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessLine extends StatelessWidget {
  const _SuccessLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
