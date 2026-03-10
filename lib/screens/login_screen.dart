import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controladors comuns
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Controladors per al formulari de creació
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  /// true = formulari de crear compte, false = formulari de login
  bool _isCreateMode = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _formError;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo i títol
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.kitchen,
                    size: 60,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Rebost',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Gestiona el teu rebost de manera fàcil',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Selector de mode: Login / Crear compte
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: false,
                      label: Text('Iniciar sessió'),
                      icon: Icon(Icons.login),
                    ),
                    ButtonSegment(
                      value: true,
                      label: Text('Crear compte'),
                      icon: Icon(Icons.person_add),
                    ),
                  ],
                  selected: {_isCreateMode},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _isCreateMode = selection.first;
                      _formError = null;
                    });
                  },
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: AppTheme.primaryColor.withValues(
                      alpha: 0.15,
                    ),
                    selectedForegroundColor: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 32),

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // ── MODE LOGIN ──
                      if (!_isCreateMode) ...[
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Correu electrònic',
                            hintText: 'exemple@correu.cat',
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'El correu és obligatori';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Contrasenya',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'La contrasenya és obligatòria';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => _handleLogin(),
                        ),
                      ],

                      // ── MODE CREAR COMPTE ──
                      if (_isCreateMode) ...[
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nom',
                            hintText: 'Introdueix el teu nom',
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'El nom és obligatori';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Nom d\'usuari',
                            hintText: 'Ex: maria_garcia',
                            prefixIcon: Icon(Icons.alternate_email),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'El nom d\'usuari és obligatori';
                            }
                            if (value.trim().contains(' ')) {
                              return 'El nom d\'usuari no pot contenir espais';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Correu electrònic',
                            hintText: 'exemple@correu.cat',
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'El correu és obligatori';
                            }
                            if (!value.contains('@') || !value.contains('.')) {
                              return 'Introdueix un correu vàlid';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Contrasenya',
                            hintText: 'Mínim 6 caràcters',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'La contrasenya és obligatòria';
                            }
                            if (value.length < 6) {
                              return 'Mínim 6 caràcters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirm,
                          decoration: InputDecoration(
                            labelText: 'Confirma la contrasenya',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value != _passwordController.text) {
                              return 'Les contrasenyes no coincideixen';
                            }
                            return null;
                          },
                        ),
                      ],

                      if (_formError != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _formError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting
                              ? null
                              : _isCreateMode
                                  ? _handleSignUp
                                  : _handleLogin,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _isCreateMode
                                        ? 'Crear compte'
                                        : 'Iniciar sessió',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    setState(() => _formError = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final authProvider = context.read<AuthProvider>();
    final error = await authProvider.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _formError = error;
      });
    }
  }

  Future<void> _handleSignUp() async {
    setState(() => _formError = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final authProvider = context.read<AuthProvider>();
    final error = await authProvider.signUp(
      name: _nameController.text.trim(),
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _formError = error;
      });
    }
  }
}
