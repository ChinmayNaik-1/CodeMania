import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:codemania/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  bool _isNavigating = false;

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
        backgroundColor: Colors.red,
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
      // Login successful - navigate based on user role
      _isNavigating = true;
      // Use a small delay to ensure state updates have propagated
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

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 980;

            return Row(
              children: [
                if (isWide) const Expanded(flex: 5, child: _PurpleShowcase()),
                Expanded(
                  flex: 4,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(28),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _AuthSwitcher(
                              active: _AuthTab.login,
                              onLoginTap: () => context.go('/login'),
                              onSignupTap: () => context.go('/register'),
                            ),
                            const SizedBox(height: 22),
                            const Text(
                              'Welcome back',
                              style: TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF161A2C),
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Pick up where you left off.',
                              style: TextStyle(
                                  color: Color(0xFF6B7280), fontSize: 16),
                            ),
                            const SizedBox(height: 22),
                            OutlinedButton.icon(
                              onPressed: authState.isLoading
                                  ? null
                                  : () => _handleGoogleSignIn(ref),
                              icon: const Icon(Icons.g_mobiledata, size: 22),
                              label: const Text('Continue with Google'),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                const Expanded(child: Divider()),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  child: Text(
                                    'or login with email',
                                    style:
                                        TextStyle(color: Colors.grey.shade600),
                                  ),
                                ),
                                const Expanded(child: Divider()),
                              ],
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Email address',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2A2F44)),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _emailController,
                              enabled: !authState.isLoading,
                              decoration: const InputDecoration(
                                hintText: 'name@company.com',
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Password',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2A2F44)),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _passwordController,
                              enabled: !authState.isLoading,
                              obscureText: true,
                              decoration: const InputDecoration(
                                hintText: 'Enter your password',
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                            if (authState.error != null) ...[
                              const SizedBox(height: 14),
                              Text(
                                authState.error!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ],
                            const SizedBox(height: 22),
                            FilledButton(
                              onPressed: authState.isLoading
                                  ? null
                                  : () => _handleLogin(ref),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF6D38F8),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 18),
                              ),
                              child: authState.isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Log In'),
                            ),
                            const SizedBox(height: 18),
                            TextButton(
                              onPressed: () => context.go('/register'),
                              child: const Text(
                                  "Don't have an account? Create one"),
                            ),
                            TextButton(
                              onPressed: () => context.go('/'),
                              child: const Text('Back to Home'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PurpleShowcase extends StatelessWidget {
  const _PurpleShowcase();

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.4, -0.2),
          radius: 1.15,
          colors: [
            Color(0xFF9E74FF),
            Color(0xFF6A37EB),
            Color(0xFF4A1FAF),
          ],
          stops: [0.0, 0.42, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -100,
            left: -120,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
          ),
          Positioned(
            bottom: -140,
            right: -80,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '<Codemania/>',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 30,
                  ),
                ),
                const Spacer(),
                const Text(
                  'Code. Compete.\nConquer.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 72,
                    height: 0.95,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -2,
                  ),
                ),
                const SizedBox(height: 26),
                const _Pitch(
                  icon: Icons.code,
                  text: '500+ problems from beginner to expert',
                ),
                const _Pitch(
                  icon: Icons.emoji_events_outlined,
                  text: 'Weekly contests and global prizes',
                ),
                const _Pitch(
                  icon: Icons.stacked_line_chart,
                  text: 'Real-time dynamic leaderboard',
                ),
                const SizedBox(height: 28),
                Container(
                  width: 360,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: const Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            '1',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'AlexDev',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '2450',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            '2',
                            style: TextStyle(
                              color: Color(0xFFE7DDFF),
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'ByteMaster',
                              style: TextStyle(
                                color: Color(0xFFEDE6FF),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '2380',
                            style: TextStyle(
                              color: Color(0xFFEDE6FF),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pitch extends StatelessWidget {
  const _Pitch({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70),
          const SizedBox(width: 12),
          Expanded(
              child: Text(text,
                  style: const TextStyle(color: Colors.white, fontSize: 18))),
        ],
      ),
    );
  }
}

enum _AuthTab { login, signup }

class _AuthSwitcher extends StatelessWidget {
  const _AuthSwitcher({
    required this.active,
    required this.onLoginTap,
    required this.onSignupTap,
  });

  final _AuthTab active;
  final VoidCallback onLoginTap;
  final VoidCallback onSignupTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 270,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFE1E5EE),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          _AuthSwitcherButton(
            label: 'Log In',
            selected: active == _AuthTab.login,
            onTap: onLoginTap,
          ),
          _AuthSwitcherButton(
            label: 'Sign Up',
            selected: active == _AuthTab.signup,
            onTap: onSignupTap,
          ),
        ],
      ),
    );
  }
}

class _AuthSwitcherButton extends StatelessWidget {
  const _AuthSwitcherButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF5C2CD5) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x402F136F),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: selected ? Colors.white : const Color(0xFF637088),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
