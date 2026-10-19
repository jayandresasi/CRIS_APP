import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../models/report.dart';
import '../theme.dart';
import '../widgets/cris_map.dart';
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

class _BodySite {
  final String name;
  final Alignment alignment;

  const _BodySite(this.name, this.alignment);
}

const List<_BodySite> _frontBodySites = [
  _BodySite('Head / Scalp', Alignment(0, -0.92)),
  _BodySite('Face', Alignment(0, -0.70)),
  _BodySite('Left Ear', Alignment(-0.28, -0.92)),
  _BodySite('Right Ear', Alignment(0.28, -0.92)),
  _BodySite('Neck', Alignment(0, -0.56)),
  _BodySite('Left Shoulder', Alignment(-0.50, -0.28)),
  _BodySite('Right Shoulder', Alignment(0.50, -0.28)),
  _BodySite('Chest', Alignment(0, -0.08)),
  _BodySite('Abdomen', Alignment(0, 0.12)),
  _BodySite('Pelvic / Groin', Alignment(0, 0.34)),
  _BodySite('Left Upper Arm', Alignment(-0.70, 0.02)),
  _BodySite('Right Upper Arm', Alignment(0.70, 0.02)),
  _BodySite('Left Elbow', Alignment(-0.72, 0.26)),
  _BodySite('Right Elbow', Alignment(0.72, 0.26)),
  _BodySite('Left Forearm', Alignment(-0.72, 0.46)),
  _BodySite('Right Forearm', Alignment(0.72, 0.46)),
  _BodySite('Left Wrist', Alignment(-0.72, 0.62)),
  _BodySite('Right Wrist', Alignment(0.72, 0.62)),
  _BodySite('Left Hand', Alignment(-0.72, 0.74)),
  _BodySite('Right Hand', Alignment(0.72, 0.74)),
  _BodySite('Left Fingers', Alignment(-0.72, 0.86)),
  _BodySite('Right Fingers', Alignment(0.72, 0.86)),
  _BodySite('Left Thigh', Alignment(-0.32, 0.62)),
  _BodySite('Right Thigh', Alignment(0.32, 0.62)),
  _BodySite('Left Knee', Alignment(-0.32, 0.80)),
  _BodySite('Right Knee', Alignment(0.32, 0.80)),
  _BodySite('Left Lower Leg', Alignment(-0.25, 0.92)),
  _BodySite('Right Lower Leg', Alignment(0.25, 0.92)),
  _BodySite('Left Ankle', Alignment(-0.20, 1.00)),
  _BodySite('Right Ankle', Alignment(0.20, 1.00)),
  _BodySite('Left Foot', Alignment(-0.10, 1.08)),
  _BodySite('Right Foot', Alignment(0.10, 1.08)),
  _BodySite('Left Toes', Alignment(-0.30, 1.08)),
  _BodySite('Right Toes', Alignment(0.30, 1.08)),
];

const List<_BodySite> _backBodySites = [
  _BodySite('Upper Back', Alignment(0, -0.08)),
  _BodySite('Lower Back', Alignment(0, 0.18)),
  _BodySite('Buttocks', Alignment(0, 0.50)),
];

const LatLng _iloiloCenter = LatLng(10.7202, 122.5621);

class ReportingPage extends StatefulWidget {
  const ReportingPage({super.key});

  @override
  State<ReportingPage> createState() => _ReportingPageState();
}

class _ReportingPageState extends State<ReportingPage> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _suffixController = TextEditingController();
  final _dobController = TextEditingController();
  final _ageController = TextEditingController();
  final _civilStatusController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _provinceController = TextEditingController(text: 'Iloilo');
  final _municipalityController = TextEditingController();
  final _barangayController = TextEditingController();
  final _streetController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _incidentMunicipalityController = TextEditingController();
  final _incidentBarangayController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _otherAnimalController = TextEditingController();
  final _breedController = TextEditingController();
  final _colorController = TextEditingController();
  final _animalAgeController = TextEditingController();
  final _otherExposureController = TextEditingController();
  final _woundCountController = TextEditingController();
  final _washMinutesController = TextEditingController();
  final _otherSubstanceController = TextEditingController();

  DateTime? _dateOfBirth;
  DateTime? _dateOfBite;
  TimeOfDay? _timeOfBite;
  String? _sex;
  String _animalType = 'Dog';
  String _ownership = 'Stray';
  String _animalSex = 'Unknown';
  String _animalAlive = 'Unknown';
  String _animalAvailable = 'Unknown';
  String _animalVaccinated = 'Unknown';
  String _exposureType = 'Bite';
  String? _bleeding;
  String? _washedWound;
  String _substance = 'None';
  bool _multipleSites = false;
  String? _bodyDiagramError;
  bool _certified = false;
  bool _reviewing = false;
  bool _isSubmitting = false;
  bool _isLoadingProfile = false;
  bool _reportingForSelf = false;
  final bool _claimedByAbtc = false;
  LatLng? _incidentPin;
  File? _woundPhoto;
  File? _animalPhoto;
  final Set<String> _behaviors = {};
  final List<String> _bodySites = [];
  final _bodySiteCountController = TextEditingController();

  bool get _patientFieldsReadOnly => _reportingForSelf || _isLoadingProfile;

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
      _mobileController,
      _emailController,
      _provinceController,
      _municipalityController,
      _barangayController,
      _streetController,
      _dateController,
      _timeController,
      _incidentMunicipalityController,
      _incidentBarangayController,
      _descriptionController,
      _otherAnimalController,
      _breedController,
      _colorController,
      _animalAgeController,
      _otherExposureController,
      _woundCountController,
      _washMinutesController,
      _otherSubstanceController,
    ]) {
      controller.dispose();
    }
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
      setState(() {
        _firstNameController.text = parts.isNotEmpty ? parts.first : '';
        _lastNameController.text =
            parts.length > 1 ? parts.sublist(1).join(' ') : '';
        _dateOfBirth = parsedDob;
        _dobController.text = parsedDob == null ? '' : _formatDate(parsedDob);
        _ageController.text = _calculateAge(parsedDob)?.toString() ?? '';
        _sex = _normalizedSex((data['sex'] ?? data['gender'] ?? '') as String);
        _mobileController.text =
            (data['contactNumber'] ?? data['contact_number'] ?? '') as String;
        _streetController.text = (data['address'] ?? '') as String;
        _barangayController.text =
            (data['barangay'] ?? data['brgy'] ?? '') as String;
        _municipalityController.text = (data['municipality'] ?? '') as String;
      });
    } catch (e) {
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
    });
  }

  Future<void> _pickBiteDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBite ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() {
      _dateOfBite = picked;
      _dateController.text = _formatDate(picked);
    });
  }

  Future<void> _pickBiteTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _timeOfBite ?? TimeOfDay.now(),
    );
    if (picked == null) return;
    setState(() {
      _timeOfBite = picked;
      _timeController.text = picked.format(context);
    });
  }

  Future<void> _pickPhoto(_EvidenceType type) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (picked == null) return;
    setState(() {
      if (type == _EvidenceType.wound) {
        _woundPhoto = File(picked.path);
      } else {
        _animalPhoto = File(picked.path);
      }
    });
  }

  int? get _bodySiteTargetCount =>
      int.tryParse(_bodySiteCountController.text.trim());

  void _toggleMultipleSites(bool? value) {
    setState(() {
      _multipleSites = value ?? false;
      if (_multipleSites && _bodySiteCountController.text.trim().isEmpty) {
        _bodySiteCountController.text = '2';
      }
      if (!_multipleSites && _bodySites.length > 1) {
        final first = _bodySites.first;
        _bodySites
          ..clear()
          ..add(first);
      }
      _bodyDiagramError = null;
    });
  }

  void _selectBodySite(String site) {
    setState(() {
      if (_multipleSites) {
        if (_bodySites.contains(site)) {
          _bodySites.remove(site);
        } else {
          final maxSites = _bodySiteTargetCount;
          if (maxSites != null && _bodySites.length >= maxSites) {
            _showSnackBar(
                'You have already selected the maximum number of bite sites.');
            return;
          }
          _bodySites.add(site);
        }
      } else {
        if (_bodySites.isEmpty || _bodySites.first != site) {
          _bodySites
            ..clear()
            ..add(site);
        }
      }
      _bodyDiagramError = null;
    });
  }

  void _undoBodySelection() {
    if (_bodySites.isEmpty) return;
    setState(() {
      _bodySites.removeLast();
      _bodyDiagramError = null;
    });
  }

  void _removeBodySite(String site) {
    setState(() {
      _bodySites.remove(site);
      _bodyDiagramError = null;
    });
  }

  void _updateBodySiteCount(String value) {
    final count = int.tryParse(value);
    if (count == null || count < 2) return;
    if (count > 20) {
      _bodySiteCountController.text = '20';
      _bodySiteCountController.selection = TextSelection.fromPosition(
        TextPosition(offset: _bodySiteCountController.text.length),
      );
    }
    if (_bodySites.length > count) {
      setState(() {
        _bodySites.removeRange(count, _bodySites.length);
      });
    }
    _bodyDiagramError = null;
  }

  String? _validateSiteCount(String? value) {
    if (!_multipleSites) return null;
    if (value == null || value.trim().isEmpty) {
      return 'Enter the number of bite/scratch sites.';
    }
    final count = int.tryParse(value.trim());
    if (count == null) {
      return 'Enter a valid number between 2 and 20.';
    }
    if (count < 2 || count > 20) {
      return 'Value must be between 2 and 20.';
    }
    return null;
  }

  void _continueToReview() {
    if (!_formKey.currentState!.validate()) return;
    if (_bodySites.isEmpty) {
      _showSnackBar('Select at least one affected body part.');
      return;
    }
    if (_multipleSites) {
      final maxSites = _bodySiteTargetCount;
      if (maxSites == null) {
        _showSnackBar('Enter the number of bite/scratch sites.');
        return;
      }
      if (_bodySites.length != maxSites) {
        _showSnackBar('Please select exactly $maxSites body sites.');
        setState(() {
          _bodyDiagramError =
              'You must select exactly $maxSites sites before continuing.';
        });
        return;
      }
    }
    if (_bleeding == null) {
      _showSnackBar('Please indicate if there was bleeding.');
      return;
    }
    if (_washedWound == null) {
      _showSnackBar('Please indicate if the wound was washed.');
      return;
    }
    setState(() => _reviewing = true);
  }

  Widget _selectedBodyPartItem(int index, String bodyPart) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                bodyPart,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              onPressed: () => _removeBodySite(bodyPart),
              icon: const Icon(Icons.close, size: 20),
              tooltip: 'Remove site',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
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
        dateOfIncident: _dateController.text.trim(),
        timeOfIncident: _timeController.text.trim(),
        locationOfIncident: _incidentLocationSummary,
        exposureType: _selectedExposure,
        animalSpecies: _selectedAnimalType,
        animalOwnership: _ownership,
        animalVaccinationStatus: _animalVaccinated,
        incidentDescription: _descriptionController.text.trim(),
        firstAidGiven: _firstAidSummary,
        patientVaccinationStatus: '',
        reportedAt: submittedAt,
      );
      await Hive.box<Report>('reports').add(report);

      final evidenceUrls = await _uploadEvidence(user.uid, caseId);
      await FirebaseFirestore.instance
          .collection('bite_reports')
          .doc(caseId)
          .set({
        'caseId': caseId,
        'userId': user.uid,
        'reportingForSelf': _reportingForSelf,
        'submittedBy': user.uid,
        'patient': {
          'lastName': _lastNameController.text.trim(),
          'firstName': _firstNameController.text.trim(),
          'middleName': _middleNameController.text.trim(),
          'suffix': _suffixController.text.trim(),
          'sex': _sex,
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
        },
        'incident': {
          'date': _dateController.text.trim(),
          'time': _timeController.text.trim(),
          'municipality': _incidentMunicipalityController.text.trim(),
          'barangay': _incidentBarangayController.text.trim(),
          'description': _descriptionController.text.trim(),
          'latitude': _incidentPin?.latitude,
          'longitude': _incidentPin?.longitude,
          'location': _incidentLocationSummary,
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
        'exposure': {
          'type': _selectedExposure,
          'bodyPartsAffected': _bodySites.toList()..sort(),
          'multipleSites': _multipleSites,
          'woundCount': int.tryParse(_woundCountController.text.trim()),
          'bleeding': _bleeding,
        },
        'firstAid': {
          'washedWithSoapAndWater': _washedWound,
          'washMinutes': int.tryParse(_washMinutesController.text.trim()),
          'substanceApplied': _selectedSubstance,
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
    if (_woundPhoto != null) {
      final ref = storage.child('bite_wound.jpg');
      await ref.putFile(_woundPhoto!);
      evidence['woundPhotoUrl'] = await ref.getDownloadURL();
    }
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

  String get _incidentLocationSummary => [
        _incidentBarangayController.text.trim(),
        _incidentMunicipalityController.text.trim(),
        if (_incidentPin != null)
          '${_incidentPin!.latitude.toStringAsFixed(6)}, ${_incidentPin!.longitude.toStringAsFixed(6)}',
      ].where((value) => value.isNotEmpty).join(', ');

  String get _selectedAnimalType => _animalType == 'Others'
      ? _otherAnimalController.text.trim()
      : _animalType;

  String get _selectedExposure => _exposureType == 'Other'
      ? _otherExposureController.text.trim()
      : _exposureType;

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

  Widget _sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 12),
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
      onSelected: (value) => controller.text = value,
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
          onChanged: (value) => controller.text = value,
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        _choiceChips(
          values: const ['Yes', 'No', 'Unknown'],
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
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ...values.map(
            (value) => RadioListTile<String>(
              value: value,
              groupValue: groupValue,
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(value),
              onChanged: (next) {
                onChanged(next);
                field.didChange(next);
              },
            ),
          ),
          if (field.hasError)
            Padding(
              padding: const EdgeInsets.only(left: 12),
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

  Widget _photoPicker(String label, File? file, _EvidenceType type) {
    return OutlinedButton.icon(
      onPressed: () => _pickPhoto(type),
      icon:
          Icon(file == null ? Icons.add_photo_alternate_outlined : Icons.check),
      label: Text(file == null ? label : '$label selected'),
    );
  }

  Widget _mapPicker() {
    final marker = _incidentPin;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tap the map to pin the exact incident location.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        CRISMap(
          center: marker ?? _iloiloCenter,
          zoom: marker == null ? 10 : 15,
          height: 260,
          markers: [
            if (marker != null)
              CRISMapMarker(
                label: 'Bite incident location',
                position: marker,
                color: AppColors.danger,
              ),
          ],
          onTap: (point) => setState(() => _incidentPin = point),
        ),
        if (marker != null) ...[
          const SizedBox(height: 8),
          Text(
            'GPS Location: ${marker.latitude.toStringAsFixed(6)}, ${marker.longitude.toStringAsFixed(6)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ],
    );
  }

  Widget _bodyDiagram() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          value: _multipleSites,
          contentPadding: EdgeInsets.zero,
          title: const Text('Multiple Sites'),
          onChanged: _toggleMultipleSites,
        ),
        if (_multipleSites) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: TextFormField(
              controller: _bodySiteCountController,
              decoration: const InputDecoration(
                labelText: 'Number of Bite/Scratch Sites',
                helperText: 'Enter a value between 2 and 20',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: _updateBodySiteCount,
              validator: _validateSiteCount,
            ),
          ),
          const SizedBox(height: 12),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 560;
            final front = _BodyDiagramPanel(
              title: 'Front',
              sites: _frontBodySites,
              selectedSites: _bodySites,
              onTap: _selectBodySite,
            );
            final back = _BodyDiagramPanel(
              title: 'Back',
              sites: _backBodySites,
              selectedSites: _bodySites,
              onTap: _selectBodySite,
            );
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: front),
                  const SizedBox(width: 12),
                  Expanded(child: back),
                ],
              );
            }
            return Column(children: [front, const SizedBox(height: 12), back]);
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _bodySites.isNotEmpty ? _undoBodySelection : null,
                icon: const Icon(Icons.undo_outlined),
                label: const Text('Undo'),
              ),
            ),
            if (_bodySites.isNotEmpty) ...[
              const SizedBox(width: 12),
              Text(
                '${_bodySites.length} selected',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: Card(
            elevation: 1,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected Body Parts',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  if (_bodySites.isEmpty)
                    Text(
                      'No body parts selected yet. Tap a region on the diagram to add a site.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  for (var i = 0; i < _bodySites.length; i++)
                    _selectedBodyPartItem(i, _bodySites[i]),
                ],
              ),
            ),
          ),
        ),
        if (_bodyDiagramError != null) ...[
          const SizedBox(height: 10),
          Text(
            _bodyDiagramError!,
            style: TextStyle(
                color: Theme.of(context).colorScheme.error, fontSize: 12),
          ),
        ],
      ],
    );
  }

  List<_SummaryItem> get _summaryItems => [
        _SummaryItem('Patient Name', _patientName),
        _SummaryItem('Sex', _sex ?? ''),
        _SummaryItem('Date of Birth', _dobController.text),
        _SummaryItem('Age', _ageController.text),
        _SummaryItem('Civil Status', _civilStatusController.text),
        _SummaryItem('Mobile Number', _mobileController.text),
        _SummaryItem('Email Address', _emailController.text),
        _SummaryItem('Residential Address', _addressSummary),
        _SummaryItem('Date of Bite', _dateController.text),
        _SummaryItem('Time of Bite', _timeController.text),
        _SummaryItem('Incident Location', _incidentLocationSummary),
        _SummaryItem('What Happened', _descriptionController.text),
        _SummaryItem('Bite Wound Photo', _woundPhoto == null ? '' : 'Selected'),
        _SummaryItem('Animal Photo', _animalPhoto == null ? '' : 'Selected'),
        _SummaryItem('Animal Type', _selectedAnimalType),
        _SummaryItem('Ownership', _ownership),
        _SummaryItem('Animal Sex', _animalSex),
        _SummaryItem('Breed', _breedController.text),
        _SummaryItem('Color', _colorController.text),
        _SummaryItem('Approximate Age', _animalAgeController.text),
        _SummaryItem('Animal Alive', _animalAlive),
        _SummaryItem('Available for Observation', _animalAvailable),
        _SummaryItem('Vaccinated Against Rabies', _animalVaccinated),
        _SummaryItem('Suspicious Behavior', _behaviors.join(', ')),
        _SummaryItem('Exposure Type', _selectedExposure),
        _SummaryItem('Body Part Affected', _bodySites.join(', ')),
        _SummaryItem('Number of Wounds', _woundCountController.text),
        _SummaryItem('Bleeding', _bleeding ?? ''),
        _SummaryItem('Washed with Soap and Water', _washedWound ?? ''),
        _SummaryItem('Wash Minutes', _washMinutesController.text),
        _SummaryItem('Substance Applied', _selectedSubstance),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Animal Bite Report')),
      body: SafeArea(
        child: _reviewing ? _buildReview() : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            ),
            _sectionTitle(
                'Section 1 - Patient Information', Icons.person_outline),
            TextFormField(
              controller: _lastNameController,
              readOnly: _patientFieldsReadOnly,
              decoration: const InputDecoration(labelText: 'Last Name'),
              textCapitalization: TextCapitalization.words,
              validator: (value) => _required(value, 'Last Name'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _firstNameController,
              readOnly: _patientFieldsReadOnly,
              decoration: const InputDecoration(labelText: 'First Name'),
              textCapitalization: TextCapitalization.words,
              validator: (value) => _required(value, 'First Name'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _middleNameController,
                    readOnly: _patientFieldsReadOnly,
                    decoration: const InputDecoration(labelText: 'Middle Name'),
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _suffixController,
                    readOnly: _patientFieldsReadOnly,
                    decoration:
                        const InputDecoration(labelText: 'Suffix (Optional)'),
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _sex,
              decoration: const InputDecoration(labelText: 'Sex'),
              items: const [
                DropdownMenuItem(value: 'Male', child: Text('Male')),
                DropdownMenuItem(value: 'Female', child: Text('Female')),
              ],
              onChanged: _patientFieldsReadOnly
                  ? null
                  : (value) => setState(() => _sex = value),
              validator: (value) => value == null ? 'Sex is required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _dobController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Date of Birth',
                      suffixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    onTap: _patientFieldsReadOnly ? null : _pickBirthDate,
                    validator: (value) => _required(value, 'Date of Birth'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _ageController,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: 'Age'),
                    validator: (value) => _required(value, 'Age'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _civilStatusController,
              readOnly: _patientFieldsReadOnly,
              decoration:
                  const InputDecoration(labelText: 'Civil Status (Optional)'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _mobileController,
              readOnly: _patientFieldsReadOnly,
              decoration: const InputDecoration(labelText: 'Mobile Number'),
              keyboardType: TextInputType.phone,
              validator: (value) => _required(value, 'Mobile Number'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              readOnly: _patientFieldsReadOnly,
              decoration:
                  const InputDecoration(labelText: 'Email Address (Optional)'),
              keyboardType: TextInputType.emailAddress,
              validator: _optionalEmail,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _provinceController,
              readOnly: _patientFieldsReadOnly,
              decoration: const InputDecoration(labelText: 'Province'),
              validator: (value) => _required(value, 'Province'),
            ),
            const SizedBox(height: 12),
            _municipalityField(
              controller: _municipalityController,
              label: 'Municipality/City',
              enabled: !_patientFieldsReadOnly,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _barangayController,
              readOnly: _patientFieldsReadOnly,
              decoration: const InputDecoration(labelText: 'Barangay'),
              textCapitalization: TextCapitalization.words,
              validator: (value) => _required(value, 'Barangay'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _streetController,
              readOnly: _patientFieldsReadOnly,
              decoration: const InputDecoration(labelText: 'Street Address'),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) => _required(value, 'Street Address'),
            ),
            _sectionTitle(
                'Section 2 - Bite Incident Information', Icons.place_outlined),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _dateController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Date of Bite',
                      suffixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    onTap: _pickBiteDate,
                    validator: (value) => _required(value, 'Date of Bite'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _timeController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Time of Bite',
                      suffixIcon: Icon(Icons.access_time_outlined),
                    ),
                    onTap: _pickBiteTime,
                    validator: (value) => _required(value, 'Time of Bite'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _municipalityField(
              controller: _incidentMunicipalityController,
              label: 'Incident Municipality',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _incidentBarangayController,
              decoration: const InputDecoration(labelText: 'Incident Barangay'),
              textCapitalization: TextCapitalization.words,
              validator: (value) => _required(value, 'Incident Barangay'),
            ),
            const SizedBox(height: 12),
            _mapPicker(),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration:
                  const InputDecoration(labelText: 'Tell us what happened.'),
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              validator: (value) => _required(value, 'Tell us what happened.'),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _photoPicker('Upload Photo of Bite Wound', _woundPhoto,
                    _EvidenceType.wound),
                _photoPicker('Upload Photo of the Animal', _animalPhoto,
                    _EvidenceType.animal),
              ],
            ),
            _sectionTitle(
                'Section 3 - Animal Information', Icons.pets_outlined),
            _choiceChips(
              values: const ['Dog', 'Cat', 'Others'],
              selected: _animalType,
              onSelected: (value) => _animalType = value,
            ),
            if (_animalType == 'Others') ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _otherAnimalController,
                decoration:
                    const InputDecoration(labelText: 'Others (Specify)'),
                validator: (value) => _required(value, 'Animal type'),
              ),
            ],
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _ownership,
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
              onChanged: (value) =>
                  setState(() => _ownership = value ?? 'Stray'),
            ),
            const SizedBox(height: 12),
            _choiceChips(
              values: const ['Male', 'Female', 'Unknown'],
              selected: _animalSex,
              onSelected: (value) => _animalSex = value,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _breedController,
                    decoration: const InputDecoration(labelText: 'Breed'),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) => _required(value, 'Breed'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _colorController,
                    decoration: const InputDecoration(labelText: 'Color'),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) => _required(value, 'Color'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _animalAgeController,
              decoration: const InputDecoration(
                  labelText: 'Approximate Age (Optional)'),
            ),
            const SizedBox(height: 16),
            _yesNoUnknown(
              label: 'Is the animal alive?',
              selected: _animalAlive,
              onSelected: (value) => _animalAlive = value,
            ),
            const SizedBox(height: 16),
            _yesNoUnknown(
              label: 'Is the animal available for observation?',
              selected: _animalAvailable,
              onSelected: (value) => _animalAvailable = value,
            ),
            const SizedBox(height: 16),
            _yesNoUnknown(
              label: 'Is the animal vaccinated against rabies?',
              selected: _animalVaccinated,
              onSelected: (value) => _animalVaccinated = value,
            ),
            const SizedBox(height: 16),
            const Text('Suspicious Animal Behavior',
                style: TextStyle(fontWeight: FontWeight.w700)),
            ..._suspiciousBehaviors.map(
              (behavior) => CheckboxListTile(
                value: _behaviors.contains(behavior),
                dense: true,
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
            _sectionTitle(
                'Section 4 - Exposure Information', Icons.healing_outlined),
            _choiceChips(
              values: const ['Bite', 'Scratch', 'Saliva Contact', 'Other'],
              selected: _exposureType,
              onSelected: (value) => _exposureType = value,
            ),
            if (_exposureType == 'Other') ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _otherExposureController,
                decoration: const InputDecoration(labelText: 'Other (Specify)'),
                validator: (value) => _required(value, 'Exposure type'),
              ),
            ],
            const SizedBox(height: 12),
            _bodyDiagram(),
            const SizedBox(height: 12),
            TextFormField(
              controller: _woundCountController,
              decoration: const InputDecoration(
                  labelText: 'Number of Bite/Scratch Wounds'),
              keyboardType: TextInputType.number,
              validator: (value) =>
                  _numberRequired(value, 'Number of Bite/Scratch Wounds'),
            ),
            const SizedBox(height: 12),
            _radioLine(
              label: 'Was there bleeding?',
              groupValue: _bleeding,
              values: const ['Yes', 'No'],
              onChanged: (value) => setState(() => _bleeding = value),
            ),
            _sectionTitle('Section 5 - First Aid Performed',
                Icons.medical_services_outlined),
            _radioLine(
              label: 'Did you wash the wound with soap and water?',
              groupValue: _washedWound,
              values: const ['Yes', 'No'],
              onChanged: (value) => setState(() => _washedWound = value),
            ),
            if (_washedWound == 'Yes') ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _washMinutesController,
                decoration: const InputDecoration(
                  labelText:
                      'Approximately how many minutes did you wash the wound?',
                ),
                keyboardType: TextInputType.number,
                validator: (value) => _numberRequired(value, 'Wash minutes'),
              ),
            ],
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _substance,
              decoration: const InputDecoration(
                labelText: 'Did you apply any substance to the wound?',
              ),
              items: const [
                DropdownMenuItem(value: 'None', child: Text('None')),
                DropdownMenuItem(value: 'Alcohol', child: Text('Alcohol')),
                DropdownMenuItem(value: 'Betadine', child: Text('Betadine')),
                DropdownMenuItem(
                    value: 'Herbal Remedy', child: Text('Herbal Remedy')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (value) =>
                  setState(() => _substance = value ?? 'None'),
            ),
            if (_substance == 'Other') ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _otherSubstanceController,
                decoration: const InputDecoration(labelText: 'Other (Specify)'),
                validator: (value) => _required(value, 'Substance applied'),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _continueToReview,
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('Review Information'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReview() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle(
            'Section 6 - Review & Submit', Icons.assignment_turned_in_outlined),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE4E8EC)),
          ),
          child: Column(
            children: [
              for (var i = 0; i < _summaryItems.length; i++) ...[
                _SummaryRow(item: _summaryItems[i]),
                if (i < _summaryItems.length - 1)
                  const Divider(height: 1, indent: 16, endIndent: 16),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          value: _certified,
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'I certify that the information provided is true and correct to the best of my knowledge.',
          ),
          onChanged: (value) => setState(() => _certified = value ?? false),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed:
              _claimedByAbtc ? null : () => setState(() => _reviewing = false),
          icon: const Icon(Icons.edit_outlined),
          label: Text(_claimedByAbtc
              ? 'Editing Disabled - Claimed by ABTC'
              : 'Edit Information'),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: _isSubmitting ? null : _submit,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_outlined),
            label: Text(_isSubmitting ? 'Submitting...' : 'Submit Report'),
          ),
        ),
      ],
    );
  }
}

enum _EvidenceType { wound, animal }

class _BodyDiagramPanel extends StatelessWidget {
  const _BodyDiagramPanel({
    required this.title,
    required this.sites,
    required this.selectedSites,
    required this.onTap,
  });

  final String title;
  final List<_BodySite> sites;
  final List<String> selectedSites;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 360,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E8EC)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(title,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                    size: const Size(220, 320), painter: _BodyPainter()),
                ..._siteButtons(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _siteButtons(BuildContext context) {
    return [
      for (var i = 0; i < sites.length; i++)
        Align(
          alignment: sites[i].alignment,
          child: Tooltip(
            message: sites[i].name,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => onTap(sites[i].name),
              child: SizedBox(
                width: 42,
                height: 42,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: selectedSites.contains(sites[i].name)
                            ? AppColors.danger
                            : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selectedSites.contains(sites[i].name)
                              ? AppColors.danger
                              : AppColors.primary,
                          width: 2,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x22000000),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    if (selectedSites.contains(sites[i].name))
                      Positioned.fill(
                        child: Center(
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${selectedSites.indexOf(sites[i].name) + 1}',
                              style: const TextStyle(
                                color: AppColors.danger,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
    ];
  }
}

class _BodyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFEAF3F6)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = const Color(0xFF9BB7C2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final centerX = size.width / 2;

    canvas.drawCircle(Offset(centerX, 30), 24, paint);
    canvas.drawCircle(Offset(centerX, 30), 24, stroke);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(centerX, 105), width: 70, height: 100),
        const Radius.circular(28),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(centerX, 105), width: 70, height: 100),
        const Radius.circular(28),
      ),
      stroke,
    );
    canvas.drawLine(
        Offset(centerX - 38, 75), Offset(centerX - 78, 165), stroke);
    canvas.drawLine(
        Offset(centerX + 38, 75), Offset(centerX + 78, 165), stroke);
    canvas.drawLine(
        Offset(centerX - 22, 154), Offset(centerX - 38, 260), stroke);
    canvas.drawLine(
        Offset(centerX + 22, 154), Offset(centerX + 38, 260), stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
