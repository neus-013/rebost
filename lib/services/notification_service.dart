import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/notification_model.dart';

class NotificationService {
  final Uuid _uuid = const Uuid();

  String _notificationsKey(String userId) => 'user_${userId}_notifications';

  Future<List<AppNotification>> getNotifications(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final notifJson = prefs.getStringList(_notificationsKey(userId)) ?? [];
    final notifications = notifJson
        .map(
          (json) => AppNotification.fromJson(
            jsonDecode(json) as Map<String, dynamic>,
          ),
        )
        .toList();
    notifications.sort((a, b) => b.date.compareTo(a.date));
    return notifications;
  }

  Future<void> addNotification(
    String userId,
    AppNotification notification,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = await getNotifications(userId);
    notifications.add(notification);
    await prefs.setStringList(
      _notificationsKey(userId),
      notifications.map((n) => jsonEncode(n.toJson())).toList(),
    );
  }

  Future<void> markAsRead(String userId, String notificationId) async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = await getNotifications(userId);
    final index = notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      notifications[index].isRead = true;
      await prefs.setStringList(
        _notificationsKey(userId),
        notifications.map((n) => jsonEncode(n.toJson())).toList(),
      );
    }
  }

  Future<void> addWelcomeNotification(String userId, String userName) async {
    final notification = AppNotification(
      id: _uuid.v4(),
      title: 'Benvingut/da, $userName!',
      message:
          'Benvingut/da a Rebost! Comença a organitzar el teu rebost, '
          'crear receptes i gestionar la llista de la compra.',
      date: DateTime.now(),
      type: NotificationType.success,
    );
    await addNotification(userId, notification);
  }

  Future<int> getUnreadCount(String userId) async {
    final notifications = await getNotifications(userId);
    return notifications.where((n) => !n.isRead).length;
  }
}
