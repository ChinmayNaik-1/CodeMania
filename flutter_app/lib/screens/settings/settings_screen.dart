import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:codemania/providers/auth_provider.dart';
import 'package:codemania/providers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final authState = ref.watch(authProvider);
    final themeMode = ref.watch(themeProvider);
    final user = authState.user;

    final themeLabel = themeMode == ThemeMode.dark ? 'Dark' : 'Light';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile card
              InkWell(
                onTap: () {
                  if (user != null) {
                    context.push('/profile/${user.id}');
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: colorScheme.primary.withOpacity(0.2),
                        child: Text(
                          user?.username.isNotEmpty == true
                              ? user!.username[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.username ?? 'Guest',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Profile, Password, Email',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: colorScheme.onSurface.withOpacity(0.6)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Subscription section
              Text(
                'Subscription',
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 12),
              _SettingsCard(
                children: [
                  _SettingsRow(
                    title: 'Premium',
                    onTap: () => context.push('/settings/dummy', extra: 'Premium'),
                  ),
                  Divider(height: 1, color: colorScheme.outline),
                  _SettingsRow(
                    title: 'Billing History',
                    onTap: () => context.push('/settings/dummy', extra: 'Billing History'),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Notification & Calendar
              Text(
                'Notification & Calendar',
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 12),
              _SettingsCard(
                children: [
                  _SettingsRow(
                    title: 'Notifications',
                    onTap: () => context.push('/settings/dummy', extra: 'Notifications'),
                  ),
                  Divider(height: 1, color: colorScheme.outline),
                  _SettingsRow(
                    title: 'Calendar Sync',
                    onTap: () => context.push('/settings/dummy', extra: 'Calendar Sync'),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Appearance
              Text(
                'Appearance',
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 12),
              _SettingsCard(
                children: [
                  _SettingsRow(
                    title: 'Theme',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          themeLabel,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.chevron_right, color: colorScheme.onSurface.withOpacity(0.6)),
                      ],
                    ),
                    onTap: () => _showThemeBottomSheet(context, ref),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Support
              Text(
                'Support',
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 12),
              _SettingsCard(
                children: [
                  _SettingsRow(
                    title: 'Help Center',
                    onTap: () => context.push('/settings/dummy', extra: 'Help Center'),
                  ),
                  Divider(height: 1, color: colorScheme.outline),
                  _SettingsRow(
                    title: 'Feedback',
                    onTap: () => context.push('/settings/dummy', extra: 'Feedback'),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Privacy & Information
              Text(
                'Privacy & Information',
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 12),
              _SettingsCard(
                children: [
                  _SettingsRow(
                    title: 'Terms',
                    onTap: () => context.push('/settings/dummy', extra: 'Terms'),
                  ),
                  Divider(height: 1, color: colorScheme.outline),
                  _SettingsRow(
                    title: 'Privacy Policy',
                    onTap: () => context.push('/settings/dummy', extra: 'Privacy Policy'),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Sign Out button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Sign Out',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showThemeBottomSheet(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final currentTheme = ref.read(themeProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Theme',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Light'),
                  trailing: currentTheme == ThemeMode.light
                      ? Icon(Icons.check, color: colorScheme.primary)
                      : null,
                  onTap: () {
                    ref.read(themeProvider.notifier).setThemeMode(ThemeMode.light);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Dark'),
                  trailing: currentTheme == ThemeMode.dark
                      ? Icon(Icons.check, color: colorScheme.primary)
                      : null,
                  onTap: () {
                    ref.read(themeProvider.notifier).setThemeMode(ThemeMode.dark);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.title,
    this.trailing,
    required this.onTap,
  });

  final String title;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            trailing ??
                Icon(Icons.chevron_right, color: colorScheme.onSurface.withOpacity(0.6)),
          ],
        ),
      ),
    );
  }
}
