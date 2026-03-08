import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pantry_item.dart';
import '../providers/auth_provider.dart';
import '../providers/pantry_provider.dart';
import '../theme/app_theme.dart';

class PantryItemFormScreen extends StatefulWidget {
  final PantryItem? item;

  const PantryItemFormScreen({super.key, this.item});

  @override
  State<PantryItemFormScreen> createState() => _PantryItemFormScreenState();
}

class _PantryItemFormScreenState extends State<PantryItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();

  String? _selectedTypeId;
  String? _selectedLocationId;
  DateTime? _purchaseDate;
  DateTime? _expiryDate;
  DateTime? _openedDate;
  PantryItemStatus _status = PantryItemStatus.tancat;

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final item = widget.item!;
      _nameController.text = item.name;
      _quantityController.text = item.quantity;
      _selectedTypeId = item.typeId;
      _selectedLocationId = item.locationId;
      _purchaseDate = item.purchaseDate;
      _expiryDate = item.expiryDate;
      _openedDate = item.openedDate;
      _status = item.status;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pantryProvider = context.watch<PantryProvider>();
    final types = pantryProvider.types;
    final locations = pantryProvider.locations;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar producte' : 'Nou producte'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Eliminar producte',
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Nom del producte
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
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantitat *',
                hintText: 'ex: 1 litre, 500g, 3 unitats',
                prefixIcon: Icon(Icons.numbers),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'La quantitat és obligatòria';
                }
                return null;
              },
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
            const SizedBox(height: 24),

            // Secció de dates
            Text(
              'Dates',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Les dates són opcionals però ajuden a controlar la caducitat.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),

            // Data de compra
            _DateField(
              label: 'Data de compra',
              icon: Icons.shopping_bag,
              date: _purchaseDate,
              onTap: () => _pickDate(
                initial: _purchaseDate,
                onPicked: (date) => setState(() => _purchaseDate = date),
              ),
              onClear: () => setState(() => _purchaseDate = null),
            ),
            const SizedBox(height: 12),

            // Data de caducitat
            _DateField(
              label: 'Data de caducitat',
              icon: Icons.event,
              date: _expiryDate,
              isWarning:
                  _expiryDate != null && _expiryDate!.isBefore(DateTime.now()),
              onTap: () => _pickDate(
                initial: _expiryDate,
                onPicked: (date) => setState(() => _expiryDate = date),
              ),
              onClear: () => setState(() => _expiryDate = null),
            ),
            const SizedBox(height: 12),

            // Data d'obertura (si s'edita)
            if (_isEditing) ...[
              _DateField(
                label: "Data d'obertura",
                icon: Icons.lock_open,
                date: _openedDate,
                onTap: () => _pickDate(
                  initial: _openedDate,
                  onPicked: (date) => setState(() => _openedDate = date),
                ),
                onClear: () => setState(() => _openedDate = null),
              ),
              const SizedBox(height: 16),

              // Estat (només si s'edita)
              DropdownButtonFormField<PantryItemStatus>(
                initialValue: _status,
                decoration: const InputDecoration(
                  labelText: 'Estat',
                  prefixIcon: Icon(Icons.info_outline),
                ),
                items: PantryItemStatus.values.map((status) {
                  final label = switch (status) {
                    PantryItemStatus.tancat => 'Tancat',
                    PantryItemStatus.encetat => 'Encetat',
                    PantryItemStatus.consumit => 'Consumit',
                    PantryItemStatus.llencat => 'Llençat',
                  };
                  return DropdownMenuItem(value: status, child: Text(label));
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _status = value);
                },
              ),
            ],

            const SizedBox(height: 32),

            // Botó guardar
            FilledButton.icon(
              onPressed: _save,
              icon: Icon(_isEditing ? Icons.save : Icons.add),
              label: Text(_isEditing ? 'Desar canvis' : 'Afegir al rebost'),
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

  Future<void> _pickDate({
    DateTime? initial,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('ca'),
      helpText: 'Selecciona una data',
      cancelText: 'Cancel·lar',
      confirmText: 'Acceptar',
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = context.read<AuthProvider>().currentUser!.id;
    final pantryProvider = context.read<PantryProvider>();

    if (_isEditing) {
      final updatedItem = widget.item!.copyWith(
        name: _nameController.text.trim(),
        quantity: _quantityController.text.trim(),
        typeId: _selectedTypeId!,
        locationId: _selectedLocationId!,
        purchaseDate: _purchaseDate,
        expiryDate: _expiryDate,
        openedDate: _openedDate,
        status: _status,
      );
      await pantryProvider.updateItem(userId, updatedItem);
    } else {
      final newItem = PantryItem(
        name: _nameController.text.trim(),
        quantity: _quantityController.text.trim(),
        typeId: _selectedTypeId!,
        locationId: _selectedLocationId!,
        purchaseDate: _purchaseDate,
        expiryDate: _expiryDate,
      );
      await pantryProvider.addItem(userId, newItem);
    }

    if (mounted) Navigator.pop(context, true);
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar producte'),
        content: Text(
          'Vols eliminar "${widget.item!.name}" del rebost? '
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
              await context.read<PantryProvider>().deleteItem(
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

class _DateField extends StatelessWidget {
  final String label;
  final IconData icon;
  final DateTime? date;
  final VoidCallback onTap;
  final VoidCallback onClear;
  final bool isWarning;

  const _DateField({
    required this.label,
    required this.icon,
    this.date,
    required this.onTap,
    required this.onClear,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: isWarning ? Colors.red : null),
          suffixIcon: date != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: onClear,
                )
              : const Icon(Icons.calendar_today, size: 20),
          border: const OutlineInputBorder(),
        ),
        child: Text(
          date != null
              ? '${date!.day.toString().padLeft(2, '0')}/'
                    '${date!.month.toString().padLeft(2, '0')}/'
                    '${date!.year}'
              : 'Sense data',
          style: TextStyle(
            color: date != null
                ? (isWarning ? Colors.red : null)
                : Colors.grey[500],
          ),
        ),
      ),
    );
  }
}
