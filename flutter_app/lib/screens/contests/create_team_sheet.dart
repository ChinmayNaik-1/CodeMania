import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:codemania/providers/contest_provider.dart';

class CreateTeamSheet extends ConsumerStatefulWidget {
  const CreateTeamSheet({super.key, required this.contestId});

  final int contestId;

  @override
  ConsumerState<CreateTeamSheet> createState() => _CreateTeamSheetState();
}

class _CreateTeamSheetState extends ConsumerState<CreateTeamSheet> {
  final TextEditingController _nameController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool _isValidName(String value) {
    final trimmed = value.trim();
    final regex = RegExp(r'^[A-Za-z0-9\s-]+$');
    return trimmed.isNotEmpty && regex.hasMatch(trimmed);
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (!_isValidName(name)) {
      setState(() => _errorText = 'Use letters, numbers, spaces, or hyphens only.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      await ref.read(contestNotifierProvider.notifier).createTeam(widget.contestId, name);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Team created! Invite your teammates.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create team: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE6E0F3),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Create Your Team', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text("You'll be the team leader.", style: TextStyle(color: Color(0xFF7A839E))),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            maxLength: 30,
            decoration: InputDecoration(
              labelText: 'Team Name',
              hintText: 'e.g. Debug Demons',
              errorText: _errorText,
            ),
            onChanged: (_) {
              if (_errorText != null) {
                setState(() => _errorText = null);
              }
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Create Team'),
            ),
          ),
        ],
      ),
    );
  }
}
