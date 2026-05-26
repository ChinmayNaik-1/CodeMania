import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:codemania/config.dart';
import 'package:codemania/models/contest.dart';
import 'package:codemania/providers/auth_provider.dart';
import 'package:codemania/providers/contest_provider.dart';
import 'package:codemania/screens/admin/add_existing_problem_sheet.dart';
import 'package:codemania/screens/admin/create_problem_screen.dart';
import 'package:codemania/services/api_service.dart';
import 'package:dio/dio.dart';

class AdminContestScreen extends ConsumerStatefulWidget {
  const AdminContestScreen({super.key});

  @override
  ConsumerState<AdminContestScreen> createState() => _AdminContestScreenState();
}

class _AdminContestScreenState extends ConsumerState<AdminContestScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _startsAt;
  DateTime? _endsAt;
  int _maxTeamSize = 1;
  int _penaltyMinutes = 20;
  int? _selectedContestId;

  Dio _client() {
    final token = Config.currentToken;
    return Dio(
      BaseOptions(
        baseUrl: Config.apiBaseUrl,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date == null) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );

    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _createContest() async {
    if (_titleController.text.trim().isEmpty || _startsAt == null || _endsAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title, start time, and end time are required.')),
      );
      return;
    }

    if (_endsAt!.isBefore(_startsAt!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time.')),
      );
      return;
    }

    try {
      await ApiService.post(
        '/api/admin/contests',
        data: {
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'max_team_size': _maxTeamSize,
          'penalty_minutes': _penaltyMinutes,
          'starts_at': _startsAt!.toIso8601String(),
          'ends_at': _endsAt!.toIso8601String(),
        },
      );

      ref.invalidate(contestListProvider);
      if (mounted) {
        setState(() {
          _titleController.clear();
          _descriptionController.clear();
          _startsAt = null;
          _endsAt = null;
          _maxTeamSize = 1;
          _penaltyMinutes = 20;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contest created.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create contest: $error')),
        );
      }
    }
  }

  Future<bool> _confirmStatusChange(String nextStatus) async {
    if (nextStatus != 'in_progress' && nextStatus != 'ended') {
      return true;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm status change'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => ctx.pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => ctx.pop(true), child: const Text('Confirm')),
        ],
      ),
    );

    return confirmed == true;
  }

  Future<void> _updateStatus(int contestId, String status) async {
    final confirmed = await _confirmStatusChange(status);
    if (!confirmed) return;

    try {
      final dio = _client();
      await dio.patch(
        '/api/admin/contests/$contestId/status',
        data: {'status': status},
      );
      ref.invalidate(contestListProvider);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    if (authState.user == null || authState.user?.isAdmin != true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go('/home');
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final contestsAsync = ref.watch(contestListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Contest Management')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Existing Contests', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          contestsAsync.when(
            data: (contests) => _ContestTable(
              contests: contests,
              onStatusChange: _updateStatus,
              onSelectContest: (id) => setState(() => _selectedContestId = id),
              onAddProblem: (contestId) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CreateProblemScreen(
                      visibility: 'contest_only',
                      contestId: contestId,
                    ),
                  ),
                );
              },
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text('Failed to load contests: $error'),
          ),
          const SizedBox(height: 20),
          const Divider(height: 32),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('New Contest', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _maxTeamSize,
                          decoration: const InputDecoration(labelText: 'Team size'),
                          items: [1, 2, 3, 4]
                              .map((size) => DropdownMenuItem(value: size, child: Text(size.toString())))
                              .toList(),
                          onChanged: (value) => setState(() => _maxTeamSize = value ?? 1),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Penalty (min)'),
                          onChanged: (value) => setState(() => _penaltyMinutes = int.tryParse(value) ?? 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _DateField(
                          label: 'Start time',
                          value: _startsAt,
                          onPick: () async {
                            final picked = await _pickDateTime(_startsAt ?? DateTime.now());
                            if (picked != null) setState(() => _startsAt = picked);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DateField(
                          label: 'End time',
                          value: _endsAt,
                          onPick: () async {
                            final picked = await _pickDateTime(_endsAt ?? DateTime.now().add(const Duration(hours: 2)));
                            if (picked != null) setState(() => _endsAt = picked);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _createContest,
                      child: const Text('Create Contest'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _selectedContestId == null
                  ? null
                  : () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CreateProblemScreen(
                            visibility: 'contest_only',
                            contestId: _selectedContestId,
                          ),
                        ),
                      );
                    },
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Create Contest-Only Problem'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onPick,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final text = value == null ? 'Select' : value!.toLocal().toString();
    return OutlinedButton(
      onPressed: onPick,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
              Text(label, style: const TextStyle(color: Color(0xFF7A839E), fontSize: 12)),
              const SizedBox(height: 4),
              Text(text, style: const TextStyle(color: Color(0xFF242453))),
        ],
      ),
    );
  }
}

class _ContestTable extends StatelessWidget {
  const _ContestTable({
    required this.contests,
    required this.onStatusChange,
    required this.onSelectContest,
    required this.onAddProblem,
  });

  final List<Contest> contests;
  final void Function(int contestId, String status) onStatusChange;
  final ValueChanged<int> onSelectContest;
  final ValueChanged<int> onAddProblem;

  ({Color color, String label}) _statusStyle(String status) {
    switch (status) {
      case 'registration_open':
        return (color: const Color(0xFF2D8CFF), label: 'Open');
      case 'in_progress':
        return (color: const Color(0xFF2EAF57), label: 'Live');
      case 'ended':
        return (color: const Color(0xFF7A839E), label: 'Ended');
      default:
        return (color: const Color(0xFF7A839E), label: 'Upcoming');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (contests.isEmpty) {
      return const Text('No contests found.');
    }

    return Column(
      children: contests.map((contest) {
        final status = _statusStyle(contest.status);
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              ListTile(
                onTap: () => onSelectContest(contest.id),
                title: Text(contest.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  '${contest.startsAt.toLocal()} → ${contest.endsAt.toLocal()} • Team size ${contest.maxTeamSize}',
                  style: const TextStyle(color: Color(0xFF7A839E), fontSize: 12),
                ),
                leading: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: status.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    status.label,
                    style: TextStyle(color: status.color, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
                trailing: SizedBox(
                  width: 160,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => onAddProblem(contest.id),
                      ),
                      DropdownButton<String>(
                        value: contest.status,
                        underline: const SizedBox.shrink(),
                        items: const [
                          DropdownMenuItem(value: 'upcoming', child: Text('upcoming')),
                          DropdownMenuItem(value: 'registration_open', child: Text('registration_open')),
                          DropdownMenuItem(value: 'in_progress', child: Text('in_progress')),
                          DropdownMenuItem(value: 'ended', child: Text('ended')),
                        ],
                        onChanged: (value) {
                          if (value != null) onStatusChange(contest.id, value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.playlist_add),
                    label: const Text('Add Existing Problem'),
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => AddExistingProblemSheet(contestId: contest.id),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
