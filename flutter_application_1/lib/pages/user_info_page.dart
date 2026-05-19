import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/profile_notifier.dart';
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

class UserInfoPage extends StatefulWidget {
  const UserInfoPage({super.key});

  @override
  State<UserInfoPage> createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();
  final _barangayController = TextEditingController();
  final _municipalityController = TextEditingController();
  final _contactNumberController = TextEditingController();

  String? _sex;
  DateTime? _dob;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _barangayController.dispose();
    _municipalityController.dispose();
    _contactNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      _showSnackBar('Please sign in before setting up your profile.');
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('user-info')
          .doc(user.uid)
          .get();
      final data = snapshot.data();
      if (data == null) return;

      final dobString = (data['dob'] ?? data['birthDate'] ?? '') as String;
      setState(() {
        _fullNameController.text = (data['fullName'] ?? '') as String;
        _dobController.text = dobString;
        _dob = DateTime.tryParse(dobString);
        _addressController.text = (data['address'] ?? '') as String;
        _barangayController.text =
            (data['barangay'] ?? data['brgy'] ?? '') as String;
        _municipalityController.text = (data['municipality'] ?? '') as String;
        _contactNumberController.text =
            (data['contactNumber'] ?? '') as String;
        final savedSex = (data['sex'] ?? '') as String;
        _sex = ['Male', 'Female'].contains(savedSex) ? savedSex : null;
      });
    } on FirebaseException catch (e) {
      _showSnackBar(e.message ?? 'Unable to load your profile.');
    } catch (e) {
      _showSnackBar('Unable to load your profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked == null) return;

    setState(() {
      _dob = picked;
      _dobController.text = _formatDate(picked);
    });
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar('Please sign in before saving your profile.');
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final profileData = <String, dynamic>{
        'uid': user.uid,
        'fullName': _fullNameController.text.trim(),
        'dob': _dobController.text.trim(),
        'address': _addressController.text.trim(),
        'barangay': _barangayController.text.trim(),
        'brgy': _barangayController.text.trim(),
        'municipality': _municipalityController.text.trim(),
        'contactNumber': _contactNumberController.text.trim(),
        'sex': _sex,
        'email': user.email ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final ref =
          FirebaseFirestore.instance.collection('user-info').doc(user.uid);
      final snapshot = await ref.get();
      await ref.set({
        ...profileData,
        if (!snapshot.exists) 'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      await context.read<ProfileNotifier>().updateProfile(
            name: _fullNameController.text.trim(),
            gender: _sex ?? '',
            age: _calculateAge(_dobController.text.trim()).toString(),
            dob: _dobController.text.trim(),
            phone: _contactNumberController.text.trim(),
            email: user.email,
            address: _addressController.text.trim(),
            profileImagePath: '',
            emergencyName: '',
            emergencyRelationship: '',
            emergencyPhone: '',
          );

      _showSnackBar('Profile saved successfully.');
    } on FirebaseException catch (e) {
      _showSnackBar(e.message ?? 'Unable to save your profile.');
    } catch (e) {
      _showSnackBar('Unable to save your profile: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  int _calculateAge(String dobString) {
    final dob = DateTime.tryParse(dobString);
    if (dob == null) return 0;
    final now = DateTime.now();
    var age = now.year - dob.year;
    final hasHadBirthday =
        now.month > dob.month || (now.month == dob.month && now.day >= dob.day);
    if (!hasHadBirthday) age--;
    return age;
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    return null;
  }

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
    return Scaffold(
      appBar: AppBar(title: const Text('User Information')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Profile Setup',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _fullNameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (value) => _required(value, 'Full name'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _dobController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Date of Birth',
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                        onTap: _pickDob,
                        validator: (value) {
                          final message = _required(value, 'Date of birth');
                          if (message != null) return message;
                          return DateTime.tryParse(value!.trim()) == null
                              ? 'Use YYYY-MM-DD format'
                              : null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          prefixIcon: Icon(Icons.home_outlined),
                        ),
                        maxLines: 2,
                        textCapitalization: TextCapitalization.sentences,
                        validator: (value) => _required(value, 'Address'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _barangayController,
                        decoration: const InputDecoration(
                          labelText: 'Barangay / Brgy',
                          prefixIcon: Icon(Icons.location_city_outlined),
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (value) => _required(value, 'Barangay'),
                      ),
                      const SizedBox(height: 12),
                      _municipalityField(),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _contactNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Contact Number',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) =>
                            _required(value, 'Contact number'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _sex,
                        decoration: const InputDecoration(
                          labelText: 'Sex',
                          prefixIcon: Icon(Icons.wc_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Male', child: Text('Male')),
                          DropdownMenuItem(
                            value: 'Female',
                            child: Text('Female'),
                          ),
                        ],
                        onChanged: (value) => setState(() => _sex = value),
                        validator: (value) =>
                            value == null ? 'Sex is required' : null,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: _isSaving ? null : _saveProfile,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(_isSaving ? 'Saving...' : 'Save Profile'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      backgroundColor: AppColors.background,
    );
  }
}
