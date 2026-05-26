import 'package:codemania/models/problem_model.dart';
import 'package:codemania/screens/problem_page/widgets/monaco_editor_view.dart';
import 'package:flutter/material.dart';

class CodeEditorPanel extends StatefulWidget {
  const CodeEditorPanel({
    super.key,
    required this.problem,
    required this.selectedLanguage,
    required this.currentCode,
    required this.saveStatusText,
    required this.onLanguageChanged,
    required this.onCodeChanged,
  });

  final Problem problem;
  final String selectedLanguage;
  final String currentCode;
  final String saveStatusText;
  final Function(String lang) onLanguageChanged;
  final Function(String code) onCodeChanged;

  @override
  State<CodeEditorPanel> createState() => _CodeEditorPanelState();
}

class _CodeEditorPanelState extends State<CodeEditorPanel> {
  Widget _headerIcon(
    IconData icon, {
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 16,
            color: const Color(0xFF8A8A8A),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF7F7F7),
            border: Border(
              bottom: BorderSide(
                color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
              ),
            ),
          ),
          child: Row(
            children: [
              Theme(
                data: Theme.of(context).copyWith(
                  focusColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: widget.selectedLanguage,
                    dropdownColor: isDark ? const Color(0xFF2D2D2D) : Colors.white,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? const Color(0xFFEBEBEB) : const Color(0xFF262626),
                      fontFamily: 'Inter',
                    ),
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      size: 16,
                      color: isDark ? const Color(0xFF8A8A8A) : const Color(0xFF595959),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'python', child: Text('Python 3')),
                      DropdownMenuItem(value: 'cpp', child: Text('C++')),
                      DropdownMenuItem(value: 'java', child: Text('Java')),
                      DropdownMenuItem(value: 'javascript', child: Text('JavaScript')),
                    ],
                    onChanged: (lang) {
                      if (lang != null) widget.onLanguageChanged(lang);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.lock_outline,
                size: 14,
                color: Color(0xFF8A8A8A),
              ),
              const SizedBox(width: 4),
              const Text(
                'Auto',
                style: TextStyle(fontSize: 12, color: Color(0xFF8A8A8A)),
              ),
              const SizedBox(width: 12),
              Text(
                widget.saveStatusText,
                style: const TextStyle(fontSize: 12, color: Color(0xFF8A8A8A)),
              ),
              const Spacer(),
              _headerIcon(
                Icons.format_align_left_outlined,
                tooltip: 'Format',
                onTap: () {},
              ),
              _headerIcon(
                Icons.undo,
                tooltip: 'Undo',
                onTap: () {},
              ),
              _headerIcon(
                Icons.fullscreen,
                tooltip: 'Fullscreen',
                onTap: () {},
              ),
            ],
          ),
        ),
        Expanded(
          child: MonacoEditorView(
            code: widget.currentCode,
            language: widget.selectedLanguage,
            theme: isDark ? 'vs-dark' : 'vs',
            onCodeChanged: widget.onCodeChanged,
          ),
        ),
        Container(
          height: 24,
          color: const Color(0xFF007ACC),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.saveStatusText.isEmpty ? ' ' : widget.saveStatusText,
                style: TextStyle(fontSize: 11, color: Colors.white),
              ),
              Text(
                '${widget.selectedLanguage.toUpperCase()} editor',
                style: const TextStyle(fontSize: 11, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
