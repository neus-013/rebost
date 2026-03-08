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

  Future<void> createUser(String name, {String? email}) async {
    final user = await _authService.createUser(name, email: email);
    await _notificationService.addWelcomeNotification(user.id, user.name);
    _currentUser = user;
    _users = await _authService.getUsers();
    notifyListeners();
  }

  Future<void> loginUser(String userId) async {
    await _authService.loginUser(userId);
    _currentUser = _users.firstWhere((u) => u.id == userId);
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> updateUser(UserModel user) async {
    await _authService.updateUser(user);
    _currentUser = user;
    _users = await _authService.getUsers();
    notifyListeners();
  }

  Future<void> deleteUser(String userId) async {
    await _authService.deleteUser(userId);
    if (_currentUser?.id == userId) {
      _currentUser = null;
    }
    _users = await _authService.getUsers();
    notifyListeners();
  }
}
