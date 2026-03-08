import 'package:shared_preferences/shared_preferences.dart';
import '../models/invitation_model.dart';

/// Servei per gestionar els rebosts compartits i les invitacions.
///
/// Concepte clau:
/// - Cada usuari té un `pantryOwnerId`: l'ID de l'usuari propietari del rebost
///   que està utilitzant. Si és null, utilitza el seu propi rebost.
/// - Quan un usuari accepta una invitació, el seu `pantryOwnerId` apunta al
///   propietari, i totes les operacions del rebost utilitzen les claus de
///   SharedPreferences del propietari.
/// - Els membres del rebost es guarden a `pantry_members_{ownerId}`.
class SharedPantryService {
  static const String _invitationsKey = 'rebost_invitations';

  // Clau per saber qui és el propietari del rebost d'un usuari
  String _pantryOwnerKey(String userId) => 'user_${userId}_pantry_owner';

  // Clau per guardar els membres d'un rebost
  String _membersKey(String ownerId) => 'pantry_members_$ownerId';

  // ============ PANTRY OWNER ============

  /// Obté l'ID del propietari del rebost que un usuari utilitza.
  /// Retorna null si l'usuari utilitza el seu propi rebost.
  Future<String?> getPantryOwnerId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pantryOwnerKey(userId));
  }

  /// Estableix el propietari del rebost per a un usuari.
  Future<void> setPantryOwnerId(String userId, String ownerId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pantryOwnerKey(userId), ownerId);
  }

  /// Elimina l'associació de rebost (l'usuari torna al seu propi rebost buit).
  Future<void> clearPantryOwnerId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pantryOwnerKey(userId));
  }

  /// Retorna l'ID efectiu del rebost: el propietari si existeix, o el propi.
  Future<String> getEffectivePantryOwnerId(String userId) async {
    final ownerId = await getPantryOwnerId(userId);
    return ownerId ?? userId;
  }

  // ============ MEMBERS ============

  /// Obté la llista de membres (IDs) d'un rebost.
  Future<List<String>> getMembers(String ownerId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_membersKey(ownerId)) ?? [];
  }

  /// Afegeix un membre al rebost.
  Future<void> addMember(String ownerId, String memberId) async {
    final prefs = await SharedPreferences.getInstance();
    final members = await getMembers(ownerId);
    if (!members.contains(memberId)) {
      members.add(memberId);
      await prefs.setStringList(_membersKey(ownerId), members);
    }
  }

  /// Elimina un membre del rebost.
  Future<void> removeMember(String ownerId, String memberId) async {
    final prefs = await SharedPreferences.getInstance();
    final members = await getMembers(ownerId);
    members.remove(memberId);
    await prefs.setStringList(_membersKey(ownerId), members);
  }

  // ============ INVITACIONS ============

  /// Obté totes les invitacions.
  Future<List<Invitation>> getAllInvitations() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getStringList(_invitationsKey) ?? [];
    return json.map((j) => Invitation.fromJsonString(j)).toList();
  }

  /// Obté les invitacions pendents per a un usuari (que ha rebut).
  Future<List<Invitation>> getPendingInvitationsFor(String userId) async {
    final all = await getAllInvitations();
    return all
        .where((i) =>
            i.toUserId == userId && i.status == InvitationStatus.pending)
        .toList();
  }

  /// Obté les invitacions enviades per un usuari.
  Future<List<Invitation>> getSentInvitations(String userId) async {
    final all = await getAllInvitations();
    return all.where((i) => i.fromUserId == userId).toList();
  }

  /// Crea una nova invitació.
  Future<Invitation> createInvitation(Invitation invitation) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await getAllInvitations();

    // Comprovar que no hi ha ja una invitació pendent entre aquests usuaris
    final existing = all.where((i) =>
        i.fromUserId == invitation.fromUserId &&
        i.toUserId == invitation.toUserId &&
        i.status == InvitationStatus.pending);
    if (existing.isNotEmpty) {
      throw Exception('Ja hi ha una invitació pendent per a aquest usuari');
    }

    all.add(invitation);
    await _saveInvitations(prefs, all);
    return invitation;
  }

  /// Accepta una invitació.
  Future<void> acceptInvitation(String invitationId) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await getAllInvitations();
    final index = all.indexWhere((i) => i.id == invitationId);
    if (index != -1) {
      all[index].status = InvitationStatus.accepted;
      await _saveInvitations(prefs, all);

      // Configurar la relació de compartició
      final inv = all[index];
      await setPantryOwnerId(inv.toUserId, inv.fromUserId);
      await addMember(inv.fromUserId, inv.toUserId);
    }
  }

  /// Rebutja una invitació.
  Future<void> rejectInvitation(String invitationId) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await getAllInvitations();
    final index = all.indexWhere((i) => i.id == invitationId);
    if (index != -1) {
      all[index].status = InvitationStatus.rejected;
      await _saveInvitations(prefs, all);
    }
  }

  /// Surt d'un rebost compartit. Esborra les dades locals del rebost
  /// i torna a l'estat propi.
  Future<void> leavePantry(String userId) async {
    final ownerId = await getPantryOwnerId(userId);
    if (ownerId == null) return; // Ja és el seu propi rebost

    // Treure de la llista de membres
    await removeMember(ownerId, userId);

    // Esborrar la referència al propietari
    await clearPantryOwnerId(userId);

    // Esborrar les dades pròpies del rebost (aniran buides)
    await _clearUserPantryData(userId);
  }

  /// Esborra les dades del rebost d'un usuari.
  Future<void> _clearUserPantryData(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final keysToRemove = prefs.getKeys().where((k) =>
        k.startsWith('user_${userId}_pantry_'));
    for (final key in keysToRemove) {
      await prefs.remove(key);
    }
  }

  /// Esborra les dades del rebost d'un usuari (públic, per usar abans d'acceptar).
  Future<void> clearUserPantryData(String userId) async {
    await _clearUserPantryData(userId);
  }

  /// Comprova si un usuari ja és membre d'un rebost (o propietari d'un amb membres).
  Future<bool> isUserInASharedPantry(String userId) async {
    final ownerId = await getPantryOwnerId(userId);
    return ownerId != null;
  }

  /// Comprova si un usuari té dades al seu propi rebost.
  Future<bool> userHasPantryData(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final itemsKey = 'user_${userId}_pantry_items';
    final items = prefs.getStringList(itemsKey) ?? [];
    return items.isNotEmpty;
  }

  Future<void> _saveInvitations(
      SharedPreferences prefs, List<Invitation> invitations) async {
    await prefs.setStringList(
      _invitationsKey,
      invitations.map((i) => i.toJsonString()).toList(),
    );
  }
}
