import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../models/sab_report.dart';
import '../theme.dart';
import '../widgets/cris_map.dart';
import '../widgets/report_form_ui.dart';

const _behaviorOptions = [
  'Unprovoked aggression or unusual attacking behavior',
  'Repeatedly biting people, animals, or objects',
  'Excessive salivation or drooling',
  'Difficulty swallowing',
  'Unusual vocalization',
  'Restlessness or unusual agitation',
  'Wandering aimlessly or appearing disoriented',
  'Weakness or difficulty moving',
  'Paralysis or difficulty using part of the body',
  'Seizure-like activity or convulsions',
  "Sudden unusual behavior compared with the animal's normal behavior",
  'Other (Specify)',
  'Unsure',
];

class SABReportingPage extends StatefulWidget {
  const SABReportingPage({super.key});

  @override
  State<SABReportingPage> createState() => _SABReportingPageState();
}

class _SABReportingPageState extends State<SABReportingPage> {
  final _formKey = GlobalKey<FormState>();
  final _animalCountController = TextEditingController(text: '1');
  final _otherAnimalController = TextEditingController();
  final _otherBehaviorController = TextEditingController();

  final Set<String> _behaviors = {};
  String? _animalType;
  String? _ownership;
  String? _stillPresent;
  String? _immediateDanger;
  DateTime? _dateObserved;
  TimeOfDay? _timeObserved;
  LatLng? _observationPoint;
  String? _locationMethod;
  XFile? _photo;
  Uint8List? _webPhoto;
  File? _devicePhoto;
  bool _consentGiven = false;
  bool _gettingLocation = false;
  bool _submitting = false;
  String? _locationError;
  String? _submitStatus;

  @override
  void initState() {
    super.initState();
    for (final controller in [
      _animalCountController,
      _otherAnimalController,
      _otherBehaviorController,
    ]) {
      controller.addListener(_refresh);
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final controller in [
      _animalCountController,
      _otherAnimalController,
      _otherBehaviorController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _hasLocation => _observationPoint != null;
  bool get _readyToReview =>
      _animalType != null &&
      (_animalType != 'Other' ||
          _otherAnimalController.text.trim().isNotEmpty) &&
      int.tryParse(_animalCountController.text) != null &&
      int.tryParse(_animalCountController.text)! > 0 &&
      _ownership != null &&
      _behaviors.isNotEmpty &&
      (!_behaviors.contains('Other (Specify)') ||
          _otherBehaviorController.text.trim().isNotEmpty) &&
      _hasLocation &&
      _dateObserved != null &&
      _timeObserved != null &&
      _stillPresent != null &&
      _immediateDanger != null &&
      _consentGiven;

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateObserved ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null) setState(() => _dateObserved = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _timeObserved ?? TimeOfDay.now(),
    );
    if (time != null) setState(() => _timeObserved = time);
  }

  void _pinLocation(LatLng point) => setState(() {
        _observationPoint = point;
        _locationMethod = 'map_pin';
        _locationError = null;
      });

  Future<void> _useCurrentLocation() async {
    setState(() {
      _gettingLocation = true;
      _locationError = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Location services are turned off.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission was not granted.');
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;
      setState(() {
        _observationPoint = LatLng(position.latitude, position.longitude);
        _locationMethod = 'current_location';
      });
    } catch (e) {
      if (mounted) {
        setState(() => _locationError = 'Unable to use current location: $e');
      }
    } finally {
      if (mounted) setState(() => _gettingLocation = false);
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final image = await ImagePicker().pickImage(source: source);
    if (image == null) return;
    final bytes = await image.readAsBytes();
    setState(() {
      _photo = image;
      _webPhoto = kIsWeb ? bytes : null;
      _devicePhoto = kIsWeb ? null : File(image.path);
    });
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _animalValue() => _animalType == 'Other'
      ? _otherAnimalController.text.trim()
      : _animalType ?? '';

  String _behaviorValue() => _behaviors
      .map((behavior) => behavior == 'Other (Specify)'
          ? 'Other: ${_otherBehaviorController.text.trim()}'
          : behavior)
      .join(', ');

  String? _required(String? value, String label) =>
      value == null || value.trim().isEmpty ? '$label is required' : null;

  String? _positiveNumber(String? value) {
    final number = int.tryParse(value ?? '');
    return number == null || number < 1 ? 'Enter at least one animal' : null;
  }

  Future<void> _review() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasLocation) {
      setState(() => _locationError =
          'Please provide the location where the animal was observed by either placing a pin on the map or using your current location.');
      return;
    }
    if (!_consentGiven) {
      _snack('Please confirm your consent before submitting.');
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ReviewSheet(
        sections: _reviewSections(),
        onEdit: () => Navigator.pop(context),
        onSubmit: () async {
          Navigator.pop(context);
          await _submit();
        },
      ),
    );
  }

  List<_ReviewSection> _reviewSections() => [
        _ReviewSection('Animal Information', {
          'Animal type': _animalValue(),
          'Number of animals': _animalCountController.text.trim(),
          'Ownership status': _ownership ?? '',
        }),
        _ReviewSection(
            'Observed Behavior', {'Selected behaviors': _behaviorValue()}),
        _ReviewSection('Location', {
          'Location method': _locationMethod == 'current_location'
              ? 'Current location'
              : 'Map pin',
          'Map location':
              '${_observationPoint!.latitude.toStringAsFixed(6)}, ${_observationPoint!.longitude.toStringAsFixed(6)}',
        }),
        _ReviewSection('Observation Details', {
          'Date observed': _formatDate(_dateObserved!),
          'Time or time period': _timeObserved!.format(context),
          'Animal still present': _stillPresent ?? '',
          'Immediate danger': _immediateDanger ?? '',
        }),
        _ReviewSection('Photo Evidence', {
          'Supporting evidence':
              _photo == null ? 'None provided' : 'Photo attached',
        }),
      ];

  Future<String?> _uploadPhoto(String uid) async {
    if (_photo == null) return null;
    final ref = FirebaseStorage.instance
        .ref()
        .child('sab_images')
        .child(uid)
        .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
    if (kIsWeb) {
      await ref.putData(_webPhoto ?? await _photo!.readAsBytes(),
          SettableMetadata(contentType: 'image/jpeg'));
    } else {
      await ref.putFile(_devicePhoto ?? File(_photo!.path));
    }
    return ref.getDownloadURL();
  }

  Future<void> _submit() async {
    // The review sheet is only opened for complete reports, but retain this
    // guard so a report can never be submitted without the required location
    // and consent if this method is invoked another way in the future.
    if (!_readyToReview) {
      _snack(
        'Complete all required fields, provide the observation location, and confirm consent before submitting.',
      );
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _snack('Please sign in to submit a report.');
      return;
    }
    setState(() => _submitting = true);
    try {
      setState(() => _submitStatus =
          _photo == null ? 'Saving report...' : 'Uploading photo...');
      final imageUrl =
          await _uploadPhoto(user.uid).timeout(const Duration(seconds: 45));
      final point = _observationPoint!;
      final location = '${point.latitude}, ${point.longitude}';
      final report = SABReport(
        lastName: '',
        firstName: '',
        middleInitial: '',
        suffix: '',
        contactNumber: '',
        address: location,
        dateOfObservation: _formatDate(_dateObserved!),
        timeOfObservation: _timeObserved!.format(context),
        location: location,
        animalType: _animalValue(),
        behaviorObserved: _behaviorValue(),
        description: '',
        photoPath: _photo?.path ?? '',
        latitude: point.latitude,
        longitude: point.longitude,
        reportedAt: DateTime.now(),
      );
      await Hive.box<SABReport>('sab_reports').add(report);
      setState(() => _submitStatus = 'Submitting report...');
      final doc = FirebaseFirestore.instance.collection('SAB_reports').doc();
      await doc.set({
        'reportId': doc.id,
        'userId': user.uid,
        'submittedBy': user.uid,
        'reportedByUID': user.uid,
        'province': 'Iloilo',
        'animalType': _animalValue(),
        'numberOfAnimals': int.parse(_animalCountController.text),
        'ownershipStatus': _ownership,
        'observedBehaviors': _behaviors.toList(),
        'behaviorObserved': _behaviorValue(),
        'otherBehavior': _otherBehaviorController.text.trim(),
        'location': location,
        'latitude': point.latitude,
        'longitude': point.longitude,
        'locationSource': _locationMethod,
        'dateOfObservation': _formatDate(_dateObserved!),
        'timeOfObservation': _timeObserved!.format(context),
        'animalStillPresent': _stillPresent,
        'immediateDanger': _immediateDanger,
        'imageURL': imageUrl,
        'imagePath': _photo?.path ?? '',
        'consentGiven': true,
        'reportStatus': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 30));
      if (!mounted) return;
      _snack('SAB report submitted successfully.');
      Navigator.pop(context);
    } on TimeoutException {
      _snack(
          'Submission is taking too long. Please check your connection and try again.');
    } on FirebaseException catch (e) {
      _snack(e.message ?? 'Unable to submit the report.');
    } catch (e) {
      _snack('Unable to submit the report: $e');
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
          _submitStatus = null;
        });
      }
    }
  }

  void _snack(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  Widget _section(String title, List<Widget> children, {String? instruction}) =>
      ReportFormSection(
        title: title,
        icon: _sectionIcon(title),
        description: instruction ?? _sectionDescription(title),
        children: children,
      );

  IconData _sectionIcon(String title) {
    if (title.contains('Animal Information')) return Icons.pets_outlined;
    if (title.contains('Behavior')) return Icons.visibility_outlined;
    if (title.contains('Location')) return Icons.location_on_outlined;
    if (title.contains('Photo')) return Icons.photo_camera_outlined;
    return Icons.description_outlined;
  }

  String? _sectionDescription(String title) {
    if (title.contains('Animal Information')) {
      return 'Share only the details you can reasonably observe.';
    }
    if (title.contains('Location')) {
      return 'Tell us where the animal was observed.';
    }
    if (title.contains('Observation')) {
      return 'Describe when the behavior happened and what you saw.';
    }
    if (title.contains('Photo')) {
      return 'A photo can help, but your safety comes first.';
    }
    return null;
  }

  Widget _choice(
    String label,
    String? value,
    ValueChanged<String?> onChanged,
    List<String> values, {
    String? helper,
  }) =>
      ReportChoiceGroup(
        label: label,
        value: value,
        options: values,
        helper: helper,
        onChanged: onChanged,
      );

  Widget _behaviorTile(String item) => ReportCheckboxTile(
        title: item,
        value: _behaviors.contains(item),
        onChanged: (selected) => setState(() {
          if (item == 'Unsure' && selected == true) {
            _behaviors
              ..clear()
              ..add(item);
          } else {
            _behaviors.remove('Unsure');
            selected == true ? _behaviors.add(item) : _behaviors.remove(item);
          }
        }),
      );

  Widget _photoPreview() {
    if (kIsWeb && _webPhoto != null) {
      return Image.memory(_webPhoto!, height: 180, fit: BoxFit.cover);
    }
    if (!kIsWeb && _devicePhoto != null) {
      return Image.file(_devicePhoto!, height: 180, fit: BoxFit.cover);
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Report Suspicious Animal Behavior')),
        body: SafeArea(
            child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _section('1. Animal Information', [
                          ReportCheckboxTile(
                            value: _consentGiven,
                            onChanged: (value) =>
                                setState(() => _consentGiven = value ?? false),
                            title:
                                'I confirm that this report is based on what I personally observed.',
                            subtitle:
                                'I understand that this is not a diagnosis of rabies.',
                          ),
                          _choice(
                              'Animal type *',
                              _animalType,
                              (v) => setState(() => _animalType = v),
                              const ['Dog', 'Cat', 'Other']),
                          if (_animalType == 'Other') ...[
                            const SizedBox(height: 12),
                            TextFormField(
                                controller: _otherAnimalController,
                                decoration: const InputDecoration(
                                    labelText: 'Specify animal type *'),
                                validator: (_) => _animalType == 'Other'
                                    ? _required(_otherAnimalController.text,
                                        'Animal type')
                                    : null)
                          ],
                          const SizedBox(height: 12),
                          TextFormField(
                              controller: _animalCountController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  labelText: 'Number of animals observed *'),
                              validator: _positiveNumber),
                          const SizedBox(height: 12),
                          _choice(
                              'Ownership status *',
                              _ownership,
                              (v) => setState(() => _ownership = v),
                              const ['Owned', 'Stray']),
                        ]),
                        _section(
                            '2. Observed Suspicious Behavior',
                            [
                              ..._behaviorOptions.map(_behaviorTile),
                              if (_behaviors.contains('Other (Specify)'))
                                TextFormField(
                                    controller: _otherBehaviorController,
                                    maxLines: 2,
                                    decoration: const InputDecoration(
                                        labelText:
                                            'Describe the other behavior *'),
                                    validator: (_) =>
                                        _behaviors.contains('Other (Specify)')
                                            ? _required(
                                                _otherBehaviorController.text,
                                                'Other behavior')
                                            : null),
                              FormField<Set<String>>(
                                  initialValue: _behaviors,
                                  validator: (_) => _behaviors.isEmpty
                                      ? 'Select at least one observed behavior'
                                      : null,
                                  builder: (state) => state.hasError
                                      ? Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8),
                                          child: Text(state.errorText!,
                                              style: const TextStyle(
                                                  color: AppColors.danger)))
                                      : const SizedBox.shrink()),
                            ],
                            instruction:
                                'Select all behaviors you personally observed.'),
                        _section('3. Location of Observation', [
                          const Text('Pin the observation location *',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 5),
                          const Text(
                              'Tap the map to place or adjust the pin. It may be different from your current location.',
                              style: TextStyle(
                                  color: Colors.black54, fontSize: 12)),
                          const SizedBox(height: 10),
                          CRISMap(
                              center: _observationPoint ??
                                  const LatLng(10.7202, 122.5621),
                              zoom: _observationPoint == null ? 10 : 16,
                              onTap: _pinLocation,
                              markers: _observationPoint == null
                                  ? const []
                                  : [
                                      CRISMapMarker(
                                          label: 'Observed animal',
                                          position: _observationPoint!,
                                          color: AppColors.danger)
                                    ]),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                              onPressed:
                                  _gettingLocation ? null : _useCurrentLocation,
                              icon: _gettingLocation
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : const Icon(Icons.my_location_outlined),
                              label: const Text('Use current location')),
                          if (_observationPoint != null)
                            Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                    'Location provided: ${_locationMethod == 'current_location' ? 'Current location' : 'Map pin'} (${_observationPoint!.latitude.toStringAsFixed(5)}, ${_observationPoint!.longitude.toStringAsFixed(5)})',
                                    style: const TextStyle(
                                        color: Colors.black54, fontSize: 12))),
                          if (_observationPoint == null &&
                              _locationError == null)
                            const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                    'Please provide the location where the animal was observed by either placing a pin on the map or using your current location.',
                                    style: TextStyle(
                                        color: AppColors.danger,
                                        fontSize: 12))),
                          if (_locationError != null)
                            Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(_locationError!,
                                    style: const TextStyle(
                                        color: AppColors.danger))),
                        ]),
                        _section('4. Observation Details', [
                          TextFormField(
                              readOnly: true,
                              controller: TextEditingController(
                                  text: _dateObserved == null
                                      ? ''
                                      : _formatDate(_dateObserved!)),
                              onTap: _pickDate,
                              decoration: const InputDecoration(
                                  labelText: 'Date observed *',
                                  suffixIcon:
                                      Icon(Icons.calendar_today_outlined)),
                              validator: (_) => _dateObserved == null
                                  ? 'Date observed is required'
                                  : null),
                          const SizedBox(height: 12),
                          TextFormField(
                              readOnly: true,
                              controller: TextEditingController(
                                  text: _timeObserved?.format(context) ?? ''),
                              onTap: _pickTime,
                              decoration: const InputDecoration(
                                  labelText:
                                      'Approximate time or time period *',
                                  suffixIcon: Icon(Icons.access_time_outlined)),
                              validator: (_) => _timeObserved == null
                                  ? 'Time or time period is required'
                                  : null),
                          const SizedBox(height: 12),
                          _choice(
                              'Is the animal still in the reported location? *',
                              _stillPresent,
                              (v) => setState(() => _stillPresent = v),
                              const ['Yes', 'No', 'Unknown']),
                          const SizedBox(height: 12),
                          _choice(
                              'Is the animal currently posing an immediate danger to people or animals? *',
                              _immediateDanger,
                              (v) => setState(() => _immediateDanger = v),
                              const ['Yes', 'No', 'Unsure']),
                        ]),
                        _section('5. Photo Evidence', [
                          const Text('Supporting Evidence (Optional)',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          const Text(
                              'Do not approach or put yourself in danger to obtain a photo.',
                              style: TextStyle(color: AppColors.danger)),
                          if (_photo != null) ...[
                            const SizedBox(height: 12),
                            ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _photoPreview())
                          ],
                          const SizedBox(height: 12),
                          Row(children: [
                            Expanded(
                                child: OutlinedButton.icon(
                                    onPressed: () =>
                                        _pickPhoto(ImageSource.camera),
                                    icon: const Icon(Icons.camera_alt_outlined),
                                    label: const Text('Take photo'))),
                            const SizedBox(width: 10),
                            Expanded(
                                child: OutlinedButton.icon(
                                    onPressed: () =>
                                        _pickPhoto(ImageSource.gallery),
                                    icon: const Icon(
                                        Icons.photo_library_outlined),
                                    label: const Text('Upload photo')))
                          ]),
                        ]),
                        if (_submitStatus != null)
                          Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(_submitStatus!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: AppColors.primary))),
                        SizedBox(
                            height: 52,
                            child: FilledButton.icon(
                                onPressed: _readyToReview && !_submitting
                                    ? _review
                                    : null,
                                icon: _submitting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2))
                                    : const Icon(Icons.fact_check_outlined),
                                label: Text(_submitting
                                    ? 'Submitting...'
                                    : 'Review report'))),
                        if (!_readyToReview)
                          const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                  'Complete all required fields, provide a location, and confirm consent to review your report.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.black54))),
                        const SizedBox(height: 24),
                      ]),
                ))),
      );
}

class _ReviewSection {
  const _ReviewSection(this.title, this.values);
  final String title;
  final Map<String, String> values;
}

class _ReviewSheet extends StatelessWidget {
  const _ReviewSheet(
      {required this.sections, required this.onEdit, required this.onSubmit});
  final List<_ReviewSection> sections;
  final VoidCallback onEdit;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) => SafeArea(
          child: DraggableScrollableSheet(
        initialChildSize: .88,
        minChildSize: .55,
        maxChildSize: .95,
        builder: (_, controller) => Column(children: [
          const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Review your report',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: sections
                  .map(
                    (section) => ReportReviewCard(
                      title: section.title,
                      values: section.values,
                    ),
                  )
                  .toList(),
            ),
          ),
          Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Expanded(
                    child: OutlinedButton(
                        onPressed: onEdit, child: const Text('Edit'))),
                const SizedBox(width: 12),
                Expanded(
                    child: FilledButton(
                        onPressed: onSubmit,
                        child: const Text('Submit report')))
              ])),
        ]),
      ));
}
