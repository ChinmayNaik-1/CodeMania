import 'package:codemania/providers/problem_provider.dart';
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
  Future<void> _refreshProblems() async {
    await ref.read(problemListProvider.notifier).fetchProblems(limit: 100);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshProblems();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(problemListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Problems'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProblems,
        child: Builder(
          builder: (context) {
            if (state.isLoading && state.problems.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.error != null && state.problems.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 80),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        state.error!,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: ElevatedButton(
                      onPressed: _refreshProblems,
                      child: const Text('Retry'),
                    ),
                  ),
                ],
              );
            }

            if (state.problems.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 80),
                  Center(child: Text('No problems found.')),
                ],
              );
            }

            return ListView.separated(
              itemCount: state.problems.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final problem = state.problems[index];
                return ListTile(
                  title: Text(problem.title),
                  subtitle: Text(
                      'Difficulty: ${problem.difficulty} • Tags: ${problem.tags.join(', ')}'),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () async {
                    await context.push('/admin/problems/create', extra: problem);
                    if (mounted) {
                      await _refreshProblems();
                    }
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
