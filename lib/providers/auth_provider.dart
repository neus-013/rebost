import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();

  UserModel? _currentUser;
  bool _isLoading = true;

  /// Cache de perfils per evitar consultes repetides
  final Map<String, UserModel> _profileCache = {};

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    _currentUser = await _authService.getCurrentUser();

    _isLoading = false;
    notifyListeners();
  }

  /// Registre amb email i contrasenya
  Future<String?> signUp({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final user = await _authService.signUp(
        email: email,
        password: password,
        name: name,
        username: username,
      );
      await _notificationService.addWelcomeNotification(user.id, user.name);
      _currentUser = user;
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  /// Iniciar sessió amb email i contrasenya
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _currentUser = await _authService.signIn(
        email: email,
        password: password,
      );
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  /// Comprova si un username està disponible
  Future<bool> isUsernameTaken(String username, {String? excludeUserId}) async {
    return _authService.isUsernameTaken(username, excludeUserId: excludeUserId);
  }

  /// Busca un usuari per username o email
  Future<UserModel?> findUserByUsernameOrEmail(String query) async {
    return _authService.findUserByUsernameOrEmail(query);
  }

  /// Canvia la contrasenya de l'usuari actual
  Future<String?> changePassword(String newPassword) async {
    try {
      await _authService.changePassword(newPassword);
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<void> logout() async {
    await _authService.signOut();
    _currentUser = null;
    _profileCache.clear();
    notifyListeners();
  }

  Future<String?> updateUser(UserModel user) async {
    try {
      await _authService.updateProfile(user);
      _currentUser = user;
      _profileCache[user.id] = user;
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<void> deleteUser(String userId) async {
    await _authService.deleteProfile(userId);
    _currentUser = null;
    _profileCache.clear();
    notifyListeners();
  }

  /// Obté un perfil per ID (des de cache o Supabase)
  Future<UserModel?> getProfileById(String userId) async {
    if (_profileCache.containsKey(userId)) return _profileCache[userId];
    final profile = await _authService.getProfileById(userId);
    if (profile != null) _profileCache[userId] = profile;
    return profile;
  }

  /// Obté un perfil per ID des de la cache (sincrón, pot retornar null)
  UserModel? getCachedProfile(String userId) {
    return _profileCache[userId];
  }
}
