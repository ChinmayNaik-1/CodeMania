import 'package:codemania/providers/problem_provider.dart';
import 'package:codemania/models/problem_model.dart';
import 'package:codemania/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ManageProblemsScreen extends ConsumerStatefulWidget {
  const ManageProblemsScreen({super.key});

  @override
  ConsumerState<ManageProblemsScreen> createState() =>
      _ManageProblemsScreenState();
}

class _ManageProblemsScreenState extends ConsumerState<ManageProblemsScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  Future<void> _refreshProblems() async {
    await ref.read(problemListProvider.notifier).fetchProblems(limit: 100);
  }

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text.toLowerCase();
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshProblems();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(problemListProvider);

    if (state.isLoading && state.problems.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Manage Problems')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null && state.problems.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Manage Problems')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(state.error!),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _refreshProblems,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final filteredProblems = state.problems.where((p) {
      final titleMatch = p.title.toLowerCase().contains(_searchQuery);
      final numMatch = p.problemNumber?.toString().contains(_searchQuery) ?? false;
      return titleMatch || numMatch;
    }).toList();

    final normalProblems = filteredProblems.where((p) => !p.isContestExclusive).toList();
    final exclusiveProblems = filteredProblems.where((p) => p.isContestExclusive).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Problems'),
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search by name or number...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            TabBar(
              labelColor: const Color(0xFF6C5CE7),
              unselectedLabelColor: const Color(0xFF6B7280),
              indicatorColor: const Color(0xFF6C5CE7),
              tabs: [
                Tab(text: "Normal  (${normalProblems.length})"),
                Tab(text: "Contest Exclusive  (${exclusiveProblems.length})"),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _ProblemList(
                    problems: normalProblems,
                    onRefresh: _refreshProblems,
                  ),
                  _ProblemList(
                    problems: exclusiveProblems,
                    onRefresh: _refreshProblems,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProblemList extends StatelessWidget {
  final List<ProblemModel> problems;
  final Future<void> Function() onRefresh;

  const _ProblemList({required this.problems, required this.onRefresh});

  Color _difficultyColor(String value) {
    switch (value.toLowerCase()) {
      case 'easy':
        return const Color(0xFF2CBB5D);
      case 'hard':
        return const Color(0xFFEF4743);
      case 'medium':
      default:
        return const Color(0xFFFFA116);
    }
  }

  Future<void> _deleteProblem(BuildContext context, int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Problem'),
        content: const Text('Are you sure you want to delete this problem?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.delete('/api/admin/problems/$id');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Problem deleted')),
          );
          onRefresh();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delete failed: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (problems.isEmpty) {
      return const Center(child: Text('No problems found.'));
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        itemCount: problems.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final p = problems[index];
          return ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF6C5CE7).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  "${p.problemNumber ?? p.id}",
                  style: const TextStyle(
                    color: Color(0xFF6C5CE7),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            title: Text(
              "${p.problemNumber ?? p.id}. ${p.title}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _difficultyColor(p.difficulty).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    p.difficulty,
                    style: TextStyle(
                      color: _difficultyColor(p.difficulty),
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (p.isContestExclusive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C5CE7).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      "Contest Only",
                      style: TextStyle(
                        color: Color(0xFF6C5CE7),
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () async {
                    await context.push('/admin/problems/${p.id}/edit');
                    if (context.mounted) {
                      await onRefresh();
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _deleteProblem(context, p.id),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
