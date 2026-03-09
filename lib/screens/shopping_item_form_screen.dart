import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/shopping_item.dart';
import '../providers/auth_provider.dart';
import '../providers/pantry_provider.dart';
import '../providers/shopping_provider.dart';
import '../theme/app_theme.dart';

class ShoppingItemFormScreen extends StatefulWidget {
  final ShoppingItem? item;

  const ShoppingItemFormScreen({super.key, this.item});

  @override
  State<ShoppingItemFormScreen> createState() => _ShoppingItemFormScreenState();
}

class _ShoppingItemFormScreenState extends State<ShoppingItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  int _quantity = 1;

  String? _selectedTypeId;
  String? _selectedLocationId;

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final item = widget.item!;
      _nameController.text = item.name;
      _quantity = item.quantity;
      _selectedTypeId = item.typeId;
      _selectedLocationId = item.locationId;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pantryProvider = context.watch<PantryProvider>();
    final types = pantryProvider.types;
    final locations = pantryProvider.locations;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar article' : 'Nou article'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Eliminar article',
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Nom
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom del producte *',
                hintText: 'ex: Llet sencera',
                prefixIcon: Icon(Icons.label),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El nom és obligatori';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Quantitat
            Row(
              children: [
                const Icon(Icons.numbers, color: Colors.grey),
                const SizedBox(width: 12),
                Text(
                  'Quantitat:',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const Spacer(),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: _quantity > 1
                            ? () => setState(() => _quantity--)
                            : null,
                        iconSize: 20,
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                      ),
                      SizedBox(
                        width: 40,
                        child: Text(
                          '$_quantity',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => setState(() => _quantity++),
                        iconSize: 20,
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _quantity == 1 ? 'unitat' : 'unitats',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tipus
            DropdownButtonFormField<String>(
              initialValue: _selectedTypeId,
              decoration: const InputDecoration(
                labelText: 'Tipus *',
                prefixIcon: Icon(Icons.category),
              ),
              items: types.map((type) {
                return DropdownMenuItem(
                  value: type.id,
                  child: Text('${type.icon} ${type.name}'),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedTypeId = value),
              validator: (value) {
                if (value == null) return 'Selecciona un tipus';
                return null;
              },
              isExpanded: true,
            ),
            const SizedBox(height: 16),

            // Ubicació
            DropdownButtonFormField<String>(
              initialValue: _selectedLocationId,
              decoration: const InputDecoration(
                labelText: 'Ubicació *',
                prefixIcon: Icon(Icons.place),
              ),
              items: locations.map((loc) {
                return DropdownMenuItem(
                  value: loc.id,
                  child: Text('${loc.icon} ${loc.name}'),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedLocationId = value),
              validator: (value) {
                if (value == null) return 'Selecciona una ubicació';
                return null;
              },
              isExpanded: true,
            ),
            const SizedBox(height: 32),

            // Botó guardar
            FilledButton.icon(
              onPressed: _save,
              icon: Icon(_isEditing ? Icons.save : Icons.add),
              label: Text(_isEditing ? 'Desar canvis' : 'Afegir a la llista'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = context.read<AuthProvider>().currentUser!.id;
    final shoppingProvider = context.read<ShoppingProvider>();

    if (_isEditing) {
      final updatedItem = widget.item!.copyWith(
        name: _nameController.text.trim(),
        quantity: _quantity,
        typeId: _selectedTypeId!,
        locationId: _selectedLocationId!,
      );
      await shoppingProvider.updateItem(userId, updatedItem);
    } else {
      final newItem = ShoppingItem(
        name: _nameController.text.trim(),
        quantity: _quantity,
        typeId: _selectedTypeId!,
        locationId: _selectedLocationId!,
      );
      await shoppingProvider.addItem(userId, newItem);
    }

    if (mounted) Navigator.pop(context, true);
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar article'),
        content: Text(
          'Vols eliminar "${widget.item!.name}" de la llista de la compra? '
          'Aquesta acció no es pot desfer.',
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
              await context.read<ShoppingProvider>().deleteItem(
                userId,
                widget.item!.id,
              );
              if (mounted) Navigator.pop(context, true);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
