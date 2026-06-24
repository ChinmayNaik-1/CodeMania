import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:codemania/providers/auth_provider.dart';
import 'package:codemania/services/socket_service.dart';

class AdminScaffold extends ConsumerWidget {
  const AdminScaffold({super.key, required this.child});
  final Widget child;

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => ctx.pop(true),
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      SocketService.disconnect();
      if (context.mounted) {
        await ref.read(authProvider.notifier).logout();
        context.go('/');
      }
    }
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/admin/problems')) {
      return 1;
    }
    if (location.startsWith('/admin/contests')) {
      return 2;
    }
    return 0; // Default to dashboard
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/admin');
        break;
      case 1:
        context.go('/admin/problems/manage');
        break;
      case 2:
        context.go('/admin/contests');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _calculateSelectedIndex(context);
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    
    final navItems = [
      const NavigationRailDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: Text('Dashboard'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.edit_note_outlined),
        selectedIcon: Icon(Icons.edit_note),
        label: Text('Problems'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.event_outlined),
        selectedIcon: Icon(Icons.event),
        label: Text('Contests'),
      ),
    ];

    final appBar = AppBar(
      title: const Text('CodeMania Admin'),
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Logout',
          onPressed: () => _confirmLogout(context, ref),
        ),
      ],
    );

    if (!isDesktop) {
      return Scaffold(
        appBar: appBar,
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (idx) => _onItemTapped(idx, context),
          destinations: navItems.map((e) => NavigationDestination(
            icon: e.icon,
            selectedIcon: e.selectedIcon,
            label: (e.label as Text).data ?? '',
          )).toList(),
        ),
      );
    }

    return Scaffold(
      appBar: appBar,
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: (idx) => _onItemTapped(idx, context),
            labelType: NavigationRailLabelType.all,
            destinations: navItems,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
            indicatorColor: Theme.of(context).colorScheme.primaryContainer,
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
