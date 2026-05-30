import 'package:codemania/features/admin/providers/create_problem_provider.dart';
import 'package:codemania/features/admin/widgets/testcase_editor_section.dart';
import 'package:codemania/models/problem_model.dart';
import 'package:codemania/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
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
  ConsumerState<CreateProblemScreen> createState() =>
      _CreateProblemScreenState();
}

class _CreateProblemScreenState extends ConsumerState<CreateProblemScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _topicsCtrl = TextEditingController();
  final _constraintsCtrl = TextEditingController();
  final _followUpCtrl = TextEditingController();

  final List<TextEditingController> _hintControllers = [];

  String _difficulty = 'Easy';

  final Map<String, TextEditingController> _stubControllers = {
    'cpp': TextEditingController(),
    'python': TextEditingController(),
    'java': TextEditingController(),
  };

  final Map<String, TextEditingController> _driverPrefixControllers = {
    'cpp': TextEditingController(),
    'python': TextEditingController(),
    'java': TextEditingController(),
  };

  final Map<String, TextEditingController> _driverSuffixControllers = {
    'cpp': TextEditingController(),
    'python': TextEditingController(),
    'java': TextEditingController(),
  };

  final List<TestCaseEntry> _entries = [];
  final List<int> _deletedIds = [];

  bool _isSaving = false;
  bool _isInit = false;
  bool _isContestExclusive = false;

  bool get _isEditing => widget.editingProblem != null;

  @override
  void initState() {
    super.initState();
    _difficulty = 'Easy';
    if (widget.visibility != null) {
      _isContestExclusive = widget.visibility == 'contest_only';
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isEditing) {
        _loadProblem(widget.editingProblem!.id);
      } else {
        setState(() {
          _entries.add(TestCaseEntry());
          _isInit = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _topicsCtrl.dispose();
    _constraintsCtrl.dispose();
    _followUpCtrl.dispose();
    for (final controller in _hintControllers) {
      controller.dispose();
    }
    for (final controller in _stubControllers.values) {
      controller.dispose();
    }
    for (final controller in _driverPrefixControllers.values) {
      controller.dispose();
    }
    for (final controller in _driverSuffixControllers.values) {
      controller.dispose();
    }
    for (final entry in _entries) {
      entry.dispose();
    }
    super.dispose();
  }

  Future<void> _loadProblem(int id) async {
    final notifier = ref.read(createProblemProvider.notifier);
    final problem = await notifier.loadProblem(id);
    if (problem == null) return;

    _titleCtrl.text = problem.title;
    _descCtrl.text = problem.description;
    _topicsCtrl.text = problem.topics.join(', ');
    _constraintsCtrl.text = problem.constraints ?? '';
    _followUpCtrl.text = problem.followUp ?? '';
    _difficulty = _normalizeDifficulty(problem.difficulty);
    _isContestExclusive = problem.isContestExclusive;

    _hintControllers
      ..forEach((ctrl) => ctrl.dispose())
      ..clear();
    for (final hint in problem.hints) {
      _hintControllers.add(TextEditingController(text: hint));
    }

    _stubControllers['cpp']!.text = problem.codeStubs?.cpp ?? '';
    _stubControllers['python']!.text = problem.codeStubs?.python ?? '';
    _stubControllers['java']!.text = problem.codeStubs?.java ?? '';

    await _loadTestCases(id);
    await _loadDriverCode(id);

    if (mounted) {
      setState(() {
        _isInit = true;
      });
    }
  }

  Future<void> _loadTestCases(int id) async {
    _entries.clear();
    try {
      final response = await ApiService.get('/api/admin/problems/$id/testcases');
      if (response.data is List && (response.data as List).isNotEmpty) {
        for (final row in (response.data as List).whereType<Map>()) {
          final mapped = Map<String, dynamic>.from(row.cast<String, dynamic>());
          _entries.add(
            TestCaseEntry(
              savedId: (mapped['id'] as num?)?.toInt(),
              input: mapped['input']?.toString() ?? '',
              output: mapped['expected_output']?.toString() ?? '',
              explanation: mapped['explanation']?.toString() ?? '',
              imageUrl: mapped['image_url']?.toString() ?? '',
              isHidden: mapped['is_hidden'] == true,
            ),
          );
        }
      } else if (response.data is Map && response.data['error'] != null) {
         debugPrint('Failed testcases: ${response.data['error']}');
      }
    } catch (e) {
      debugPrint('Error loading testcases: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load test cases.')),
        );
      }
    }

    if (_entries.isEmpty) {
      _entries.add(TestCaseEntry());
    }
  }

  Future<void> _loadDriverCode(int id) async {
    try {
      final response = await ApiService.get('/api/admin/problems/$id/drivers');
      if (response.data is Map && response.data['drivers'] is List) {
        for (final row in (response.data['drivers'] as List).whereType<Map>()) {
          final mapped = Map<String, dynamic>.from(row.cast<String, dynamic>());
          final language = mapped['language']?.toString();
          if (language == null || !_driverPrefixControllers.containsKey(language)) {
            continue;
          }
          _driverPrefixControllers[language]!.text = mapped['driver_prefix']?.toString() ?? '';
          _driverSuffixControllers[language]!.text = mapped['driver_suffix']?.toString() ?? '';
        }
      } else if (response.data is Map && response.data['error'] != null) {
         debugPrint('Failed drivers: ${response.data['error']}');
      }
    } catch (e) {
      debugPrint('Error loading drivers: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load driver code.')),
        );
      }
    }
  }

  String _normalizeDifficulty(String value) {
    switch (value.toLowerCase()) {
      case 'easy':
        return 'Easy';
      case 'hard':
        return 'Hard';
      case 'medium':
      default:
        return 'Medium';
    }
  }

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

  List<String> _parseTopics() {
    return _topicsCtrl.text
        .split(',')
        .map((topic) => topic.trim())
        .where((topic) => topic.isNotEmpty)
        .toList();
  }

  Future<void> _onSave() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final hasTestCase = _entries.any((entry) => entry.hasRequiredFields);
    if (!hasTestCase) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one test case.')),
      );
      return;
    }

    final payload = {
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'difficulty': _difficulty.toLowerCase(),
      'topics': _parseTopics(),
      'constraints': _constraintsCtrl.text.trim(),
      'hints': _hintControllers
          .map((controller) => controller.text.trim())
          .where((text) => text.isNotEmpty)
          .toList(),
      'follow_up': _followUpCtrl.text.trim().isEmpty
          ? null
          : _followUpCtrl.text.trim(),
      'is_contest_exclusive': _isContestExclusive,
      'code_stubs': {
        'cpp': _stubControllers['cpp']!.text,
        'python': _stubControllers['python']!.text,
        'java': _stubControllers['java']!.text,
      },
    };

    final driverCode = <String, Map<String, String>>{};
    for (final lang in _driverPrefixControllers.keys) {
      driverCode[lang] = {
        'prefix': _driverPrefixControllers[lang]!.text,
        'suffix': _driverSuffixControllers[lang]!.text,
      };
    }

    setState(() => _isSaving = true);
    final notifier = ref.read(createProblemProvider.notifier);
    final result = await notifier.saveProblem(
      payload: payload,
      entries: _entries,
      deletedIds: _deletedIds,
      driverCode: driverCode,
      problemId: _isEditing ? widget.editingProblem!.id : null,
    );
    setState(() => _isSaving = false);

    if (result == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save problem.')),
        );
      }
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved')), 
    );
    if (_isEditing) {
      context.pop();
    } else {
      context.go('/admin/problems/manage');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createProblemProvider);
    final title = _isEditing
        ? 'Edit Problem: ${widget.editingProblem!.title}'
        : 'Create Problem';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving || state.isLoading || !_isInit ? null : _onSave,
        backgroundColor: const Color(0xFF2CBB5D),
        icon: const Icon(Icons.save),
        label: const Text('Save Problem'),
      ),
      body: state.isLoading || !_isInit
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C3CE1)))
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildBasicInfoSection(context),
                    _buildTestCasesSection(),
                    _buildStarterCodeSection(),
                    _buildDriverCodeSection(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBasicInfoSection(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: true,
      title: const Text('Basic Info'),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Problem Title *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _difficulty,
                decoration: InputDecoration(
                  labelText: 'Difficulty *',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: _difficultyColor(_difficulty).withOpacity(0.08),
                ),
                items: const ['Easy', 'Medium', 'Hard']
                    .map((value) => DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _difficulty = value);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _topicsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Topics',
                  hintText: 'Array, Two Pointers, Hash Map',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                minLines: 8,
                maxLines: null,
                decoration: const InputDecoration(
                  labelText: 'Description (Markdown supported)',
                  hintText: 'Use **bold**, `code`,\n\n```cpp\ncode block\n```',
                  border: OutlineInputBorder(),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => _openMarkdownPreview(context, _descCtrl.text),
                  child: const Text('Preview'),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _constraintsCtrl,
                minLines: 3,
                maxLines: null,
                decoration: const InputDecoration(
                  labelText: 'Constraints (Markdown, use - for bullets)',
                  hintText: '- 1 <= n <= 10^5\n- -10^9 <= nums[i] <= 10^9',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _followUpCtrl,
                decoration: const InputDecoration(
                  labelText: 'Follow-up (optional)',
                  hintText: 'Could you do it in O(n log n)?',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Contest Exclusive'),
                subtitle: const Text('Hide from main problem list'),
                value: _isContestExclusive,
                onChanged: (val) => setState(() => _isContestExclusive = val),
              ),
              const SizedBox(height: 12),
              _buildHintsSection(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHintsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Hints', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        for (int i = 0; i < _hintControllers.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _hintControllers[i],
                    decoration: InputDecoration(
                      hintText: 'Hint ${i + 1}',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.remove_circle),
                  onPressed: () {
                    setState(() {
                      _hintControllers[i].dispose();
                      _hintControllers.removeAt(i);
                    });
                  },
                ),
              ],
            ),
          ),
        OutlinedButton.icon(
          onPressed: () {
            setState(() => _hintControllers.add(TextEditingController()));
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Hint'),
        ),
      ],
    );
  }

  Widget _buildTestCasesSection() {
    return ExpansionTile(
      title: const Text('Test Cases'),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TestcaseEditorSection(
            entries: _entries,
            onAdd: () {
              setState(() => _entries.add(TestCaseEntry()));
            },
            onRemove: (index) {
              final entry = _entries.removeAt(index);
              if (entry.savedId != null) {
                _deletedIds.add(entry.savedId!);
              }
              entry.dispose();
              setState(() {});
            },
            onChanged: () => setState(() {}),
          ),
        ),
      ],
    );
  }

  Widget _buildStarterCodeSection() {
    return ExpansionTile(
      title: const Text('Starter Code'),
      children: [
        DefaultTabController(
          length: 3,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const TabBar(
                  isScrollable: true,
                  tabs: [
                    Tab(text: 'C++'),
                    Tab(text: 'Python'),
                    Tab(text: 'Java'),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 300,
                  child: TabBarView(
                    children: [
                      _stubEditor('C++', _stubControllers['cpp']!),
                      _stubEditor('Python', _stubControllers['python']!),
                      _stubEditor('Java', _stubControllers['java']!),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _stubEditor(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      minLines: 8,
      maxLines: null,
      style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
      decoration: InputDecoration(
        labelText: '$label starter code',
        border: const OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
    );
  }

  Widget _buildDriverCodeSection() {
    return ExpansionTile(
      title: const Text('Driver Code'),
      children: [
        DefaultTabController(
          length: 3,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const TabBar(
                  isScrollable: true,
                  tabs: [
                    Tab(text: 'C++'),
                    Tab(text: 'Python'),
                    Tab(text: 'Java'),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 360,
                  child: TabBarView(
                    children: [
                      _driverEditor('cpp'),
                      _driverEditor('python'),
                      _driverEditor('java'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _driverEditor(String lang) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          TextFormField(
            controller: _driverPrefixControllers[lang]!,
            minLines: 5,
            maxLines: null,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            decoration: const InputDecoration(
              labelText: 'Driver Prefix',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _driverSuffixControllers[lang]!,
            minLines: 5,
            maxLines: null,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            decoration: const InputDecoration(
              labelText: 'Driver Suffix',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }

  void _openMarkdownPreview(BuildContext context, String content) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: MarkdownBody(data: content),
          ),
        );
      },
    );
  }
}
