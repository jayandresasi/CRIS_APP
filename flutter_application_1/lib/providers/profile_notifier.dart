import 'package:flutter/material.dart';

/// State management for user profile information
class ProfileNotifier extends ChangeNotifier {
  String _name = 'John Doe';
  String _gender = 'Prefer not to say';
  String _age = '34';
  String _dob = '1991-05-18';
  String _phone = '';
  String _email = '';
  String _address = '123 Main Street';
  String _profileImagePath = '';
  String _emergencyName = 'Jane Doe';
  String _emergencyRelationship = 'Spouse';
  String _emergencyPhone = '09123456789';

  String get name => _name;
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

  void updateProfile({
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
  }) {
    _name = name;
    _gender = gender;
    _age = age;
    _dob = dob;
    _phone = phone;
    _email = email ?? '';
    _address = address;
    _profileImagePath = profileImagePath;
    _emergencyName = emergencyName;
    _emergencyRelationship = emergencyRelationship;
    _emergencyPhone = emergencyPhone;
    notifyListeners();
  }
}
