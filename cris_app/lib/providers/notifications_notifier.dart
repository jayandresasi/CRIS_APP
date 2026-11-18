import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:material_ui/material_ui.dart';
import '../models/notification.dart';
import '../theme.dart';

/// State management for application notifications
class NotificationsNotifier extends ChangeNotifier with WidgetsBindingObserver {
  final List<AppNotification> _notifications = [];
  List<AppNotification> _vaccineReminders = const [];
  Set<String> _readVaccineReminderIds = <String>{};
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _patientsSubscription;
  Timer? _midnightTimer;
  String? _userId;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _patients = const [];

  NotificationsNotifier() {
    _loadReadVaccineReminderIds();
    WidgetsBinding.instance.addObserver(this);
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(_listenForPatientSchedules);
    _scheduleMidnightRefresh();
  }

  List<AppNotification> get notifications =>
      List.unmodifiable([..._vaccineReminders, ..._notifications]);

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isRead = true;
      notifyListeners();
      return;
    }
    final reminder = _vaccineReminders.where((n) => n.id == id).firstOrNull;
    if (reminder != null && !reminder.isRead) {
      reminder.isRead = true;
      _readVaccineReminderIds.add(id);
      _saveReadVaccineReminderIds();
      notifyListeners();
    }
  }

  void addNotification(AppNotification notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }

  void markVaccineRemindersAsRead() {
    final unread = _vaccineReminders.where((reminder) => !reminder.isRead).toList();
    if (unread.isEmpty) return;
    for (final reminder in unread) {
      reminder.isRead = true;
      _readVaccineReminderIds.add(reminder.id);
    }
    _saveReadVaccineReminderIds();
    notifyListeners();
  }

  void _loadReadVaccineReminderIds() {
    if (!Hive.isBoxOpen('settings')) return;
    final stored = Hive.box('settings').get('readVaccineReminderIds');
    if (stored is List) {
      _readVaccineReminderIds = stored.whereType<String>().toSet();
    }
  }

  void _saveReadVaccineReminderIds() {
    if (Hive.isBoxOpen('settings')) {
      Hive.box('settings').put('readVaccineReminderIds', _readVaccineReminderIds.toList());
    }
  }

  void _listenForPatientSchedules(User? user) {
    _patientsSubscription?.cancel();
    _patients = const [];
    _userId = user?.uid;
    if (user == null) {
      _vaccineReminders = const [];
      notifyListeners();
      return;
    }
    final userId = user.uid;
    _patientsSubscription = FirebaseFirestore.instance
        .collection('patients')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      if (FirebaseAuth.instance.currentUser?.uid != userId) return;
      _patients = snapshot.docs;
      _recalculateVaccineReminders();
    }, onError: (_) {
      _patients = const [];
      _recalculateVaccineReminders();
    });
  }

  void _recalculateVaccineReminders() {
    final userId = _userId;
    if (userId == null) return;
    final today = _dateOnly(DateTime.now());
    final schedules = _patients
        .expand((patient) => _scheduledDoses(patient.data(), patient.id))
        .where((dose) => !dose.isCompleted)
        .toList()
      ..sort((first, second) => first.date.compareTo(second.date));
    final showPatientNames = schedules.map((dose) => dose.patientName).toSet().length > 1;
    final reminders = schedules.map((dose) {
      final daysUntil = _dateOnly(dose.date).difference(today).inDays;
      if (daysUntil < 0 || daysUntil > 2) return null;
      final dateText = _formatDate(dose.date);
      final patientPrefix = showPatientNames ? '${dose.patientName}: ' : '';
      final timing = switch (daysUntil) {
        0 => 'Today is your Day ${dose.doseNumber} vaccine',
        1 => 'Your Day ${dose.doseNumber} vaccine is tomorrow',
        _ => 'Your Day ${dose.doseNumber} vaccine is in 2 days',
      };
      final id = 'vaccine:$userId:${dose.documentId}:day${dose.doseNumber}:${_dateKey(dose.date)}';
      return AppNotification(
        id: id,
        message: '$patientPrefix$timing ($dateText).',
        emoji: '\u{1F489}',
        color: AppColors.accent,
        dateText: dateText,
        isVaccineReminder: true,
        isRead: _readVaccineReminderIds.contains(id),
      );
    }).whereType<AppNotification>().toList();
    _vaccineReminders = reminders;
    notifyListeners();
  }

  void _scheduleMidnightRefresh() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    _midnightTimer = Timer(nextMidnight.difference(now) + const Duration(seconds: 1), () {
      _recalculateVaccineReminders();
      _scheduleMidnightRefresh();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _recalculateVaccineReminders();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    _patientsSubscription?.cancel();
    _midnightTimer?.cancel();
    super.dispose();
  }
}

class _ScheduledDose {
  const _ScheduledDose({
    required this.documentId,
    required this.doseNumber,
    required this.date,
    required this.patientName,
    required this.isCompleted,
  });

  final String documentId;
  final int doseNumber;
  final DateTime date;
  final String patientName;
  final bool isCompleted;
}

List<_ScheduledDose> _scheduledDoses(Map<String, dynamic> patient, String documentId) {
  final rawSchedule = patient['pepScheduleDates'];
  if (rawSchedule is! Map) return const [];
  final dates = <int, DateTime>{};
  for (final entry in rawSchedule.entries) {
    final doseNumber = _doseNumber(entry.key);
    final date = _scheduleDate(entry.value);
    if (doseNumber != null && date != null) dates[doseNumber] = date;
  }
  if (dates.isEmpty) return const [];
  final completed = <int>{};
  final rawCompleted = patient['completedDoses'];
  if (rawCompleted is List) {
    for (final value in rawCompleted) {
      final doseNumber = _doseNumber(value);
      if (doseNumber != null && dates.containsKey(doseNumber)) completed.add(doseNumber);
    }
  }
  final rawPatient = patient['patient'];
  final patientMap = rawPatient is Map ? Map<String, dynamic>.from(rawPatient) : const <String, dynamic>{};
  final patientName = (patientMap['fullName'] ?? patient['fullName'] ?? patient['name'] ?? documentId).toString();
  return dates.entries.map((entry) => _ScheduledDose(
    documentId: documentId,
    doseNumber: entry.key,
    date: entry.value,
    patientName: patientName,
    isCompleted: completed.contains(entry.key),
  )).toList();
}

int? _doseNumber(Object? value) {
  if (value is! String) return null;
  final normalized = value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  final match = RegExp(r'^day(\d+)$').firstMatch(normalized);
  return match == null ? null : int.tryParse(match.group(1)!);
}

DateTime? _scheduleDate(Object? value) {
  if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return null;
  final parts = value.split('-').map(int.tryParse).toList();
  if (parts.any((part) => part == null)) return null;
  final date = DateTime(parts[0]!, parts[1]!, parts[2]!);
  return date.year == parts[0] && date.month == parts[1] && date.day == parts[2] ? date : null;
}

DateTime _dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

String _dateKey(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

String _formatDate(DateTime value) =>
    '${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][value.month - 1]} ${value.day}, ${value.year}';
