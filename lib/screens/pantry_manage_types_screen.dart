import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pantry_types.dart';
import '../providers/auth_provider.dart';
import '../providers/pantry_provider.dart';
import '../theme/app_theme.dart';

class PantryManageTypesScreen extends StatelessWidget {
  const PantryManageTypesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tipus i ubicacions'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.category), text: 'Tipus'),
              Tab(icon: Icon(Icons.place), text: 'Ubicacions'),
            ],
          ),
        ),
        body: const TabBarView(children: [_TypesTab(), _LocationsTab()]),
      ),
    );
  }
}

// ─── TIPUS ──────────────────────────────────────────────

class _TypesTab extends StatelessWidget {
  const _TypesTab();

  @override
  Widget build(BuildContext context) {
    final pantryProvider = context.watch<PantryProvider>();
    final types = pantryProvider.types;

    return Scaffold(
      body: types.isEmpty
          ? const Center(child: Text('No hi ha tipus definits'))
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: types.length,
              itemBuilder: (context, index) {
                final type = types[index];
                return ListTile(
                  leading: Text(
                    type.icon,
                    style: const TextStyle(fontSize: 28),
                  ),
                  title: Text(type.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () =>
                            _showEditTypeDialog(context, pantryProvider, type),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          size: 20,
                          color: Colors.red,
                        ),
                        onPressed: () =>
                            _confirmDeleteType(context, pantryProvider, type),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTypeDialog(context, pantryProvider),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddTypeDialog(BuildContext context, PantryProvider provider) {
    final nameController = TextEditingController();
    final iconController = TextEditingController(text: '🏷️');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nou tipus'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: iconController,
              decoration: const InputDecoration(
                labelText: 'Emoji/Icona',
                hintText: '🏷️',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nom del tipus',
                hintText: 'ex: Espècies',
              ),
              textCapitalization: TextCapitalization.sentences,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel·lar'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              final icon = iconController.text.trim();
              if (name.isEmpty) return;
              final userId = ctx.read<AuthProvider>().currentUser!.id;
              provider.addType(
                userId,
                ItemType(name: name, icon: icon.isEmpty ? '🏷️' : icon),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Afegir'),
          ),
        ],
      ),
    );
  }

  void _showEditTypeDialog(
    BuildContext context,
    PantryProvider provider,
    ItemType type,
  ) {
    final nameController = TextEditingController(text: type.name);
    final iconController = TextEditingController(text: type.icon);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar tipus'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: iconController,
              decoration: const InputDecoration(labelText: 'Emoji/Icona'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nom del tipus'),
              textCapitalization: TextCapitalization.sentences,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel·lar'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              final icon = iconController.text.trim();
              if (name.isEmpty) return;
              final userId = ctx.read<AuthProvider>().currentUser!.id;
              provider.updateType(
                userId,
                ItemType(
                  id: type.id,
                  name: name,
                  icon: icon.isEmpty ? '🏷️' : icon,
                ),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Desar'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteType(
    BuildContext context,
    PantryProvider provider,
    ItemType type,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar tipus'),
        content: Text(
          'Vols eliminar el tipus "${type.name}"?\n'
          'Els productes amb aquest tipus no es veuran afectats.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel·lar'),
          ),
          TextButton(
            onPressed: () {
              final userId = ctx.read<AuthProvider>().currentUser!.id;
              provider.deleteType(userId, type.id);
              Navigator.pop(ctx);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ─── UBICACIONS ─────────────────────────────────────────

class _LocationsTab extends StatelessWidget {
  const _LocationsTab();

  @override
  Widget build(BuildContext context) {
    final pantryProvider = context.watch<PantryProvider>();
    final locations = pantryProvider.locations;

    return Scaffold(
      body: locations.isEmpty
          ? const Center(child: Text('No hi ha ubicacions definides'))
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: locations.length,
              itemBuilder: (context, index) {
                final loc = locations[index];
                return ListTile(
                  leading: Text(loc.icon, style: const TextStyle(fontSize: 28)),
                  title: Text(loc.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _showEditLocationDialog(
                          context,
                          pantryProvider,
                          loc,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          size: 20,
                          color: Colors.red,
                        ),
                        onPressed: () => _confirmDeleteLocation(
                          context,
                          pantryProvider,
                          loc,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddLocationDialog(context, pantryProvider),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddLocationDialog(BuildContext context, PantryProvider provider) {
    final nameController = TextEditingController();
    final iconController = TextEditingController(text: '📦');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nova ubicació'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: iconController,
              decoration: const InputDecoration(
                labelText: 'Emoji/Icona',
                hintText: '📦',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Nom de la ubicació",
                hintText: 'ex: Prestatge superior',
              ),
              textCapitalization: TextCapitalization.sentences,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel·lar'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              final icon = iconController.text.trim();
              if (name.isEmpty) return;
              final userId = ctx.read<AuthProvider>().currentUser!.id;
              provider.addLocation(
                userId,
                ItemLocation(name: name, icon: icon.isEmpty ? '📦' : icon),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Afegir'),
          ),
        ],
      ),
    );
  }

  void _showEditLocationDialog(
    BuildContext context,
    PantryProvider provider,
    ItemLocation loc,
  ) {
    final nameController = TextEditingController(text: loc.name);
    final iconController = TextEditingController(text: loc.icon);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar ubicació'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: iconController,
              decoration: const InputDecoration(labelText: 'Emoji/Icona'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Nom de la ubicació",
              ),
              textCapitalization: TextCapitalization.sentences,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel·lar'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              final icon = iconController.text.trim();
              if (name.isEmpty) return;
              final userId = ctx.read<AuthProvider>().currentUser!.id;
              provider.updateLocation(
                userId,
                ItemLocation(
                  id: loc.id,
                  name: name,
                  icon: icon.isEmpty ? '📦' : icon,
                ),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Desar'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteLocation(
    BuildContext context,
    PantryProvider provider,
    ItemLocation loc,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar ubicació'),
        content: Text(
          'Vols eliminar la ubicació "${loc.name}"?\n'
          'Els productes amb aquesta ubicació no es veuran afectats.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel·lar'),
          ),
          TextButton(
            onPressed: () {
              final userId = ctx.read<AuthProvider>().currentUser!.id;
              provider.deleteLocation(userId, loc.id);
              Navigator.pop(ctx);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
