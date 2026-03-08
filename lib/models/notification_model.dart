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
    'relatedItemId': relatedItemId,
    'isRead': isRead,
  };

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        title: json['title'] as String,
        message: json['message'] as String,
        date: DateTime.parse(json['date'] as String),
        type: NotificationType.values.byName(json['type'] as String),
        relatedItemId: json['relatedItemId'] as String?,
        isRead: json['isRead'] as bool? ?? false,
      );
}

enum NotificationType { info, warning, success, reminder, expiry }
