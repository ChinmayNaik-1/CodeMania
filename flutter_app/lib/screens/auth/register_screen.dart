import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:codemania/providers/auth_provider.dart';
import 'package:codemania/core/theme/app_theme.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _handleRegister(WidgetRef ref) async {
    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 100));

    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (username.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    if (password.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }

    if (password != confirmPassword) {
      _showError('Passwords do not match');
      return;
    }

    final error = await ref.read(authProvider.notifier).register(username, email, password);

    if (error == null && mounted) {
      context.go('/home');
    } else if (error != null && mounted) {
      _showError(error);
    }
  }

  Future<void> _handleGoogleSignUp(WidgetRef ref) async {
    final error = await ref.read(authProvider.notifier).loginWithGoogle();

    if (error != null && mounted) {
      _showError(error);
      return;
    }

    if (!mounted) return;
    final authState = ref.read(authProvider);
    if (authState.pendingGoogleSignup) {
      context.go('/google-signup-complete');
      return;
    }

    if (authState.user?.isAdmin == true) {
      context.go('/admin');
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: Icon(Icons.close, color: colorScheme.onBackground),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      '{ }',
                      style: textTheme.displayLarge?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Start CodeMania',
                    textAlign: TextAlign.center,
                    style: textTheme.displayMedium,
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _usernameController,
                          enabled: !authState.isLoading,
                          style: TextStyle(color: colorScheme.onSurface),
                          decoration: InputDecoration(
                            hintText: 'Username',
                            hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        Divider(color: colorScheme.outline, height: 24),
                        TextField(
                          controller: _emailController,
                          enabled: !authState.isLoading,
                          style: TextStyle(color: colorScheme.onSurface),
                          decoration: InputDecoration(
                            hintText: 'Email',
                            hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        Divider(color: colorScheme.outline, height: 24),
                        TextField(
                          controller: _passwordController,
                          enabled: !authState.isLoading,
                          obscureText: _obscurePassword,
                          style: TextStyle(color: colorScheme.onSurface),
                          decoration: InputDecoration(
                            hintText: 'Password',
                            hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ),
                        ),
                        Divider(color: colorScheme.outline, height: 24),
                        TextField(
                          controller: _confirmPasswordController,
                          enabled: !authState.isLoading,
                          obscureText: _obscureConfirmPassword,
                          style: TextStyle(color: colorScheme.onSurface),
                          decoration: InputDecoration(
                            hintText: 'Confirm Password',
                            hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                });
                              },
                              icon: Icon(
                                _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                color: colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: authState.isLoading ? null : () => _handleRegister(ref),
                      child: authState.isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : const Text('Create Account'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Already have an account? Sign in'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
