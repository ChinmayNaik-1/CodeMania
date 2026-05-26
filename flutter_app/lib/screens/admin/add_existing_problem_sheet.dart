import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:codemania/models/problem_model.dart';
import 'package:codemania/services/api_service.dart';

class AddExistingProblemSheet extends StatefulWidget {
  const AddExistingProblemSheet({super.key, required this.contestId});

  final int contestId;

  @override
  State<AddExistingProblemSheet> createState() => _AddExistingProblemSheetState();
}

class _AddExistingProblemSheetState extends State<AddExistingProblemSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<Problem> _allProblems = [];
  List<Problem> _filteredProblems = [];
  bool _isLoading = true;
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _loadProblems();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProblems() async {
    setState(() => _isLoading = true);
    try {
      final problemsResponse = await ApiService.get('/api/problems', params: {
        'page': 1,
        'limit': 2000,
      });
      final problemsData = problemsResponse.data;
      final problemsList = (problemsData is Map ? problemsData['problems'] : null) as List? ?? [];
      final allProblems = problemsList
          .whereType<Map>()
          .map((problem) => Problem.fromJson(Map<String, dynamic>.from(problem)))
          .toList();

      final contestResponse = await ApiService.get('/api/contests/${widget.contestId}');
      final contestData = contestResponse.data;
      final contestProblems = (contestData is Map ? contestData['problems'] : null) as List? ?? [];
      final contestProblemIds = contestProblems
          .whereType<Map>()
          .map((problem) => (problem['id'] as num?)?.toInt())
          .whereType<int>()
          .toSet();

      final availableProblems = allProblems
          .where((problem) => !contestProblemIds.contains(problem.id))
          .toList();

      if (mounted) {
        setState(() {
          _allProblems = availableProblems;
          _filteredProblems = availableProblems;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load problems: $error')),
        );
      }
    }
  }

  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredProblems = List<Problem>.from(_allProblems);
      } else {
        _filteredProblems = _allProblems
            .where((problem) => problem.title.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  Future<void> _addProblem(int problemId) async {
    setState(() => _isAdding = true);
    try {
      await ApiService.post(
        '/api/admin/contests/${widget.contestId}/problems',
        data: {'problemId': problemId},
      );

      if (mounted) {
        setState(() {
          _allProblems = _allProblems.where((problem) => problem.id != problemId).toList();
          _filteredProblems = _filteredProblems.where((problem) => problem.id != problemId).toList();
          _isAdding = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Problem added to contest.')),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isAdding = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_extractErrorMessage(error))),
        );
      }
    }
  }

  String _extractErrorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['error'] != null) {
        return data['error'].toString();
      }
    }
    return 'Failed to add problem.';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Stack(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: const BoxDecoration(
                color: Color(0xFFFDFDFF),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      controller: scrollController,
                      children: [
                        Center(
                          child: Container(
                            width: 44,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6E0F3),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const Text(
                          'Add Existing Problem',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Select a problem from the public pool.',
                          style: TextStyle(color: Color(0xFF7A839E), fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search),
                            hintText: 'Search problems',
                            filled: true,
                            fillColor: const Color(0xFFF4F2FB),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_filteredProblems.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Text('No problems available.'),
                          )
                        else
                          ..._filteredProblems.map(
                            (problem) => _ProblemTile(
                              problem: problem,
                              onAdd: () => _addProblem(problem.id),
                            ),
                          ),
                      ],
                    ),
            ),
            if (_isAdding)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.15),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ProblemTile extends StatelessWidget {
  const _ProblemTile({required this.problem, required this.onAdd});

  final Problem problem;
  final VoidCallback onAdd;

  Color _difficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return const Color(0xFF2CBB5D);
      case 'medium':
        return const Color(0xFFFFA116);
      case 'hard':
        return const Color(0xFFEF4743);
      default:
        return const Color(0xFF7A839E);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _difficultyColor(problem.difficulty);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(problem.title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  problem.difficulty,
                  style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: onAdd,
        ),
      ),
    );
  }
}
