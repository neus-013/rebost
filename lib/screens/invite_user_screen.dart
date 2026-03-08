import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/shared_pantry_provider.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';

class InviteUserScreen extends StatefulWidget {
  const InviteUserScreen({super.key});

  @override
  State<InviteUserScreen> createState() => _InviteUserScreenState();
}

class _InviteUserScreenState extends State<InviteUserScreen> {
  final _searchController = TextEditingController();
  UserModel? _foundUser;
  String? _searchError;
  bool _isSearching = false;
  bool _isSending = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUser() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _foundUser = null;
      _searchError = null;
    });

    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser!;

    final user = await authProvider.findUserByUsernameOrEmail(query);

    setState(() {
      _isSearching = false;
      if (user == null) {
        _searchError = 'No s\'ha trobat cap usuari amb "$query"';
      } else if (user.id == currentUser.id) {
        _searchError = 'No et pots convidar a tu mateix/a';
      } else {
        _foundUser = user;
      }
    });
  }

  Future<void> _sendInvitation() async {
    if (_foundUser == null) return;

    setState(() => _isSending = true);

    final sharedProvider = context.read<SharedPantryProvider>();
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.currentUser!.id;

    try {
      await sharedProvider.sendInvitation(currentUserId, _foundUser!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invitació enviada a ${_foundUser!.name}'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isSending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sharedProvider = context.watch<SharedPantryProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Convidar al rebost'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instruccions
            Card(
              color: AppTheme.primaryColor.withValues(alpha: 0.05),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.primaryColor),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Cerca un usuari pel nom d\'usuari o correu electrònic '
                        'per convidar-lo a compartir el teu rebost.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Camp de cerca
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Nom d\'usuari o correu',
                      hintText: 'Ex: maria_garcia o maria@correu.cat',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _searchUser(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isSearching ? null : _searchUser,
                  child: _isSearching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Cercar'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Resultat de la cerca
            if (_searchError != null)
              Card(
                color: Colors.red.withValues(alpha: 0.05),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _searchError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (_foundUser != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryColor,
                          child: Text(
                            _foundUser!.name[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          _foundUser!.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('@${_foundUser!.username}'),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isSending ? null : _sendInvitation,
                          icon: _isSending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send),
                          label: Text(
                            _isSending
                                ? 'Enviant...'
                                : 'Enviar invitació',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Invitacions enviades
            if (sharedProvider.sentInvitations.isNotEmpty) ...[
              Text(
                'Invitacions enviades',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...sharedProvider.sentInvitations.map((inv) {
                final toUser = authProvider.getUserById(inv.toUserId);
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey[300],
                      child: Text(
                        toUser?.name[0].toUpperCase() ?? '?',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                    title: Text(toUser?.name ?? 'Usuari desconegut'),
                    subtitle: Text('@${toUser?.username ?? '?'}'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Pendent',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],

            // Membres actuals
            if (sharedProvider.isInSharedPantry) ...[
              const SizedBox(height: 24),
              Text(
                'Membres del rebost',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...sharedProvider.members.map((memberId) {
                final memberUser = authProvider.getUserById(memberId);
                final isOwner = memberId == sharedProvider.effectiveOwnerId;
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryColor,
                      child: Text(
                        memberUser?.name[0].toUpperCase() ?? '?',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(memberUser?.name ?? memberId),
                    subtitle: Text('@${memberUser?.username ?? '?'}'),
                    trailing: isOwner
                        ? const Chip(
                            label: Text('Propietari',
                                style: TextStyle(fontSize: 11)),
                            backgroundColor: Color(0xFFFFF8E1),
                            avatar: Icon(Icons.star,
                                size: 14, color: Colors.amber),
                          )
                        : null,
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
