import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/notification_model.dart';
import '../models/pantry_item.dart';

class NotificationService {
  final Uuid _uuid = const Uuid();
  SupabaseClient get _client => Supabase.instance.client;

  Future<List<AppNotification>> getNotifications(String userId) async {
    final response = await _client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('date', ascending: false);
    return (response as List)
        .map((json) => AppNotification.fromJson(json))
        .toList();
  }

  Future<void> addNotification(
    String userId,
    AppNotification notification,
  ) async {
    final data = notification.toJson();
    data['user_id'] = userId;
    await _client.from('notifications').insert(data);
  }

  Future<void> markAsRead(String userId, String notificationId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId)
        .eq('user_id', userId);
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
    final response = await _client
        .from('notifications')
        .select('id')
        .eq('user_id', userId)
        .eq('is_read', false);
    return (response as List).length;
  }

  /// Comprova els productes i crea notificacions de caducitat.
  /// Retorna el nombre de noves notificacions creades.
  Future<int> checkExpiryNotifications(
    String userId,
    List<PantryItem> items,
  ) async {
    // Obtenir els items ja notificats
    final existingNotifs = await _client
        .from('expiry_notified')
        .select()
        .eq('user_id', userId);

    final notifiedSet = <String>{};
    for (final n in existingNotifs) {
      final itemId = n['item_id'] as String;
      final type = n['notification_type'] as String;
      notifiedSet.add('$itemId:$type');
    }

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
        await _client.from('expiry_notified').upsert({
          'user_id': userId,
          'item_id': item.id,
          'notification_type': 'expired',
        });
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
        await _client.from('expiry_notified').upsert({
          'user_id': userId,
          'item_id': item.id,
          'notification_type': 'approaching',
        });
        count++;
      }
    }

    return count;
  }
}
