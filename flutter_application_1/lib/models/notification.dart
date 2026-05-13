import 'package:flutter/material.dart';

/// Represents a notification in the app.
/// Named AppNotification to avoid shadowing Flutter's built-in Notification class.
class AppNotification {
  final String id;
  final String message;
  final String emoji;
  final Color color;
  bool isRead;

  AppNotification({
    required this.id,
    required this.message,
    required this.emoji,
    required this.color,
    this.isRead = false,
  });
}
