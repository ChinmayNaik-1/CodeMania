import 'package:flutter/material.dart';

class StarterCodeTab extends StatefulWidget {
  const StarterCodeTab({
    super.key,
    required this.codeStubs,
    required this.onStubChanged,
  });

  final Map<String, String> codeStubs;
  final void Function(String lang, String code) onStubChanged;

  @override
  State<StarterCodeTab> createState() => _StarterCodeTabState();
}

class _StarterCodeTabState extends State<StarterCodeTab> {
  static const _languages = [
    {'key': 'cpp', 'label': 'C++'},
    {'key': 'python', 'label': 'Python 3'},
    {'key': 'java', 'label': 'Java'},
    {'key': 'javascript', 'label': 'JavaScript'},
  ];

  static const _defaultTemplates = {
    'cpp': 'class Solution {\npublic:\n    // write your solution here\n\n};',
    'python': 'class Solution:\n    def solve(self):\n        pass',
    'java': 'class Solution {\n    // write your solution here\n}',
    'javascript': 'var solve = function() {\n    \n};',
  };

  late String _selectedLanguage;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = 'cpp';
    _controller = TextEditingController(
      text: widget.codeStubs[_selectedLanguage] ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant StarterCodeTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextText = widget.codeStubs[_selectedLanguage] ?? '';
    if (_controller.text != nextText) {
      _controller.text = nextText;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setLanguage(String language) {
    setState(() {
      _selectedLanguage = language;
      _controller.text = widget.codeStubs[_selectedLanguage] ?? '';
    });
  }

  void _applyTemplate(String code) {
    widget.onStubChanged(_selectedLanguage, code);
    setState(() {
      _controller.text = code;
    });
  }

  @override
  Widget build(BuildContext context) {
    final label = _languages.firstWhere((item) => item['key'] == _selectedLanguage)['label'];

    return DefaultTabController(
      length: _languages.length,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TabBar(
              isScrollable: true,
              onTap: (index) => _setLanguage(_languages[index]['key']!),
              tabs: _languages
                  .map((lang) => Tab(text: lang['label'] as String))
                  .toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              minLines: 12,
              maxLines: 25,
              onChanged: (value) => widget.onStubChanged(_selectedLanguage, value),
              style: const TextStyle(fontFamily: 'Courier', fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Starter code for $label',
                alignLabelWithHint: true,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This code appears in the editor when a user opens this\n'
              'problem for the first time. Leave empty to use the\n'
              'language default template.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton(
                  onPressed: () => _applyTemplate(
                    _defaultTemplates[_selectedLanguage] ?? '',
                  ),
                  child: const Text('Insert default template'),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () => _applyTemplate(''),
                  child: const Text('Clear'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
