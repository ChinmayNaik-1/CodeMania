import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:codemania/models/team_invite.dart';
import 'package:codemania/providers/contest_provider.dart';

class InviteResponseSheet extends ConsumerStatefulWidget {
  const InviteResponseSheet({super.key, required this.invite});

  final TeamInvite invite;

  @override
  ConsumerState<InviteResponseSheet> createState() => _InviteResponseSheetState();
}

class _InviteResponseSheetState extends ConsumerState<InviteResponseSheet> {
  bool _isSubmitting = false;

  Future<void> _respond(bool accept) async {
    setState(() => _isSubmitting = true);
    try {
      await ref.read(contestNotifierProvider.notifier).respondToInvite(widget.invite.id, accept);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to respond: $error')),
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
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Team Invite', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Text('Contest: ${widget.invite.contestTitle}'),
          const SizedBox(height: 4),
          Text('Team: ${widget.invite.teamName}'),
          const SizedBox(height: 4),
          Text('Leader: ${widget.invite.leaderUsername}'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSubmitting ? null : () => _respond(false),
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : () => _respond(true),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Accept'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
