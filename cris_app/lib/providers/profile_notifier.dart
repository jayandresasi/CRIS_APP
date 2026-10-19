import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// State management for user profile — persisted in Hive 'settings' box.
/// Call ProfileNotifier.load() before using the notifier.
class ProfileNotifier extends ChangeNotifier {
  static const _boxName = 'settings';

  String _name = '';
  String _gender = '';
  String _age = '';
  String _dob = '';
  String _phone = '';
  String _email = '';
  String _address = '';
  String _profileImagePath = '';
  String _emergencyName = '';
  String _emergencyRelationship = '';
  String _emergencyPhone = '';

  String get name => _name.isNotEmpty ? _name : 'User';
  String get gender => _gender;
  String get age => _age;
  String get dob => _dob;
  String get phone => _phone;
  String get email => _email;
  String get address => _address;
  String get profileImagePath => _profileImagePath;
  String get emergencyName => _emergencyName;
  String get emergencyRelationship => _emergencyRelationship;
  String get emergencyPhone => _emergencyPhone;

  /// Loads saved profile from disk. Call once at startup after opening the box.
  void load() {
    final box = Hive.box(_boxName);
    _name = box.get('name', defaultValue: '') as String;
    _gender = box.get('gender', defaultValue: '') as String;
    _age = box.get('age', defaultValue: '') as String;
    _dob = box.get('dob', defaultValue: '') as String;
    _phone = box.get('phone', defaultValue: '') as String;
    _email = box.get('email', defaultValue: '') as String;
    _address = box.get('address', defaultValue: '') as String;
    _profileImagePath = box.get('profileImagePath', defaultValue: '') as String;
    _emergencyName = box.get('emergencyName', defaultValue: '') as String;
    _emergencyRelationship =
        box.get('emergencyRelationship', defaultValue: '') as String;
    _emergencyPhone = box.get('emergencyPhone', defaultValue: '') as String;
    notifyListeners();
  }

  /// Called right after login so the profile email matches the login credential.
  Future<void> setEmail(String email) async {
    _email = email;
    await Hive.box(_boxName).put('email', email);
    notifyListeners();
  }

  Future<void> updateProfile({
    required String name,
    required String gender,
    required String age,
    required String dob,
    required String phone,
    String? email,
    required String address,
    required String profileImagePath,
    required String emergencyName,
    required String emergencyRelationship,
    required String emergencyPhone,
  }) async {
    _name = name;
    _gender = gender;
    _age = age;
    _dob = dob;
    _phone = phone;
    _email = email ?? _email;
    _address = address;
    _profileImagePath = profileImagePath;
    _emergencyName = emergencyName;
    _emergencyRelationship = emergencyRelationship;
    _emergencyPhone = emergencyPhone;

    final box = Hive.box(_boxName);
    await box.putAll({
      'name': _name,
      'gender': _gender,
      'age': _age,
      'dob': _dob,
      'phone': _phone,
      'email': _email,
      'address': _address,
      'profileImagePath': _profileImagePath,
      'emergencyName': _emergencyName,
      'emergencyRelationship': _emergencyRelationship,
      'emergencyPhone': _emergencyPhone,
    });

    notifyListeners();
  }
}
