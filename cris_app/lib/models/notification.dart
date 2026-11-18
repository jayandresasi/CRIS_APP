import 'package:material_ui/material_ui.dart';

/// Represents a notification in the app.
/// Named AppNotification to avoid shadowing Flutter's built-in Notification class.
class AppNotification {
  final String id;
  final String message;
  final String emoji;
  final Color color;
  final String? dateText;
  final bool isVaccineReminder;
  bool isRead;

  AppNotification({
    required this.id,
    required this.message,
    required this.emoji,
    required this.color,
    this.dateText,
    this.isVaccineReminder = false,
    this.isRead = false,
  });
}
