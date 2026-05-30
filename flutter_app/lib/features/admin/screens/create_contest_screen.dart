import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:codemania/services/api_service.dart';

const _kPrimary = Color(0xFF6C5CE7);
const _kBg = Color(0xFFF5F3FF);
const _kTextPri = Color(0xFF1A1A2E);
const _kTextSec = Color(0xFF6B7280);
const _kError = Color(0xFFFF375F);
const _kEasy = Color(0xFF00B8A3);
const _kMedium = Color(0xFFFFA116);
const _kHard = Color(0xFFFF375F);

// ─────────────────────────────────────────────────────────────────────────────
// CreateContestScreen
// ─────────────────────────────────────────────────────────────────────────────

class CreateContestScreen extends ConsumerStatefulWidget {
  const CreateContestScreen({super.key, this.contestId});
  final int? contestId;

  @override
  ConsumerState<CreateContestScreen> createState() =>
      _CreateContestScreenState();
}

class _CreateContestScreenState extends ConsumerState<CreateContestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  String _contestType = 'solo';
  int _maxTeamSize = 2;
  DateTime _startTime = DateTime.now().add(const Duration(days: 1));
  DateTime _endTime = DateTime.now().add(const Duration(days: 1, hours: 2));
  bool _isLoading = false;
  bool _searching = false;
  List<Map<String, dynamic>> _searchResults = [];
  List<_ProblemEntry> _problems = [];

  @override
  void initState() {
    super.initState();
    if (widget.contestId != null) {
      _loadExistingContest();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExistingContest() async {
    try {
      final res =
          await ApiService.get('/api/contests/${widget.contestId}');
      final data = res.data as Map<String, dynamic>;
      setState(() {
        _titleCtrl.text = data['title'] as String? ?? '';
        _descCtrl.text = data['description'] as String? ?? '';
        _contestType = data['contest_type'] as String? ?? 'solo';
        _maxTeamSize = (data['max_team_size'] as num?)?.toInt() ?? 2;
        _startTime =
            DateTime.parse(data['start_time'] as String? ?? '').toLocal();
        _endTime =
            DateTime.parse(data['end_time'] as String? ?? '').toLocal();
        final probs = data['problems'] as List? ?? [];
        _problems = probs.map((p) {
          final pm = p as Map<String, dynamic>;
          return _ProblemEntry(
            id: pm['id'] as int,
            title: pm['title'] as String,
            difficulty: pm['difficulty'] as String? ?? 'medium',
            points: (pm['points'] as num?)?.toInt() ?? 100,
            order: (pm['problem_order'] as num?)?.toInt() ?? 1,
          );
        }).toList();
      });
    } catch (e) {
      _snack('Failed to load contest: $e', isError: true);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? _kError : _kPrimary,
    ));
  }

  Future<void> _searchProblems(String q) async {
    if (q.length < 2) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final res = await ApiService.get('/problems', params: {'search': q});
      final raw = res.data;
      final list = (raw is List)
          ? raw
          : (raw as Map<String, dynamic>?)?['problems'] as List? ?? [];
      if (mounted) {
        setState(() {
          _searchResults = (list)
              .where((p) => _problems.every(
                  (ep) => ep.id != (p as Map<String, dynamic>)['id']))
              .map((p) => p as Map<String, dynamic>)
              .toList();
        });
      }
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _addProblem(Map<String, dynamic> p) {
    final difficulty = p['difficulty'] as String? ?? 'medium';
    final defaultPoints = difficulty == 'easy'
        ? 100
        : difficulty == 'hard'
            ? 300
            : 200;
    setState(() {
      _problems.add(_ProblemEntry(
        id: p['id'] as int,
        title: p['title'] as String,
        difficulty: difficulty,
        points: defaultPoints,
        order: _problems.length + 1,
      ));
      _searchResults.removeWhere((r) => r['id'] == p['id']);
    });
  }

  void _removeProblem(int id) {
    setState(() {
      _problems.removeWhere((p) => p.id == id);
      // Re-number
      for (int i = 0; i < _problems.length; i++) {
        _problems[i] = _problems[i].copyWith(order: i + 1);
      }
    });
  }

  Future<void> _pickDateTime(
      {required bool isStart}) async {
    final initial = isStart ? _startTime : _endTime;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(primary: _kPrimary)),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    final result = DateTime(
        date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _startTime = result;
      } else {
        _endTime = result;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startTime.isAfter(_endTime)) {
      _snack('Start time must be before end time', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final body = {
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        'contest_type': _contestType,
        'max_team_size': _contestType == 'team' ? _maxTeamSize : 1,
        'start_time': _startTime.toUtc().toIso8601String(),
        'end_time': _endTime.toUtc().toIso8601String(),
        'problems': _problems
            .map((p) => {
                  'problem_id': p.id,
                  'points': p.points,
                  'problem_order': p.order,
                })
            .toList(),
      };

      if (widget.contestId == null) {
        await ApiService.post('/api/contests/admin/create', data: body);
        _snack('Contest created!');
      } else {
        await ApiService.put(
            '/api/contests/admin/${widget.contestId}', data: body);
        _snack('Contest updated!');
      }

      if (mounted) context.go('/admin/contests');
    } catch (e) {
      _snack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _publish() async {
    if (widget.contestId == null) return;
    setState(() => _isLoading = true);
    try {
      await ApiService.put(
          '/api/contests/admin/${widget.contestId}/publish');
      _snack('Contest published — now upcoming!');
      if (mounted) context.go('/admin/contests');
    } catch (e) {
      _snack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _fmt(DateTime dt) {
    final l = dt.toLocal();
    final pad = (int n) => n.toString().padLeft(2, '0');
    return '${l.year}-${pad(l.month)}-${pad(l.day)} ${pad(l.hour)}:${pad(l.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.contestId != null;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/admin/contests'),
          icon: const Icon(Icons.arrow_back, color: _kTextPri),
        ),
        title: Text(isEdit ? 'Edit Contest' : 'Create Contest',
            style: const TextStyle(
                color: _kTextPri,
                fontWeight: FontWeight.w700,
                fontSize: 18)),
        actions: [
          if (isEdit)
            TextButton.icon(
              onPressed: _isLoading ? null : _publish,
              icon: const Icon(Icons.publish, color: _kPrimary),
              label: const Text('Publish',
                  style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w700)),
            ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _save,
        backgroundColor: _kPrimary,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.save, color: Colors.white),
        label: Text(isEdit ? 'Save Changes' : 'Create',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Section 1: Basic Info ──────────────────────────────────────
            _SectionCard(
              title: 'Basic Information',
              icon: Icons.info_outline,
              children: [
                TextFormField(
                  controller: _titleCtrl,
                  decoration: _inputDec('Contest Title'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descCtrl,
                  minLines: 3,
                  maxLines: 6,
                  decoration: _inputDec('Description (optional)'),
                ),
                const SizedBox(height: 12),
                // Contest type
                const Text('Contest Type',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: _kTextPri)),
                const SizedBox(height: 8),
                Row(children: [
                  _TypeChip(
                    label: 'Solo',
                    selected: _contestType == 'solo',
                    onTap: () => setState(() => _contestType = 'solo'),
                  ),
                  const SizedBox(width: 8),
                  _TypeChip(
                    label: 'Team',
                    selected: _contestType == 'team',
                    onTap: () => setState(() => _contestType = 'team'),
                  ),
                ]),
                if (_contestType == 'team') ...[
                  const SizedBox(height: 12),
                  Row(children: [
                    const Text('Max Team Size: ',
                        style: TextStyle(fontSize: 14, color: _kTextPri)),
                    IconButton(
                      onPressed: _maxTeamSize > 2
                          ? () => setState(() => _maxTeamSize--)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline,
                          color: _kPrimary),
                    ),
                    Text('$_maxTeamSize',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: _kTextPri)),
                    IconButton(
                      onPressed: _maxTeamSize < 5
                          ? () => setState(() => _maxTeamSize++)
                          : null,
                      icon: const Icon(Icons.add_circle_outline,
                          color: _kPrimary),
                    ),
                  ]),
                ],
              ],
            ),
            const SizedBox(height: 16),
            // ── Section 2: Schedule ────────────────────────────────────────
            _SectionCard(
              title: 'Schedule',
              icon: Icons.schedule,
              children: [
                _DateTimeTile(
                  label: 'Start Time',
                  value: _fmt(_startTime),
                  onTap: () => _pickDateTime(isStart: true),
                ),
                const SizedBox(height: 8),
                _DateTimeTile(
                  label: 'End Time',
                  value: _fmt(_endTime),
                  onTap: () => _pickDateTime(isStart: false),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // ── Section 3: Problems ────────────────────────────────────────
            _SectionCard(
              title: 'Problems',
              icon: Icons.code,
              children: [
                // Search bar
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search problems to add…',
                    prefixIcon:
                        const Icon(Icons.search, color: _kTextSec),
                    suffixIcon: _searching
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: _kPrimary),
                            ),
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF5F3FF),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                  ),
                  onChanged: _searchProblems,
                ),
                // Search results
                if (_searchResults.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5E5F0)),
                    ),
                    child: Column(
                      children: _searchResults.map((p) {
                        final diff = p['difficulty'] as String? ?? 'medium';
                        return ListTile(
                          title: Text(p['title'] as String,
                              style: const TextStyle(fontSize: 14)),
                          leading: _DiffBadge(difficulty: diff),
                          trailing: IconButton(
                            onPressed: () {
                              _addProblem(p);
                              _searchCtrl.clear();
                              setState(() => _searchResults = []);
                            },
                            icon: const Icon(Icons.add_circle,
                                color: _kPrimary),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
                // Added problems (reorderable)
                if (_problems.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Contest Problems',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: _kTextSec)),
                  const SizedBox(height: 6),
                  ReorderableListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex--;
                        final item = _problems.removeAt(oldIndex);
                        _problems.insert(newIndex, item);
                        for (int i = 0; i < _problems.length; i++) {
                          _problems[i] = _problems[i].copyWith(order: i + 1);
                        }
                      });
                    },
                    children: _problems.map((p) {
                      return Container(
                        key: ValueKey(p.id),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F3FF),
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: const Color(0xFFE5E5F0)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.drag_handle,
                              color: _kTextSec, size: 20),
                          const SizedBox(width: 8),
                          Text('#${p.order}',
                              style: const TextStyle(
                                  color: _kTextSec, fontSize: 12)),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(p.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14))),
                          _DiffBadge(difficulty: p.difficulty),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 72,
                            child: TextFormField(
                              initialValue: p.points.toString(),
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                hintText: 'pts',
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 6),
                                isDense: true,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: const BorderSide(
                                        color: Color(0xFFE5E5F0))),
                              ),
                              onChanged: (v) {
                                final pts = int.tryParse(v) ?? p.points;
                                setState(() {
                                  _problems[_problems.indexOf(p)] =
                                      p.copyWith(points: pts);
                                });
                              },
                            ),
                          ),
                          IconButton(
                            onPressed: () => _removeProblem(p.id),
                            icon: const Icon(Icons.close, color: _kError, size: 18),
                          ),
                        ]),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 80), // FAB space
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _kTextSec),
        filled: true,
        fillColor: const Color(0xFFF5F3FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kPrimary),
        ),
      );
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard(
      {required this.title,
      required this.icon,
      required this.children});
  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: _kPrimary, size: 20),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: _kTextPri)),
          ]),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip(
      {required this.label,
      required this.selected,
      required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _kPrimary : const Color(0xFFF5F3FF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected ? _kPrimary : const Color(0xFFE5E5F0)),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : _kTextSec,
                fontWeight: FontWeight.w700,
                fontSize: 14)),
      ),
    );
  }
}

class _DateTimeTile extends StatelessWidget {
  const _DateTimeTile(
      {required this.label, required this.value, required this.onTap});
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F3FF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5E5F0)),
        ),
        child: Row(children: [
          const Icon(Icons.calendar_today, size: 18, color: _kPrimary),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: _kTextSec)),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: _kTextPri)),
          ]),
          const Spacer(),
          const Icon(Icons.edit_outlined, size: 16, color: _kTextSec),
        ]),
      ),
    );
  }
}

class _DiffBadge extends StatelessWidget {
  const _DiffBadge({required this.difficulty});
  final String difficulty;

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (difficulty.toLowerCase()) {
      case 'easy':
        color = _kEasy;
        break;
      case 'hard':
        color = _kHard;
        break;
      default:
        color = _kMedium;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        difficulty[0].toUpperCase() + difficulty.substring(1),
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ─── _ProblemEntry ────────────────────────────────────────────────────────────

class _ProblemEntry {
  final int id;
  final String title;
  final String difficulty;
  final int points;
  final int order;

  const _ProblemEntry({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.points,
    required this.order,
  });

  _ProblemEntry copyWith({int? points, int? order}) => _ProblemEntry(
        id: id,
        title: title,
        difficulty: difficulty,
        points: points ?? this.points,
        order: order ?? this.order,
      );
}
