import 'package:codemania/models/problem_model.dart';
import 'package:flutter/material.dart';

class DescriptionTab extends StatelessWidget {
  const DescriptionTab({
    super.key,
    required this.problem,
  });

  final Problem problem;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '${problem.id}. ${problem.title}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _difficultyBadge(problem.difficulty),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _MetaChip(label: 'Topics'),
              _MetaChip(label: 'Companies'),
              _MetaChip(label: '💡 Hint'),
            ],
          ),
          const SizedBox(height: 16),
          ..._buildDescriptionParagraphs(isDark),
          if (problem.testCases.isNotEmpty) ...[
            const SizedBox(height: 20),
            ..._buildExamples(isDark),
          ],
          if (problem.constraints.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Text(
              'Constraints:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...problem.constraints.map(
              (constraint) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Text('• ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.45,
                            color: isDark ? const Color(0xFFE5E7EB) : const Color(0xFF111827),
                          ),
                          children: parseInlineText(constraint, isDark),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildDescriptionParagraphs(bool isDark) {
    final lines = problem.description
        .split('\n')
        .map((line) => line.trimRight())
        .toList();

    final widgets = <Widget>[];
    for (final line in lines) {
      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 10));
      } else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  height: 1.55,
                  color: isDark ? const Color(0xFFE5E7EB) : const Color(0xFF111827),
                ),
                children: parseInlineText(line, isDark),
              ),
            ),
          ),
        );
      }
    }

    return widgets;
  }

  List<Widget> _buildExamples(bool isDark) {
    final maxExamples = problem.testCases.length < 3 ? problem.testCases.length : 3;

    return List<Widget>.generate(maxExamples, (index) {
      final testCase = problem.testCases[index];
      final inputText = _formatInput(testCase);

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Example ${index + 1}:',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF3A3A3A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _labelValueLine('Input:', inputText),
                  const SizedBox(height: 6),
                  _labelValueLine('Output:', testCase.expectedOutput),
                  if ((testCase.explanation ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _labelValueLine('Explanation:', testCase.explanation!.trim()),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  String _formatInput(TestCase testCase) {
    final format = problem.inputFormat;

    if (format.isNotEmpty) {
      return format
          .map((key) => '$key = ${testCase.inputs[key] ?? ''}')
          .join(', ');
    }

    return testCase.inputs.entries
        .map((entry) => '${entry.key} = ${entry.value}')
        .join(', ');
  }

  Widget _labelValueLine(String label, String value) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label ',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(
              color: Color(0xFFD1D5DB),
              fontFamily: 'JetBrains Mono',
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _difficultyBadge(String difficulty) {
    final lower = difficulty.toLowerCase();
    Color color;
    String text;
    switch (lower) {
      case 'easy':
        color = const Color(0xFF2CBB5D);
        text = 'Easy';
        break;
      case 'medium':
        color = const Color(0xFFFFA116);
        text = 'Medium';
        break;
      case 'hard':
      default:
        color = const Color(0xFFEF4743);
        text = 'Hard';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFD1D5DB)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
        ),
      ),
    );
  }
}

List<InlineSpan> parseInlineText(String text, bool isDark) {
  final spans = <InlineSpan>[];
  final pattern = RegExp(r'(`[^`]+`|\*\*[^*]+\*\*|\*[^*]+\*)');

  int currentIndex = 0;
  for (final match in pattern.allMatches(text)) {
    if (match.start > currentIndex) {
      spans.add(TextSpan(text: text.substring(currentIndex, match.start)));
    }

    final token = match.group(0) ?? '';
    if (token.startsWith('`') && token.endsWith('`')) {
      final codeText = token.substring(1, token.length - 1);
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 1),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              codeText,
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 13,
                color: isDark ? const Color(0xFFE5E7EB) : const Color(0xFF111827),
              ),
            ),
          ),
        ),
      );
    } else if (token.startsWith('**') && token.endsWith('**')) {
      spans.add(
        TextSpan(
          text: token.substring(2, token.length - 2),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    } else if (token.startsWith('*') && token.endsWith('*')) {
      spans.add(
        TextSpan(
          text: token.substring(1, token.length - 1),
          style: const TextStyle(fontStyle: FontStyle.italic),
        ),
      );
    } else {
      spans.add(TextSpan(text: token));
    }

    currentIndex = match.end;
  }

  if (currentIndex < text.length) {
    spans.add(TextSpan(text: text.substring(currentIndex)));
  }

  return spans;
}
