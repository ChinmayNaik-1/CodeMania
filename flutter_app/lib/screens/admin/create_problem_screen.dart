import 'package:codemania/models/problem_model.dart';
import 'package:codemania/features/admin/widgets/hidden_testcase_section.dart';
import 'package:codemania/screens/admin/driver_code_tab.dart';
import 'package:codemania/screens/admin/starter_code_tab.dart';
import 'package:codemania/providers/problem_provider.dart';
import 'package:codemania/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CreateProblemScreen extends ConsumerStatefulWidget {
  const CreateProblemScreen({
    super.key,
    this.editingProblem,
    this.visibility,
    this.contestId,
  });

  final ProblemModel? editingProblem;
  final String? visibility;
  final int? contestId;

  @override
  ConsumerState<CreateProblemScreen> createState() => _CreateProblemScreenState();
}

class _CreateProblemScreenState extends ConsumerState<CreateProblemScreen> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final constraintsController = TextEditingController();
  final inputFormatController = TextEditingController();
  final contestIdController = TextEditingController();

  String selectedDifficulty = 'medium';
  String selectedVisibility = 'public';
  List<String> tags = [];

  final tagController = TextEditingController();

  final exampleInputController = TextEditingController();
  final exampleOutputController = TextEditingController();
  final exampleExplanationController = TextEditingController();

  final judgeInputController = TextEditingController();
  final judgeOutputController = TextEditingController();

  final List<Map<String, dynamic>> _existingExamples = [];
  final List<Map<String, dynamic>> _existingJudgeCases = [];
  final List<Map<String, dynamic>> _newExamples = [];
  final List<Map<String, dynamic>> _newJudgeCases = [];
  Map<String, String> _codeStubs = {};

  bool _isSubmitting = false;

  bool get _isEditing => widget.editingProblem != null;

  @override
  void initState() {
    super.initState();
    final problem = widget.editingProblem;
    if (widget.visibility != null) {
      selectedVisibility = widget.visibility!;
    }
    if (widget.contestId != null) {
      contestIdController.text = widget.contestId.toString();
    }
    if (problem != null) {
      titleController.text = problem.title;
      descriptionController.text = problem.description;
      selectedDifficulty = problem.difficulty;
      tags = List<String>.from(problem.tags);
      constraintsController.text = problem.constraints.join('\n');
      inputFormatController.text = problem.inputFormat.join(', ');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadFullProblem(problem.id);
      });
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    constraintsController.dispose();
    inputFormatController.dispose();
    contestIdController.dispose();
    tagController.dispose();
    exampleInputController.dispose();
    exampleOutputController.dispose();
    exampleExplanationController.dispose();
    judgeInputController.dispose();
    judgeOutputController.dispose();
    super.dispose();
  }

  Future<void> _loadFullProblem(int id) async {
    try {
      final response = await ApiService.get('/problems/$id', params: const {'includeAllCases': 1});
      final payload = response.data as Map<String, dynamic>;
      final codeStubs = payload['code_stubs'];
      if (codeStubs is Map) {
        _codeStubs = codeStubs.map(
          (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
        );
      }
      final constraints = payload['constraints'];
      if (constraints is List) {
        constraintsController.text = constraints.map((e) => e.toString()).join('\n');
      } else if (constraints is String) {
        constraintsController.text = constraints;
      }

      final inputFormat = payload['input_format'];
      if (inputFormat is List) {
        inputFormatController.text = inputFormat.map((e) => e.toString()).join(', ');
      }

      final testCases = (payload['test_cases'] as List?) ?? const [];
      _existingExamples.clear();
      _existingJudgeCases.clear();

      for (final raw in testCases.whereType<Map>()) {
        final tc = Map<String, dynamic>.from(raw.cast<String, dynamic>());
        final isSample = tc['is_sample'] == true;
        if (isSample) {
          _existingExamples.add(tc);
        } else {
          _existingJudgeCases.add(tc);
        }
      }

      if (mounted) setState(() {});
    } catch (_) {
      // Keep screen usable even if supplemental fields are unavailable.
    }
  }

  void _addTag() {
    final value = tagController.text.trim();
    if (value.isEmpty) return;

    setState(() {
      tags.add(value);
      tagController.clear();
    });
  }

  void _removeTag(int index) {
    setState(() {
      tags.removeAt(index);
    });
  }

  void _addExample() {
    final input = exampleInputController.text.trim();
    final output = exampleOutputController.text.trim();
    final explanation = exampleExplanationController.text.trim();

    if (input.isEmpty || output.isEmpty) return;

    setState(() {
      _newExamples.add({
        'input': input,
        'expected_output': output,
        'explanation': explanation.isEmpty ? null : explanation,
        'is_sample': true,
      });
      exampleInputController.clear();
      exampleOutputController.clear();
      exampleExplanationController.clear();
    });
  }

  void _removeNewExample(int index) {
    setState(() {
      _newExamples.removeAt(index);
    });
  }

  void _addJudgeCase() {
    final input = judgeInputController.text.trim();
    final output = judgeOutputController.text.trim();

    if (input.isEmpty || output.isEmpty) return;

    setState(() {
      _newJudgeCases.add({
        'input': input,
        'expected_output': output,
        'is_sample': false,
      });
      judgeInputController.clear();
      judgeOutputController.clear();
    });
  }

  void _removeNewJudgeCase(int index) {
    setState(() {
      _newJudgeCases.removeAt(index);
    });
  }

  List<String> _parseConstraints() {
    return constraintsController.text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  List<String> _parseInputFormat() {
    return inputFormatController.text
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
  }

  Future<void> _createOrUpdateProblem() async {
    if (titleController.text.trim().isEmpty || descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in title and description.')),
      );
      return;
    }

    final contestIdValue = int.tryParse(contestIdController.text.trim());
    if (selectedVisibility == 'contest_only' && contestIdValue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contest ID is required for contest-only problems.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final constraints = _parseConstraints();
      final inputFormat = _parseInputFormat();
      final allNewCases = [..._newExamples, ..._newJudgeCases];

      if (_isEditing) {
        final problemId = widget.editingProblem!.id;
        final updateResponse = await ApiService.put(
          '/problems/$problemId',
          data: {
            'title': titleController.text.trim(),
            'description': descriptionController.text.trim(),
            'difficulty': selectedDifficulty,
            'tags': tags,
            'constraints': constraints,
            'input_format': inputFormat,
            'code_stubs': _codeStubs,
            'is_active': true,
            'visibility': selectedVisibility,
            'contest_id': selectedVisibility == 'contest_only' ? contestIdValue : null,
          },
        );

        if (updateResponse.statusCode == 200 && allNewCases.isNotEmpty) {
          for (final testCase in allNewCases) {
            await ApiService.post(
              '/problems/$problemId/testcases',
              data: {
                'input': testCase['input'],
                'expected_output': testCase['expected_output'],
                'is_sample': testCase['is_sample'] == true,
                'explanation': testCase['explanation'],
              },
            );
          }
        }
      } else {
        await ApiService.post(
          '/problems',
          data: {
            'title': titleController.text.trim(),
            'description': descriptionController.text.trim(),
            'difficulty': selectedDifficulty,
            'tags': tags,
            'constraints': constraints,
            'input_format': inputFormat,
            'code_stubs': _codeStubs,
            'testCases': allNewCases,
            'visibility': selectedVisibility,
            'contest_id': selectedVisibility == 'contest_only' ? contestIdValue : null,
          },
        );
      }

      ref.invalidate(problemListProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Problem updated successfully!' : 'Problem created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  Widget _labeledField(String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        field,
      ],
    );
  }

  Widget _buildExistingCaseCard(Map<String, dynamic> testCase, {required bool isExample}) {
    final title = isExample ? 'Existing Example' : 'Existing Judge Case';
    final explanation = (testCase['explanation'] ?? '').toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Input: ${testCase['inputs'] ?? testCase['input'] ?? ''}'),
            const SizedBox(height: 4),
            Text('Output: ${testCase['expected_output'] ?? ''}'),
            if (isExample && explanation.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Explanation: $explanation'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNewCaseCard(Map<String, dynamic> testCase, int index, {required bool isExample}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text((isExample ? 'Example ' : 'Judge Case ') + (index + 1).toString()),
        subtitle: Text('Input: ${testCase['input']}\nOutput: ${testCase['expected_output']}'),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => isExample ? _removeNewExample(index) : _removeNewJudgeCase(index),
        ),
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _labeledField(
            'Title',
            TextField(
              controller: titleController,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ),
          const SizedBox(height: 16),
          _labeledField(
            'Description',
            TextField(
              controller: descriptionController,
              maxLines: 7,
              decoration: const InputDecoration(
                hintText: 'Problem text (supports inline formatting in viewer).',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _labeledField(
            'Constraints (one per line)',
            TextField(
              controller: constraintsController,
              maxLines: 5,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ),
          const SizedBox(height: 16),
          _labeledField(
            'Input Format (comma-separated, e.g. nums,target)',
            TextField(
              controller: inputFormatController,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ),
          const SizedBox(height: 16),
          _labeledField(
            'Difficulty',
            DropdownButton<String>(
              value: selectedDifficulty,
              isExpanded: true,
              items: ['easy', 'medium', 'hard']
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => selectedDifficulty = value);
                }
              },
            ),
          ),
          const SizedBox(height: 16),
          _labeledField(
            'Visibility',
            DropdownButton<String>(
              value: selectedVisibility,
              isExpanded: true,
              items: ['public', 'contest_only']
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => selectedVisibility = value);
                }
              },
            ),
          ),
          if (selectedVisibility == 'contest_only') ...[
            const SizedBox(height: 16),
            _labeledField(
              'Contest ID',
              TextField(
                controller: contestIdController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            ),
          ],
          const SizedBox(height: 16),
          _sectionTitle('Tags'),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: tagController,
                  decoration: const InputDecoration(
                    hintText: 'Enter tag',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: _addTag, child: const Text('Add')),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: tags
                .asMap()
                .entries
                .map((entry) => Chip(
                      label: Text(entry.value),
                      onDeleted: () => _removeTag(entry.key),
                    ))
                .toList(),
          ),
          const SizedBox(height: 22),
          _sectionTitle('Examples (for description panel only)'),
          _labeledField(
            'Example Input',
            TextField(
              controller: exampleInputController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'nums = [2,7,11,15]\ntarget = 9',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _labeledField(
            'Example Output',
            TextField(
              controller: exampleOutputController,
              maxLines: 2,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ),
          const SizedBox(height: 10),
          _labeledField(
            'Example Explanation (optional)',
            TextField(
              controller: exampleExplanationController,
              maxLines: 3,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _addExample,
              child: const Text('Add Example'),
            ),
          ),
          const SizedBox(height: 10),
          ..._existingExamples.map((tc) => _buildExistingCaseCard(tc, isExample: true)),
          ..._newExamples
              .asMap()
              .entries
              .map((entry) => _buildNewCaseCard(entry.value, entry.key, isExample: true)),
          const SizedBox(height: 22),
          _sectionTitle('Judge Test Cases (for run/submit evaluation)'),
          _labeledField(
            'Judge Input',
            TextField(
              controller: judgeInputController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'nums = [3,2,4]\ntarget = 6',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _labeledField(
            'Judge Expected Output',
            TextField(
              controller: judgeOutputController,
              maxLines: 2,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _addJudgeCase,
              child: const Text('Add Judge Test Case'),
            ),
          ),
          const SizedBox(height: 10),
          ..._existingJudgeCases.map((tc) => _buildExistingCaseCard(tc, isExample: false)),
          ..._newJudgeCases
              .asMap()
              .entries
              .map((entry) => _buildNewCaseCard(entry.value, entry.key, isExample: false)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _createOrUpdateProblem,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(_isEditing ? 'Update Problem' : 'Create Problem'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (_isEditing) ...[
            const SizedBox(height: 24),
            HiddenTestcaseSection(problemId: widget.editingProblem!.id),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit Problem' : 'Create Problem'),
          elevation: 0,
          actions: [
            IconButton(
              onPressed: _isSubmitting ? null : _createOrUpdateProblem,
              tooltip: _isEditing ? 'Update problem' : 'Create problem',
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Details'),
              Tab(text: 'Starter Code'),
              Tab(text: 'Driver Code'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildDetailsTab(),
            StarterCodeTab(
              codeStubs: _codeStubs,
              onStubChanged: (lang, code) {
                setState(() => _codeStubs[lang] = code);
              },
            ),
            DriverCodeTab(problemId: _isEditing ? widget.editingProblem!.id : null),
          ],
        ),
      ),
    );
  }
}
