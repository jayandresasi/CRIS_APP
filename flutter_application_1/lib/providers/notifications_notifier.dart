import 'package:flutter/material.dart';
import '../models/notification.dart';

/// State management for application notifications
class NotificationsNotifier extends ChangeNotifier {
  final List<AppNotification> _notifications = [
    AppNotification(
      id: '1',
      message: '⚠️ Confirmed rabies case detected 4 km from your address.',
      emoji: '⚠️',
      color: const Color(0xFFFF4C4C),
      isRead: false,
    ),
    AppNotification(
      id: '2',
      message: '💉 Your 3rd vaccine dose is due tomorrow.',
      emoji: '💉',
      color: const Color(0xFF5BC0EB),
      isRead: false,
    ),
  ];

  List<AppNotification> get notifications => _notifications;

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isRead = true;
      notifyListeners();
    }
  }

  void addNotification(AppNotification notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }
}
