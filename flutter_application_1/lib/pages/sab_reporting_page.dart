import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exif/exif.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
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
  XFile? _photo;
  double? _latitude;
  double? _longitude;
  String? _photoError;
  bool _isProcessingPhoto = false;
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign in to submit a report.'),
          ),
        );
      }
      return;
    }

    if (_photo == null) {
      setState(() => _photoError = 'Please upload or take a photo.');
      return;
    }
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
        timeOfObservation: _timeOfObservation?.format(context) ??
            TimeOfDay.now().format(context),
        location: _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim()
            : (_latitude != null && _longitude != null
                ? '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}'
                : 'Unknown location'),
        behaviorObserved: _behaviorObserved ?? '',
        description: _descriptionController.text.trim(),
        photoPath: _photo?.path ?? '',
        latitude: _latitude,
        longitude: _longitude,
        reportedAt: now,
      );

      await Hive.box<SABReport>('sab_reports').add(report);

      try {
        final doc = {
          'lastName': _lastNameController.text.trim(),
          'firstName': _firstNameController.text.trim(),
          'middleInitial': _middleInitialController.text.trim(),
          'suffix': _suffixController.text.trim(),
          'contactNumber': _contactNumberController.text.trim(),
          'address': _addressController.text.trim(),
          'dateOfObservation': report.dateOfObservation,
          'timeOfObservation': report.timeOfObservation,
          'location': report.location,
          'behaviorObserved': report.behaviorObserved,
          'description': report.description,
          'photoPath': report.photoPath,
          'latitude': report.latitude,
          'longitude': report.longitude,
          'submittedBy': user.uid,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        };
        await FirebaseFirestore.instance.collection('sab_reports').add(doc);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Saved locally but failed to upload: $e')),
          );
        }
      }

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

  Future<double?> _readGpsCoordinate(
      IfdTag? coordinateTag, IfdTag? refTag) async {
    if (coordinateTag == null || refTag == null) return null;
    final values = coordinateTag.values;
    if (values == null || values.length != 3) return null;

    double toDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    }

    final degrees = toDouble(values[0]);
    final minutes = toDouble(values[1]);
    final seconds = toDouble(values[2]);
    var coordinate = degrees + (minutes / 60) + (seconds / 3600);
    final ref = refTag.printable?.replaceAll(RegExp(r'[^A-Z]'), '');
    if (ref == 'S' || ref == 'W') coordinate = -coordinate;
    return coordinate;
  }

  Future<void> _processPickedPhoto(XFile photo) async {
    setState(() {
      _photo = photo;
      _photoError = null;
      _isProcessingPhoto = true;
      _locationController.text = 'Reading location from photo...';
    });

    try {
      final bytes = await photo.readAsBytes();
      final tags = await readExifFromBytes(bytes) ?? {};
      final lat = await _readGpsCoordinate(
        tags['GPS GPSLatitude'],
        tags['GPS GPSLatitudeRef'],
      );
      final lon = await _readGpsCoordinate(
        tags['GPS GPSLongitude'],
        tags['GPS GPSLongitudeRef'],
      );

      setState(() {
        _latitude = lat;
        _longitude = lon;
        if (lat != null && lon != null) {
          _locationController.text =
              '${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}';
        } else {
          _locationController.text = 'No GPS metadata found in photo.';
        }
      });
    } catch (e) {
      setState(() {
        _locationController.text = 'Unable to read photo location.';
      });
    } finally {
      setState(() => _isProcessingPhoto = false);
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: source,
      maxWidth: 1800,
      maxHeight: 1800,
      imageQuality: 80,
    );
    if (image != null) {
      await _processPickedPhoto(image);
    }
  }

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
              _sectionHeader('Photo Evidence'),
              _card([
                if (_photo != null)
                  Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          File(_photo!.path),
                          fit: BoxFit.cover,
                          height: 220,
                          width: double.infinity,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                if (_isProcessingPhoto) ...[
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ],
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _pickPhoto(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Take Photo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _pickPhoto(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Upload Photo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_photoError != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _photoError!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: _locationController,
                  readOnly: true,
                  style: _fieldStyle,
                  decoration: _dec('Location (from photo)'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Photo location is required'
                      : null,
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
                DropdownButtonFormField<String>(
                  initialValue: _behaviorObserved,
                  style: _fieldStyle,
                  decoration: _dec('Behavior Observed'),
                  items: [
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
