import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:codemania/services/api_service.dart';

// ─── Shared input decoration helper ──────────────────────────────────────────
InputDecoration _fieldDecoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Color(0xFF666680)),
    filled: true,
    fillColor: const Color(0xFFF0F0F8),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFE5E5F0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFE5E5F0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF6C3CE1), width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFEF4444)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class EditProfileSheet extends ConsumerStatefulWidget {
  const EditProfileSheet({super.key});

  @override
  ConsumerState<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _avatarCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    _avatarCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final body = <String, dynamic>{};
      if (_usernameCtrl.text.trim().isNotEmpty) {
        body['username'] = _usernameCtrl.text.trim();
      }
      if (_bioCtrl.text.trim().isNotEmpty) {
        body['bio'] = _bioCtrl.text.trim();
      }
      if (_avatarCtrl.text.trim().isNotEmpty) {
        body['avatar_url'] = _avatarCtrl.text.trim();
      }

      final res = await ApiService.put('/api/profile', data: body);
      if (res.statusCode == 200) {
        if (mounted) Navigator.of(context).pop();
      } else {
        throw Exception(res.data['error'] ?? 'Error updating profile');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Handle bar ───────────────────────────────────────────────
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E5F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const Text(
              'Edit Profile',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Leave fields blank to keep existing values.',
              style: TextStyle(color: Color(0xFF666680), fontSize: 13),
            ),
            const SizedBox(height: 20),

            // ── Username ─────────────────────────────────────────────────
            TextFormField(
              controller: _usernameCtrl,
              decoration: _fieldDecoration('Username'),
              style: const TextStyle(color: Color(0xFF1A1A2E)),
              validator: (v) {
                if (v == null || v.isEmpty) return null;
                if (!RegExp(r'^\w{3,20}$').hasMatch(v)) {
                  return '3–20 characters, letters/numbers/underscore only';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // ── Bio ──────────────────────────────────────────────────────
            TextFormField(
              controller: _bioCtrl,
              decoration: _fieldDecoration('Bio'),
              style: const TextStyle(color: Color(0xFF1A1A2E)),
              maxLength: 150,
              maxLines: 2,
              buildCounter: (context, {required currentLength, required isFocused, maxLength}) =>
                  Text('$currentLength / $maxLength',
                      style: const TextStyle(color: Color(0xFF666680), fontSize: 11)),
            ),
            const SizedBox(height: 14),

            // ── Avatar URL ───────────────────────────────────────────────
            TextFormField(
              controller: _avatarCtrl,
              decoration: _fieldDecoration('Avatar URL'),
              style: const TextStyle(color: Color(0xFF1A1A2E)),
              keyboardType: TextInputType.url,
              validator: (v) {
                if (v == null || v.isEmpty) return null;
                final uri = Uri.tryParse(v);
                if (uri == null || !uri.isAbsolute) return 'Enter a valid URL';
                return null;
              },
            ),
            const SizedBox(height: 28),

            // ── Save button ──────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isLoading ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6C3CE1),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Changes',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
