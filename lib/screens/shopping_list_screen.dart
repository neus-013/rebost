import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/shopping_item.dart';
import '../providers/auth_provider.dart';
import '../providers/pantry_provider.dart';
import '../providers/shopping_provider.dart';
import '../theme/app_theme.dart';
import 'shopping_item_form_screen.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final userId = context.read<AuthProvider>().currentUser!.id;
    await context.read<ShoppingProvider>().loadItems(userId);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final shoppingProvider = context.watch<ShoppingProvider>();
    final pantryProvider = context.watch<PantryProvider>();
    final userId = authProvider.currentUser!.id;

    return Scaffold(
      body: Column(
        children: [
          // Barra de selecció
          if (shoppingProvider.selectionMode)
            _buildSelectionBar(shoppingProvider, userId),

          // Llista
          Expanded(
            child: shoppingProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : shoppingProvider.items.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 140),
                      itemCount: shoppingProvider.items.length,
                      itemBuilder: (context, index) {
                        final item = shoppingProvider.items[index];
                        final type = pantryProvider.getTypeById(item.typeId);
                        final location =
                            pantryProvider.getLocationById(item.locationId);
                        final isSelected = shoppingProvider.isSelected(item.id);

                        return _ShoppingItemTile(
                          item: item,
                          typeIcon: type?.icon ?? '🏷️',
                          typeName: type?.name ?? 'Desconegut',
                          locationName: location != null
                              ? '${location.icon} ${location.name}'
                              : null,
                          isSelected: isSelected,
                          selectionMode: shoppingProvider.selectionMode,
                          onTap: () {
                            if (shoppingProvider.selectionMode) {
                              shoppingProvider.toggleSelection(item.id);
                            } else {
                              _editItem(item);
                            }
                          },
                          onLongPress: () {
                            shoppingProvider.toggleSelection(item.id);
                          },
                          onBuy: () => _buyItem(userId, item),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Botó comprar tot
          if (shoppingProvider.items.isNotEmpty &&
              !shoppingProvider.selectionMode)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FloatingActionButton.extended(
                heroTag: 'buyAll',
                onPressed: () => _buyAll(userId),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.shopping_bag),
                label: const Text('Comprar tot'),
              ),
            ),
          // Botó afegir
          FloatingActionButton.extended(
            heroTag: 'addItem',
            onPressed: () => _addItem(),
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('Afegir'),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionBar(ShoppingProvider provider, String userId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.primaryColor.withValues(alpha: 0.1),
      child: Row(
        children: [
          Text(
            '${provider.selectedCount} seleccionat(s)',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          TextButton(
            onPressed: provider.allSelected
                ? () => provider.clearSelection()
                : () => provider.selectAll(),
            child: Text(
              provider.allSelected ? 'Deseleccionar tot' : 'Seleccionar tot',
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () => _buySelected(userId),
            icon: const Icon(Icons.shopping_bag, size: 18),
            label: const Text('Comprar'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => provider.clearSelection(),
            tooltip: 'Cancel·lar selecció',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'La llista de la compra és buida',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Afegeix productes prement el botó +',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _addItem() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ShoppingItemFormScreen()),
    );
    if (result == true && mounted) _loadData();
  }

  void _editItem(ShoppingItem item) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ShoppingItemFormScreen(item: item)),
    );
    if (result == true && mounted) _loadData();
  }

  Future<void> _buyItem(String userId, ShoppingItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Comprar producte'),
        content: Text(
          'Vols comprar "${item.name}" (${item.quantityDisplay})?\n'
          "S'afegirà al rebost amb la data de compra d'avui.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel·lar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Comprar',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<ShoppingProvider>().buySingleItem(userId, item);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${item.name}" afegit al rebost!'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
        // Recarregar el rebost
        context.read<PantryProvider>().loadAll(userId);
      }
    }
  }

  Future<void> _buySelected(String userId) async {
    final provider = context.read<ShoppingProvider>();
    final count = provider.selectedCount;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Comprar seleccionats'),
        content: Text(
          'Vols comprar $count producte(s) seleccionat(s)?\n'
          "S'afegiran al rebost amb la data de compra d'avui.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel·lar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Comprar',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final bought = await provider.buySelectedItems(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$bought producte(s) afegit(s) al rebost!'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
        context.read<PantryProvider>().loadAll(userId);
      }
    }
  }

  Future<void> _buyAll(String userId) async {
    final provider = context.read<ShoppingProvider>();
    final count = provider.items.length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Comprar tot'),
        content: Text(
          'Vols comprar tots els $count producte(s) de la llista?\n'
          "S'afegiran al rebost amb la data de compra d'avui.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel·lar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Comprar tot',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final bought = await provider.buyAllItems(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$bought producte(s) afegit(s) al rebost!'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
        context.read<PantryProvider>().loadAll(userId);
      }
    }
  }
}

// ============ WIDGETS ============

class _ShoppingItemTile extends StatelessWidget {
  final ShoppingItem item;
  final String typeIcon;
  final String typeName;
  final String? locationName;
  final bool isSelected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onBuy;

  const _ShoppingItemTile({
    required this.item,
    required this.typeIcon,
    required this.typeName,
    this.locationName,
    required this.isSelected,
    required this.selectionMode,
    required this.onTap,
    required this.onLongPress,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: isSelected
          ? AppTheme.primaryColor.withValues(alpha: 0.08)
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? const BorderSide(color: AppTheme.primaryColor, width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Checkbox de selecció o icona
              if (selectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    isSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: isSelected ? AppTheme.primaryColor : Colors.grey,
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(typeIcon, style: const TextStyle(fontSize: 24)),
                ),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          item.quantityDisplay,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                        const Text(
                          ' · ',
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text(
                          typeName,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                        if (locationName != null) ...[
                          const Text(
                            ' · ',
                            style: TextStyle(color: Colors.grey),
                          ),
                          Flexible(
                            child: Text(
                              locationName!,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Botó comprar individual
              if (!selectionMode)
                IconButton(
                  icon: const Icon(
                    Icons.shopping_bag_outlined,
                    color: Colors.orange,
                  ),
                  tooltip: 'Comprar',
                  onPressed: onBuy,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
