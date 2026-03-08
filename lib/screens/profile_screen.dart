import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser!;
    _nameController = TextEditingController(text: user.name);
    _emailController = TextEditingController(text: user.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
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
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Correu electrònic',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _nameController.text = user.name;
                        _emailController.text = user.email ?? '';
                        setState(() => _isEditing = false);
                      },
                      child: const Text('Cancel·lar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_nameController.text.trim().isNotEmpty) {
                          user.name = _nameController.text.trim();
                          user.email = _emailController.text.trim().isEmpty
                              ? null
                              : _emailController.text.trim();
                          await authProvider.updateUser(user);
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
