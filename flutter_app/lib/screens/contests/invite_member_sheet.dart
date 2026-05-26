import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:codemania/providers/contest_provider.dart';
import 'package:codemania/services/api_service.dart';

class InviteMemberSheet extends ConsumerStatefulWidget {
  const InviteMemberSheet({super.key, required this.teamId});

  final int teamId;

  @override
  ConsumerState<InviteMemberSheet> createState() => _InviteMemberSheetState();
}

class _InviteMemberSheetState extends ConsumerState<InviteMemberSheet> {
  final TextEditingController _usernameController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _usernameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<int?> _resolveUserId(String username) async {
    try {
      final response = await ApiService.get('/api/users/search', params: {'username': username});
      final payload = response.data as Map<String, dynamic>;
      final users = payload['users'] as List? ?? const [];
      if (users.isEmpty) return null;
      final first = users.first as Map<String, dynamic>;
      return (first['id'] as num?)?.toInt();
    } catch (_) {
      return null;
    }
  }

  Future<void> _sendInvite() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      setState(() => _errorText = 'Username is required.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      final userId = await _resolveUserId(username);
      if (userId != null) {
        await ref.read(contestNotifierProvider.notifier).inviteUser(widget.teamId, userId);
      } else {
        await ApiService.post(
          '/api/contests/teams/${widget.teamId}/invite',
          data: {'inviteeUsername': username},
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invite sent!')),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() => _errorText = 'Could not send invite. ${error.toString()}');
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
          const Text('Invite a Member', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          TextField(
            controller: _usernameController,
            focusNode: _focusNode,
            decoration: InputDecoration(
              labelText: 'Username',
              hintText: 'Enter their exact username',
              errorText: _errorText,
            ),
            onChanged: (_) {
              if (_errorText != null) {
                setState(() => _errorText = null);
              }
            },
          ),
          const SizedBox(height: 6),
          const Text(
            "They'll receive an invite notification.",
            style: TextStyle(color: Color(0xFF7A839E), fontSize: 12),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _sendInvite,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Send Invite'),
            ),
          ),
        ],
      ),
    );
  }
}
