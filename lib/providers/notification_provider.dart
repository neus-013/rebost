import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../models/pantry_item.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();

  List<AppNotification> _notifications = [];
  int _unreadCount = 0;

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  Future<void> loadNotifications(String userId) async {
    _notifications = await _service.getNotifications(userId);
    _unreadCount = _notifications.where((n) => !n.isRead).length;
    notifyListeners();
  }

  Future<void> markAsRead(String userId, String notificationId) async {
    await _service.markAsRead(userId, notificationId);
    await loadNotifications(userId);
  }

  Future<void> markAllAsRead(String userId) async {
    for (final n in _notifications.where((n) => !n.isRead)) {
      await _service.markAsRead(userId, n.id);
    }
    await loadNotifications(userId);
  }

  /// Comprova les dates de caducitat i crea notificacions si cal
  Future<void> checkExpiryNotifications(
    String userId,
    List<PantryItem> items,
  ) async {
    final count = await _service.checkExpiryNotifications(userId, items);
    if (count > 0) {
      await loadNotifications(userId);
    }
  }
}
