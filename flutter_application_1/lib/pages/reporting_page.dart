import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/report.dart';
import '../theme.dart';
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

class ReportingPage extends StatefulWidget {
  const ReportingPage({super.key});

  @override
  State<ReportingPage> createState() => _ReportingPageState();
}

class _ReportingPageState extends State<ReportingPage> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _barangayController = TextEditingController();
  final _municipalityController = TextEditingController();
  final _incidentLocationController = TextEditingController();
  final _incidentBarangayController = TextEditingController();
  final _incidentMunicipalityController = TextEditingController();
  final _animalSpeciesController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();

  String? _sex;
  String? _exposureType;
  String _animalOwnership = 'Stray';
  String _animalVaccinationStatus = 'Unknown';
  String _firstAidGiven = 'None';
  String _patientVaccinationStatus = 'Not vaccinated';
  bool _reportingForSelf = false;
  bool _isLoadingProfile = false;
  bool _isSubmitting = false;
  DateTime? _dateOfIncident;
  TimeOfDay? _timeOfIncident;

  bool get _patientFieldsReadOnly => _reportingForSelf || _isLoadingProfile;

  @override
  void dispose() {
    _fullNameController.dispose();
    _ageController.dispose();
    _contactNumberController.dispose();
    _addressController.dispose();
    _barangayController.dispose();
    _municipalityController.dispose();
    _incidentLocationController.dispose();
    _incidentBarangayController.dispose();
    _incidentMunicipalityController.dispose();
    _animalSpeciesController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _timeController.dispose();
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

      final dob = (data['dob'] ?? data['birthDate'] ?? '') as String;
      final calculatedAge = _calculateAge(dob);
      setState(() {
        _fullNameController.text = (data['fullName'] ?? '') as String;
        _ageController.text = calculatedAge == null ? '' : '$calculatedAge';
        _sex = _normalizedSex((data['sex'] ?? data['gender'] ?? '') as String);
        _contactNumberController.text =
            (data['contactNumber'] ?? data['contact_number'] ?? '') as String;
        _addressController.text = (data['address'] ?? '') as String;
        _barangayController.text =
            (data['barangay'] ?? data['brgy'] ?? '') as String;
        _municipalityController.text = (data['municipality'] ?? '') as String;
      });
    } on FirebaseException catch (e) {
      setState(() => _reportingForSelf = false);
      _showSnackBar(e.message ?? 'Unable to load your profile.');
    } catch (e) {
      setState(() => _reportingForSelf = false);
      _showSnackBar('Unable to load your profile: $e');
    } finally {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  void _clearPatientFields() {
    setState(() {
      _fullNameController.clear();
      _ageController.clear();
      _sex = null;
      _contactNumberController.clear();
      _addressController.clear();
      _barangayController.clear();
      _municipalityController.clear();
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfIncident ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() {
      _dateOfIncident = picked;
      _dateController.text = _formatDate(picked);
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _timeOfIncident ?? TimeOfDay.now(),
    );
    if (picked == null) return;
    setState(() {
      _timeOfIncident = picked;
      _timeController.text = picked.format(context);
    });
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

    if (!_formKey.currentState!.validate()) return;

    final dateStr = _dateController.text.trim();
    final timeStr = _timeController.text.trim();
    setState(() => _isSubmitting = true);

    try {
      final nameParts = _splitName(_fullNameController.text.trim());
      final report = Report(
        lastName: nameParts.lastName,
        firstName: nameParts.firstName,
        middleInitial: '',
        suffix: '',
        age: _ageController.text.trim(),
        gender: _sex ?? '',
        contactNumber: _contactNumberController.text.trim(),
        address: _addressController.text.trim(),
        dateOfIncident: dateStr,
        timeOfIncident: timeStr,
        locationOfIncident: _incidentLocationController.text.trim(),
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

      final doc = <String, dynamic>{
        'reportingForSelf': _reportingForSelf,
        'submittedBy': user.uid,
        'patient': {
          'fullName': _fullNameController.text.trim(),
          'age': int.parse(_ageController.text.trim()),
          'sex': _sex,
          'contactNumber': _contactNumberController.text.trim(),
          'address': _addressController.text.trim(),
          'barangay': _barangayController.text.trim(),
          'municipality': _municipalityController.text.trim(),
        },
        'incident': {
          'date': dateStr,
          'time': timeStr,
          'location': _incidentLocationController.text.trim(),
          'barangay': _incidentBarangayController.text.trim(),
          'municipality': _incidentMunicipalityController.text.trim(),
          'exposureType': _exposureType,
          'description': _descriptionController.text.trim(),
        },
        'animal': {
          'species': _animalSpeciesController.text.trim(),
          'ownership': _animalOwnership,
          'vaccinationStatus': _animalVaccinationStatus,
        },
        'medical': {
          'firstAidGiven': _firstAidGiven,
          'patientVaccinationStatus': _patientVaccinationStatus,
        },
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('bite_reports').add(doc);

      if (!mounted) return;
      _showSnackBar('Bite report submitted successfully.');
      Navigator.pop(context);
    } on FirebaseException catch (e) {
      _showSnackBar(e.message ?? 'Unable to upload bite report.');
    } catch (e) {
      _showSnackBar('Unable to submit bite report: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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

  String? _ageValidator(String? value) {
    final message = _required(value, 'Age');
    if (message != null) return message;
    final age = int.tryParse(value!.trim());
    if (age == null) return 'Age must be a number';
    if (age < 0 || age > 120) return 'Age must be between 0 and 120';
    return null;
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  int? _calculateAge(String dobString) {
    final dob = DateTime.tryParse(dobString);
    if (dob == null) return null;
    final now = DateTime.now();
    var age = now.year - dob.year;
    final hasHadBirthday =
        now.month > dob.month || (now.month == dob.month && now.day >= dob.day);
    if (!hasHadBirthday) age--;
    return age;
  }

  String? _normalizedSex(String value) {
    if (value == 'Male' || value == 'Female') return value;
    return null;
  }

  _NameParts _splitName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length <= 1) return _NameParts(firstName: fullName, lastName: '');
    return _NameParts(
      firstName: parts.first,
      lastName: parts.sublist(1).join(' '),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 10),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
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
        textController.text = controller.text;
        textController.selection = TextSelection.collapsed(
          offset: textController.text.length,
        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Report Bite Incident')),
      body: SafeArea(
        child: SingleChildScrollView(
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
                _sectionTitle('Patient Information'),
                TextFormField(
                  controller: _fullNameController,
                  readOnly: _patientFieldsReadOnly,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) => _required(value, 'Full name'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _ageController,
                        readOnly: _patientFieldsReadOnly,
                        decoration: const InputDecoration(labelText: 'Age'),
                        keyboardType: TextInputType.number,
                        validator: _ageValidator,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _sex,
                        decoration: const InputDecoration(labelText: 'Sex'),
                        items: const [
                          DropdownMenuItem(value: 'Male', child: Text('Male')),
                          DropdownMenuItem(
                            value: 'Female',
                            child: Text('Female'),
                          ),
                        ],
                        onChanged: _patientFieldsReadOnly
                            ? null
                            : (value) => setState(() => _sex = value),
                        validator: (value) =>
                            value == null ? 'Sex is required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _contactNumberController,
                  readOnly: _patientFieldsReadOnly,
                  decoration: const InputDecoration(labelText: 'Contact Number'),
                  keyboardType: TextInputType.phone,
                  validator: (value) => _required(value, 'Contact number'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  readOnly: _patientFieldsReadOnly,
                  decoration: const InputDecoration(labelText: 'Address'),
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) => _required(value, 'Address'),
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
                _municipalityField(
                  controller: _municipalityController,
                  label: 'Municipality',
                  enabled: !_patientFieldsReadOnly,
                ),
                _sectionTitle('Location of Incident'),
                TextFormField(
                  controller: _incidentLocationController,
                  decoration: const InputDecoration(
                    labelText: 'Specific Location / Landmark',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) =>
                      _required(value, 'Location of incident'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _incidentBarangayController,
                  decoration: const InputDecoration(labelText: 'Barangay'),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) => _required(value, 'Incident barangay'),
                ),
                const SizedBox(height: 12),
                _municipalityField(
                  controller: _incidentMunicipalityController,
                  label: 'Incident Municipality',
                ),
                _sectionTitle('Incident Details'),
                TextFormField(
                  controller: _dateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Date of Incident',
                    suffixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  onTap: _pickDate,
                  validator: (value) => _required(value, 'Date of incident'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _timeController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Time of Incident',
                    suffixIcon: Icon(Icons.access_time_outlined),
                  ),
                  onTap: _pickTime,
                  validator: (value) => _required(value, 'Time of incident'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _exposureType,
                  decoration: const InputDecoration(labelText: 'Type of Exposure'),
                  items: const [
                    DropdownMenuItem(value: 'Bite', child: Text('Bite')),
                    DropdownMenuItem(value: 'Scratch', child: Text('Scratch')),
                    DropdownMenuItem(
                      value: 'Lick on wound',
                      child: Text('Lick on wound'),
                    ),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (value) => setState(() => _exposureType = value),
                  validator: (value) =>
                      value == null ? 'Type of exposure is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _animalSpeciesController,
                  decoration: const InputDecoration(
                    labelText: 'Animal Species',
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) => _required(value, 'Animal species'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _animalOwnership,
                  decoration: const InputDecoration(labelText: 'Animal Ownership'),
                  items: const [
                    DropdownMenuItem(value: 'Stray', child: Text('Stray')),
                    DropdownMenuItem(value: 'Owned', child: Text('Owned')),
                    DropdownMenuItem(value: 'Unknown', child: Text('Unknown')),
                  ],
                  onChanged: (value) =>
                      setState(() => _animalOwnership = value ?? 'Stray'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _animalVaccinationStatus,
                  decoration: const InputDecoration(
                    labelText: 'Animal Vaccination Status',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Vaccinated',
                      child: Text('Vaccinated'),
                    ),
                    DropdownMenuItem(
                      value: 'Not vaccinated',
                      child: Text('Not vaccinated'),
                    ),
                    DropdownMenuItem(value: 'Unknown', child: Text('Unknown')),
                  ],
                  onChanged: (value) => setState(
                    () => _animalVaccinationStatus = value ?? 'Unknown',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description of Incident',
                  ),
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) => _required(value, 'Description'),
                ),
                _sectionTitle('Medical Information'),
                DropdownButtonFormField<String>(
                  initialValue: _firstAidGiven,
                  decoration: const InputDecoration(labelText: 'First Aid Given'),
                  items: const [
                    DropdownMenuItem(value: 'None', child: Text('None')),
                    DropdownMenuItem(
                      value: 'Wound washed',
                      child: Text('Wound washed'),
                    ),
                    DropdownMenuItem(
                      value: 'Antiseptic applied',
                      child: Text('Antiseptic applied'),
                    ),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (value) =>
                      setState(() => _firstAidGiven = value ?? 'None'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _patientVaccinationStatus,
                  decoration: const InputDecoration(
                    labelText: 'Patient Vaccination Status',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Not vaccinated',
                      child: Text('Not vaccinated'),
                    ),
                    DropdownMenuItem(
                      value: 'Partially vaccinated',
                      child: Text('Partially vaccinated'),
                    ),
                    DropdownMenuItem(
                      value: 'Fully vaccinated',
                      child: Text('Fully vaccinated'),
                    ),
                  ],
                  onChanged: (value) => setState(
                    () => _patientVaccinationStatus =
                        value ?? 'Not vaccinated',
                  ),
                ),
                const SizedBox(height: 24),
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
                    label: Text(
                      _isSubmitting ? 'Submitting...' : 'Submit Report',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NameParts {
  const _NameParts({required this.firstName, required this.lastName});

  final String firstName;
  final String lastName;
}
