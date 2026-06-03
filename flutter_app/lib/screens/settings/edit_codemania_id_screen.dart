import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:codemania/providers/auth_provider.dart';
import 'package:codemania/services/api_service.dart';

class EditCodeManiaIdScreen extends ConsumerStatefulWidget {
  const EditCodeManiaIdScreen({super.key});

  @override
  ConsumerState<EditCodeManiaIdScreen> createState() => _EditCodeManiaIdScreenState();
}

class _EditCodeManiaIdScreenState extends ConsumerState<EditCodeManiaIdScreen> {
  late TextEditingController _idController;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _idController = TextEditingController(text: user?.username ?? '');
  }

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  Future<void> _saveId() async {
    final newId = _idController.text.trim();
    
    if (newId.isEmpty) {
      setState(() => _errorMessage = 'CodeMania ID cannot be empty');
      return;
    }

    if (newId.length < 3) {
      setState(() => _errorMessage = 'CodeMania ID must be at least 3 characters');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.put('/profile/username', data: {
        'username': newId,
      });

      if (response.statusCode == 200) {
        // Update auth provider with new user data
        final currentUser = ref.read(authProvider).user;
        if (currentUser != null) {
          final updatedUser = currentUser.copyWith(username: newId);
          ref.read(authProvider.notifier).updateUser(updatedUser);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('CodeMania ID updated successfully')),
          );
          context.pop();
        }
      } else {
        setState(() => _errorMessage = response.data['error'] ?? 'Failed to update CodeMania ID');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to update CodeMania ID: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('CodeMania ID'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveId,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Confirm',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ID',
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _idController,
                      autofocus: true,
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Enter your CodeMania ID',
                        hintStyle: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Only one change allowed every 90 days.',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
