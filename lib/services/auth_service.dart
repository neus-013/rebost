import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';

class AuthService {
  static const String _usersKey = 'rebost_users';
  static const String _currentUserKey = 'rebost_current_user';
  final Uuid _uuid = const Uuid();

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

  Future<UserModel> createUser(String name, {String? email}) async {
    final prefs = await SharedPreferences.getInstance();
    final user = UserModel(
      id: _uuid.v4(),
      name: name,
      email: email,
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

  Future<void> loginUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, userId);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }

  Future<void> updateUser(UserModel user) async {
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
