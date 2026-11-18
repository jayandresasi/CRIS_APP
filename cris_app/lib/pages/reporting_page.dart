import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:material_ui/material_ui.dart';

import '../models/report.dart';
import '../theme.dart';
import '../widgets/report_form_ui.dart';
import 'login_page.dart';

const List<String> iloiloMunicipalities = [
  'Ajuy', 'Alimodian', 'Anilao', 'Badiangan', 'Balasan', 'Banate',
  'Barotac Nuevo', 'Barotac Viejo', 'Batad', 'Bingawan', 'Cabatuan',
  'Calinog', 'Carles', 'Concepcion', 'Dingle', 'Duenas', 'Dumangas',
  'Estancia', 'Guimbal', 'Igbaras', 'Iloilo City', 'Janiuay', 'Lambunao',
  'Leganes', 'Lemery', 'Leon', 'Maasin', 'Miagao', 'Mina', 'New Lucena',
  'Oton', 'Passi City', 'Pavia', 'Pototan', 'San Dionisio', 'San Enrique',
  'San Joaquin', 'San Miguel', 'San Rafael', 'Santa Barbara', 'Sara',
  'Tigbauan', 'Tubungan', 'Zarraga',
];

class ReportingPage extends StatefulWidget {
  const ReportingPage({
    super.key,
    this.reportingForSelf = false,
    this.facilityId,
    this.facilityAcronym,
    this.facilityName,
  });

  final bool reportingForSelf;
  final String? facilityId;
  final String? facilityAcronym;
  final String? facilityName;

  @override
  State<ReportingPage> createState() => _ReportingPageState();
}

class _ReportingPageState extends State<ReportingPage> {
  final _formKey = GlobalKey<FormState>();
  final _formScrollController = ScrollController();
  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _suffixController = TextEditingController();
  final _dobController = TextEditingController();
  final _ageController = TextEditingController();
  final _civilStatusController = TextEditingController();
  final _religionController = TextEditingController();
  final _spouseController = TextEditingController();
  final _parentNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _provinceController = TextEditingController(text: 'Iloilo');
  final _municipalityController = TextEditingController();
  final _barangayController = TextEditingController();
  final _streetController = TextEditingController();
  final _otherPhilHealthController = TextEditingController();

  DateTime? _dateOfBirth;
  String? _sex;
  bool _isLoadingProfile = false;
  bool _reportingForSelf = false;
  bool _showPageErrors = false;
  bool _isSubmitting = false;
  int _currentPage = 0;
  final Set<String> _philHealthMemberships = {};

  bool get _patientFieldsReadOnly =>
      _reportingForSelf || _isLoadingProfile;

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
      _lastNameController, _firstNameController, _middleNameController,
      _suffixController, _dobController, _ageController, _civilStatusController,
      _religionController, _spouseController, _parentNameController,
      _mobileController, _provinceController, _municipalityController,
      _barangayController, _streetController, _otherPhilHealthController,
    ]) {
      controller.dispose();
    }
    _formScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _isLoadingProfile = true);
    try {
      final data = await FirebaseFirestore.instance
          .collection('user-info')
          .doc(user.uid)
          .get()
          .then((snapshot) => snapshot.data());
      if (!mounted) return;
      if (data == null) {
        setState(() => _reportingForSelf = false);
        return;
      }
      final parts = ((data['fullName'] ?? '') as String).trim().split(RegExp(r'\s+'));
      final dob = DateTime.tryParse((data['dob'] ?? data['birthDate'] ?? '') as String);
      setState(() {
        _firstNameController.text = parts.isNotEmpty ? parts.first : '';
        _lastNameController.text = parts.length > 1 ? parts.sublist(1).join(' ') : '';
        _dateOfBirth = dob;
        _dobController.text = dob == null ? '' : _formatDate(dob);
        _ageController.text = _calculateAge(dob)?.toString() ?? '';
        _sex = _normalizedSex((data['sex'] ?? data['gender'] ?? '') as String);
        _civilStatusController.text =
            _normalizedCivilStatus(data['civilStatus'] as String? ?? '') ?? '';
        _mobileController.text =
            (data['contactNumber'] ?? data['contact_number'] ?? '') as String;
        _streetController.text = (data['address'] ?? '') as String;
        _barangayController.text = (data['barangay'] ?? data['brgy'] ?? '') as String;
        _municipalityController.text = (data['municipality'] ?? '') as String;
      });
    } catch (_) {
      if (mounted) setState(() => _reportingForSelf = false);
    } finally {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
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

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  int? _calculateAge(DateTime? dob) {
    if (dob == null) return null;
    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) age--;
    return age;
  }

  String? _normalizedSex(String value) =>
      value == 'Male' || value == 'Female' ? value : null;
  String? _normalizedCivilStatus(String value) =>
      const ['Single', 'Married', 'Divorced'].contains(value) ? value : null;
  String? _required(String? value, String label) =>
      value == null || value.trim().isEmpty ? '$label is required' : null;

  String get _patientName {
    final lastName = _lastNameController.text.trim();
    final givenNames = [
      _firstNameController.text.trim(),
      _middleNameController.text.trim(),
      _suffixController.text.trim(),
    ].where((value) => value.isNotEmpty).join(' ');
    return lastName.isEmpty
        ? givenNames
        : givenNames.isEmpty
            ? lastName
            : '$lastName, $givenNames';
  }
  String get _addressSummary => [
        _streetController.text.trim(), _barangayController.text.trim(),
        _municipalityController.text.trim(), _provinceController.text.trim(),
      ].where((value) => value.isNotEmpty).join(', ');

  List<_FormPage> get _formPages => [
        _FormPage('Patient Information', _patientFields()),
        _FormPage('PhilHealth (PHIC) Membership', _philHealthFields()),
      ];

  List<Widget> _patientFields() => _withGaps([
        _sectionTitle('Patient Information', Icons.person_outline),
        _fieldRow(_patientLastNameField(), _patientFirstNameField()),
        _fieldRow(_patientMiddleNameField(), _patientSuffixField()),
        _fieldRow(_patientDobField(), _patientAgeField()),
        _fieldRow(_patientSexField(), _patientCivilStatusField()),
        _fieldRow(_religionField(), _patientMobileField()),
        _fieldRow(_spouseField(), _parentNameField()),
        _fieldRow(_patientStreetField(), _patientBarangayField()),
        _fieldRow(_patientMunicipalityField(), _patientProvinceField()),
      ]);

  List<Widget> _philHealthFields() => _withGaps([
        _sectionTitle('PhilHealth (PHIC) Membership', Icons.health_and_safety_outlined),
        LayoutBuilder(builder: (context, constraints) => Column(children: [
              _membershipRow('NHTS', '4Ps'),
              const SizedBox(height: 10),
              _membershipRow('Senior citizen', 'LGU sponsored'),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: (constraints.maxWidth - 10) / 2,
                  child: Column(children: [
                    _membershipTile('Others'),
                    if (_philHealthMemberships.contains('Others')) ...[
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _otherPhilHealthController,
                        decoration: const InputDecoration(labelText: 'Specify'),
                        validator: (value) => _required(value, 'Specify'),
                      ),
                    ],
                  ]),
                ),
              ),
            ])),
      ]);

  List<Widget> _withGaps(List<Widget> children, {double gap = 10}) => [
        for (var index = 0; index < children.length; index++) ...[
          if (index > 0) SizedBox(height: gap),
          children[index],
        ],
      ];

  Widget _sectionTitle(String title, IconData icon) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 6),
        child: Row(children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w800))),
        ]),
      );

  Widget _fieldRow(Widget left, Widget right) => Row(children: [
        Expanded(child: left), const SizedBox(width: 10), Expanded(child: right),
      ]);

  Widget _patientLastNameField() => _textField(_lastNameController, 'Last name', required: true, capitalization: TextCapitalization.words);
  Widget _patientFirstNameField() => _textField(_firstNameController, 'First name', required: true, capitalization: TextCapitalization.words);
  Widget _patientMiddleNameField() => _textField(_middleNameController, 'Middle name', hint: 'Middle name (optional)', capitalization: TextCapitalization.words);
  Widget _patientSuffixField() => _textField(_suffixController, 'Suffix', hint: 'e.g., Jr., Sr., III (optional)', capitalization: TextCapitalization.words);
  Widget _religionField() => _textField(_religionController, 'Religion');
  Widget _spouseField() => _textField(_spouseController, 'Husband / wife', hint: 'Name of spouse (if applicable)', capitalization: TextCapitalization.words);
  Widget _parentNameField() => _textField(_parentNameController, "Father / mother's name", hint: 'Name of parent (for minors)', capitalization: TextCapitalization.words);
  Widget _patientMobileField() => _textField(_mobileController, 'Contact number', hint: '09xx xxx xxxx', required: true, keyboardType: TextInputType.phone);
  Widget _patientStreetField() => _textField(_streetController, 'House no. / Street', hint: 'House no., street/purok', required: true, capitalization: TextCapitalization.sentences);
  Widget _patientBarangayField() => _textField(_barangayController, 'Barangay', required: true, capitalization: TextCapitalization.words);
  Widget _patientProvinceField() => _textField(_provinceController, 'Province', hint: 'e.g. Iloilo', required: true, capitalization: TextCapitalization.words);

  Widget _textField(TextEditingController controller, String label, {
    String? hint, bool required = false, TextCapitalization capitalization = TextCapitalization.none, TextInputType? keyboardType,
  }) => TextFormField(
        controller: controller,
        readOnly: _patientFieldsReadOnly,
        decoration: InputDecoration(labelText: label, hintText: hint),
        textCapitalization: capitalization,
        keyboardType: keyboardType,
        validator: required ? (value) => _required(value, label) : null,
      );

  Widget _patientDobField() => TextFormField(
        controller: _dobController, readOnly: true,
        decoration: const InputDecoration(labelText: 'Birthday', hintText: 'mm/dd/yyyy', suffixIcon: Icon(Icons.calendar_today_outlined)),
        onTap: _patientFieldsReadOnly ? null : _pickBirthDate,
        validator: (value) => _required(value, 'Birthday'),
      );
  Widget _patientAgeField() => TextFormField(
        controller: _ageController, readOnly: true,
        decoration: const InputDecoration(labelText: 'Age', hintText: '0'),
        validator: (value) => _required(value, 'Age'),
      );
  Widget _patientSexField() => DropdownButtonFormField<String>(
        initialValue: _sex, isExpanded: true, decoration: const InputDecoration(labelText: 'Sex'),
        items: const [DropdownMenuItem(value: 'Male', child: Text('Male')), DropdownMenuItem(value: 'Female', child: Text('Female'))],
        onChanged: _patientFieldsReadOnly ? null : (value) => setState(() => _sex = value),
        validator: (value) => value == null ? 'Sex is required' : null,
      );
  Widget _patientCivilStatusField() => DropdownButtonFormField<String>(
        initialValue: _normalizedCivilStatus(_civilStatusController.text), isExpanded: true,
        decoration: const InputDecoration(labelText: 'Civil status'),
        items: const [DropdownMenuItem(value: 'Single', child: Text('Single')), DropdownMenuItem(value: 'Married', child: Text('Married')), DropdownMenuItem(value: 'Divorced', child: Text('Divorced'))],
        onChanged: _patientFieldsReadOnly ? null : (value) => setState(() => _civilStatusController.text = value ?? ''),
      );
  Widget _patientMunicipalityField() => Autocomplete<String>(
        initialValue: TextEditingValue(text: _municipalityController.text),
        optionsBuilder: (value) {
          final query = value.text.trim().toLowerCase();
          return query.isEmpty ? iloiloMunicipalities : iloiloMunicipalities.where((item) => item.toLowerCase().contains(query));
        },
        onSelected: (value) => _municipalityController.text = value,
        fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
          if (controller.text != _municipalityController.text) controller.text = _municipalityController.text;
          return TextFormField(
            controller: controller, focusNode: focusNode, readOnly: _patientFieldsReadOnly,
            decoration: const InputDecoration(labelText: 'City / Municipality'),
            textCapitalization: TextCapitalization.words,
            onChanged: (value) => _municipalityController.text = value,
            validator: (value) => _required(value, 'City / Municipality'),
          );
        },
      );

  Widget _membershipRow(String first, String second) => Row(children: [
        Expanded(child: _membershipTile(first)), const SizedBox(width: 10), Expanded(child: _membershipTile(second)),
      ]);
  Widget _membershipTile(String membership) => ReportCheckboxTile(
        title: membership, value: _philHealthMemberships.contains(membership),
        onChanged: (checked) => setState(() {
          if (checked ?? false) {
            _philHealthMemberships.add(membership);
          } else {
            _philHealthMemberships.remove(membership);
            if (membership == 'Others') _otherPhilHealthController.clear();
          }
        }),
      );

  void _goToNextPage() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _showPageErrors = true);
    if (!_formKey.currentState!.validate()) return;
    setState(() { _currentPage = 1; _showPageErrors = false; });
    _formScrollController.jumpTo(0);
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _showPageErrors = true);
    if (!_formKey.currentState!.validate() || _isSubmitting) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar('Please sign in to submit a report.');
      if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()));
      return;
    }
    setState(() => _isSubmitting = true);
    final submittedAt = DateTime.now();
    final caseId = 'CRIS-${submittedAt.year}${submittedAt.month.toString().padLeft(2, '0')}${submittedAt.day.toString().padLeft(2, '0')}-${submittedAt.millisecondsSinceEpoch}';
    const status = 'Pending ABTC Claim';
    try {
      await Hive.box<Report>('reports').add(Report(
        lastName: _lastNameController.text.trim(), firstName: _firstNameController.text.trim(), middleInitial: _middleNameController.text.trim(), suffix: _suffixController.text.trim(), age: _ageController.text.trim(), gender: _sex ?? '', contactNumber: _mobileController.text.trim(), address: _addressSummary,
        dateOfIncident: '', timeOfIncident: '', locationOfIncident: '', exposureType: '', animalSpecies: '', animalOwnership: '', animalVaccinationStatus: '', incidentDescription: '', firstAidGiven: '', patientVaccinationStatus: '', reportedAt: submittedAt,
      ));
      await FirebaseFirestore.instance.collection('patients').doc(caseId).set({
        'caseId': caseId, 'userId': user.uid, 'reportingForSelf': _reportingForSelf, 'submittedBy': user.uid,
        'facilityAcronym': widget.facilityAcronym,
        'facilityId': widget.facilityId,
        'facility': {'id': widget.facilityId, 'name': widget.facilityName},
        'patient': {
          'lastName': _lastNameController.text.trim(), 'firstName': _firstNameController.text.trim(), 'middleName': _middleNameController.text.trim(), 'suffix': _suffixController.text.trim(), 'sex': _sex, 'dateOfBirth': _dobController.text.trim(), 'age': int.tryParse(_ageController.text.trim()), 'civilStatus': _civilStatusController.text.trim(), 'religion': _religionController.text.trim(), 'contactNumber': _mobileController.text.trim(), 'husbandOrWife': _spouseController.text.trim(), 'fatherOrMotherName': _parentNameController.text.trim(), 'province': _provinceController.text.trim(), 'municipality': _municipalityController.text.trim(), 'barangay': _barangayController.text.trim(), 'streetAddress': _streetController.text.trim(), 'fullName': _patientName,
        },
        'lastName': _lastNameController.text.trim(),
        'firstName': _firstNameController.text.trim(),
        'middleName': _middleNameController.text.trim(),
        'suffix': _suffixController.text.trim(),
        'fullName': _patientName,
        'name': _patientName,
        'birthday': _dobController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()),
        'sex': _sex ?? '',
        'civilStatus': _civilStatusController.text.trim(),
        'religion': _religionController.text.trim(),
        'contactNo': _mobileController.text.trim(),
        'spouseName': _spouseController.text.trim(),
        'parentName': _parentNameController.text.trim(),
        'address': {
          'houseStreet': _streetController.text.trim(),
          'barangay': _barangayController.text.trim(),
          'cityMunicipality': _municipalityController.text.trim(),
          'province': _provinceController.text.trim(),
          'fullAddress': _addressSummary,
        },
        'philHealthMembership': {
          'selections': _philHealthMemberships.toList()..sort(),
          'otherSpecify': _philHealthMemberships.contains('Others') ? _otherPhilHealthController.text.trim() : null,
        },
        'status': status, 'claimedByAbtc': false, 'claimedByAbtcId': null,
        'createdAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp(), 'submittedAt': submittedAt.toIso8601String(),
      });
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => _ReportSuccessPage(caseId: caseId, status: status, submittedAt: submittedAt)));
    } catch (e) {
      _showSnackBar('Unable to submit report: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final page = _formPages[_currentPage];
    return Scaffold(
      backgroundColor: AppColors.background, resizeToAvoidBottomInset: true,
      appBar: AppBar(toolbarHeight: 56, title: const Text('New Report', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
      body: SafeArea(child: Theme(
        data: Theme.of(context).copyWith(inputDecorationTheme: Theme.of(context).inputDecorationTheme.copyWith(isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12))),
        child: Form(
          key: _formKey, autovalidateMode: _showPageErrors ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
          child: Column(children: [
            Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 4), child: ReportFormProgressHeader(pageTitle: page.title, currentPage: _currentPage + 1, totalPages: 2)),
            Expanded(child: SingleChildScrollView(
              controller: _formScrollController, keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: page.fields),
            )),
            ReportFormNavigation(
              onBack: _currentPage == 0 ? null : () { FocusManager.instance.primaryFocus?.unfocus(); setState(() { _currentPage = 0; _showPageErrors = false; }); _formScrollController.jumpTo(0); },
              onNext: _currentPage == 0 ? _goToNextPage : _submit,
              nextLabel: _currentPage == 0 ? 'Next' : 'Submit',
              nextIcon: _currentPage == 0 ? Icons.arrow_forward : Icons.fact_check_outlined,
              nextEnabled: !_isSubmitting,
            ),
          ]),
        ),
      )),
    );
  }
}

class _FormPage {
  const _FormPage(this.title, this.fields);
  final String title;
  final List<Widget> fields;
}

class _ReportSuccessPage extends StatelessWidget {
  const _ReportSuccessPage({required this.caseId, required this.status, required this.submittedAt});
  final String caseId;
  final String status;
  final DateTime submittedAt;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Report Submitted')),
        body: SafeArea(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Icon(Icons.check_circle_outline, size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            Text('Report Submitted', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 24),
            _SuccessLine(label: 'Case ID', value: caseId), _SuccessLine(label: 'Report Status', value: status), _SuccessLine(label: 'Submitted', value: submittedAt.toLocal().toString()),
            const Spacer(), FilledButton(onPressed: () => Navigator.popUntil(context, (route) => route.isFirst), child: const Text('Done')),
          ]),
        )),
      );
}

class _SuccessLine extends StatelessWidget {
  const _SuccessLine({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: Colors.black54)), const SizedBox(height: 4), Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ]),
      );
}
