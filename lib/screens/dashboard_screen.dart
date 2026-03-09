import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/notification_model.dart';
import '../models/pantry_item.dart';
import '../models/shopping_item.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/pantry_provider.dart';
import '../providers/shared_pantry_provider.dart';
import '../providers/shopping_provider.dart';
import '../theme/app_theme.dart';
import 'profile_screen.dart';
import 'pantry_screen.dart';
import 'recipes_screen.dart';
import 'shopping_list_screen.dart';
import 'invite_user_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications();
      _loadSharedPantry();
    });
  }

  Future<void> _loadNotifications() async {
    final authProvider = context.read<AuthProvider>();
    final notifProvider = context.read<NotificationProvider>();
    final pantryProvider = context.read<PantryProvider>();
    if (authProvider.currentUser != null) {
      final userId = authProvider.currentUser!.id;
      await pantryProvider.loadAll(userId);
      await notifProvider.checkExpiryNotifications(
        userId,
        pantryProvider.allItems,
      );
      await notifProvider.loadNotifications(userId);
    }
  }

  Future<void> _loadSharedPantry() async {
    final authProvider = context.read<AuthProvider>();
    final sharedProvider = context.read<SharedPantryProvider>();
    if (authProvider.currentUser != null) {
      await sharedProvider.loadAll(authProvider.currentUser!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser!;

    final screens = [
      _DashboardHome(
        onNavigate: (index) => setState(() => _currentIndex = index),
      ),
      const PantryScreen(),
      const RecipesScreen(),
      const ShoppingListScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: _currentIndex == 0
            ? const Text('Rebost')
            : Text(_getTitle(_currentIndex)),
        actions: [
          if (_currentIndex == 0) ...[
            // Botó d'invitació
            IconButton(
              icon: const Icon(Icons.person_add),
              tooltip: 'Convidar al rebost',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InviteUserScreen()),
              ),
            ),
            // Invitacions pendents
            Consumer<SharedPantryProvider>(
              builder: (context, sharedProvider, _) {
                final pending = sharedProvider.pendingInvitations;
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.mail_outline),
                      tooltip: 'Invitacions pendents',
                      onPressed: () => _showPendingInvitations(context),
                    ),
                    if (pending.isNotEmpty)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${pending.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            Consumer<NotificationProvider>(
              builder: (context, notifProvider, _) {
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      onPressed: () => _showNotifications(context),
                    ),
                    if (notifProvider.unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppTheme.accentColor,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${notifProvider.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
          // Icona de l'usuari
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                child: Text(
                  user.name[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Inici'),
          BottomNavigationBarItem(icon: Icon(Icons.kitchen), label: 'Rebost'),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Receptes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Compra',
          ),
        ],
      ),
    );
  }

  String _getTitle(int index) {
    switch (index) {
      case 1:
        return 'El meu rebost';
      case 2:
        return 'Els meus llibres de receptes';
      case 3:
        return 'Llista de la compra';
      default:
        return 'Rebost';
    }
  }

  void _showPendingInvitations(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final sharedProvider = context.read<SharedPantryProvider>();
    final pantryProvider = context.read<PantryProvider>();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final pending = sharedProvider.pendingInvitations;
        if (pending.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mail_outline, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No tens invitacions pendents',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          itemCount: pending.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Invitacions pendents',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              );
            }
            final inv = pending[index - 1];
            final fromUser = authProvider.getUserById(inv.fromUserId);
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryColor,
                  child: Text(
                    fromUser?.name[0].toUpperCase() ?? '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(fromUser?.name ?? 'Usuari desconegut'),
                subtitle: Text('Vol compartir el seu rebost amb tu'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      tooltip: 'Rebutjar',
                      onPressed: () async {
                        final userId = authProvider.currentUser!.id;
                        await sharedProvider.rejectInvitation(inv.id, userId);
                        if (context.mounted) Navigator.pop(ctx);
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.check,
                        color: AppTheme.primaryColor,
                      ),
                      tooltip: 'Acceptar',
                      onPressed: () async {
                        Navigator.pop(ctx);
                        _confirmAcceptInvitation(
                          context,
                          inv,
                          sharedProvider,
                          authProvider,
                          pantryProvider,
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmAcceptInvitation(
    BuildContext context,
    dynamic invitation,
    SharedPantryProvider sharedProvider,
    AuthProvider authProvider,
    PantryProvider pantryProvider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Acceptar invitació'),
        content: const Text(
          '⚠️ Si acceptes, les teves dades actuals del rebost es perdran '
          'i passaràs a compartir el rebost de l\'altra persona.\n\n'
          'Totes les modificacions es sincronitzaran entre tots els membres.\n\n'
          'Vols continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel·lar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final userId = authProvider.currentUser!.id;
              await sharedProvider.acceptInvitation(invitation.id, userId);
              // Reload pantry with new effective owner
              if (authProvider.currentUser != null) {
                await pantryProvider.loadAll(authProvider.currentUser!.id);
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Invitació acceptada! Ara comparteixes el rebost.',
                    ),
                    backgroundColor: AppTheme.primaryColor,
                  ),
                );
              }
            },
            child: const Text('Acceptar'),
          ),
        ],
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final notifProvider = context.read<NotificationProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notificacions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (notifProvider.unreadCount > 0)
                    TextButton(
                      onPressed: () {
                        notifProvider.markAllAsRead(
                          authProvider.currentUser!.id,
                        );
                      },
                      child: const Text('Marcar totes com a llegides'),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: notifProvider.notifications.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_off,
                            size: 48,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No tens notificacions',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: notifProvider.notifications.length,
                      itemBuilder: (context, index) {
                        final notif = notifProvider.notifications[index];
                        return _NotificationTile(
                          notification: notif,
                          onTap: () {
                            if (!notif.isRead) {
                              notifProvider.markAsRead(
                                authProvider.currentUser!.id,
                                notif.id,
                              );
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardHome extends StatelessWidget {
  final void Function(int) onNavigate;

  const _DashboardHome({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser!;
    final notifProvider = context.watch<NotificationProvider>();
    final pantryProvider = context.watch<PantryProvider>();

    // Productes actius amb data de caducitat dins dels propers 5 dies (o ja caducats)
    final expiringItems =
        pantryProvider.allItems.where((item) {
            if (!item.isActive || item.expiryDate == null) return false;
            final days = item.daysUntilExpiry!;
            return days <= 5; // incloem caducats (negatiu) i fins a 5 dies
          }).toList()
          ..sort((a, b) => a.daysUntilExpiry!.compareTo(b.daysUntilExpiry!));

    return RefreshIndicator(
      onRefresh: () async {
        await pantryProvider.loadAll(user.id);
        await notifProvider.loadNotifications(user.id);
        await notifProvider.checkExpiryNotifications(
          user.id,
          pantryProvider.allItems,
        );
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Salutació
            Text(
              'Hola, ${user.name}! 👋',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              _getGreeting(),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            // Notificacions recents
            if (notifProvider.notifications.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notificacions recents',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (notifProvider.unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${notifProvider.unreadCount} noves',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              ...notifProvider.notifications
                  .take(3)
                  .map(
                    (notif) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _NotificationCard(notification: notif),
                    ),
                  ),
              const SizedBox(height: 16),
            ],

            // Productes a punt de caducar
            if (expiringItems.isNotEmpty) ...[
              Text(
                'Productes a punt de caducar',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...expiringItems.map(
                (item) => _ExpiryItemCard(
                  item: item,
                  onDiscard: () =>
                      _discardItem(context, item, pantryProvider, user.id),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Accesos ràpids
            Text(
              'Accés ràpid',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickAccessCard(
                    icon: Icons.kitchen,
                    label: 'El meu\nrebost',
                    color: AppTheme.primaryColor,
                    onTap: () => onNavigate(1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickAccessCard(
                    icon: Icons.menu_book,
                    label: 'Llibres de\nreceptes',
                    color: AppTheme.secondaryColor,
                    onTap: () => onNavigate(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickAccessCard(
                    icon: Icons.shopping_cart,
                    label: 'Llista de\nla compra',
                    color: AppTheme.accentColor,
                    onTap: () => onNavigate(3),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bon dia! Què necessites avui?';
    if (hour < 20) return 'Bona tarda! Què necessites avui?';
    return 'Bona nit! Què necessites avui?';
  }

  void _discardItem(
    BuildContext context,
    PantryItem item,
    PantryProvider pantryProvider,
    String userId,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Llençar producte'),
        content: Text(
          'Vols llençar "${item.name}"?\n'
          'Aquest producte ${item.isExpired ? "ja ha caducat" : "està a punt de caducar"}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel·lar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await pantryProvider.discardItem(
                userId,
                item.id,
                qty: item.quantity,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${item.name} llençat'),
                    backgroundColor: Colors.orange,
                  ),
                );
                // Preguntar si vol afegir a la llista de la compra
                _askAddToShoppingList(context, item, userId);
              }
            },
            child: const Text('Llençar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _askAddToShoppingList(
    BuildContext context,
    PantryItem item,
    String userId,
  ) {
    int shoppingQty = item.quantity;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Afegir a la compra?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Vols afegir "${item.name}" a la llista de la compra?'),
              const SizedBox(height: 16),
              Text(
                'Quantes unitats?',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: shoppingQty > 1
                        ? () => setDialogState(() => shoppingQty--)
                        : null,
                    iconSize: 32,
                  ),
                  SizedBox(
                    width: 60,
                    child: Text(
                      '$shoppingQty',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => setDialogState(() => shoppingQty++),
                    iconSize: 32,
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final shoppingProvider = context.read<ShoppingProvider>();
                final shoppingItem = ShoppingItem(
                  name: item.name,
                  quantity: shoppingQty,
                  unit: item.unit,
                  typeId: item.typeId,
                  locationId: item.locationId,
                );
                await shoppingProvider.addItem(userId, shoppingItem);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '"${item.name}" afegit a la llista de la compra!',
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              child: const Text(
                'Afegir a la compra',
                style: TextStyle(color: Colors.orange),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpiryItemCard extends StatelessWidget {
  final PantryItem item;
  final VoidCallback onDiscard;

  const _ExpiryItemCard({required this.item, required this.onDiscard});

  @override
  Widget build(BuildContext context) {
    final days = item.daysUntilExpiry ?? 0;
    final color = _getExpiryColor(days);
    final daysText = _getDaysText(days);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          daysText,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
        trailing: days < 0
            ? TextButton.icon(
                onPressed: onDiscard,
                icon: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Colors.red,
                ),
                label: const Text(
                  'Llençar',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              )
            : Text(
                item.quantityDisplay,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
      ),
    );
  }

  Color _getExpiryColor(int days) {
    if (days <= 1) return Colors.red;
    if (days <= 3) return Colors.orange;
    return Colors.green;
  }

  String _getDaysText(int days) {
    if (days < 0) {
      final absDays = days.abs();
      return 'Caducat fa ${absDays == 1 ? "1 dia" : "$absDays dies"}';
    }
    if (days == 0) return 'Caduca avui!';
    if (days == 1) return 'Caduca demà';
    return 'Caduca en $days dies';
  }
}

class _QuickAccessCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAccessCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;

  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: notification.isRead
          ? null
          : AppTheme.primaryColor.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_getIcon(), color: _getColor(), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: notification.isRead
                          ? FontWeight.normal
                          : FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (notification.type) {
      case NotificationType.info:
        return Icons.info_outline;
      case NotificationType.warning:
        return Icons.warning_amber;
      case NotificationType.success:
        return Icons.check_circle_outline;
      case NotificationType.reminder:
        return Icons.alarm;
      case NotificationType.expiry:
        return Icons.event_busy;
    }
  }

  Color _getColor() {
    switch (notification.type) {
      case NotificationType.info:
        return Colors.blue;
      case NotificationType.warning:
        return Colors.orange;
      case NotificationType.success:
        return AppTheme.primaryColor;
      case NotificationType.reminder:
        return Colors.purple;
      case NotificationType.expiry:
        return Colors.red;
    }
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getColor().withValues(alpha: 0.1),
        child: Icon(_getIcon(), color: _getColor(), size: 20),
      ),
      title: Text(
        notification.title,
        style: TextStyle(
          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
        ),
      ),
      subtitle: Text(
        notification.message,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: notification.isRead
          ? null
          : Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
            ),
      onTap: onTap,
    );
  }

  IconData _getIcon() {
    switch (notification.type) {
      case NotificationType.info:
        return Icons.info_outline;
      case NotificationType.warning:
        return Icons.warning_amber;
      case NotificationType.success:
        return Icons.check_circle_outline;
      case NotificationType.reminder:
        return Icons.alarm;
      case NotificationType.expiry:
        return Icons.event_busy;
    }
  }

  Color _getColor() {
    switch (notification.type) {
      case NotificationType.info:
        return Colors.blue;
      case NotificationType.warning:
        return Colors.orange;
      case NotificationType.success:
        return AppTheme.primaryColor;
      case NotificationType.reminder:
        return Colors.purple;
      case NotificationType.expiry:
        return Colors.red;
    }
  }
}
