import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:codemania/app_theme.dart';
import 'package:codemania/providers/auth_provider.dart';
import 'package:codemania/services/socket_service.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
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
      // Disconnect Socket.IO before logout
      SocketService.disconnect();
      if (context.mounted) {
        await ref.read(authProvider.notifier).logout();
        // Navigate to login after logout
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CodeMania Admin'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _confirmLogout(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Statistics',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard('Problems', '0', Icons.assignment),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard('Contests', '0', Icons.event),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard('Users', '0', Icons.people),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard('Submissions', '0', Icons.send),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.push('/admin/problems/create');
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Create Problem'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.push('/admin/problems/manage');
                      },
                      icon: const Icon(Icons.edit_note_outlined),
                      label: const Text('Manage/Edit Problems'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.push('/admin/contests');
                      },
                      icon: const Icon(Icons.event),
                      label: const Text('Create Contest'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Text(
                'Recent Submissions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text('No recent submissions'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.primaryColor),
            const SizedBox(height: 12),
            Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 8),
            Text(value,
                style:
                    const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
