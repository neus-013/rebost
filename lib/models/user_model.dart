import 'dart:convert';

class UserModel {
  final String id;
  String name;
  String username;
  String? email;
  String? avatarUrl;
  String? passwordHash;
  String? salt;
  DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.username,
    this.email,
    this.avatarUrl,
    this.passwordHash,
    this.salt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get hasPassword => passwordHash != null && salt != null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'username': username,
    'email': email,
    'avatarUrl': avatarUrl,
    'passwordHash': passwordHash,
    'salt': salt,
    'createdAt': createdAt.toIso8601String(),
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] as String,
    name: json['name'] as String,
    username: json['username'] as String? ?? json['name'] as String,
    email: json['email'] as String?,
    avatarUrl: json['avatarUrl'] as String?,
    passwordHash: json['passwordHash'] as String?,
    salt: json['salt'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  String toJsonString() => jsonEncode(toJson());

  factory UserModel.fromJsonString(String jsonString) =>
      UserModel.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
}
