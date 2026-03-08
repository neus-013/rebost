import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/notification_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RebostApp());
}

class RebostApp extends StatelessWidget {
  const RebostApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        title: 'Rebost',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.kitchen,
                size: 64,
                color: AppTheme.primaryColor,
              ),
              SizedBox(height: 16),
              CircularProgressIndicator(
                color: AppTheme.primaryColor,
              ),
              SizedBox(height: 16),
              Text('Carregant...'),
            ],
          ),
        ),
      );
    }

    if (authProvider.isLoggedIn) {
      return const DashboardScreen();
    }

    return const LoginScreen();
  }
}
