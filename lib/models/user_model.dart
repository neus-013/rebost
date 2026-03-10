import 'dart:convert';

class UserModel {
  final String id;
  String name;
  String username;
  String? email;
  String? avatarUrl;
  DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.username,
    this.email,
    this.avatarUrl,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'username': username,
    'email': email,
    'avatar_url': avatarUrl,
    'created_at': createdAt.toIso8601String(),
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] as String,
    name: json['name'] as String,
    username: json['username'] as String? ?? json['name'] as String,
    email: json['email'] as String?,
    avatarUrl: json['avatar_url'] as String?,
    createdAt: json['created_at'] != null
        ? DateTime.parse(json['created_at'] as String)
        : DateTime.now(),
  );

  String toJsonString() => jsonEncode(toJson());

  factory UserModel.fromJsonString(String jsonString) =>
      UserModel.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
}
