import 'package:flutter/material.dart';

class TestCaseEntry {
  TestCaseEntry({
    this.savedId,
    String input = '',
    String output = '',
    String explanation = '',
    String imageUrl = '',
    bool isHidden = false,
  })  : inputCtrl = TextEditingController(text: input),
        outputCtrl = TextEditingController(text: output),
        explanationCtrl = TextEditingController(text: explanation),
        imageUrlCtrl = TextEditingController(text: imageUrl),
        isHidden = isHidden;

  int? savedId;
  final TextEditingController inputCtrl;
  final TextEditingController outputCtrl;
  final TextEditingController explanationCtrl;
  final TextEditingController imageUrlCtrl;
  bool isHidden;

  bool get hasRequiredFields =>
      inputCtrl.text.trim().isNotEmpty && outputCtrl.text.trim().isNotEmpty;

  Map<String, dynamic> toPayload() {
    return {
      'input': inputCtrl.text.trim(),
      'expected_output': outputCtrl.text.trim(),
      'explanation': explanationCtrl.text.trim().isEmpty
          ? null
          : explanationCtrl.text.trim(),
      'image_url': imageUrlCtrl.text.trim().isEmpty
          ? null
          : imageUrlCtrl.text.trim(),
      'is_hidden': isHidden,
    };
  }

  void dispose() {
    inputCtrl.dispose();
    outputCtrl.dispose();
    explanationCtrl.dispose();
    imageUrlCtrl.dispose();
  }
}

class TestcaseEditorSection extends StatelessWidget {
  const TestcaseEditorSection({
    super.key,
    required this.entries,
    required this.onAdd,
    required this.onRemove,
    required this.onChanged,
  });

  final List<TestCaseEntry> entries;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < entries.length; i++) _caseCard(context, i, entries[i]),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add Test Case'),
          ),
        ),
      ],
    );
  }

  Widget _caseCard(BuildContext context, int index, TestCaseEntry entry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Case ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                const Text('Hidden', style: TextStyle(fontSize: 12)),
                Switch(
                  value: entry.isHidden,
                  onChanged: (value) {
                    entry.isHidden = value;
                    onChanged();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red[400],
                  onPressed: () => onRemove(index),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: entry.inputCtrl,
              minLines: 2,
              maxLines: 6,
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Required' : null,
              decoration: const InputDecoration(
                labelText: 'Input *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: entry.outputCtrl,
              minLines: 2,
              maxLines: 6,
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Required' : null,
              decoration: const InputDecoration(
                labelText: 'Expected Output *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: entry.explanationCtrl,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Explanation (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: entry.imageUrlCtrl,
              minLines: 1,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Diagram Image URL (optional)',
                hintText: 'https://...jpg - shown above example in description',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
