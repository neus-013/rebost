import 'dart:convert';
import 'package:uuid/uuid.dart';

enum InvitationStatus {
  pending,
  accepted,
  rejected,
}

class Invitation {
  final String id;
  final String fromUserId;
  final String toUserId;
  InvitationStatus status;
  DateTime createdAt;

  Invitation({
    String? id,
    required this.fromUserId,
    required this.toUserId,
    this.status = InvitationStatus.pending,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Invitation.fromJson(Map<String, dynamic> json) => Invitation(
        id: json['id'] as String,
        fromUserId: json['fromUserId'] as String,
        toUserId: json['toUserId'] as String,
        status: InvitationStatus.values.byName(json['status'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  String toJsonString() => jsonEncode(toJson());

  factory Invitation.fromJsonString(String jsonString) =>
      Invitation.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
}
