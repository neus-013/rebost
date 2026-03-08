import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/shared_pantry_provider.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  bool _isEditing = false;
  String? _formError;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser!;
    _nameController = TextEditingController(text: user.name);
    _usernameController = TextEditingController(text: user.username);
    _emailController = TextEditingController(text: user.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final sharedPantryProvider = context.watch<SharedPantryProvider>();
    final user = authProvider.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('El meu perfil'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar
            CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.primaryColor,
              child: Text(
                user.name[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 40,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (!_isEditing) ...[
              Text(
                user.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '@${user.username}',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppTheme.primaryColor),
              ),
              if (user.email != null) ...[
                const SizedBox(height: 4),
                Text(
                  user.email!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Membre des del ${_formatDate(user.createdAt)}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ],
            if (_isEditing) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Nom d\'usuari',
                  prefixIcon: Icon(Icons.alternate_email),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Correu electrònic',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              if (_formError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _formError!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _nameController.text = user.name;
                        _usernameController.text = user.username;
                        _emailController.text = user.email ?? '';
                        setState(() {
                          _isEditing = false;
                          _formError = null;
                        });
                      },
                      child: const Text('Cancel·lar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        setState(() => _formError = null);
                        if (_nameController.text.trim().isNotEmpty &&
                            _usernameController.text.trim().isNotEmpty) {
                          user.name = _nameController.text.trim();
                          user.username = _usernameController.text.trim();
                          user.email = _emailController.text.trim().isEmpty
                              ? null
                              : _emailController.text.trim();
                          final error = await authProvider.updateUser(user);
                          if (error != null && mounted) {
                            setState(() => _formError = error);
                          } else {
                            setState(() => _isEditing = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Perfil actualitzat'),
                                  backgroundColor: AppTheme.primaryColor,
                                ),
                              );
                            }
                          }
                        }
                      },
                      child: const Text('Desar'),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // Opcions
            _SettingsItem(
              icon: Icons.lock,
              title: 'Canviar contrasenya',
              subtitle: 'Actualitza la teva contrasenya',
              onTap: () => _showChangePasswordDialog(context, authProvider),
            ),
            _SettingsItem(
              icon: Icons.color_lens,
              title: 'Aparença',
              subtitle: 'Personalitza l\'aspecte de l\'app',
              onTap: () {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Pròximament...')));
              },
            ),
            _SettingsItem(
              icon: Icons.notifications,
              title: 'Notificacions',
              subtitle: 'Configura les notificacions',
              onTap: () {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Pròximament...')));
              },
            ),
            _SettingsItem(
              icon: Icons.info,
              title: 'Sobre Rebost',
              subtitle: 'Versió 1.0.0',
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'Rebost',
                  applicationVersion: '1.0.0',
                  applicationIcon: const Icon(
                    Icons.kitchen,
                    size: 48,
                    color: AppTheme.primaryColor,
                  ),
                  children: [
                    const Text(
                      'Una app per a la gestió del rebost, receptes i llista de la compra.',
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Rebost compartit
            if (sharedPantryProvider.isInSharedPantry) ...[
              _SettingsItem(
                icon: Icons.group,
                title: 'Rebost compartit',
                subtitle:
                    'Estàs en un rebost compartit amb ${sharedPantryProvider.members.length} membres',
                onTap: () => _showSharedPantryInfo(
                  context,
                  sharedPantryProvider,
                  authProvider,
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _showLeavePantryDialog(context, sharedPantryProvider),
                  icon: const Icon(Icons.exit_to_app, color: Colors.orange),
                  label: const Text(
                    'Sortir del rebost compartit',
                    style: TextStyle(color: Colors.orange),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.orange),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
            ],

            // Canviar d'usuari
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await authProvider.logout();
                  if (context.mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Canviar de perfil'),
              ),
            ),
            const SizedBox(height: 12),

            // Tancar sessió
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await authProvider.logout();
                  if (context.mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Tancar sessió',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Eliminar compte
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => _showDeleteDialog(context, authProvider),
                child: const Text(
                  'Eliminar el meu compte',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSharedPantryInfo(
    BuildContext context,
    SharedPantryProvider sharedProvider,
    AuthProvider authProvider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rebost compartit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Membres (${sharedProvider.members.length}):'),
            const SizedBox(height: 8),
            ...sharedProvider.members.map((memberId) {
              final memberUser = authProvider.getUserById(memberId);
              final isOwner = memberId == sharedProvider.effectiveOwnerId;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      isOwner ? Icons.star : Icons.person,
                      size: 16,
                      color: isOwner ? Colors.amber : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      memberUser?.name ?? memberId,
                      style: TextStyle(
                        fontWeight: isOwner
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    if (isOwner)
                      const Text(
                        ' (propietari)',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tancar'),
          ),
        ],
      ),
    );
  }

  void _showLeavePantryDialog(
    BuildContext context,
    SharedPantryProvider sharedProvider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sortir del rebost compartit'),
        content: const Text(
          'Si surts del rebost compartit, les teves dades del rebost compartit '
          'es perdran i començaràs amb un rebost buit. '
          'El propietari conservarà totes les dades.\n\n'
          'Estàs segur/a?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel·lar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final userId = context.read<AuthProvider>().currentUser!.id;
              await sharedProvider.leavePantry(userId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Has sortit del rebost compartit'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            child: const Text('Sortir', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'gener',
      'febrer',
      'març',
      'abril',
      'maig',
      'juny',
      'juliol',
      'agost',
      'setembre',
      'octubre',
      'novembre',
      'desembre',
    ];
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }

  void _showChangePasswordDialog(
    BuildContext context,
    AuthProvider authProvider,
  ) {
    final currentPwdCtrl = TextEditingController();
    final newPwdCtrl = TextEditingController();
    final confirmPwdCtrl = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    String? error;
    final hasPassword = authProvider.currentUser?.hasPassword ?? false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Canviar contrasenya'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasPassword) ...[
                  TextField(
                    controller: currentPwdCtrl,
                    obscureText: obscureCurrent,
                    decoration: InputDecoration(
                      labelText: 'Contrasenya actual',
                      prefixIcon: const Icon(Icons.lock_open),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureCurrent
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () => setDialogState(
                          () => obscureCurrent = !obscureCurrent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: newPwdCtrl,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: 'Nova contrasenya',
                    hintText: 'Mínim 6 caràcters',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNew ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () =>
                          setDialogState(() => obscureNew = !obscureNew),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPwdCtrl,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirma la nova contrasenya',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirm
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () => setDialogState(
                        () => obscureConfirm = !obscureConfirm,
                      ),
                    ),
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    error!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel·lar'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Validar contrasenya actual
                if (hasPassword &&
                    !authProvider.verifyCurrentPassword(currentPwdCtrl.text)) {
                  setDialogState(
                    () => error = 'La contrasenya actual no és correcta',
                  );
                  return;
                }
                // Validar nova contrasenya
                if (newPwdCtrl.text.length < 6) {
                  setDialogState(
                    () => error =
                        'La nova contrasenya ha de tenir mínim 6 caràcters',
                  );
                  return;
                }
                if (newPwdCtrl.text != confirmPwdCtrl.text) {
                  setDialogState(
                    () => error = 'Les contrasenyes no coincideixen',
                  );
                  return;
                }
                await authProvider.changePassword(newPwdCtrl.text);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Contrasenya actualitzada correctament'),
                      backgroundColor: AppTheme.primaryColor,
                    ),
                  );
                }
              },
              child: const Text('Desar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar compte'),
        content: const Text(
          'Estàs segur/a que vols eliminar el teu compte? '
          'Totes les dades es perdran de manera irreversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel·lar'),
          ),
          TextButton(
            onPressed: () async {
              final userId = authProvider.currentUser!.id;
              await authProvider.deleteUser(userId);
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
