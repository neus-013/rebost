import 'dart:convert';

class UserModel {
  final String id;
  String name;
  String? email;
  String? avatarUrl;
  DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    this.email,
    this.avatarUrl,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'avatarUrl': avatarUrl,
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  String toJsonString() => jsonEncode(toJson());

  factory UserModel.fromJsonString(String jsonString) =>
      UserModel.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
}
