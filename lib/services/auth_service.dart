import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthService {
  SupabaseClient get _client => Supabase.instance.client;

  // ── Sessió ──────────────────────────────────────────

  /// Retorna el perfil de l'usuari autenticat actual, o null
  Future<UserModel?> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final response = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    if (response == null) return null;
    return UserModel.fromJson(response);
  }

  // ── Registre ──────────────────────────────────────────

  /// Crea un compte nou amb email i contrasenya
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
    required String username,
  }) async {
    // Verificar que el username no estigui en ús
    final existing = await _client
        .from('profiles')
        .select('id')
        .ilike('username', username)
        .maybeSingle();
    if (existing != null) {
      throw Exception('El nom d\'usuari "$username" ja està en ús');
    }

    // Registrar-se amb Supabase Auth
    final authResponse = await _client.auth.signUp(
      email: email,
      password: password,
    );

    final user = authResponse.user;
    if (user == null) throw Exception('Error al crear el compte');

    // Crear perfil a la taula profiles
    await _client.from('profiles').insert({
      'id': user.id,
      'name': name,
      'username': username,
      'email': email,
    });

    return UserModel(id: user.id, name: name, username: username, email: email);
  }

  // ── Inici de sessió ──────────────────────────────────

  /// Inicia sessió amb email i contrasenya
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final authResponse = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = authResponse.user;
    if (user == null) throw Exception('Error al iniciar sessió');

    final response = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();
    return UserModel.fromJson(response);
  }

  /// Tanca la sessió
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ── Perfil ──────────────────────────────────────────

  /// Actualitza el perfil d'un usuari
  Future<void> updateProfile(UserModel profile) async {
    // Verificar unicitat del username
    if (await isUsernameTaken(profile.username, excludeUserId: profile.id)) {
      throw Exception('El nom d\'usuari "${profile.username}" ja està en ús');
    }

    await _client
        .from('profiles')
        .update({
          'name': profile.name,
          'username': profile.username,
          'email': profile.email,
          'avatar_url': profile.avatarUrl,
        })
        .eq('id', profile.id);
  }

  /// Canvia la contrasenya (l'usuari ja està autenticat)
  Future<void> changePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  // ── Cerques ──────────────────────────────────────────

  /// Comprova si un username ja existeix
  Future<bool> isUsernameTaken(String username, {String? excludeUserId}) async {
    var query = _client
        .from('profiles')
        .select('id')
        .ilike('username', username);
    if (excludeUserId != null) {
      query = query.neq('id', excludeUserId);
    }
    final response = await query.maybeSingle();
    return response != null;
  }

  /// Comprova si un email ja existeix en els perfils
  Future<bool> isEmailTaken(String email, {String? excludeUserId}) async {
    var query = _client.from('profiles').select('id').ilike('email', email);
    if (excludeUserId != null) {
      query = query.neq('id', excludeUserId);
    }
    final response = await query.maybeSingle();
    return response != null;
  }

  /// Busca un usuari per username o email
  Future<UserModel?> findUserByUsernameOrEmail(String query) async {
    final q = query.toLowerCase().trim();
    final response = await _client
        .from('profiles')
        .select()
        .or('username.ilike.$q,email.ilike.$q')
        .maybeSingle();
    if (response == null) return null;
    return UserModel.fromJson(response);
  }

  /// Obté un perfil per ID
  Future<UserModel?> getProfileById(String userId) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (response == null) return null;
    return UserModel.fromJson(response);
  }

  /// Obté tots els perfils
  Future<List<UserModel>> getAllProfiles() async {
    final response = await _client.from('profiles').select();
    return (response as List).map((json) => UserModel.fromJson(json)).toList();
  }

  /// Elimina el perfil (les dades es borren en cascada per les FK)
  Future<void> deleteProfile(String userId) async {
    await _client.from('profiles').delete().eq('id', userId);
    await _client.auth.signOut();
  }
}
