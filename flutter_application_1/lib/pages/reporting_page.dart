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
  final _biteArea = TextEditingController();
  final _otherAnimalType = TextEditingController();
  final _lastVaccinationDate = TextEditingController();
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
  String? _animalCaged;
  String? _animalAlive;
  String? _availableForObservation;
  String? _animalVaccinated;
  String? _exposureCategory;
  String? _exposureType;
  String? _bleeding;
  String? _washedWound;
  String _appliedSubstance = 'None';
  DateTime? _selectedBirthDate;
  DateTime? _selectedLastVaccinationDate;
  DateTime? _selectedBiteDate;
  TimeOfDay? _selectedBiteTime;
  LatLng? _incidentCoordinates;
  XFile? _woundPhoto;
  XFile? _animalPhoto;
  Uint8List? _woundBytes;
  Uint8List? _animalBytes;
  final Set<String> _behaviors = {};
  final List<_BodySiteSelection> _bodySites = [];
  bool _multipleSites = false;
  int _affectedSiteLimit = 1;
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
      _biteArea,
      _otherAnimalType,
      _lastVaccinationDate,
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

  Future<void> _pickLastVaccinationDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedLastVaccinationDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedLastVaccinationDate = picked;
        _lastVaccinationDate.text = _formatDate(picked);
      });
    }
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

  void _selectBodySite(_BodySiteSelection site) {
    setState(() {
      final existingIndex =
          _bodySites.indexWhere((selection) => selection.id == site.id);
      if (_multipleSites) {
        if (existingIndex >= 0) {
          _bodySites.removeAt(existingIndex);
        } else if (_bodySites.length < _affectedSiteLimit) {
          _bodySites.add(site);
        } else {
          _showSnackBar(
              'You can only select the number of affected sites specified.');
        }
      } else {
        _bodySites
          ..clear()
          ..add(site);
      }
      _biteArea.text = _bodySites.map((selection) => selection.name).join(', ');
    });
  }

  void _setMultipleSites(bool value) {
    if (!value && _bodySites.length > 1) {
      _showSnackBar(
          'Remove extra body locations before turning off Multiple Sites.');
      return;
    }
    setState(() {
      _multipleSites = value;
      _affectedSiteLimit = value ? _affectedSiteLimit : 1;
    });
  }

  void _changeAffectedSiteLimit(int change) {
    if (!_multipleSites) return;
    final nextLimit = _affectedSiteLimit + change;
    if (nextLimit < 1) return;
    if (nextLimit < _bodySites.length) {
      _showSnackBar(
          'Remove selected body locations before reducing the number of affected sites.');
      return;
    }
    setState(() => _affectedSiteLimit = nextLimit);
  }

  void _removeBodySite(_BodySiteSelection site) {
    setState(() {
      _bodySites.removeWhere((selection) => selection.id == site.id);
      _biteArea.text =
          _bodySites.map((selection) => selection.name).join(', ');
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
    if (!_multipleSites && _bodySites.length != 1) {
      _showSnackBar('Select exactly one body area, or enable Multiple Sites.');
      return;
    }
    if (_bodySites.length > _affectedSiteLimit) {
      _showSnackBar(
          'You can only select the number of affected sites specified.');
      return;
    }
    setState(() => _reviewing = true);
  }

  Future<void> _submit() async {
    // The button is disabled while saving, and this guard also protects
    // against duplicate invocations before the widget rebuilds.
    if (_submitting) return;
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
          .collection('app-database')
          .doc(caseId)
          .set({
        // Canonical bite-case fields used by Firestore consumers. The nested
        // data below retains the complete existing report payload.
        'lastName': _lastName.text.trim(),
        'firstName': _firstName.text.trim(),
        'middleName': _middleName.text.trim(),
        'age': int.tryParse(_age.text.trim()),
        'sex': _sex,
        'contactNo': _mobile.text.trim(),
        'houseStreet': _streetAddress.text.trim(),
        'barangay': _residenceBarangay.text.trim(),
        'cityMunicipality': _residenceMunicipality.text.trim(),
        'province': _province.text.trim(),
        'biteArea': _bodySites.map((site) => site.name).toList(),
        'biteAreaDescription': _biteArea.text.trim(),
        'animalType': _resolvedAnimalType(),
        'animalOther': _animalType == 'Others (Specify)'
            ? _otherAnimalType.text.trim()
            : null,
        'animalCaged': _animalCaged == 'Yes'
            ? true
            : _animalCaged == 'No'
                ? false
                : null,
        'priorVaccination': _animalVaccinated,
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
          'caged': _animalCaged,
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
          'bodySites': _bodySites.map((site) => site.name).toList(),
          'areaDescription': _biteArea.text.trim(),
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
        'submittedAt': FieldValue.serverTimestamp(),
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
      _showSnackBar(_submissionErrorMessage(e));
    } catch (_) {
      _showSnackBar(
          'Unable to submit your bite report. Please try again shortly.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _submissionErrorMessage(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'You do not have permission to submit a bite report.';
      case 'unavailable':
      case 'network-request-failed':
        return 'Unable to submit your bite report. Check your connection and try again.';
      default:
        return 'Unable to submit your bite report. Please try again shortly.';
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
                  _patientInformationSection(),
                  _section('2. Incident Location', [
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
                  ]),
                  _section('3. Animal Information', [
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
                    _subheading('Suspicious Animal Behavior'),
                    ..._behaviorOptions.map((option) => _reportCheckboxTile(
                        title: option,
                        value: _behaviors.contains(option),
                        onChanged: (checked) =>
                            _toggleSuspiciousBehavior(option, checked ?? false))),
                  ]),
                  _section('4. Exposure Information', [
                    _subheading('Exposure and Bite Details'),
                    const Divider(),
                    _field(_biteArea, 'Area of the Bite',
                        hintText: 'e.g., Right lower leg'),
                    _responsivePatientFieldGrid([
                      _dropdown(
                          'Type of animal',
                          _animalType,
                          const ['Dog', 'Cat', 'Others'],
                          (v) => setState(() => _animalType = v),
                          required: true),
                      _yesNo('Previously vaccinated?', _animalVaccinated,
                          (v) => setState(() => _animalVaccinated = v)),
                    ]),
                    _yesNoUnknown('Was the animal caged?', _animalCaged,
                        (v) => setState(() => _animalCaged = v)),
                    _subheading('Body Part Affected'),
                    _reportCheckboxTile(
                        title: 'Multiple Sites',
                        value: _multipleSites,
                        subtitle:
                            'Select this before choosing more than one body location.',
                        onChanged: (value) => _setMultipleSites(value ?? false)),
                    _AffectedSiteQuantitySelector(
                        value: _affectedSiteLimit,
                        enabled: _multipleSites,
                        onDecrease: () => _changeAffectedSiteLimit(-1),
                        onIncrease: () => _changeAffectedSiteLimit(1)),
                    const Text('Tap the affected body part(s).'),
                    _BodySiteSelector(
                        selected: _bodySites, onSelected: _selectBodySite),
                    if (_bodySites.isNotEmpty)
                      _SelectedBodyPartsList(
                          selections: _bodySites, onRemove: _removeBodySite),
                    const SizedBox(height: 12),
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
        if (_incidentCoordinates != null)
          _summary('Incident Location', {
            'GPS Location':
                '${_incidentCoordinates!.latitude.toStringAsFixed(6)}, ${_incidentCoordinates!.longitude.toStringAsFixed(6)}',
          }),
        _summary('Animal Information', {
          'Animal': _resolvedAnimalType(),
          'Ownership': _ownership,
          'Description': [_breed.text, _color.text, _animalAge.text]
              .where((v) => v.trim().isNotEmpty)
              .join(', '),
          'Suspicious behavior': _behaviors.join(', ')
        }),
        _summary('Exposure & First Aid', {
          'Exposure': _resolvedExposure(),
          'Area of bite': _biteArea.text,
          'Body areas': _bodySites.map((site) => site.name).join(', '),
          'Animal caged': _animalCaged ?? '',
          'Previously vaccinated': _animalVaccinated ?? '',
          'Bleeding': _bleeding ?? '',
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

  Widget _patientInformationSection() => Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cream),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person_rounded,
                        color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Patient information',
                      style:
                          Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: const Color(0xFF172554),
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 32, color: AppColors.cream),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _reportingForSelf,
                onChanged: _loadingProfile ? null : _setReportingForSelf,
                title: const Text('Reporting for self?'),
                subtitle: const Text('Use saved profile details'),
                secondary: _loadingProfile
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.person_outline),
              ),
              const SizedBox(height: 12),
              _responsivePatientFieldGrid([
                _patientLabeledField(
                  'Last name',
                  _field(
                    _lastName,
                    'Last Name',
                    required: true,
                    readOnly: _patientReadOnly,
                    showLabel: false,
                    hintText: 'Last name',
                  ),
                ),
                _patientLabeledField(
                  'First name',
                  _field(
                    _firstName,
                    'First Name',
                    required: true,
                    readOnly: _patientReadOnly,
                    showLabel: false,
                    hintText: 'First name',
                  ),
                ),
                _patientLabeledField(
                  'Middle name',
                  _field(
                    _middleName,
                    'Middle Name',
                    readOnly: _patientReadOnly,
                    showLabel: false,
                    hintText: 'Middle name (optional)',
                  ),
                ),
                _patientLabeledField(
                  'Age',
                  _field(
                    _age,
                    'Age (Automatically calculated)',
                    readOnly: true,
                    showLabel: false,
                    hintText: 'Automatically calculated',
                  ),
                ),
                _patientLabeledField(
                  'Sex',
                  _dropdown(
                    'Sex',
                    _sex,
                    const ['Male', 'Female'],
                    (v) => setState(() => _sex = v),
                    required: true,
                    enabled: !_patientReadOnly,
                    showLabel: false,
                    hintText: 'Select',
                  ),
                ),
                _patientLabeledField(
                  'Contact number',
                  _field(
                    _mobile,
                    'Mobile Number',
                    required: true,
                    keyboardType: TextInputType.phone,
                    readOnly: _patientReadOnly,
                    showLabel: false,
                    hintText: '09xx xxx xxxx',
                  ),
                ),
                _patientLabeledField(
                  'House no. / Street',
                  _field(
                    _streetAddress,
                    'Street Address',
                    required: true,
                    readOnly: _patientReadOnly,
                    showLabel: false,
                    hintText: 'House no., street/purok',
                  ),
                ),
                _patientLabeledField(
                  'Barangay',
                  _field(
                    _residenceBarangay,
                    'Barangay',
                    required: true,
                    readOnly: _patientReadOnly,
                    showLabel: false,
                    hintText: 'Barangay',
                  ),
                ),
                _patientLabeledField(
                  'City / Municipality',
                  _municipalityField(
                    _residenceMunicipality,
                    'Municipality/City',
                    enabled: !_patientReadOnly,
                    showLabel: false,
                    hintText: 'City or municipality',
                  ),
                ),
                _patientLabeledField(
                  'Province',
                  _field(
                    _province,
                    'Province',
                    required: true,
                    readOnly: _patientReadOnly,
                    showLabel: false,
                    hintText: 'e.g. Iloilo',
                  ),
                ),
                _patientLabeledField(
                  'Date of birth',
                  _dateField(
                    _birthDate,
                    'Date of Birth',
                    _pickBirthDate,
                    required: true,
                    readOnly: _patientReadOnly,
                    showLabel: false,
                    hintText: 'Select date',
                  ),
                ),
                _patientLabeledField(
                  'Suffix',
                  _field(
                    _suffix,
                    'Suffix (Optional)',
                    readOnly: _patientReadOnly,
                    showLabel: false,
                    hintText: 'Suffix (optional)',
                  ),
                ),
                _patientLabeledField(
                  'Civil status',
                  _field(
                    _civilStatus,
                    'Civil Status (Optional)',
                    readOnly: _patientReadOnly,
                    showLabel: false,
                    hintText: 'Civil status (optional)',
                  ),
                ),
                _patientLabeledField(
                  'Email address',
                  _field(
                    _email,
                    'Email Address (Optional)',
                    validator: _emailValidator,
                    keyboardType: TextInputType.emailAddress,
                    readOnly: _patientReadOnly,
                    showLabel: false,
                    hintText: 'Email address (optional)',
                  ),
                ),
              ]),
            ],
          ),
        ),
      );

  Widget _patientLabeledField(String label, Widget field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 7),
          field,
        ],
      );

  Widget _responsivePatientFieldGrid(List<Widget> fields) => LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            return Column(
              children: [
                for (var index = 0; index < fields.length; index++) ...[
                  fields[index],
                  if (index < fields.length - 1) const SizedBox(height: 16),
                ],
              ],
            );
          }

          return Column(
            children: [
              for (var index = 0; index < fields.length; index += 2) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: fields[index]),
                    const SizedBox(width: 24),
                    Expanded(
                      child: index + 1 < fields.length
                          ? fields[index + 1]
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
                if (index + 2 < fields.length) const SizedBox(height: 16),
              ],
            ],
          );
        },
      );

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
          bool showLabel = true,
          String? hintText,
          String? Function(String?)? validator}) =>
      TextFormField(
          controller: controller,
          readOnly: readOnly,
          maxLines: maxLines,
          keyboardType: keyboardType,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
              labelText: showLabel ? label : null, hintText: hintText),
          validator: validator ??
              (required
                  ? (v) => _required(v, label.replaceAll(' (Optional)', ''))
                  : null));
  Widget _dateField(
          TextEditingController controller, String label, VoidCallback onTap,
          {bool required = false,
          bool readOnly = false,
          bool showLabel = true,
          String? hintText}) =>
      TextFormField(
          controller: controller,
          readOnly: true,
          enabled: !readOnly,
          onTap: onTap,
          decoration: InputDecoration(
              labelText: showLabel ? label : null,
              hintText: hintText,
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
          {bool required = false,
          bool enabled = true,
          bool showLabel = true,
          String? hintText}) =>
      DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          style: const TextStyle(color: Colors.black87),
          dropdownColor: Colors.white,
          iconEnabledColor: Colors.black54,
          decoration: InputDecoration(
            labelText: showLabel ? label : null,
            hintText: hintText ?? 'Select $label',
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
          {bool enabled = true, bool showLabel = true, String? hintText}) =>
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
                    labelText: showLabel ? label : null,
                    hintText: hintText ?? 'Select or enter $label',
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

class _AffectedSiteQuantitySelector extends StatelessWidget {
  const _AffectedSiteQuantitySelector({
    required this.value,
    required this.enabled,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int value;
  final bool enabled;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) => Row(children: [
        const Expanded(
            child: Text('Number of Affected Sites',
                style: TextStyle(fontWeight: FontWeight.w600))),
        IconButton(
            tooltip: 'Decrease affected sites',
            onPressed: enabled && value > 1 ? onDecrease : null,
            icon: const Icon(Icons.remove_circle_outline)),
        Semantics(
            label: '$value affected site${value == 1 ? '' : 's'}',
            child: SizedBox(
                width: 28,
                child: Text('$value', textAlign: TextAlign.center))),
        IconButton(
            tooltip: 'Increase affected sites',
            onPressed: enabled ? onIncrease : null,
            icon: const Icon(Icons.add_circle_outline)),
      ]);
}

class _SelectedBodyPartsList extends StatelessWidget {
  const _SelectedBodyPartsList({
    required this.selections,
    required this.onRemove,
  });

  final List<_BodySiteSelection> selections;
  final ValueChanged<_BodySiteSelection> onRemove;

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Selected Body Parts:',
            style: TextStyle(fontWeight: FontWeight.w700)),
        ...selections.map((selection) => Row(children: [
              const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.circle, size: 10, color: AppColors.danger)),
              Expanded(child: Text(selection.name)),
              TextButton(
                  onPressed: () => onRemove(selection), child: const Text('Remove')),
            ])),
      ]));
}

class _BodySiteSelector extends StatelessWidget {
  const _BodySiteSelector({required this.selected, required this.onSelected});

  final List<_BodySiteSelection> selected;
  final ValueChanged<_BodySiteSelection> onSelected;

  @override
  Widget build(BuildContext context) => Container(
      decoration: BoxDecoration(
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(8),
      child: Center(
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: AspectRatio(
                  aspectRatio: 700 / 724,
                  child: LayoutBuilder(builder: (context, constraints) {
                    return Semantics(
                        label: 'Interactive front and back body diagram',
                        child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapDown: (details) {
                              final position = Offset(
                                  details.localPosition.dx / constraints.maxWidth,
                                  details.localPosition.dy / constraints.maxHeight);
                              final selection = _BodyPartMap.resolve(position);
                              if (selection != null) onSelected(selection);
                            },
                            child: Stack(children: [
                              const Positioned.fill(
                                  child: Image(
                                      image: AssetImage(
                                          'assets/images/bodydiagram.webp'),
                                      fit: BoxFit.fill)),
                              ...selected.map((selection) => Positioned(
                                  left: selection.position.dx *
                                          constraints.maxWidth -
                                      8,
                                  top: selection.position.dy *
                                          constraints.maxHeight -
                                      8,
                                  child: const IgnorePointer(
                                      child: Icon(Icons.circle,
                                          size: 16, color: AppColors.danger)))),
                            ])));
                  })))));
}

class _BodySiteSelection {
  const _BodySiteSelection({
    required this.id,
    required this.name,
    required this.position,
  });

  final String id;
  final String name;
  final Offset position;
}

class _BodyPartMap {
  static _BodySiteSelection? resolve(Offset position) {
    for (final region in _regions) {
      if (region.bounds.contains(position)) {
        return _BodySiteSelection(
            id: region.id, name: region.name, position: position);
      }
    }
    return null;
  }

  // Bounds are fractions of the supplied 700 x 724 image. This keeps hit
  // testing and marker placement aligned when the diagram is resized.
  static const _regions = <_BodyHitRegion>[
    // Front view: smaller regions come first so fingers, ears and joints are
    // not swallowed by the larger adjacent body-area bounds.
    _BodyHitRegion('front-right-ear', 'Right Ear', Rect.fromLTRB(.232, .115, .252, .155)),
    _BodyHitRegion('front-left-ear', 'Left Ear', Rect.fromLTRB(.348, .115, .368, .155)),
    _BodyHitRegion('front-face', 'Face', Rect.fromLTRB(.245, .105, .355, .190)),
    _BodyHitRegion('front-head', 'Head', Rect.fromLTRB(.250, .055, .350, .120)),
    _BodyHitRegion('front-neck', 'Neck', Rect.fromLTRB(.270, .185, .330, .225)),
    _BodyHitRegion('front-right-fingers', 'Right Fingers', Rect.fromLTRB(.075, .570, .135, .630)),
    _BodyHitRegion('front-left-fingers', 'Left Fingers', Rect.fromLTRB(.465, .570, .525, .630)),
    _BodyHitRegion('front-right-hand', 'Right Hand', Rect.fromLTRB(.105, .535, .180, .615)),
    _BodyHitRegion('front-left-hand', 'Left Hand', Rect.fromLTRB(.420, .535, .495, .615)),
    _BodyHitRegion('front-right-wrist', 'Right Wrist', Rect.fromLTRB(.145, .510, .195, .565)),
    _BodyHitRegion('front-left-wrist', 'Left Wrist', Rect.fromLTRB(.405, .510, .455, .565)),
    _BodyHitRegion('front-right-elbow', 'Right Elbow', Rect.fromLTRB(.165, .390, .225, .450)),
    _BodyHitRegion('front-left-elbow', 'Left Elbow', Rect.fromLTRB(.375, .390, .435, .450)),
    _BodyHitRegion('front-right-forearm', 'Right Forearm', Rect.fromLTRB(.145, .435, .210, .535)),
    _BodyHitRegion('front-left-forearm', 'Left Forearm', Rect.fromLTRB(.390, .435, .455, .535)),
    _BodyHitRegion('front-right-upper-arm', 'Right Upper Arm', Rect.fromLTRB(.165, .275, .230, .405)),
    _BodyHitRegion('front-left-upper-arm', 'Left Upper Arm', Rect.fromLTRB(.370, .275, .435, .405)),
    _BodyHitRegion('front-right-shoulder', 'Right Shoulder', Rect.fromLTRB(.175, .210, .245, .290)),
    _BodyHitRegion('front-left-shoulder', 'Left Shoulder', Rect.fromLTRB(.355, .210, .425, .290)),
    _BodyHitRegion('front-right-toe', 'Right Toes', Rect.fromLTRB(.220, .930, .285, .970)),
    _BodyHitRegion('front-left-toe', 'Left Toes', Rect.fromLTRB(.315, .930, .380, .970)),
    _BodyHitRegion('front-right-foot', 'Right Foot', Rect.fromLTRB(.215, .900, .290, .950)),
    _BodyHitRegion('front-left-foot', 'Left Foot', Rect.fromLTRB(.310, .900, .385, .950)),
    _BodyHitRegion('front-right-ankle', 'Right Ankle', Rect.fromLTRB(.225, .870, .285, .920)),
    _BodyHitRegion('front-left-ankle', 'Left Ankle', Rect.fromLTRB(.315, .870, .375, .920)),
    _BodyHitRegion('front-right-knee', 'Right Knee', Rect.fromLTRB(.220, .735, .290, .800)),
    _BodyHitRegion('front-left-knee', 'Left Knee', Rect.fromLTRB(.310, .735, .380, .800)),
    _BodyHitRegion('front-right-lower-leg', 'Right Lower Leg', Rect.fromLTRB(.220, .785, .290, .885)),
    _BodyHitRegion('front-left-lower-leg', 'Left Lower Leg', Rect.fromLTRB(.310, .785, .380, .885)),
    _BodyHitRegion('front-right-thigh', 'Right Thigh', Rect.fromLTRB(.215, .565, .295, .755)),
    _BodyHitRegion('front-left-thigh', 'Left Thigh', Rect.fromLTRB(.305, .565, .385, .755)),
    _BodyHitRegion('front-right-hip', 'Right Hip', Rect.fromLTRB(.185, .500, .250, .590)),
    _BodyHitRegion('front-left-hip', 'Left Hip', Rect.fromLTRB(.350, .500, .415, .590)),
    _BodyHitRegion('front-pelvis', 'Pelvis/Groin', Rect.fromLTRB(.245, .485, .355, .585)),
    _BodyHitRegion('front-abdomen', 'Abdomen', Rect.fromLTRB(.235, .365, .365, .495)),
    _BodyHitRegion('front-chest', 'Chest', Rect.fromLTRB(.225, .230, .375, .380)),

    // Back view.
    _BodyHitRegion('back-left-ear', 'Left Ear (Back)', Rect.fromLTRB(.628, .115, .648, .155)),
    _BodyHitRegion('back-right-ear', 'Right Ear (Back)', Rect.fromLTRB(.742, .115, .762, .155)),
    _BodyHitRegion('back-head', 'Head (Back)', Rect.fromLTRB(.645, .055, .745, .135)),
    _BodyHitRegion('back-neck', 'Neck (Back)', Rect.fromLTRB(.665, .180, .725, .225)),
    _BodyHitRegion('back-left-fingers', 'Left Fingers (Back)', Rect.fromLTRB(.500, .570, .560, .630)),
    _BodyHitRegion('back-right-fingers', 'Right Fingers (Back)', Rect.fromLTRB(.830, .570, .890, .630)),
    _BodyHitRegion('back-left-hand', 'Left Hand (Back)', Rect.fromLTRB(.515, .535, .590, .615)),
    _BodyHitRegion('back-right-hand', 'Right Hand (Back)', Rect.fromLTRB(.800, .535, .875, .615)),
    _BodyHitRegion('back-left-wrist', 'Left Wrist (Back)', Rect.fromLTRB(.555, .510, .605, .565)),
    _BodyHitRegion('back-right-wrist', 'Right Wrist (Back)', Rect.fromLTRB(.785, .510, .835, .565)),
    _BodyHitRegion('back-left-elbow', 'Left Elbow (Back)', Rect.fromLTRB(.565, .390, .625, .450)),
    _BodyHitRegion('back-right-elbow', 'Right Elbow (Back)', Rect.fromLTRB(.755, .390, .815, .450)),
    _BodyHitRegion('back-left-forearm', 'Left Forearm (Back)', Rect.fromLTRB(.545, .435, .610, .535)),
    _BodyHitRegion('back-right-forearm', 'Right Forearm (Back)', Rect.fromLTRB(.770, .435, .835, .535)),
    _BodyHitRegion('back-left-upper-arm', 'Left Upper Arm (Back)', Rect.fromLTRB(.565, .275, .630, .405)),
    _BodyHitRegion('back-right-upper-arm', 'Right Upper Arm (Back)', Rect.fromLTRB(.750, .275, .815, .405)),
    _BodyHitRegion('back-left-shoulder', 'Left Shoulder (Back)', Rect.fromLTRB(.565, .210, .635, .290)),
    _BodyHitRegion('back-right-shoulder', 'Right Shoulder (Back)', Rect.fromLTRB(.750, .210, .820, .290)),
    _BodyHitRegion('back-left-toe', 'Left Toes (Back)', Rect.fromLTRB(.640, .930, .705, .970)),
    _BodyHitRegion('back-right-toe', 'Right Toes (Back)', Rect.fromLTRB(.735, .930, .800, .970)),
    _BodyHitRegion('back-left-foot', 'Left Foot (Back)', Rect.fromLTRB(.635, .900, .710, .950)),
    _BodyHitRegion('back-right-foot', 'Right Foot (Back)', Rect.fromLTRB(.730, .900, .805, .950)),
    _BodyHitRegion('back-left-ankle', 'Left Ankle (Back)', Rect.fromLTRB(.645, .870, .705, .920)),
    _BodyHitRegion('back-right-ankle', 'Right Ankle (Back)', Rect.fromLTRB(.735, .870, .795, .920)),
    _BodyHitRegion('back-left-knee', 'Left Knee (Back)', Rect.fromLTRB(.640, .735, .710, .800)),
    _BodyHitRegion('back-right-knee', 'Right Knee (Back)', Rect.fromLTRB(.730, .735, .800, .800)),
    _BodyHitRegion('back-left-lower-leg', 'Left Lower Leg (Back)', Rect.fromLTRB(.640, .785, .710, .885)),
    _BodyHitRegion('back-right-lower-leg', 'Right Lower Leg (Back)', Rect.fromLTRB(.730, .785, .800, .885)),
    _BodyHitRegion('back-left-thigh', 'Left Thigh (Back)', Rect.fromLTRB(.635, .565, .715, .755)),
    _BodyHitRegion('back-right-thigh', 'Right Thigh (Back)', Rect.fromLTRB(.725, .565, .805, .755)),
    _BodyHitRegion('back-left-hip', 'Left Hip (Back)', Rect.fromLTRB(.605, .500, .670, .590)),
    _BodyHitRegion('back-right-hip', 'Right Hip (Back)', Rect.fromLTRB(.770, .500, .835, .590)),
    _BodyHitRegion('back-pelvis', 'Pelvis/Groin (Back)', Rect.fromLTRB(.655, .485, .745, .590)),
    _BodyHitRegion('back-lower-back', 'Lower Back', Rect.fromLTRB(.625, .365, .765, .505)),
    _BodyHitRegion('back-upper-back', 'Upper Back', Rect.fromLTRB(.615, .225, .775, .380)),
  ];
}

class _BodyHitRegion {
  const _BodyHitRegion(this.id, this.name, this.bounds);

  final String id;
  final String name;
  final Rect bounds;
}
