import 'package:flutter/material.dart';

/// Represents a notification in the app
class Notification {
  final String id;
  final String message;
  final String emoji;
  final Color color;
  bool isRead;

  Notification({
    required this.id,
    required this.message,
    required this.emoji,
    required this.color,
    this.isRead = false,
  });
}
