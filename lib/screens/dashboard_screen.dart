import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/notification_model.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../theme/app_theme.dart';
import 'profile_screen.dart';
import 'pantry_screen.dart';
import 'recipes_screen.dart';
import 'shopping_list_screen.dart';

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
    });
  }

  Future<void> _loadNotifications() async {
    final authProvider = context.read<AuthProvider>();
    final notifProvider = context.read<NotificationProvider>();
    if (authProvider.currentUser != null) {
      await notifProvider.loadNotifications(authProvider.currentUser!.id);
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
          if (_currentIndex == 0)
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

    return RefreshIndicator(
      onRefresh: () async {
        await notifProvider.loadNotifications(user.id);
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
    }
  }
}
