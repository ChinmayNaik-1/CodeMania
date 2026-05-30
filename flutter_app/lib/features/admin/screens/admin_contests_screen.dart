import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:codemania/core/models/contest_model.dart';
import 'package:codemania/services/api_service.dart';

final adminContestsFutureProvider = FutureProvider.autoDispose<List<ContestModel>>((ref) async {
  final res = await ApiService.get('/api/contests/admin/contests');
  if (res.statusCode == 200) {
    return (res.data as List).map((x) => ContestModel.fromJson(x)).toList();
  } else {
    throw Exception('Failed to load admin contests: ${res.data}');
  }
});

class AdminContestsScreen extends ConsumerWidget {
  const AdminContestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncContests = ref.watch(adminContestsFutureProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Manage Contests', style: TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Color(0xFF1A1A2E)),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/contests/create'),
        backgroundColor: const Color(0xFF6C5CE7),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Create Contest', style: TextStyle(color: Colors.white)),
      ),
      body: asyncContests.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Error: $e', style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(adminContestsFutureProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (contests) {
          if (contests.isEmpty) {
            return const Center(child: Text('No contests found.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: contests.length,
            itemBuilder: (context, index) {
              final contest = contests[index];
              return _AdminContestCard(contest: contest);
            },
          );
        },
      ),
    );
  }
}

class _AdminContestCard extends ConsumerWidget {
  const _AdminContestCard({required this.contest});
  final ContestModel contest;

  Color _getStatusColor(String status) {
    switch (status) {
      case 'draft': return Colors.grey;
      case 'upcoming': return const Color(0xFF6C5CE7);
      case 'live': return const Color(0xFF00B8A3);
      case 'ended': return const Color(0xFF6B7280);
      default: return Colors.grey;
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Contest'),
        content: Text('Are you sure you want to delete "${contest.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final res = await ApiService.delete('/api/contests/admin/${contest.id}');
                if (res.statusCode == 200) {
                  ref.refresh(adminContestsFutureProvider);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${res.data}')));
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _publish(BuildContext context, WidgetRef ref) async {
    try {
      final res = await ApiService.put('/api/contests/admin/${contest.id}/publish');
      if (res.statusCode == 200) {
        ref.refresh(adminContestsFutureProvider);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${res.data}')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = DateFormat('MMM d, h:mm a');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          contest.title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(contest.status.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        backgroundColor: _getStatusColor(contest.status),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(contest.contestType.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('${fmt.format(contest.startTime.toLocal())} → ${fmt.format(contest.endTime.toLocal())}', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text('${contest.problemCount} problems', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (contest.status == 'draft')
                  IconButton(
                    icon: const Icon(Icons.publish, color: Colors.green),
                    tooltip: 'Publish',
                    onPressed: () => _publish(context, ref),
                  ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  tooltip: 'Edit',
                  onPressed: () => context.push('/admin/contests/${contest.id}/edit'),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Delete',
                  onPressed: () => _confirmDelete(context, ref),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
