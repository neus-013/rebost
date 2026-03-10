import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  bool _isLoading = true;

  /// Cache de perfils per evitar consultes repetides
  final Map<String, UserModel> _profileCache = {};

  bool _pendingEmailVerification = false;
  String? _pendingEmail;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  bool get pendingEmailVerification => _pendingEmailVerification;
  String? get pendingEmail => _pendingEmail;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    _currentUser = await _authService.getCurrentUser();

    _isLoading = false;
    notifyListeners();
  }

  /// Registre amb email i contrasenya.
  /// Retorna null si tot ha anat bé (pot requerir verificació d'email).
  Future<String?> signUp({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      _pendingEmailVerification = false;
      _pendingEmail = null;

      final needsVerification = await _authService.signUp(
        email: email,
        password: password,
        name: name,
        username: username,
      );

      if (needsVerification) {
        _pendingEmailVerification = true;
        _pendingEmail = email;
        notifyListeners();
        return null;
      }

      // Si no cal verificació (cas improbable amb confirm email activat)
      _currentUser = await _authService.getCurrentUser();
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  /// Reenvia el correu de verificació
  Future<String?> resendVerificationEmail() async {
    if (_pendingEmail == null) return 'No hi ha cap correu pendent';
    try {
      await _authService.resendVerificationEmail(_pendingEmail!);
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  /// Torna de la pantalla de verificació al formulari de login
  void clearPendingVerification() {
    _pendingEmailVerification = false;
    _pendingEmail = null;
    notifyListeners();
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
