import 'package:material_ui/material_ui.dart';
import '../models/notification.dart';

/// State management for application notifications
class NotificationsNotifier extends ChangeNotifier {
  final List<AppNotification> _notifications = [];

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
