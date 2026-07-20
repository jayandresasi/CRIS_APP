import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
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
  'Dueñas',
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

/// Patient-facing Animal Bite Report. Clinical classification and PEP fields
/// are deliberately absent; those are completed by ABTC staff after claim.
class ReportingPage extends StatefulWidget {
  const ReportingPage({super.key, this.isClaimedByAbtc = false});

  /// Set by an editor route when an ABTC has already claimed the report.
  final bool isClaimedByAbtc;

  @override
  State<ReportingPage> createState() => _ReportingPageState();
}

class _ReportingPageState extends State<ReportingPage> {
  final _formKey = GlobalKey<FormState>();
  final _lastName = TextEditingController();
  final _firstName = TextEditingController();
  final _middleName = TextEditingController();
  final _suffix = TextEditingController();
  final _birthDate = TextEditingController();
  final _age = TextEditingController();
  final _civilStatus = TextEditingController();
  final _mobile = TextEditingController();
  final _email = TextEditingController();
  final _province = TextEditingController(text: 'Iloilo');
  final _residenceMunicipality = TextEditingController();
  final _residenceBarangay = TextEditingController();
  final _streetAddress = TextEditingController();
  final _biteDate = TextEditingController();
  final _biteTime = TextEditingController();
  final _incidentMunicipality = TextEditingController();
  final _incidentBarangay = TextEditingController();
  final _description = TextEditingController();
  final _otherAnimalType = TextEditingController();
  final _breed = TextEditingController();
  final _color = TextEditingController();
  final _animalAge = TextEditingController();
  final _otherExposure = TextEditingController();
  final _woundCount = TextEditingController();
  final _washMinutes = TextEditingController();
  final _otherSubstance = TextEditingController();

  String? _sex;
  String? _animalType;
  String _ownership = 'Stray';
  String _animalSex = 'Unknown';
  String? _animalAlive;
  String? _availableForObservation;
  String? _animalVaccinated;
  String? _exposureType;
  String? _bleeding;
  String? _washedWound;
  String _appliedSubstance = 'None';
  DateTime? _selectedBirthDate;
  DateTime? _selectedBiteDate;
  TimeOfDay? _selectedBiteTime;
  LatLng? _incidentCoordinates;
  XFile? _woundPhoto;
  XFile? _animalPhoto;
  Uint8List? _woundBytes;
  Uint8List? _animalBytes;
  final Set<String> _behaviors = {};
  final Set<String> _bodySites = {};
  bool _multipleSites = false;
  bool _certified = false;
  bool _reviewing = false;
  bool _reportingForSelf = false;
  bool _loadingProfile = false;
  bool _submitting = false;
  bool get _patientReadOnly => _reportingForSelf || _loadingProfile;
  bool get _isClaimedByAbtc => widget.isClaimedByAbtc;

  @override
  void dispose() {
    for (final controller in [
      _lastName,
      _firstName,
      _middleName,
      _suffix,
      _birthDate,
      _age,
      _civilStatus,
      _mobile,
      _email,
      _province,
      _residenceMunicipality,
      _residenceBarangay,
      _streetAddress,
      _biteDate,
      _biteTime,
      _incidentMunicipality,
      _incidentBarangay,
      _description,
      _otherAnimalType,
      _breed,
      _color,
      _animalAge,
      _otherExposure,
      _woundCount,
      _washMinutes,
      _otherSubstance,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _setReportingForSelf(bool value) async {
    if (value == _reportingForSelf) return;
    setState(() => _reportingForSelf = value);
    if (!value) {
      setState(_clearPatientFields);
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _reportingForSelf = false);
      _showSnackBar('Please sign in to use your profile.');
      return;
    }
    setState(() => _loadingProfile = true);
    try {
      final data = (await FirebaseFirestore.instance
              .collection('user-info')
              .doc(user.uid)
              .get())
          .data();
      if (data == null) {
        setState(() => _reportingForSelf = false);
        _showSnackBar('No saved profile found. Please set up your profile.');
        return;
      }
      final names = _splitFullName('${data['fullName'] ?? ''}');
      final dob = _dateFromValue(data['dob'] ?? data['birthDate']);
      if (!mounted) return;
      setState(() {
        _firstName.text = names.first;
        _lastName.text = names.last;
        _sex = _validOption(
            '${data['sex'] ?? data['gender'] ?? ''}', ['Male', 'Female']);
        _mobile.text =
            '${data['contactNumber'] ?? data['contact_number'] ?? ''}';
        _email.text = '${data['email'] ?? ''}';
        _province.text = '${data['province'] ?? 'Iloilo'}';
        _residenceMunicipality.text = '${data['municipality'] ?? ''}';
        _residenceBarangay.text = '${data['barangay'] ?? data['brgy'] ?? ''}';
        _streetAddress.text = '${data['address'] ?? ''}';
        if (dob != null) _setBirthDate(dob);
      });
    } on FirebaseException catch (e) {
      setState(() => _reportingForSelf = false);
      _showSnackBar(e.message ?? 'Unable to load your profile.');
    } finally {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  void _clearPatientFields() {
    for (final controller in [
      _lastName,
      _firstName,
      _middleName,
      _suffix,
      _birthDate,
      _age,
      _civilStatus,
      _mobile,
      _email,
      _residenceMunicipality,
      _residenceBarangay,
      _streetAddress,
    ]) {
      controller.clear();
    }
    _province.text = 'Iloilo';
    _sex = null;
    _selectedBirthDate = null;
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ??
          DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _setBirthDate(picked));
  }

  void _setBirthDate(DateTime date) {
    _selectedBirthDate = date;
    _birthDate.text = _formatDate(date);
    _age.text = '${_calculateAge(date)}';
  }

  Future<void> _pickBiteDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBiteDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedBiteDate = picked;
        _biteDate.text = _formatDate(picked);
      });
    }
  }

  Future<void> _pickBiteTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedBiteTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedBiteTime = picked;
        _biteTime.text = picked.format(context);
      });
    }
  }

  Future<void> _pickPhoto(bool wound) async {
    final photo = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (photo == null) return;
    final bytes = await photo.readAsBytes();
    if (!mounted) return;
    setState(() {
      if (wound) {
        _woundPhoto = photo;
        _woundBytes = bytes;
      } else {
        _animalPhoto = photo;
        _animalBytes = bytes;
      }
    });
  }

  void _selectBodySite(String site) {
    setState(() {
      if (_multipleSites) {
        if (!_bodySites.add(site)) _bodySites.remove(site);
      } else {
        _bodySites
          ..clear()
          ..add(site);
      }
    });
  }

  String? _required(String? value, String label) =>
      value == null || value.trim().isEmpty ? '$label is required' : null;

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return RegExp(r'^\S+@\S+\.\S+$').hasMatch(value.trim())
        ? null
        : 'Enter a valid email address';
  }

  String? _numberValidator(String? value, String label) {
    final required = _required(value, label);
    if (required != null) return required;
    return int.tryParse(value!.trim()) == null
        ? '$label must be a number'
        : null;
  }

  Future<void> _showReview() async {
    if (!_formKey.currentState!.validate()) return;
    if (_bodySites.isEmpty) {
      _showSnackBar('Select at least one body area affected.');
      return;
    }
    setState(() => _reviewing = true);
  }

  Future<void> _submit() async {
    if (!_certified) {
      _showSnackBar('Please certify that the information is true and correct.');
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar('Please sign in to submit a report.');
      if (mounted) {
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const LoginPage()));
      }
      return;
    }
    setState(() => _submitting = true);
    final now = DateTime.now();
    final caseId =
        'BITE-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch % 1000000}-${Random().nextInt(900) + 100}';
    try {
      final woundUrl = await _uploadPhoto(
          _woundPhoto, _woundBytes, user.uid, caseId, 'wound');
      final animalUrl = await _uploadPhoto(
          _animalPhoto, _animalBytes, user.uid, caseId, 'animal');
      final report = Report(
        lastName: _lastName.text.trim(),
        firstName: _firstName.text.trim(),
        middleInitial: _middleName.text.trim(),
        suffix: _suffix.text.trim(),
        age: _age.text.trim(),
        gender: _sex ?? '',
        contactNumber: _mobile.text.trim(),
        address: _streetAddress.text.trim(),
        dateOfIncident: _biteDate.text.trim(),
        timeOfIncident: _biteTime.text.trim(),
        locationOfIncident: [
          _incidentBarangay.text.trim(),
          _incidentMunicipality.text.trim()
        ].where((v) => v.isNotEmpty).join(', '),
        exposureType: _resolvedExposure(),
        animalSpecies: _resolvedAnimalType(),
        animalOwnership: _ownership,
        animalVaccinationStatus: _animalVaccinated ?? 'Unknown',
        incidentDescription: _description.text.trim(),
        firstAidGiven: _firstAidSummary(),
        patientVaccinationStatus: 'To be assessed by ABTC',
        reportedAt: now,
      );
      await Hive.box<Report>('reports').add(report);
      await FirebaseFirestore.instance
          .collection('bite_reports')
          .doc(caseId)
          .set({
        'caseId': caseId,
        'reportId': caseId,
        'userId': user.uid,
        'submittedBy': user.uid,
        'reportingForSelf': _reportingForSelf,
        'status': 'Pending ABTC Claim',
        'abtcClaimed': false,
        'patient': {
          'lastName': _lastName.text.trim(),
          'firstName': _firstName.text.trim(),
          'middleName': _middleName.text.trim(), 'suffix': _suffix.text.trim(),
          'fullName': _fullName(), 'sex': _sex,
          'dateOfBirth': _birthDate.text.trim(),
          'age': int.tryParse(_age.text.trim()),
          'civilStatus': _civilStatus.text.trim(),
          'mobileNumber': _mobile.text.trim(),
          'emailAddress': _email.text.trim(),
          'address': {
            'province': _province.text.trim(),
            'municipality': _residenceMunicipality.text.trim(),
            'barangay': _residenceBarangay.text.trim(),
            'streetAddress': _streetAddress.text.trim()
          },
          // Legacy fields retained for existing history/admin readers.
          'contactNumber': _mobile.text.trim(),
          'barangay': _residenceBarangay.text.trim(),
          'municipality': _residenceMunicipality.text.trim(),
        },
        'incident': {
          'date': _biteDate.text.trim(),
          'time': _biteTime.text.trim(),
          'municipality': _incidentMunicipality.text.trim(),
          'barangay': _incidentBarangay.text.trim(),
          'location': [
            _incidentBarangay.text.trim(),
            _incidentMunicipality.text.trim()
          ].where((v) => v.isNotEmpty).join(', '),
          'latitude': _incidentCoordinates?.latitude,
          'longitude': _incidentCoordinates?.longitude,
          'description': _description.text.trim(),
          'woundPhotoUrl': woundUrl,
          'animalPhotoUrl': animalUrl,
          'exposureType': _resolvedExposure(),
        },
        'animal': {
          'type': _resolvedAnimalType(),
          'species': _resolvedAnimalType(),
          'ownership': _ownership,
          'sex': _animalSex,
          'breed': _breed.text.trim(),
          'color': _color.text.trim(),
          'approximateAge': _animalAge.text.trim(),
          'alive': _animalAlive,
          'availableForObservation': _availableForObservation,
          'vaccinatedAgainstRabies': _animalVaccinated,
          'vaccinationStatus': _animalVaccinated,
          'suspiciousBehaviors': _behaviors.toList(),
        },
        'exposure': {
          'type': _resolvedExposure(),
          'bodySites': _bodySites.toList(),
          'multipleSites': _multipleSites,
          'numberOfWounds': int.tryParse(_woundCount.text.trim()),
          'bleeding': _bleeding,
        },
        'firstAid': {
          'washedWithSoapAndWater': _washedWound,
          'washMinutes': _washedWound == 'Yes'
              ? int.tryParse(_washMinutes.text.trim())
              : null,
          'substanceApplied': _resolvedSubstance(),
        },
        'submittedAt': Timestamp.fromDate(now),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  _SubmissionSuccess(caseId: caseId, submittedAt: now)));
    } on FirebaseException catch (e) {
      _showSnackBar(e.message ?? 'Unable to submit bite report.');
    } catch (e) {
      _showSnackBar('Unable to submit bite report: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<String?> _uploadPhoto(XFile? photo, Uint8List? bytes, String uid,
      String caseId, String label) async {
    if (photo == null || bytes == null) return null;
    final ref = FirebaseStorage.instance
        .ref()
        .child('bite_reports')
        .child(uid)
        .child(caseId)
        .child('$label.jpg');
    await ref.putData(
        bytes, SettableMetadata(contentType: photo.mimeType ?? 'image/jpeg'));
    return ref.getDownloadURL();
  }

  @override
  Widget build(BuildContext context) =>
      _reviewing ? _buildReview() : _buildForm();

  Widget _buildForm() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Animal Bite Report')),
      body: SafeArea(
          child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
            key: _formKey,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _section('1. Patient Information', [
                    SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _reportingForSelf,
                        onChanged:
                            _loadingProfile ? null : _setReportingForSelf,
                        title: const Text('Reporting for self?'),
                        subtitle: const Text('Use saved profile details'),
                        secondary: _loadingProfile
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.person_outline)),
                    _subheading('Patient Name'),
                    _twoFields(
                        _field(_lastName, 'Last Name',
                            required: true, readOnly: _patientReadOnly),
                        _field(_firstName, 'First Name',
                            required: true, readOnly: _patientReadOnly)),
                    _twoFields(
                        _field(_middleName, 'Middle Name',
                            readOnly: _patientReadOnly),
                        _field(_suffix, 'Suffix (Optional)',
                            readOnly: _patientReadOnly)),
                    _subheading('Personal Information'),
                    _twoFields(
                        _dropdown('Sex', _sex, const ['Male', 'Female'],
                            (v) => setState(() => _sex = v),
                            required: true, enabled: !_patientReadOnly),
                        _dateField(_birthDate, 'Date of Birth', _pickBirthDate,
                            required: true, readOnly: _patientReadOnly)),
                    _twoFields(
                        _field(_age, 'Age (Automatically calculated)',
                            readOnly: true),
                        _field(_civilStatus, 'Civil Status (Optional)',
                            readOnly: _patientReadOnly)),
                    _subheading('Contact Information'),
                    _twoFields(
                        _field(_mobile, 'Mobile Number',
                            required: true,
                            keyboardType: TextInputType.phone,
                            readOnly: _patientReadOnly),
                        _field(_email, 'Email Address (Optional)',
                            validator: _emailValidator,
                            keyboardType: TextInputType.emailAddress,
                            readOnly: _patientReadOnly)),
                    _subheading('Residential Address'),
                    _field(_province, 'Province',
                        required: true, readOnly: _patientReadOnly),
                    const SizedBox(height: 12),
                    _municipalityField(
                        _residenceMunicipality, 'Municipality/City',
                        enabled: !_patientReadOnly),
                    const SizedBox(height: 12),
                    _field(_residenceBarangay, 'Barangay',
                        required: true, readOnly: _patientReadOnly),
                    const SizedBox(height: 12),
                    _field(_streetAddress, 'Street Address',
                        required: true, readOnly: _patientReadOnly),
                  ]),
                  _section('2. Bite Incident Information', [
                    _subheading('Incident Details'),
                    _twoFields(
                        _dateField(_biteDate, 'Date of Bite', _pickBiteDate,
                            required: true),
                        _timeField()),
                    _municipalityField(_incidentMunicipality, 'Municipality'),
                    const SizedBox(height: 12),
                    _field(_incidentBarangay, 'Barangay', required: true),
                    _subheading('Incident Location'),
                    Text(
                        'Tap the map to pin the exact incident location. This is optional.',
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 8),
                    CRISMap(
                        center: _incidentCoordinates ??
                            const LatLng(10.7202, 122.5621),
                        zoom: _incidentCoordinates == null ? 10 : 16,
                        onTap: (point) =>
                            setState(() => _incidentCoordinates = point),
                        markers: _incidentCoordinates == null
                            ? const []
                            : [
                                CRISMapMarker(
                                    label: 'Bite incident',
                                    position: _incidentCoordinates!,
                                    color: AppColors.danger)
                              ]),
                    if (_incidentCoordinates != null)
                      Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                              'Pinned: ${_incidentCoordinates!.latitude.toStringAsFixed(6)}, ${_incidentCoordinates!.longitude.toStringAsFixed(6)}')),
                    _subheading('Incident Description'),
                    _field(_description, 'Tell us what happened.',
                        required: true, maxLines: 4),
                    _subheading('Supporting Evidence (Optional)'),
                    _photoPicker('Upload Photo of Bite Wound', _woundBytes,
                        () => _pickPhoto(true)),
                    const SizedBox(height: 10),
                    _photoPicker('Upload Photo of the Animal', _animalBytes,
                        () => _pickPhoto(false)),
                  ]),
                  _section('3. Animal Information', [
                    _subheading('Animal Type'),
                    _dropdown(
                        'Animal Type',
                        _animalType,
                        const ['Dog', 'Cat', 'Others (Specify)'],
                        (v) => setState(() => _animalType = v),
                        required: true),
                    if (_animalType == 'Others (Specify)') ...[
                      const SizedBox(height: 12),
                      _field(_otherAnimalType, 'Specify animal type',
                          required: true)
                    ],
                    const SizedBox(height: 12),
                    _dropdown(
                        'Ownership',
                        _ownership,
                        const [
                          'Owned (Caged)',
                          'Owned (Allowed to Roam)',
                          'Stray',
                          'Unknown'
                        ],
                        (v) => setState(() => _ownership = v ?? 'Unknown'),
                        required: true),
                    const SizedBox(height: 12),
                    _dropdown(
                        'Animal Sex',
                        _animalSex,
                        const ['Male', 'Female', 'Unknown'],
                        (v) => setState(() => _animalSex = v ?? 'Unknown'),
                        required: true),
                    _subheading('Physical Description'),
                    _twoFields(
                        _field(_breed, 'Breed'), _field(_color, 'Color')),
                    _field(_animalAge, 'Approximate Age (Optional)'),
                    _subheading('Animal Condition'),
                    _yesNoUnknown('Is the animal alive?', _animalAlive,
                        (v) => setState(() => _animalAlive = v)),
                    _yesNoUnknown(
                        'Is the animal available for observation?',
                        _availableForObservation,
                        (v) => setState(() => _availableForObservation = v)),
                    _yesNoUnknown(
                        'Is the animal vaccinated against rabies?',
                        _animalVaccinated,
                        (v) => setState(() => _animalVaccinated = v)),
                    _subheading('Suspicious Animal Behavior'),
                    ..._behaviorOptions.map((option) => _reportCheckboxTile(
                        title: option,
                        value: _behaviors.contains(option),
                        onChanged: (checked) =>
                            _toggleSuspiciousBehavior(option, checked ?? false))),
                  ]),
                  _section('4. Exposure Information', [
                    _dropdown(
                        'Exposure Type',
                        _exposureType,
                        const [
                          'Bite',
                          'Scratch',
                          'Saliva Contact',
                          'Other (Specify)'
                        ],
                        (v) => setState(() => _exposureType = v),
                        required: true),
                    if (_exposureType == 'Other (Specify)') ...[
                      const SizedBox(height: 12),
                      _field(_otherExposure, 'Specify exposure type',
                          required: true)
                    ],
                    _subheading('Body Part Affected'),
                    _reportCheckboxTile(
                        title: 'Multiple Sites',
                        value: _multipleSites,
                        subtitle:
                            'Select this before choosing more than one body location.',
                        onChanged: (value) => setState(() {
                              _multipleSites = value ?? false;
                              if (!_multipleSites && _bodySites.length > 1) {
                                _bodySites.removeWhere(
                                    (site) => site != _bodySites.first);
                              }
                            })),
                    _BodySiteSelector(
                        selected: _bodySites, onSelected: _selectBodySite),
                    if (_bodySites.isNotEmpty)
                      Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text('Selected: ${_bodySites.join(', ')}')),
                    const SizedBox(height: 12),
                    _field(_woundCount, 'Number of Bite/Scratch Wounds',
                        required: true,
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            _numberValidator(v, 'Number of wounds')),
                    _yesNo('Was there bleeding?', _bleeding,
                        (v) => setState(() => _bleeding = v)),
                  ]),
                  _section('5. First Aid Performed', [
                    _subheading('Wound Care'),
                    _yesNo('Did you wash the wound with soap and water?',
                        _washedWound, (v) => setState(() => _washedWound = v)),
                    if (_washedWound == 'Yes')
                      _field(_washMinutes,
                          'Approximately how many minutes did you wash the wound?',
                          required: true,
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              _numberValidator(v, 'Wash duration')),
                    _subheading('Other First Aid'),
                    _dropdown(
                        'Did you apply any substance to the wound?',
                        _appliedSubstance,
                        const [
                          'None',
                          'Alcohol',
                          'Betadine',
                          'Herbal Remedy',
                          'Other'
                        ],
                        (v) => setState(() => _appliedSubstance = v ?? 'None'),
                        required: true),
                    if (_appliedSubstance == 'Other') ...[
                      const SizedBox(height: 12),
                      _field(_otherSubstance, 'Specify substance',
                          required: true)
                    ],
                  ]),
                  const SizedBox(height: 24),
                  SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                          onPressed: _showReview,
                          icon: const Icon(Icons.fact_check_outlined),
                          label: const Text('Review Information'))),
                ])),
      )),
    );
  }

  Widget _buildReview() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
          leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _reviewing = false)),
          title: const Text('Review & Submit')),
      body: SafeArea(
          child: ListView(padding: const EdgeInsets.all(16), children: [
        Text('Review your report',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        const Text(
            'Please check the details below before submitting. ABTC personnel will complete any clinical assessment.'),
        _summary('Patient Information', {
          'Patient': _fullName(),
          'Sex / Age': '${_sex ?? ''} / ${_age.text}',
          'Date of Birth': _birthDate.text,
          'Civil Status': _civilStatus.text,
          'Mobile Number': _mobile.text,
          'Email': _email.text,
          'Address': [
            _streetAddress.text,
            _residenceBarangay.text,
            _residenceMunicipality.text,
            _province.text
          ].where((v) => v.trim().isNotEmpty).join(', ')
        }),
        _summary('Bite Incident Information', {
          'Date / Time': '${_biteDate.text} ${_biteTime.text}',
          'Location': [_incidentBarangay.text, _incidentMunicipality.text]
              .where((v) => v.trim().isNotEmpty)
              .join(', '),
          'GPS Location': _incidentCoordinates == null
              ? ''
              : '${_incidentCoordinates!.latitude.toStringAsFixed(6)}, ${_incidentCoordinates!.longitude.toStringAsFixed(6)}',
          'What happened': _description.text,
          'Evidence': [
            'Wound photo: ${_woundPhoto == null ? 'Not provided' : 'Attached'}',
            'Animal photo: ${_animalPhoto == null ? 'Not provided' : 'Attached'}'
          ].join('\n')
        }),
        _summary('Animal Information', {
          'Animal': _resolvedAnimalType(),
          'Ownership / Sex': '$_ownership / $_animalSex',
          'Description': [_breed.text, _color.text, _animalAge.text]
              .where((v) => v.trim().isNotEmpty)
              .join(', '),
          'Alive / Available / Vaccinated':
              '${_animalAlive ?? ''} / ${_availableForObservation ?? ''} / ${_animalVaccinated ?? ''}',
          'Suspicious behavior': _behaviors.join(', ')
        }),
        _summary('Exposure & First Aid', {
          'Exposure': _resolvedExposure(),
          'Body areas': _bodySites.join(', '),
          'Wounds / Bleeding': '${_woundCount.text} / ${_bleeding ?? ''}',
          'Washed wound': _washedWound == 'Yes'
              ? 'Yes, ${_washMinutes.text} minutes'
              : _washedWound ?? '',
          'Substance applied': _resolvedSubstance()
        }),
        CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _certified,
            onChanged: (value) => setState(() => _certified = value ?? false),
            title: const Text(
                'I certify that the information provided is true and correct to the best of my knowledge.')),
        const SizedBox(height: 12),
        SizedBox(
            height: 50,
            child: OutlinedButton.icon(
                onPressed: _isClaimedByAbtc
                    ? null
                    : () => setState(() => _reviewing = false),
                icon: const Icon(Icons.edit_outlined),
                label: Text(_isClaimedByAbtc
                    ? 'Editing unavailable — claimed by ABTC'
                    : 'Edit Information'))),
        const SizedBox(height: 12),
        SizedBox(
            height: 52,
            child: FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send_outlined),
                label: Text(_submitting ? 'Submitting...' : 'Submit Report'))),
      ])),
    );
  }

  Widget _section(String title, List<Widget> children) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(0, 20, 0, 8),
            child: Text(title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w700))),
        Card(
            margin: EdgeInsets.zero,
            child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _spaced(children))))
      ]);
  List<Widget> _spaced(List<Widget> children) => [
        for (var i = 0; i < children.length; i++) ...[
          children[i],
          if (i < children.length - 1) const SizedBox(height: 12)
        ]
      ];
  Widget _subheading(String value) => Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700)));
  Widget _twoFields(Widget left, Widget right) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right)
      ]);
  Widget _field(TextEditingController controller, String label,
          {bool required = false,
          bool readOnly = false,
          int maxLines = 1,
          TextInputType? keyboardType,
          String? Function(String?)? validator}) =>
      TextFormField(
          controller: controller,
          readOnly: readOnly,
          maxLines: maxLines,
          keyboardType: keyboardType,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: label),
          validator: validator ??
              (required
                  ? (v) => _required(v, label.replaceAll(' (Optional)', ''))
                  : null));
  Widget _dateField(
          TextEditingController controller, String label, VoidCallback onTap,
          {bool required = false, bool readOnly = false}) =>
      TextFormField(
          controller: controller,
          readOnly: true,
          enabled: !readOnly,
          onTap: onTap,
          decoration: InputDecoration(
              labelText: label,
              suffixIcon: const Icon(Icons.calendar_today_outlined)),
          validator: required ? (v) => _required(v, label) : null);
  Widget _timeField() => TextFormField(
      controller: _biteTime,
      readOnly: true,
      onTap: _pickBiteTime,
      decoration: const InputDecoration(
          labelText: 'Time of Bite',
          suffixIcon: Icon(Icons.access_time_outlined)),
      validator: (v) => _required(v, 'Time of Bite'));
  Widget _dropdown(String label, String? value, List<String> options,
          ValueChanged<String?> onChanged,
          {bool required = false, bool enabled = true}) =>
      DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          style: const TextStyle(color: Colors.black87),
          dropdownColor: Colors.white,
          iconEnabledColor: Colors.black54,
          decoration: InputDecoration(
            labelText: label,
            hintText: 'Select $label',
            labelStyle: const TextStyle(color: Colors.black87),
            floatingLabelStyle: const TextStyle(color: AppColors.primary),
            hintStyle: const TextStyle(color: Colors.black54),
          ),
          items: options
              .map((v) => DropdownMenuItem(
                  value: v,
                  child: Text(v,
                      style: const TextStyle(color: Colors.black87))))
              .toList(),
          onChanged: enabled ? onChanged : null,
          validator:
              required ? (v) => v == null ? '$label is required' : null : null);
  Widget _reportCheckboxTile({
    required String title,
    required bool value,
    required ValueChanged<bool?> onChanged,
    String? subtitle,
  }) =>
      CheckboxListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        value: value,
        selected: value,
        tileColor: const Color(0xFFF7F7F7),
        selectedTileColor: const Color(0xFFFFE7D8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: AppColors.primary,
        checkColor: Colors.white,
        title: Text(
          title,
          style: TextStyle(
            color: value ? AppColors.primaryVariant : const Color(0xFF4B5563),
            fontWeight: value ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        subtitle: subtitle == null
            ? null
            : Text(subtitle, style: const TextStyle(color: Color(0xFF5F6B76))),
        onChanged: onChanged,
      );
  Widget _yesNo(
          String question, String? value, ValueChanged<String?> onChanged) =>
      _dropdown(question, value, const ['Yes', 'No'], onChanged,
          required: true);
  Widget _yesNoUnknown(
          String question, String? value, ValueChanged<String?> onChanged) =>
      _dropdown(question, value, const ['Yes', 'No', 'Unknown'], onChanged,
          required: true);
  Widget _municipalityField(TextEditingController controller, String label,
          {bool enabled = true}) =>
      Autocomplete<String>(
          initialValue: TextEditingValue(text: controller.text),
          optionsBuilder: (value) {
            final query = value.text.trim().toLowerCase();
            return query.isEmpty
                ? iloiloMunicipalities
                : iloiloMunicipalities
                    .where((item) => item.toLowerCase().contains(query));
          },
          onSelected: (value) => controller.text = value,
          optionsViewBuilder: (_, onSelected, options) => Material(
              elevation: 4,
              color: Colors.white,
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 240),
                  child: ListView(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      children: options
                          .map((option) => InkWell(
                              onTap: () => onSelected(option),
                              child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  child: Text(option,
                                      style: const TextStyle(
                                          color: Colors.black87)))))
                          .toList()))),
          fieldViewBuilder: (_, textController, focusNode, __) {
            textController.value = TextEditingValue(
                text: controller.text,
                selection:
                    TextSelection.collapsed(offset: controller.text.length));
            return TextFormField(
                controller: textController,
                focusNode: focusNode,
                enabled: enabled,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                    labelText: label,
                    hintText: 'Select or enter $label',
                    labelStyle: const TextStyle(color: Colors.black87),
                    floatingLabelStyle:
                        const TextStyle(color: AppColors.primary),
                    hintStyle: const TextStyle(color: Colors.black54),
                    suffixIcon: const Icon(Icons.search)),
                textCapitalization: TextCapitalization.words,
                onChanged: (value) => controller.text = value,
                validator: (value) => _required(value, label));
          });
  Widget _photoPicker(String label, Uint8List? bytes, VoidCallback onPressed) =>
      OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(bytes == null
              ? Icons.add_a_photo_outlined
              : Icons.check_circle_outline),
          label: Text(bytes == null ? label : '$label attached'));
  Widget _summary(String title, Map<String, String> values) => Card(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
          padding: const EdgeInsets.all(14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: AppColors.primary)),
            const SizedBox(height: 8),
            ...values.entries
                .where((entry) => entry.value.trim().isNotEmpty)
                .map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Text('${entry.key}: ${entry.value}')))
          ])));
  String _resolvedAnimalType() => _animalType == 'Others (Specify)'
      ? _otherAnimalType.text.trim()
      : _animalType ?? '';
  void _toggleSuspiciousBehavior(String option, bool selected) {
    const exclusiveOptions = {
      'No suspicious behavior observed',
      'Unknown',
    };
    setState(() {
      if (selected && exclusiveOptions.contains(option)) {
        _behaviors
          ..clear()
          ..add(option);
      } else if (selected) {
        _behaviors
          ..removeAll(exclusiveOptions)
          ..add(option);
      } else {
        _behaviors.remove(option);
      }
    });
  }

  String _resolvedExposure() => _exposureType == 'Other (Specify)'
      ? _otherExposure.text.trim()
      : _exposureType ?? '';
  String _resolvedSubstance() => _appliedSubstance == 'Other'
      ? _otherSubstance.text.trim()
      : _appliedSubstance;
  String _firstAidSummary() => _washedWound == 'Yes'
      ? 'Washed with soap and water for ${_washMinutes.text} minutes; ${_resolvedSubstance()}'
      : _resolvedSubstance();
  String _fullName() => [
        _lastName.text.trim(),
        _firstName.text.trim(),
        _middleName.text.trim(),
        _suffix.text.trim()
      ].where((v) => v.isNotEmpty).join(', ');
  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  int _calculateAge(DateTime dob) {
    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  DateTime? _dateFromValue(Object? value) {
    if (value is Timestamp) return value.toDate();
    return DateTime.tryParse('$value');
  }

  ({String first, String last}) _splitFullName(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    return parts.length < 2
        ? (first: value, last: '')
        : (first: parts.first, last: parts.skip(1).join(' '));
  }

  String? _validOption(String value, List<String> options) =>
      options.contains(value) ? value : null;
}

const _behaviorOptions = [
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

class _SubmissionSuccess extends StatelessWidget {
  const _SubmissionSuccess({required this.caseId, required this.submittedAt});
  final String caseId;
  final DateTime submittedAt;
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Report Submitted')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: Colors.green, size: 72),
                    const SizedBox(height: 16),
                    Text('Report submitted successfully',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 20),
                    _successLine('Case ID', caseId),
                    _successLine('Report Status', 'Pending ABTC Claim'),
                    _successLine(
                      'Submission Date and Time',
                      '${submittedAt.year}-${submittedAt.month.toString().padLeft(2, '0')}-${submittedAt.day.toString().padLeft(2, '0')}  ${TimeOfDay.fromDateTime(submittedAt).format(context)}',
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Done'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
  Widget _successLine(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(color: Colors.black54, fontSize: 12)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700))
      ]));
}

class _BodySiteSelector extends StatelessWidget {
  const _BodySiteSelector({required this.selected, required this.onSelected});
  final Set<String> selected;
  final ValueChanged<String> onSelected;
  @override
  Widget build(BuildContext context) => Container(
      decoration: BoxDecoration(
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(8),
      child: Row(children: [
        Expanded(
            child: _BodyDiagram(
                side: 'Front', selected: selected, onSelected: onSelected)),
        const VerticalDivider(),
        Expanded(
            child: _BodyDiagram(
                side: 'Back', selected: selected, onSelected: onSelected))
      ]));
}

class _BodyDiagram extends StatelessWidget {
  const _BodyDiagram(
      {required this.side, required this.selected, required this.onSelected});
  final String side;
  final Set<String> selected;
  final ValueChanged<String> onSelected;
  static const _regions = <String>[
    'Head',
    'Chest',
    'Left Arm',
    'Right Arm',
    'Abdomen',
    'Left Leg',
    'Right Leg',
    'Left Foot',
    'Right Foot'
  ];
  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(side, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          AspectRatio(
            aspectRatio: .48,
            child: LayoutBuilder(
              builder: (context, constraints) => Stack(
                children: [
                  CustomPaint(size: Size.infinite, painter: _BodyPainter()),
                  ..._regions.map((region) {
                    final key = '$side $region';
                    return Align(
                      alignment: _regionAlignment(region),
                      child: Semantics(
                        button: true,
                        label: key,
                        child: InkWell(
                          onTap: () => onSelected(key),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: selected.contains(key)
                                  ? AppColors.danger
                                  : Colors.transparent,
                              border: Border.all(
                                color: selected.contains(key)
                                    ? AppColors.danger
                                    : Colors.transparent,
                              ),
                            ),
                            child: selected.contains(key)
                                ? const Icon(Icons.location_on,
                                    size: 20, color: Colors.white)
                                : null,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      );
  Alignment _regionAlignment(String region) => switch (region) {
        'Head' => const Alignment(0, -.88),
        'Chest' => const Alignment(0, -.42),
        'Abdomen' => const Alignment(0, -.08),
        'Left Arm' => const Alignment(-.68, -.31),
        'Right Arm' => const Alignment(.68, -.31),
        'Left Leg' => const Alignment(-.22, .48),
        'Right Leg' => const Alignment(.22, .48),
        'Left Foot' => const Alignment(-.25, .9),
        _ => const Alignment(.25, .9)
      };
}

class _BodyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE8EDF0)
      ..style = PaintingStyle.fill;
    final outline = Paint()
      ..color = const Color(0xFF9EABB4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final cx = size.width / 2;
    canvas.drawCircle(Offset(cx, size.height * .1), size.width * .16, paint);
    canvas.drawCircle(Offset(cx, size.height * .1), size.width * .16, outline);
    final torso = RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(cx, size.height * .36),
            width: size.width * .38,
            height: size.height * .38),
        const Radius.circular(22));
    canvas.drawRRect(torso, paint);
    canvas.drawRRect(torso, outline);
    for (final side in [-1, 1]) {
      final arm = Rect.fromCenter(
          center: Offset(cx + side * size.width * .31, size.height * .36),
          width: size.width * .11,
          height: size.height * .33);
      canvas.drawRRect(
          RRect.fromRectAndRadius(arm, const Radius.circular(12)), paint);
      canvas.drawRRect(
          RRect.fromRectAndRadius(arm, const Radius.circular(12)), outline);
      final leg = Rect.fromCenter(
          center: Offset(cx + side * size.width * .11, size.height * .72),
          width: size.width * .15,
          height: size.height * .37);
      canvas.drawRRect(
          RRect.fromRectAndRadius(leg, const Radius.circular(12)), paint);
      canvas.drawRRect(
          RRect.fromRectAndRadius(leg, const Radius.circular(12)), outline);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
