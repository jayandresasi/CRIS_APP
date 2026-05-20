import 'dart:io';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exif/exif.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../models/sab_report.dart';
import '../theme.dart';

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
  final _barangayController = TextEditingController();
  final _municipalityController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _behaviorObserved;
  String? _animalType;
  final _otherAnimalTypeController = TextEditingController();
  DateTime? _dateOfObservation;
  TimeOfDay? _timeOfObservation;
  XFile? _photo;
  File? _pickedImage;
  Uint8List? _webImageBytes;
  double? _latitude;
  double? _longitude;
  String? _photoError;
  String? _submitStatus;
  bool _includeCurrentLocation = false;
  bool _reportingForSelf = false;
  bool _isLoadingProfile = false;
  bool _isGettingLocation = false;
  bool _isProcessingPhoto = false;
  bool _isSubmitting = false;

  bool get _reporterFieldsReadOnly => _reportingForSelf || _isLoadingProfile;

  @override
  void dispose() {
    _lastNameController.dispose();
    _firstNameController.dispose();
    _middleInitialController.dispose();
    _suffixController.dispose();
    _contactNumberController.dispose();
    _addressController.dispose();
    _barangayController.dispose();
    _municipalityController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _otherAnimalTypeController.dispose();
    super.dispose();
  }

  Future<void> _setReportingForSelf(bool value) async {
    if (value == _reportingForSelf) return;
    setState(() => _reportingForSelf = value);
    if (value) {
      await _loadCurrentUserProfile();
    } else {
      setState(() {
        _lastNameController.clear();
        _firstNameController.clear();
        _middleInitialController.clear();
        _suffixController.clear();
        _contactNumberController.clear();
        _addressController.clear();
        _barangayController.clear();
        _municipalityController.clear();
      });
    }
  }

  Future<void> _loadCurrentUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _reportingForSelf = false);
      _showSnackBar('Please sign in to use your profile.');
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

      final name = _splitFullName((data['fullName'] ?? '') as String);
      setState(() {
        _firstNameController.text = name.firstName;
        _lastNameController.text = name.lastName;
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfObservation ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() => _dateOfObservation = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _timeOfObservation ?? TimeOfDay.now(),
    );
    if (picked == null) return;
    setState(() => _timeOfObservation = picked);
  }

  Future<void> _setIncludeCurrentLocation(bool value) async {
    setState(() => _includeCurrentLocation = value);
    if (value) {
      await _captureCurrentLocation();
    } else {
      setState(() {
        _latitude = null;
        _longitude = null;
        _locationController.clear();
      });
      if (_photo != null) {
        await _tryUsePhotoGeotag(_photo!);
      }
    }
  }

  Future<void> _captureCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
      _photoError = null;
      _locationController.text = 'Getting current location...';
    });

    try {
      final position = await _getCurrentPosition();
      if (position == null) {
        setState(() {
          _includeCurrentLocation = false;
          _latitude = null;
          _longitude = null;
          _locationController.text = 'Unable to get current location.';
          _photoError =
              'Current location is unavailable. Please allow location permission.';
        });
        return;
      }

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationController.text =
            '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
      });
    } catch (e) {
      setState(() {
        _includeCurrentLocation = false;
        _latitude = null;
        _longitude = null;
        _locationController.text = 'Unable to get current location.';
        _photoError = 'Unable to get current location: $e';
      });
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  Future<Position?> _getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    setState(() {
      _photoError = null;
      _isProcessingPhoto = true;
      _locationController.text = 'Opening camera...';
    });

    try {
      final photo = await picker.pickImage(
        source: ImageSource.camera,
      );
      if (photo == null) {
        setState(() {
          _locationController.clear();
          _isProcessingPhoto = false;
        });
        return;
      }

      await _processPickedImage(photo);
    } catch (e) {
      setState(() {
        _photoError = 'Unable to take photo: $e';
        _locationController.text = 'Unable to read photo geotag.';
      });
    } finally {
      if (mounted) setState(() => _isProcessingPhoto = false);
    }
  }

  Future<void> _pickGalleryPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
    );
    if (image == null) return;

    setState(() {
      _photoError = null;
      _isProcessingPhoto = true;
      _locationController.text = 'Reading GPS geotag from photo...';
    });

    try {
      await _processPickedImage(image);
    } catch (e) {
      setState(() {
        _photoError = 'Unable to read photo geotag: $e';
        _locationController.text = 'Unable to read photo geotag.';
      });
    } finally {
      if (mounted) setState(() => _isProcessingPhoto = false);
    }
  }

  Future<void> _processPickedImage(XFile image) async {
    final bytes = await image.readAsBytes();
    final coordinates =
        _includeCurrentLocation ? null : await _readGpsFromImageBytes(bytes);
    setState(() {
      _photo = image;
      _webImageBytes = kIsWeb ? bytes : null;
      _pickedImage = kIsWeb ? null : File(image.path);
      if (!_includeCurrentLocation) {
        _latitude = coordinates?.latitude;
        _longitude = coordinates?.longitude;
        _locationController.text = coordinates == null
            ? 'No GPS geotag found in this photo.'
            : '${coordinates.latitude.toStringAsFixed(6)}, ${coordinates.longitude.toStringAsFixed(6)}';
        _photoError = coordinates == null
            ? 'This photo has no GPS geotag. You can turn on "Include current location?" to use GPS instead.'
            : null;
      }
    });
  }

  Future<void> _tryUsePhotoGeotag(XFile image) async {
    final bytes = _webImageBytes ?? await image.readAsBytes();
    final coordinates = await _readGpsFromImageBytes(bytes);
    setState(() {
      _latitude = coordinates?.latitude;
      _longitude = coordinates?.longitude;
      _locationController.text = coordinates == null
          ? 'No GPS geotag found in this photo.'
          : '${coordinates.latitude.toStringAsFixed(6)}, ${coordinates.longitude.toStringAsFixed(6)}';
      _photoError = coordinates == null
          ? 'This photo has no GPS geotag. You can turn on "Include current location?" to use GPS instead.'
          : null;
    });
  }

  Future<_GpsCoordinates?> _readGpsFromImageBytes(Uint8List bytes) async {
    final tags = await readExifFromBytes(bytes);
    if (tags == null) return null;
    final latitude = _readGpsCoordinate(
      tags['GPS GPSLatitude'],
      tags['GPS GPSLatitudeRef'],
    );
    final longitude = _readGpsCoordinate(
      tags['GPS GPSLongitude'],
      tags['GPS GPSLongitudeRef'],
    );
    if (latitude == null || longitude == null) return null;
    return _GpsCoordinates(latitude: latitude, longitude: longitude);
  }

  double? _readGpsCoordinate(IfdTag? coordinateTag, IfdTag? refTag) {
    if (coordinateTag == null || refTag == null) return null;
    final values = coordinateTag.values;
    if (values == null || values.length < 3) return null;

    final degrees = _exifNumberToDouble(values[0]);
    final minutes = _exifNumberToDouble(values[1]);
    final seconds = _exifNumberToDouble(values[2]);
    if (degrees == null || minutes == null || seconds == null) return null;

    var coordinate = degrees + (minutes / 60) + (seconds / 3600);
    final ref = (refTag.printable ?? '').replaceAll(RegExp(r'[^A-Za-z]'), '');
    if (ref == 'S' || ref == 'W') coordinate = -coordinate;
    return coordinate;
  }

  double? _exifNumberToDouble(Object value) {
    if (value is Ratio) {
      return value.numerator / value.denominator;
    }
    if (value is num) return value.toDouble();
    final text = value.toString();
    if (text.contains('/')) {
      final parts = text.split('/');
      if (parts.length == 2) {
        final numerator = double.tryParse(parts[0].trim());
        final denominator = double.tryParse(parts[1].trim());
        if (numerator != null && denominator != null && denominator != 0) {
          return numerator / denominator;
        }
      }
    }
    return double.tryParse(text);
  }

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar('Please sign in to submit a report.');
      return;
    }

    if (_photo == null) {
      setState(() => _photoError = 'Please take or upload a photo.');
      return;
    }
    if (_latitude == null || _longitude == null) {
      setState(() => _photoError =
          'Location is required. Turn on "Include current location?" or use a geotagged photo.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final dateStr = _dateOfObservation == null
        ? _formatDate(DateTime.now())
        : _formatDate(_dateOfObservation!);
    final timeStr =
        _timeOfObservation?.format(context) ?? TimeOfDay.now().format(context);

    setState(() => _isSubmitting = true);
    try {
      setState(() => _submitStatus = 'Uploading photo...');
      final imageUrl = await _uploadPhotoToStorage(_photo!, user.uid)
          .timeout(const Duration(seconds: 45));
      final now = DateTime.now();
      final locationText = _locationController.text.trim();

      final report = SABReport(
        lastName: _lastNameController.text.trim(),
        firstName: _firstNameController.text.trim(),
        middleInitial: _middleInitialController.text.trim(),
        suffix: _suffixController.text.trim(),
        contactNumber: _contactNumberController.text.trim(),
        address: _addressController.text.trim(),
        dateOfObservation: dateStr,
        timeOfObservation: timeStr,
        location: locationText,
        animalType: _resolvedAnimalType(),
        behaviorObserved: _behaviorObserved ?? '',
        description: _descriptionController.text.trim(),
        photoPath: _photo?.path ?? '',
        latitude: _latitude,
        longitude: _longitude,
        reportedAt: now,
      );
      setState(() => _submitStatus = 'Saving local copy...');
      await Hive.box<SABReport>('sab_reports').add(report);

      setState(() => _submitStatus = 'Saving report...');
      final collection = FirebaseFirestore.instance.collection('SAB_reports');
      final docRef = collection.doc();
      await docRef.set({
        'reportId': docRef.id,
        'userId': user.uid,
        'province': 'Iloilo',
        'reportingForSelf': _reportingForSelf,
        'submittedBy': user.uid,
        'reportedByUID': user.uid,
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'middleInitial': _middleInitialController.text.trim(),
        'suffix': _suffixController.text.trim(),
        'fullName': _fullName(),
        'contactNumber': _contactNumberController.text.trim(),
        'address': _addressController.text.trim(),
        'barangay': _barangayController.text.trim(),
        'municipality': _municipalityController.text.trim(),
        'location': locationText,
        'dateOfObservation': dateStr,
        'timeOfObservation': timeStr,
        'animalType': _resolvedAnimalType(),
        'behaviorObserved': _behaviorObserved,
        'description': _descriptionController.text.trim(),
        'imageURL': imageUrl,
        'imagePath': _photo?.path ?? '',
        'latitude': _latitude,
        'longitude': _longitude,
        'locationSource':
            _includeCurrentLocation ? 'current_location' : 'photo_geotag',
        'reportStatus': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 30));

      if (!mounted) return;
      _showSnackBar('SAB report submitted successfully.');
      Navigator.pop(context);
    } on FirebaseException catch (e) {
      _showSnackBar(e.message ?? 'Unable to upload SAB report.');
    } on TimeoutException {
      _showSnackBar(
        'Submission is taking too long. Please check your internet connection and try again.',
      );
    } catch (e) {
      _showSnackBar('Unable to submit SAB report: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _submitStatus = null;
        });
      }
    }
  }

  Future<String> _uploadPhotoToStorage(XFile photo, String uid) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('sab_images')
        .child(uid)
        .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
    final UploadTask uploadTask;
    if (kIsWeb) {
      final bytes = _webImageBytes ?? await photo.readAsBytes();
      uploadTask = ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
    } else {
      uploadTask = ref.putFile(_pickedImage ?? File(photo.path));
    }
    final snapshot = await uploadTask;
    if (snapshot.state != TaskState.success) {
      throw Exception('Image upload failed');
    }
    return ref.getDownloadURL();
  }

  Widget _photoPreview() {
    if (kIsWeb && _webImageBytes != null) {
      return Image.memory(
        _webImageBytes!,
        fit: BoxFit.cover,
        height: 220,
        width: double.infinity,
      );
    }
    if (!kIsWeb && _pickedImage != null) {
      return Image.file(
        _pickedImage!,
        fit: BoxFit.cover,
        height: 220,
        width: double.infinity,
      );
    }
    return Container(
      height: 160,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8ECF0)),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image_outlined, size: 40, color: Colors.black38),
          SizedBox(height: 8),
          Text(
            'No image selected',
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _fullName() {
    return [
      _firstNameController.text.trim(),
      _lastNameController.text.trim(),
    ].where((part) => part.isNotEmpty).join(' ');
  }

  String _resolvedAnimalType() {
    if (_animalType == 'Other') return _otherAnimalTypeController.text.trim();
    return _animalType ?? '';
  }

  _NameParts _splitFullName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length <= 1) {
      return _NameParts(firstName: fullName.trim(), lastName: '');
    }
    return _NameParts(
      firstName: parts.first,
      lastName: parts.sublist(1).join(' '),
    );
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

  Widget _municipalityField() {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: _municipalityController.text),
      optionsBuilder: (value) {
        final query = value.text.trim().toLowerCase();
        if (query.isEmpty) return iloiloMunicipalities;
        return iloiloMunicipalities.where(
          (municipality) => municipality.toLowerCase().contains(query),
        );
      },
      onSelected: (value) => _municipalityController.text = value,
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        controller.text = _municipalityController.text;
        controller.selection = TextSelection.collapsed(
          offset: controller.text.length,
        );
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          enabled: !_reporterFieldsReadOnly,
          decoration: const InputDecoration(
            labelText: 'Municipality',
            suffixIcon: Icon(Icons.search),
          ),
          textCapitalization: TextCapitalization.words,
          onChanged: (value) => _municipalityController.text = value,
          validator: (value) => _required(value, 'Municipality'),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = _dateOfObservation == null
        ? ''
        : _formatDate(_dateOfObservation!);
    final timeLabel = _timeOfObservation?.format(context) ?? '';

    return Scaffold(
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
                _sectionHeader('Reporter Information'),
                _card([
                  SwitchListTile(
                    value: _reportingForSelf,
                    onChanged: _isLoadingProfile ? null : _setReportingForSelf,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Reporting for self?'),
                    subtitle: const Text('Use saved profile details'),
                    secondary: _isLoadingProfile
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.person_outline),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _firstNameController,
                          readOnly: _reporterFieldsReadOnly,
                          decoration:
                              const InputDecoration(labelText: 'First Name'),
                          textCapitalization: TextCapitalization.words,
                          validator: (value) =>
                              _required(value, 'First name'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _lastNameController,
                          readOnly: _reporterFieldsReadOnly,
                          decoration:
                              const InputDecoration(labelText: 'Last Name'),
                          textCapitalization: TextCapitalization.words,
                          validator: (value) => _required(value, 'Last name'),
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
                          readOnly: _reporterFieldsReadOnly,
                          decoration: const InputDecoration(
                            labelText: 'Middle Initial',
                          ),
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _suffixController,
                          readOnly: _reporterFieldsReadOnly,
                          decoration: const InputDecoration(labelText: 'Suffix'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _contactNumberController,
                    readOnly: _reporterFieldsReadOnly,
                    decoration:
                        const InputDecoration(labelText: 'Contact Number'),
                    keyboardType: TextInputType.phone,
                    validator: (value) =>
                        _required(value, 'Contact number'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressController,
                    readOnly: _reporterFieldsReadOnly,
                    decoration: const InputDecoration(labelText: 'Address'),
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    validator: (value) => _required(value, 'Address'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _barangayController,
                    readOnly: _reporterFieldsReadOnly,
                    decoration: const InputDecoration(labelText: 'Barangay'),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) => _required(value, 'Barangay'),
                  ),
                  const SizedBox(height: 12),
                  _municipalityField(),
                ]),
                _sectionHeader('Photo Evidence'),
                _card([
                  SwitchListTile(
                    value: _includeCurrentLocation,
                    onChanged: _isGettingLocation
                        ? null
                        : _setIncludeCurrentLocation,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Include current location?'),
                    subtitle: const Text(
                      'Use device GPS for this report location',
                    ),
                    secondary: _isGettingLocation
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location_outlined),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: _photoPreview(),
                  ),
                  const SizedBox(height: 12),
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
                        child: FilledButton.icon(
                          onPressed: _isProcessingPhoto ? null : _takePhoto,
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text('Take Photo'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed:
                              _isProcessingPhoto ? null : _pickGalleryPhoto,
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Upload Photo'),
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
                    decoration: const InputDecoration(
                      labelText: 'GPS Coordinates',
                    ),
                    validator: (value) =>
                        _required(value, 'GPS coordinates'),
                  ),
                ]),
                _sectionHeader('Incident Details'),
                _card([
                  TextFormField(
                    readOnly: true,
                    controller: TextEditingController(text: dateLabel),
                    decoration: const InputDecoration(
                      labelText: 'Date of Observation',
                      suffixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    onTap: _pickDate,
                    validator: (_) => _dateOfObservation == null
                        ? 'Date of observation is required'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    readOnly: true,
                    controller: TextEditingController(text: timeLabel),
                    decoration: const InputDecoration(
                      labelText: 'Time of Observation',
                      suffixIcon: Icon(Icons.access_time_outlined),
                    ),
                    onTap: _pickTime,
                    validator: (_) => _timeOfObservation == null
                        ? 'Time of observation is required'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _animalType,
                    decoration: const InputDecoration(
                      labelText: 'Type of Animal',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Canine', child: Text('Canine')),
                      DropdownMenuItem(value: 'Feline', child: Text('Feline')),
                      DropdownMenuItem(value: 'Other', child: Text('Other')),
                    ],
                    onChanged: (value) => setState(() => _animalType = value),
                    validator: (value) =>
                        value == null ? 'Type of animal is required' : null,
                  ),
                  if (_animalType == 'Other') ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _otherAnimalTypeController,
                      decoration: const InputDecoration(
                        labelText: 'Specify Animal Type',
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) => _animalType == 'Other'
                          ? _required(value, 'Animal type')
                          : null,
                    ),
                  ],
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _behaviorObserved,
                    decoration:
                        const InputDecoration(labelText: 'Behavior Observed'),
                    items: const [
                      DropdownMenuItem(
                        value: 'Aggression',
                        child: Text('Aggression'),
                      ),
                      DropdownMenuItem(
                        value: 'Excessive drooling',
                        child: Text('Excessive drooling'),
                      ),
                      DropdownMenuItem(
                        value: 'Staggering / Disoriented',
                        child: Text('Staggering / Disoriented'),
                      ),
                      DropdownMenuItem(
                        value: 'Unprovoked biting',
                        child: Text('Unprovoked biting'),
                      ),
                      DropdownMenuItem(
                        value: 'Hiding / Fearfulness',
                        child: Text('Hiding / Fearfulness'),
                      ),
                      DropdownMenuItem(value: 'Other', child: Text('Other')),
                    ],
                    onChanged: (value) =>
                        setState(() => _behaviorObserved = value),
                    validator: (value) =>
                        value == null ? 'Behavior observed is required' : null,
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
                ]),
                const SizedBox(height: 24),
                if (_submitStatus != null) ...[
                  Text(
                    _submitStatus!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
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

class _GpsCoordinates {
  const _GpsCoordinates({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}
