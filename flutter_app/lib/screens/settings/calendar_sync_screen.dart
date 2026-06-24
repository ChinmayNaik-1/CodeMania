import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Calendar sync settings state provider
final calendarSyncProvider = StateNotifierProvider<CalendarSyncNotifier, CalendarSyncState>((ref) {
  return CalendarSyncNotifier();
});

class CalendarSyncState {
  final bool isEnabled;
  final String? lastSyncTime;

  CalendarSyncState({
    this.isEnabled = false,
    this.lastSyncTime,
  });

  CalendarSyncState copyWith({
    bool? isEnabled,
    String? lastSyncTime,
  }) {
    return CalendarSyncState(
      isEnabled: isEnabled ?? this.isEnabled,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }
}

class CalendarSyncNotifier extends StateNotifier<CalendarSyncState> {
  CalendarSyncNotifier() : super(CalendarSyncState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = CalendarSyncState(
      isEnabled: prefs.getBool('calendar_sync_enabled') ?? false,
      lastSyncTime: prefs.getString('last_sync_time'),
    );
  }

  Future<void> toggleSync(bool value) async {
    state = state.copyWith(isEnabled: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('calendar_sync_enabled', value);
    
    if (value) {
      final now = DateTime.now();
      final timeStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      state = state.copyWith(lastSyncTime: timeStr);
      await prefs.setString('last_sync_time', timeStr);
    }
  }
}

class CalendarSyncScreen extends ConsumerWidget {
  const CalendarSyncScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final syncState = ref.watch(calendarSyncProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Calendar Sync'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main toggle card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Export Calendar',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Sync contests to your calendar',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: syncState.isEnabled,
                      onChanged: (value) {
                        ref.read(calendarSyncProvider.notifier).toggleSync(value);
                      },
                      activeColor: const Color(0xFF2563EB),
                    ),
                  ],
                ),
              ),

              if (syncState.isEnabled) ...[
                const SizedBox(height: 16),
                
                // Last sync info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF10B981).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: const Color(0xFF10B981),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Calendar Sync Active',
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                            if (syncState.lastSyncTime != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Last synced: ${syncState.lastSyncTime}',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // How it works section
              Text(
                'How Calendar Sync Works',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.event_available,
                      title: 'Automatic Updates',
                      description: 'Contests are automatically added to your calendar when scheduled',
                    ),
                    const SizedBox(height: 16),
                    _InfoRow(
                      icon: Icons.notifications_active,
                      title: 'Reminders',
                      description: 'Get calendar reminders 30 minutes before contests start',
                    ),
                    const SizedBox(height: 16),
                    _InfoRow(
                      icon: Icons.sync,
                      title: 'Real-time Sync',
                      description: 'Changes to contest schedules are synced automatically',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Setup instructions
              Text(
                'Setup Instructions',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SetupStep(
                      number: 1,
                      text: 'Enable Calendar Sync using the toggle above',
                    ),
                    const SizedBox(height: 12),
                    _SetupStep(
                      number: 2,
                      text: 'Open your device calendar app (Google Calendar, Apple Calendar, etc.)',
                    ),
                    const SizedBox(height: 12),
                    _SetupStep(
                      number: 3,
                      text: 'Look for "CodeMania Contests" in your calendar subscriptions',
                    ),
                    const SizedBox(height: 12),
                    _SetupStep(
                      number: 4,
                      text: 'All upcoming contests will appear automatically',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Supported platforms
              Text(
                'Supported Platforms',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _PlatformRow(icon: Icons.calendar_today, name: 'Google Calendar'),
                    const SizedBox(height: 12),
                    _PlatformRow(icon: Icons.apple, name: 'Apple Calendar (iCal)'),
                    const SizedBox(height: 12),
                    _PlatformRow(icon: Icons.event, name: 'Microsoft Outlook'),
                    const SizedBox(height: 12),
                    _PlatformRow(icon: Icons.calendar_month, name: 'Other iCal Compatible Calendars'),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF2563EB),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SetupStep extends StatelessWidget {
  const _SetupStep({
    required this.number,
    required this.text,
  });

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number.toString(),
              style: textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              text,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.8),
                height: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PlatformRow extends StatelessWidget {
  const _PlatformRow({
    required this.icon,
    required this.name,
  });

  final IconData icon;
  final String name;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(
          icon,
          color: colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 12),
        Text(
          name,
          style: textTheme.bodyMedium,
        ),
        const Spacer(),
        Icon(
          Icons.check_circle,
          color: const Color(0xFF10B981),
          size: 18,
        ),
      ],
    );
  }
}
