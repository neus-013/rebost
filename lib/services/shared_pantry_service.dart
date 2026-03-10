import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/invitation_model.dart';

/// Servei per gestionar els rebosts compartits i les invitacions.
///
/// Concepte clau:
/// - Cada usuari pot ser membre del rebost d'un altre (pantry_shares).
/// - Quan un usuari accepta una invitació, es crea un registre a pantry_shares
///   i totes les operacions del rebost utilitzen l'owner_id del propietari.
class SharedPantryService {
  SupabaseClient get _client => Supabase.instance.client;

  // ============ PANTRY OWNER ============

  /// Obté l'ID del propietari del rebost que un usuari utilitza.
  /// Retorna null si l'usuari utilitza el seu propi rebost.
  Future<String?> getPantryOwnerId(String userId) async {
    final response = await _client
        .from('pantry_shares')
        .select('owner_id')
        .eq('member_id', userId)
        .maybeSingle();
    return response?['owner_id'] as String?;
  }

  /// Retorna l'ID efectiu del rebost: el propietari si existeix, o el propi.
  Future<String> getEffectivePantryOwnerId(String userId) async {
    final ownerId = await getPantryOwnerId(userId);
    return ownerId ?? userId;
  }

  // ============ MEMBERS ============

  /// Obté la llista de membres (IDs) d'un rebost.
  Future<List<String>> getMembers(String ownerId) async {
    final response = await _client
        .from('pantry_shares')
        .select('member_id')
        .eq('owner_id', ownerId);
    return (response as List)
        .map((r) => r['member_id'] as String)
        .toList();
  }

  /// Afegeix un membre al rebost.
  Future<void> addMember(String ownerId, String memberId) async {
    await _client.from('pantry_shares').upsert({
      'owner_id': ownerId,
      'member_id': memberId,
    });
  }

  /// Elimina un membre del rebost.
  Future<void> removeMember(String ownerId, String memberId) async {
    await _client
        .from('pantry_shares')
        .delete()
        .eq('owner_id', ownerId)
        .eq('member_id', memberId);
  }

  // ============ INVITACIONS ============

  /// Obté les invitacions pendents per a un usuari (que ha rebut).
  Future<List<Invitation>> getPendingInvitationsFor(String userId) async {
    final response = await _client
        .from('invitations')
        .select()
        .eq('to_user_id', userId)
        .eq('status', 'pending');
    return (response as List)
        .map((json) => Invitation.fromJson(json))
        .toList();
  }

  /// Obté les invitacions enviades per un usuari.
  Future<List<Invitation>> getSentInvitations(String userId) async {
    final response = await _client
        .from('invitations')
        .select()
        .eq('from_user_id', userId);
    return (response as List)
        .map((json) => Invitation.fromJson(json))
        .toList();
  }

  /// Crea una nova invitació.
  Future<Invitation> createInvitation(Invitation invitation) async {
    // Comprovar que no hi ha ja una invitació pendent entre aquests usuaris
    final existing = await _client
        .from('invitations')
        .select('id')
        .eq('from_user_id', invitation.fromUserId)
        .eq('to_user_id', invitation.toUserId)
        .eq('status', 'pending')
        .maybeSingle();

    if (existing != null) {
      throw Exception('Ja hi ha una invitació pendent per a aquest usuari');
    }

    await _client.from('invitations').insert(invitation.toJson());
    return invitation;
  }

  /// Accepta una invitació.
  Future<void> acceptInvitation(String invitationId) async {
    // Obtenir la invitació
    final response = await _client
        .from('invitations')
        .select()
        .eq('id', invitationId)
        .single();
    final inv = Invitation.fromJson(response);

    // Actualitzar l'estat
    await _client
        .from('invitations')
        .update({'status': 'accepted'})
        .eq('id', invitationId);

    // Crear la relació de compartició
    await addMember(inv.fromUserId, inv.toUserId);
  }

  /// Rebutja una invitació.
  Future<void> rejectInvitation(String invitationId) async {
    await _client
        .from('invitations')
        .update({'status': 'rejected'})
        .eq('id', invitationId);
  }

  /// Surt d'un rebost compartit.
  Future<void> leavePantry(String userId) async {
    final ownerId = await getPantryOwnerId(userId);
    if (ownerId == null) return;
    await removeMember(ownerId, userId);
  }

  /// Esborra les dades del rebost d'un usuari.
  Future<void> clearUserPantryData(String userId) async {
    await _client.from('pantry_items').delete().eq('owner_id', userId);
    await _client.from('item_types').delete().eq('owner_id', userId);
    await _client.from('item_locations').delete().eq('owner_id', userId);
    await _client.from('shopping_items').delete().eq('owner_id', userId);
  }

  /// Comprova si un usuari té dades al seu propi rebost.
  Future<bool> userHasPantryData(String userId) async {
    final response = await _client
        .from('pantry_items')
        .select('id')
        .eq('owner_id', userId)
        .limit(1);
    return (response as List).isNotEmpty;
  }
}
