import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Notification settings state provider
final notificationSettingsProvider = StateNotifierProvider<NotificationSettingsNotifier, NotificationSettings>((ref) {
  return NotificationSettingsNotifier();
});

class NotificationSettings {
  final bool contestNotifications;
  final bool dailyCodingChallenge;
  final bool systemNotifications;
  final bool friendActivity;

  NotificationSettings({
    this.contestNotifications = true,
    this.dailyCodingChallenge = true,
    this.systemNotifications = false,
    this.friendActivity = false,
  });

  NotificationSettings copyWith({
    bool? contestNotifications,
    bool? dailyCodingChallenge,
    bool? systemNotifications,
    bool? friendActivity,
  }) {
    return NotificationSettings(
      contestNotifications: contestNotifications ?? this.contestNotifications,
      dailyCodingChallenge: dailyCodingChallenge ?? this.dailyCodingChallenge,
      systemNotifications: systemNotifications ?? this.systemNotifications,
      friendActivity: friendActivity ?? this.friendActivity,
    );
  }
}

class NotificationSettingsNotifier extends StateNotifier<NotificationSettings> {
  NotificationSettingsNotifier() : super(NotificationSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = NotificationSettings(
      contestNotifications: prefs.getBool('contest_notifications') ?? true,
      dailyCodingChallenge: prefs.getBool('daily_coding_challenge') ?? true,
      systemNotifications: prefs.getBool('system_notifications') ?? false,
      friendActivity: prefs.getBool('friend_activity') ?? false,
    );
  }

  Future<void> toggleContest(bool value) async {
    state = state.copyWith(contestNotifications: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('contest_notifications', value);
  }

  Future<void> toggleDailyCodingChallenge(bool value) async {
    state = state.copyWith(dailyCodingChallenge: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('daily_coding_challenge', value);
  }

  Future<void> toggleSystemNotifications(bool value) async {
    state = state.copyWith(systemNotifications: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('system_notifications', value);
  }

  Future<void> toggleFriendActivity(bool value) async {
    state = state.copyWith(friendActivity: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('friend_activity', value);
  }
}

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final settings = ref.watch(notificationSettingsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Notifications'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Alert banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF2563EB).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: const Color(0xFF2563EB),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Allow Notifications on This Device',
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Notifications from CodeMania are turned off on this device. Change your notifications settings to get important updates.',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.7),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Notification toggles
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _NotificationToggle(
                      title: 'Contest',
                      subtitle: 'Get notified about upcoming contests and results',
                      value: settings.contestNotifications,
                      onChanged: (value) {
                        ref.read(notificationSettingsProvider.notifier).toggleContest(value);
                      },
                    ),
                    Divider(height: 1, color: colorScheme.outline.withOpacity(0.3)),
                    _NotificationToggle(
                      title: 'Daily Coding Challenge',
                      subtitle: 'Daily problem recommendations and streaks',
                      value: settings.dailyCodingChallenge,
                      onChanged: (value) {
                        ref.read(notificationSettingsProvider.notifier).toggleDailyCodingChallenge(value);
                      },
                    ),
                    Divider(height: 1, color: colorScheme.outline.withOpacity(0.3)),
                    _NotificationToggle(
                      title: 'System Notifications',
                      subtitle: 'Updates about maintenance and new features',
                      value: settings.systemNotifications,
                      onChanged: (value) {
                        ref.read(notificationSettingsProvider.notifier).toggleSystemNotifications(value);
                      },
                    ),
                    Divider(height: 1, color: colorScheme.outline.withOpacity(0.3)),
                    _NotificationToggle(
                      title: 'Friend Activity',
                      subtitle: 'Get notified when friends solve problems',
                      value: settings.friendActivity,
                      onChanged: (value) {
                        ref.read(notificationSettingsProvider.notifier).toggleFriendActivity(value);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Info section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.notifications_outlined,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'About Notifications',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Notifications help you stay updated with contests, challenges, and your coding progress. You can customize which notifications you receive at any time.',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7),
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationToggle extends StatelessWidget {
  const _NotificationToggle({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF2563EB),
          ),
        ],
      ),
    );
  }
}
