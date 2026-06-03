import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:codemania/providers/auth_provider.dart';
import 'package:codemania/core/theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  bool _isNavigating = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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

  Future<void> _handleLogin(WidgetRef ref) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    final error = await ref.read(authProvider.notifier).login(email, password);
    if (error != null && mounted) {
      _showError(error);
    } else if (!_isNavigating && mounted) {
      _isNavigating = true;
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;

      final authState = ref.read(authProvider);
      if (authState.user?.isAdmin == true) {
        context.go('/admin');
      } else {
        context.go('/home');
      }
    }
  }

  Future<void> _handleGoogleSignIn(WidgetRef ref) async {
    final error = await ref.read(authProvider.notifier).loginWithGoogle();
    if (error != null && mounted) {
      _showError(error);
      return;
    }

    if (!_isNavigating && mounted) {
      _isNavigating = true;
      await Future.delayed(const Duration(milliseconds: 100));
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
                          controller: _emailController,
                          enabled: !authState.isLoading,
                          style: TextStyle(color: colorScheme.onSurface),
                          decoration: InputDecoration(
                            hintText: 'Email or Username',
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: authState.isLoading ? null : () => _handleLogin(ref),
                      child: authState.isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : const Text('Sign in'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {},
                        child: const Text('Forgot password?'),
                      ),
                      const SizedBox(width: 16),
                      TextButton(
                        onPressed: () => context.go('/register'),
                        child: const Text('Create Account'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SocialButton(
                        icon: Icons.code,
                        onTap: () {},
                      ),
                      const SizedBox(width: 16),
                      _SocialButton(
                        label: 'G',
                        onTap: authState.isLoading ? null : () => _handleGoogleSignIn(ref),
                      ),
                    ],
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

class _SocialButton extends StatelessWidget {
  const _SocialButton({this.icon, this.label, this.onTap});

  final IconData? icon;
  final String? label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: icon != null
              ? Icon(icon, color: colorScheme.onSurface)
              : Text(
                  label ?? '',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
