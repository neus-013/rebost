import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/notification_model.dart';
import '../models/pantry_item.dart';

class NotificationService {
  final Uuid _uuid = const Uuid();

  String _notificationsKey(String userId) => 'user_${userId}_notifications';
  String _expiryNotifiedKey(String userId) => 'user_${userId}_expiry_notified';

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

  /// Comprova els productes i crea notificacions de caducitat.
  /// Retorna el nombre de noves notificacions creades.
  Future<int> checkExpiryNotifications(
    String userId,
    List<PantryItem> items,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    // Registre d'ítems ja notificats: "itemId:tipus" (approaching / expired)
    final notifiedSet = (prefs.getStringList(_expiryNotifiedKey(userId)) ?? [])
        .toSet();
    int count = 0;

    for (final item in items) {
      if (!item.isActive || item.expiryDate == null) continue;

      final days = item.daysUntilExpiry!;
      final approachingKey = '${item.id}:approaching';
      final expiredKey = '${item.id}:expired';

      // Producte caducat
      if (days < 0 && !notifiedSet.contains(expiredKey)) {
        await addNotification(
          userId,
          AppNotification(
            id: _uuid.v4(),
            title: '⚠️ ${item.name} ha caducat!',
            message:
                '${item.name} ha superat la data de caducitat. '
                'Considera llençar-lo per seguretat.',
            date: DateTime.now(),
            type: NotificationType.expiry,
            relatedItemId: item.id,
          ),
        );
        notifiedSet.add(expiredKey);
        count++;
      }
      // Producte a punt de caducar (2 dies o menys)
      else if (days >= 0 &&
          days <= 2 &&
          !notifiedSet.contains(approachingKey)) {
        final daysText = days == 0
            ? 'avui'
            : days == 1
            ? 'demà'
            : 'en $days dies';
        await addNotification(
          userId,
          AppNotification(
            id: _uuid.v4(),
            title: '🕐 ${item.name} caduca $daysText',
            message:
                '${item.name} caduca $daysText. '
                'Consumeix-lo aviat!',
            date: DateTime.now(),
            type: NotificationType.warning,
            relatedItemId: item.id,
          ),
        );
        notifiedSet.add(approachingKey);
        count++;
      }
    }

    await prefs.setStringList(_expiryNotifiedKey(userId), notifiedSet.toList());
    return count;
  }
}
