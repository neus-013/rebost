import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';

class AuthService {
  static const String _usersKey = 'rebost_users';
  static const String _currentUserKey = 'rebost_current_user';
  final Uuid _uuid = const Uuid();

  // ── Hashing ──────────────────────────────────────────

  /// Genera un salt aleatori de 32 bytes codificat en base64
  String _generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Encode(saltBytes);
  }

  /// Retorna el hash SHA-256 de la contrasenya + salt
  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode('$salt:$password');
    // Fem múltiples iteracions per ser més segurs
    var digest = sha256.convert(bytes);
    for (var i = 0; i < 9999; i++) {
      digest = sha256.convert(utf8.encode('$salt:${digest.toString()}'));
    }
    return digest.toString();
  }

  /// Verifica que la contrasenya coincideix amb el hash guardat
  bool verifyPassword(String password, String storedHash, String salt) {
    return _hashPassword(password, salt) == storedHash;
  }

  Future<List<UserModel>> getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getStringList(_usersKey) ?? [];
    return usersJson.map((json) => UserModel.fromJsonString(json)).toList();
  }

  Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_currentUserKey);
    if (userId == null) return null;
    final users = await getUsers();
    try {
      return users.firstWhere((u) => u.id == userId);
    } catch (_) {
      return null;
    }
  }

  /// Comprova si un username ja existeix (retorna true si està ocupat)
  Future<bool> isUsernameTaken(String username, {String? excludeUserId}) async {
    final users = await getUsers();
    return users.any(
      (u) =>
          u.username.toLowerCase() == username.toLowerCase() &&
          u.id != excludeUserId,
    );
  }

  /// Comprova si un email ja existeix (retorna true si està ocupat)
  Future<bool> isEmailTaken(String email, {String? excludeUserId}) async {
    final users = await getUsers();
    return users.any(
      (u) =>
          u.email != null &&
          u.email!.toLowerCase() == email.toLowerCase() &&
          u.id != excludeUserId,
    );
  }

  /// Busca un usuari per username o email
  Future<UserModel?> findUserByUsernameOrEmail(String query) async {
    final users = await getUsers();
    final q = query.toLowerCase().trim();
    try {
      return users.firstWhere(
        (u) =>
            u.username.toLowerCase() == q ||
            (u.email != null && u.email!.toLowerCase() == q),
      );
    } catch (_) {
      return null;
    }
  }

  Future<UserModel> createUser(
    String name, {
    required String username,
    required String password,
    String? email,
  }) async {
    // Validar unicitat
    if (await isUsernameTaken(username)) {
      throw Exception('El nom d\'usuari "$username" ja està en ús');
    }
    if (email != null && email.isNotEmpty && await isEmailTaken(email)) {
      throw Exception('El correu electrònic "$email" ja està en ús');
    }

    final salt = _generateSalt();
    final passwordHash = _hashPassword(password, salt);

    final prefs = await SharedPreferences.getInstance();
    final user = UserModel(
      id: _uuid.v4(),
      name: name,
      username: username,
      email: email,
      passwordHash: passwordHash,
      salt: salt,
    );
    final users = await getUsers();
    users.add(user);
    await prefs.setStringList(
      _usersKey,
      users.map((u) => u.toJsonString()).toList(),
    );
    await prefs.setString(_currentUserKey, user.id);
    return user;
  }

  Future<void> loginUser(String userId, {String? password}) async {
    final users = await getUsers();
    final user = users.firstWhere((u) => u.id == userId);

    // Si l'usuari té contrasenya, cal verificar-la
    if (user.hasPassword) {
      if (password == null || password.isEmpty) {
        throw Exception('Cal introduir la contrasenya');
      }
      if (!verifyPassword(password, user.passwordHash!, user.salt!)) {
        throw Exception('Contrasenya incorrecta');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, userId);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }

  Future<void> updateUser(UserModel user) async {
    // Validar unicitat del username
    if (await isUsernameTaken(user.username, excludeUserId: user.id)) {
      throw Exception('El nom d\'usuari "${user.username}" ja està en ús');
    }
    if (user.email != null &&
        user.email!.isNotEmpty &&
        await isEmailTaken(user.email!, excludeUserId: user.id)) {
      throw Exception('El correu electrònic "${user.email}" ja està en ús');
    }

    final prefs = await SharedPreferences.getInstance();
    final users = await getUsers();
    final index = users.indexWhere((u) => u.id == user.id);
    if (index != -1) {
      users[index] = user;
      await prefs.setStringList(
        _usersKey,
        users.map((u) => u.toJsonString()).toList(),
      );
    }
  }

  /// Canvia la contrasenya d'un usuari
  Future<void> changePassword(String userId, String newPassword) async {
    final prefs = await SharedPreferences.getInstance();
    final users = await getUsers();
    final index = users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      final salt = _generateSalt();
      final hash = _hashPassword(newPassword, salt);
      users[index].passwordHash = hash;
      users[index].salt = salt;
      await prefs.setStringList(
        _usersKey,
        users.map((u) => u.toJsonString()).toList(),
      );
    }
  }

  Future<void> deleteUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final users = await getUsers();
    users.removeWhere((u) => u.id == userId);
    await prefs.setStringList(
      _usersKey,
      users.map((u) => u.toJsonString()).toList(),
    );
    final currentUserId = prefs.getString(_currentUserKey);
    if (currentUserId == userId) {
      await prefs.remove(_currentUserKey);
    }
    // Eliminar dades de l'usuari
    await _clearUserData(prefs, userId);
  }

  Future<void> _clearUserData(SharedPreferences prefs, String userId) async {
    final keys = prefs.getKeys().where((k) => k.startsWith('user_${userId}_'));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
