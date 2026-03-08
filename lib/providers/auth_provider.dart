import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();

  UserModel? _currentUser;
  List<UserModel> _users = [];
  bool _isLoading = true;

  UserModel? get currentUser => _currentUser;
  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    _users = await _authService.getUsers();
    _currentUser = await _authService.getCurrentUser();

    _isLoading = false;
    notifyListeners();
  }

  /// Comprova si un username està disponible
  Future<bool> isUsernameTaken(String username, {String? excludeUserId}) async {
    return _authService.isUsernameTaken(username, excludeUserId: excludeUserId);
  }

  /// Comprova si un email està disponible
  Future<bool> isEmailTaken(String email, {String? excludeUserId}) async {
    return _authService.isEmailTaken(email, excludeUserId: excludeUserId);
  }

  /// Busca un usuari per username o email
  Future<UserModel?> findUserByUsernameOrEmail(String query) async {
    return _authService.findUserByUsernameOrEmail(query);
  }

  Future<String?> createUser(
    String name, {
    required String username,
    required String password,
    String? email,
  }) async {
    try {
      final user = await _authService.createUser(
        name,
        username: username,
        password: password,
        email: email,
      );
      await _notificationService.addWelcomeNotification(user.id, user.name);
      _currentUser = user;
      _users = await _authService.getUsers();
      notifyListeners();
      return null; // Cap error
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<String?> loginUser(String userId, {String? password}) async {
    try {
      await _authService.loginUser(userId, password: password);
      _currentUser = _users.firstWhere((u) => u.id == userId);
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  /// Canvia la contrasenya de l'usuari actual
  Future<void> changePassword(String newPassword) async {
    if (_currentUser == null) return;
    await _authService.changePassword(_currentUser!.id, newPassword);
    _users = await _authService.getUsers();
    _currentUser = _users.firstWhere((u) => u.id == _currentUser!.id);
    notifyListeners();
  }

  /// Verifica la contrasenya actual de l'usuari
  bool verifyCurrentPassword(String password) {
    if (_currentUser == null || !_currentUser!.hasPassword) return true;
    return _authService.verifyPassword(
      password,
      _currentUser!.passwordHash!,
      _currentUser!.salt!,
    );
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }

  Future<String?> updateUser(UserModel user) async {
    try {
      await _authService.updateUser(user);
      _currentUser = user;
      _users = await _authService.getUsers();
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<void> deleteUser(String userId) async {
    await _authService.deleteUser(userId);
    if (_currentUser?.id == userId) {
      _currentUser = null;
    }
    _users = await _authService.getUsers();
    notifyListeners();
  }

  /// Obté un usuari per ID
  UserModel? getUserById(String userId) {
    try {
      return _users.firstWhere((u) => u.id == userId);
    } catch (_) {
      return null;
    }
  }
}
