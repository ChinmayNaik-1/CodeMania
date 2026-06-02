import 'package:codemania/models/driver_code.dart';
import 'package:codemania/providers/driver_code_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DriverCodeTab extends StatelessWidget {
  const DriverCodeTab({super.key, required this.problemId});

  final int? problemId;

  @override
  Widget build(BuildContext context) {
    if (problemId == null) {
      return const Center(
        child: Card(
          margin: EdgeInsets.all(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('Save the problem first to configure driver code.'),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _openEditorSheet(context, null),
                icon: const Icon(Icons.add),
                label: const Text('Add Driver'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Consumer(
              builder: (context, ref, _) {
                final asyncDrivers = ref.watch(driverCodeListProvider(problemId!));
                return asyncDrivers.when(
                  data: (drivers) {
                    if (drivers.isEmpty) {
                      return const Center(
                        child: Text(
                          'No driver code configured yet.',
                          style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: drivers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final driver = drivers[index];
                        final preview = driver.driverPrefix.replaceAll('\n', ' ');
                        final previewText = preview.length > 60
                            ? preview.substring(0, 60) + '...'
                            : preview;

                        return Card(
                          child: ListTile(
                            title: Text(driver.language),
                            subtitle: Text(
                              previewText,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontFamily: 'Courier',
                              ),
                            ),
                            trailing: Wrap(
                              spacing: 8,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _openEditorSheet(context, driver),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _confirmDelete(context, driver),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Failed to load driver code: $error',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => ref.invalidate(driverCodeListProvider(problemId!)),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openEditorSheet(BuildContext context, DriverCode? driver) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DriverCodeEditorSheet(
        problemId: problemId!,
        driver: driver,
      ),
    );
  }

  void _confirmDelete(BuildContext context, DriverCode driver) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete driver code?'),
        content: Text('Delete ${driver.language} driver code?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () async {
                final dio = ref.read(dioProvider);
                await deleteDriverCode(dio, problemId!, driver.language);
                ref.invalidate(driverCodeListProvider(problemId!));
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }
}

class DriverCodeEditorSheet extends StatefulWidget {
  const DriverCodeEditorSheet({
    super.key,
    required this.problemId,
    this.driver,
  });

  final int problemId;
  final DriverCode? driver;

  @override
  State<DriverCodeEditorSheet> createState() => _DriverCodeEditorSheetState();
}

class _DriverCodeEditorSheetState extends State<DriverCodeEditorSheet> {
  static const _languageOptions = [
    {'value': 'cpp', 'label': 'C++'},
    {'value': 'python', 'label': 'Python 3'},
    {'value': 'java', 'label': 'Java'},
    {'value': 'javascript', 'label': 'JavaScript'},
  ];

  late String _selectedLanguage;
  late TextEditingController _prefixController;
  late TextEditingController _suffixController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.driver?.language ?? 'cpp';
    _prefixController = TextEditingController(text: widget.driver?.driverPrefix ?? '');
    _suffixController = TextEditingController(text: widget.driver?.driverSuffix ?? '');
  }

  @override
  void dispose() {
    _prefixController.dispose();
    _suffixController.dispose();
    super.dispose();
  }

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    if (_selectedLanguage.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Language is required.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final dio = ref.read(dioProvider);
      final driver = DriverCode(
        language: _selectedLanguage,
        driverPrefix: _prefixController.text,
        driverSuffix: _suffixController.text,
      );
      await upsertDriverCode(dio, widget.problemId, driver);
      ref.invalidate(driverCodeListProvider(widget.problemId));
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save driver code: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.driver != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Consumer(
        builder: (context, ref, _) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'Edit Driver Code' : 'Add Driver Code',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 12),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Language',
                  border: OutlineInputBorder(),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedLanguage,
                    isExpanded: true,
                    items: _languageOptions
                        .map(
                          (option) => DropdownMenuItem(
                            value: option['value'],
                            child: Text(option['label']!),
                          ),
                        )
                        .toList(),
                    onChanged: isEditing
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() => _selectedLanguage = value);
                            }
                          },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _prefixController,
                minLines: 8,
                maxLines: 20,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Driver Prefix (code above your solution)',
                  hintText: '// e.g. #include<bits/stdc++.h>\nusing namespace std;',
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontFamily: 'Courier'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _suffixController,
                minLines: 8,
                maxLines: 20,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Driver Suffix (main harness below your solution)',
                  hintText: '// e.g. int main() { ... }',
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontFamily: 'Courier'),
              ),
              const SizedBox(height: 12),
              ExpansionTile(
                title: const Text('Preview assembled code'),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: Colors.grey.shade200,
                    child: Text(
                      [
                        _prefixController.text,
                        '// ── YOUR CODE GOES HERE ──',
                        _suffixController.text,
                      ].join('\n'),
                      style: const TextStyle(fontFamily: 'Courier'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : () => _save(context, ref),
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
