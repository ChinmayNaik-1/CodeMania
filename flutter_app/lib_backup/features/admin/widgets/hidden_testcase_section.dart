import 'package:codemania/services/api_service.dart';
import 'package:flutter/material.dart';

class HiddenTestcaseSection extends StatefulWidget {
  const HiddenTestcaseSection({
    super.key,
    required this.problemId,
  });

  final int problemId;

  @override
  State<HiddenTestcaseSection> createState() => _HiddenTestcaseSectionState();
}

class _HiddenTestcaseSectionState extends State<HiddenTestcaseSection> {
  bool _isLoading = true;
  bool _isSaving = false;
  List<Map<String, dynamic>> _hiddenCases = const [];
  List<Map<String, dynamic>> _visibleCases = const [];

  @override
  void initState() {
    super.initState();
    _loadCases();
  }

  Future<void> _loadCases() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get('/api/admin/problems/${widget.problemId}/testcases');
      final rows = <Map<String, dynamic>>[];
      if (response.data is List) {
        for (final row in (response.data as List).whereType<Map>()) {
          rows.add(Map<String, dynamic>.from(row.cast<String, dynamic>()));
        }
      }

      _hiddenCases = rows.where((row) => row['is_hidden'] == true).toList();
      _visibleCases = rows.where((row) => row['is_hidden'] != true).toList();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load test cases.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteCase(String testcaseId) async {
    setState(() => _isSaving = true);
    try {
      await ApiService.delete('/api/admin/problems/${widget.problemId}/testcases/$testcaseId');
      await _loadCases();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete test case.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _openAddCaseSheet({required bool hidden}) async {
    final inputController = TextEditingController();
    final expectedController = TextEditingController();
    final explanationController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hidden ? 'Add Hidden Test Case' : 'Add Visible Test Case',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: inputController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Input',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: expectedController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Expected Output',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: explanationController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Explanation (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final input = inputController.text.trim();
                    final expected = expectedController.text.trim();
                    if (input.isEmpty || expected.isEmpty) {
                      return;
                    }

                    Navigator.of(context).pop();
                    setState(() => _isSaving = true);
                    try {
                      await ApiService.post(
                        '/api/admin/problems/${widget.problemId}/testcases',
                        data: {
                          'input': input,
                          'expected_output': expected,
                          'explanation': explanationController.text.trim().isEmpty
                              ? null
                              : explanationController.text.trim(),
                          'is_hidden': hidden,
                        },
                      );
                      await _loadCases();
                    } catch (_) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to save test case.')),
                      );
                    } finally {
                      if (mounted) {
                        setState(() => _isSaving = false);
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        );
      },
    );

    inputController.dispose();
    expectedController.dispose();
    explanationController.dispose();
  }

  Widget _buildCaseList(
    String title,
    IconData icon,
    List<Map<String, dynamic>> rows, {
    required bool hidden,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _isSaving ? null : () => _openAddCaseSheet(hidden: hidden),
                  icon: const Icon(Icons.add),
                  label: Text(hidden ? 'Add Hidden Test Case' : 'Add Visible Test Case'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (rows.isEmpty)
              Text(
                hidden ? 'No hidden test cases yet.' : 'No visible test cases yet.',
                style: const TextStyle(color: Colors.grey),
              )
            else
              ...rows.map((row) {
                final id = (row['id'] ?? '').toString();
                final input = (row['input'] ?? '').toString();
                final expected = (row['expected_output'] ?? '').toString();
                final previewInput = input.length > 80 ? '${input.substring(0, 80)}…' : input;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    dense: true,
                    title: Text(previewInput),
                    subtitle: Text(
                      expected,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      onPressed: _isSaving ? null : () => _deleteCase(id),
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCaseList(
          'Visible Test Cases (shown to users as examples)',
          Icons.visibility,
          _visibleCases,
          hidden: false,
        ),
        const SizedBox(height: 12),
        _buildCaseList(
          'Hidden Test Cases',
          Icons.lock,
          _hiddenCases,
          hidden: true,
        ),
      ],
    );
  }
}
