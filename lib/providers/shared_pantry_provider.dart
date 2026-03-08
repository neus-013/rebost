import 'package:flutter/material.dart';
import '../models/invitation_model.dart';
import '../services/shared_pantry_service.dart';

/// Provider per gestionar l'estat dels rebosts compartits i les invitacions.
class SharedPantryProvider extends ChangeNotifier {
  final SharedPantryService _service = SharedPantryService();

  String? _effectiveOwnerId;
  List<Invitation> _pendingInvitations = [];
  List<Invitation> _sentInvitations = [];
  List<String> _members = [];
  bool _isInSharedPantry = false;
  bool _isLoading = false;

  String? get effectiveOwnerId => _effectiveOwnerId;
  List<Invitation> get pendingInvitations => _pendingInvitations;
  List<Invitation> get sentInvitations => _sentInvitations;
  List<String> get members => _members;
  bool get isInSharedPantry => _isInSharedPantry;
  bool get isLoading => _isLoading;
  int get pendingCount => _pendingInvitations.length;

  /// Carrega totes les dades de compartició per a un usuari.
  Future<void> loadAll(String userId) async {
    _isLoading = true;
    notifyListeners();

    _effectiveOwnerId = await _service.getPantryOwnerId(userId);
    _isInSharedPantry = _effectiveOwnerId != null;
    _pendingInvitations = await _service.getPendingInvitationsFor(userId);
    _sentInvitations = await _service.getSentInvitations(userId);

    // Carregar membres (si soc propietari o estic en un rebost)
    final ownerId = _effectiveOwnerId ?? userId;
    _members = await _service.getMembers(ownerId);

    _isLoading = false;
    notifyListeners();
  }

  /// Retorna l'ID efectiu del propietari del rebost.
  /// Si l'usuari està en un rebost compartit, retorna el propietari.
  /// Si no, retorna el propi userId.
  String getEffectiveOwnerId(String userId) {
    return _effectiveOwnerId ?? userId;
  }

  /// Envia una invitació a un altre usuari.
  Future<String?> sendInvitation(String fromUserId, String toUserId) async {
    try {
      // No es pot convidar a si mateix
      if (fromUserId == toUserId) {
        return 'No et pots convidar a tu mateix';
      }

      // No es pot convidar si l'usuari ja és al rebost
      final members = await _service.getMembers(fromUserId);
      if (members.contains(toUserId)) {
        return 'Aquest usuari ja és al teu rebost';
      }

      final invitation = Invitation(fromUserId: fromUserId, toUserId: toUserId);
      await _service.createInvitation(invitation);
      _sentInvitations = await _service.getSentInvitations(fromUserId);
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  /// Accepta una invitació. Retorna true si l'usuari tenia dades i s'han esborrat.
  Future<bool> acceptInvitation(String invitationId, String userId) async {
    // Comprovar si l'usuari tenia dades pròpies
    final hadData = await _service.userHasPantryData(userId);

    // Esborrar dades pròpies del rebost si en tenia
    if (hadData) {
      await _service.clearUserPantryData(userId);
    }

    // Acceptar la invitació (configura la relació)
    await _service.acceptInvitation(invitationId);

    // Recarregar
    await loadAll(userId);
    return hadData;
  }

  /// Rebutja una invitació.
  Future<void> rejectInvitation(String invitationId, String userId) async {
    await _service.rejectInvitation(invitationId);
    _pendingInvitations = await _service.getPendingInvitationsFor(userId);
    notifyListeners();
  }

  /// Surt del rebost compartit.
  Future<void> leavePantry(String userId) async {
    await _service.leavePantry(userId);
    _effectiveOwnerId = null;
    _isInSharedPantry = false;
    _members = [];
    notifyListeners();
  }

  /// Comprova si l'usuari convidat tenia dades.
  Future<bool> inviteeHasData(String userId) async {
    return _service.userHasPantryData(userId);
  }
}
