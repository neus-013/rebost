class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime date;
  final NotificationType type;
  final String? relatedItemId;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
    this.type = NotificationType.info,
    this.relatedItemId,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'date': date.toIso8601String(),
    'type': type.name,
    'related_item_id': relatedItemId,
    'is_read': isRead,
  };

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        title: json['title'] as String,
        message: json['message'] as String,
        date: DateTime.parse(json['date'] as String),
        type: NotificationType.values.byName(json['type'] as String),
        relatedItemId: json['related_item_id'] as String?,
        isRead: json['is_read'] as bool? ?? false,
      );
}

enum NotificationType { info, warning, success, reminder, expiry }
