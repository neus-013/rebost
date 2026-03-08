import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pantry_item.dart';
import '../models/pantry_types.dart';
import '../providers/auth_provider.dart';
import '../providers/pantry_provider.dart';
import '../theme/app_theme.dart';
import 'pantry_item_form_screen.dart';
import 'pantry_manage_types_screen.dart';

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  final _searchController = TextEditingController();
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final userId = context.read<AuthProvider>().currentUser!.id;
    await context.read<PantryProvider>().loadAll(userId);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final pantryProvider = context.watch<PantryProvider>();
    final userId = authProvider.currentUser!.id;

    return Scaffold(
      body: Column(
        children: [
          // Barra de cerca i filtres
          _buildSearchBar(pantryProvider),
          if (_showFilters) _buildFilterChips(pantryProvider),

          // Resum ràpid
          if (pantryProvider.expiredCount > 0 ||
              pantryProvider.expiringSoonCount > 0)
            _buildAlertBanner(pantryProvider),

          // Llista d'items
          Expanded(
            child: pantryProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : pantryProvider.items.isEmpty
                ? _buildEmptyState(pantryProvider)
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: pantryProvider.items.length,
                      itemBuilder: (context, index) {
                        final item = pantryProvider.items[index];
                        return _PantryItemTile(
                          item: item,
                          type: pantryProvider.getTypeById(item.typeId),
                          location: pantryProvider.getLocationById(
                            item.locationId,
                          ),
                          onOpen: () =>
                              pantryProvider.openItem(userId, item.id),
                          onConsume: () => _showQuantityDialog(
                            context,
                            item: item,
                            title: 'Consumir producte',
                            actionLabel: 'Consumir',
                            actionColor: AppTheme.primaryColor,
                            onConfirm: (qty) =>
                                pantryProvider.consumeItem(userId, item.id, qty: qty),
                          ),
                          onDiscard: () => _showQuantityDialog(
                            context,
                            item: item,
                            title: 'Llençar producte',
                            actionLabel: 'Llençar',
                            actionColor: Colors.red,
                            onConfirm: (qty) =>
                                pantryProvider.discardItem(userId, item.id, qty: qty),
                          ),
                          onTap: () => _editItem(context, item),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addItem(context),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Afegir'),
      ),
    );
  }

  Widget _buildSearchBar(PantryProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cercar al rebost...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          provider.setSearchQuery('');
                        },
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) => provider.setSearchQuery(value),
            ),
          ),
          const SizedBox(width: 8),
          Badge(
            isLabelVisible:
                provider.filterTypeId != null ||
                provider.filterLocationId != null ||
                !provider.showOnlyActive,
            child: IconButton(
              icon: const Icon(Icons.tune),
              onPressed: () => setState(() => _showFilters = !_showFilters),
              style: IconButton.styleFrom(
                backgroundColor: _showFilters
                    ? AppTheme.primaryColor.withValues(alpha: 0.1)
                    : null,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Gestionar tipus i ubicacions',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PantryManageTypesScreen(),
                ),
              );
              if (mounted) _loadData();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(PantryProvider provider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          // Filtre actiu/tot
          FilterChip(
            label: Text(provider.showOnlyActive ? 'Actius' : 'Tots'),
            selected: !provider.showOnlyActive,
            onSelected: (selected) => provider.setShowOnlyActive(!selected),
          ),
          const SizedBox(width: 8),

          // Filtre per tipus
          PopupMenuButton<String?>(
            child: Chip(
              avatar: const Icon(Icons.category, size: 18),
              label: Text(
                provider.filterTypeId != null
                    ? (provider.getTypeById(provider.filterTypeId!)?.name ??
                          'Tipus')
                    : 'Tipus',
              ),
              deleteIcon: provider.filterTypeId != null
                  ? const Icon(Icons.close, size: 18)
                  : null,
              onDeleted: provider.filterTypeId != null
                  ? () => provider.setTypeFilter(null)
                  : null,
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('Tots els tipus')),
              ...provider.types.map(
                (type) => PopupMenuItem(
                  value: type.id,
                  child: Text('${type.icon} ${type.name}'),
                ),
              ),
            ],
            onSelected: (value) => provider.setTypeFilter(value),
          ),
          const SizedBox(width: 8),

          // Filtre per ubicació
          PopupMenuButton<String?>(
            child: Chip(
              avatar: const Icon(Icons.place, size: 18),
              label: Text(
                provider.filterLocationId != null
                    ? (provider
                              .getLocationById(provider.filterLocationId!)
                              ?.name ??
                          'Ubicació')
                    : 'Ubicació',
              ),
              deleteIcon: provider.filterLocationId != null
                  ? const Icon(Icons.close, size: 18)
                  : null,
              onDeleted: provider.filterLocationId != null
                  ? () => provider.setLocationFilter(null)
                  : null,
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('Totes les ubicacions'),
              ),
              ...provider.locations.map(
                (loc) => PopupMenuItem(
                  value: loc.id,
                  child: Text('${loc.icon} ${loc.name}'),
                ),
              ),
            ],
            onSelected: (value) => provider.setLocationFilter(value),
          ),
          const SizedBox(width: 8),

          if (provider.filterTypeId != null ||
              provider.filterLocationId != null ||
              !provider.showOnlyActive)
            ActionChip(
              avatar: const Icon(Icons.clear_all, size: 18),
              label: const Text('Netejar filtres'),
              onPressed: () {
                _searchController.clear();
                provider.clearFilters();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAlertBanner(PantryProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: provider.expiredCount > 0
            ? Colors.red.withValues(alpha: 0.1)
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: provider.expiredCount > 0
              ? Colors.red.withValues(alpha: 0.3)
              : Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber,
            color: provider.expiredCount > 0 ? Colors.red : Colors.orange,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              [
                if (provider.expiredCount > 0)
                  '${provider.expiredCount} producte(s) caducat(s)',
                if (provider.expiringSoonCount > 0)
                  '${provider.expiringSoonCount} a punt de caducar',
              ].join(' · '),
              style: TextStyle(
                color: provider.expiredCount > 0
                    ? Colors.red[700]
                    : Colors.orange[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(PantryProvider provider) {
    final hasFilters =
        provider.searchQuery.isNotEmpty ||
        provider.filterTypeId != null ||
        provider.filterLocationId != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasFilters ? Icons.search_off : Icons.kitchen,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              hasFilters
                  ? 'Cap producte trobat amb els filtres actuals'
                  : 'El teu rebost és buit',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'Prova a canviar els filtres de cerca'
                  : 'Afegeix el primer producte prement el botó +',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            if (hasFilters) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  _searchController.clear();
                  provider.clearFilters();
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Netejar filtres'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _addItem(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const PantryItemFormScreen()),
    );
    if (result == true && mounted) _loadData();
  }

  void _editItem(BuildContext context, PantryItem item) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PantryItemFormScreen(item: item)),
    );
    if (result == true && mounted) _loadData();
  }

  void _showQuantityDialog(
    BuildContext context, {
    required PantryItem item,
    required String title,
    required String actionLabel,
    required Color actionColor,
    required Future<void> Function(int qty) onConfirm,
  }) {
    if (item.quantity <= 1) {
      // Si només hi ha 1, no cal preguntar
      onConfirm(1);
      return;
    }

    int selectedQty = item.quantity;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${item.name} — tens ${item.quantity} ${item.unit}'),
              const SizedBox(height: 16),
              Text('Quantes unitats?',
                  style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: selectedQty > 1
                        ? () => setDialogState(() => selectedQty--)
                        : null,
                    iconSize: 32,
                  ),
                  SizedBox(
                    width: 60,
                    child: Text(
                      '$selectedQty',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: selectedQty < item.quantity
                        ? () => setDialogState(() => selectedQty++)
                        : null,
                    iconSize: 32,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setDialogState(() => selectedQty = item.quantity),
                child: const Text('Totes'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel·lar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                onConfirm(selectedQty);
              },
              child: Text(actionLabel, style: TextStyle(color: actionColor)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PantryItemTile extends StatelessWidget {
  final PantryItem item;
  final ItemType? type;
  final ItemLocation? location;
  final VoidCallback onOpen;
  final VoidCallback onConsume;
  final VoidCallback onDiscard;
  final VoidCallback onTap;

  const _PantryItemTile({
    required this.item,
    this.type,
    this.location,
    required this.onOpen,
    required this.onConsume,
    required this.onDiscard,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isExpired = item.isExpired;
    final isExpiringSoon = item.isExpiringSoon;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: isExpired
          ? Colors.red.withValues(alpha: 0.05)
          : isExpiringSoon
          ? Colors.orange.withValues(alpha: 0.05)
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isExpired
            ? BorderSide(color: Colors.red.withValues(alpha: 0.3))
            : isExpiringSoon
            ? BorderSide(color: Colors.orange.withValues(alpha: 0.3))
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Icona del tipus
                  Text(
                    type?.icon ?? '🏷️',
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            _StatusBadge(status: item.status),
                          ],
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
                            if (location != null) ...[
                              const Text(
                                ' · ',
                                style: TextStyle(color: Colors.grey),
                              ),
                              Text(
                                '${location!.icon} ${location!.name}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Info dates
              if (item.expiryDate != null ||
                  item.purchaseDate != null ||
                  item.openedDate != null) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    if (item.expiryDate != null)
                      _DateChip(
                        icon: Icons.event,
                        label: 'Cad: ${_formatDate(item.expiryDate!)}',
                        color: isExpired
                            ? Colors.red
                            : isExpiringSoon
                            ? Colors.orange
                            : Colors.grey[600]!,
                      ),
                    if (item.purchaseDate != null)
                      _DateChip(
                        icon: Icons.shopping_bag,
                        label: 'Compra: ${_formatDate(item.purchaseDate!)}',
                        color: Colors.grey[600]!,
                      ),
                    if (item.openedDate != null)
                      _DateChip(
                        icon: Icons.lock_open,
                        label: 'Encetat: ${_formatDate(item.openedDate!)}',
                        color: Colors.blue,
                      ),
                  ],
                ),
              ],

              // Botons d'acció
              if (item.isActive) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (item.status == PantryItemStatus.tancat)
                      _ActionButton(
                        icon: Icons.lock_open,
                        label: 'Encetar',
                        color: Colors.blue,
                        onPressed: onOpen,
                      ),
                    const SizedBox(width: 8),
                    _ActionButton(
                      icon: Icons.check_circle_outline,
                      label: 'Consumir',
                      color: AppTheme.primaryColor,
                      onPressed: onConsume,
                    ),
                    const SizedBox(width: 8),
                    _ActionButton(
                      icon: Icons.delete_outline,
                      label: 'Llençar',
                      color: Colors.red,
                      onPressed: onDiscard,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

class _StatusBadge extends StatelessWidget {
  final PantryItemStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      PantryItemStatus.tancat => ('Tancat', Colors.grey),
      PantryItemStatus.encetat => ('Encetat', Colors.blue),
      PantryItemStatus.consumit => ('Consumit', AppTheme.primaryColor),
      PantryItemStatus.llencat => ('Llençat', Colors.red),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _DateChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 12)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
