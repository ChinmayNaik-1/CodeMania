import 'package:codemania/models/problem_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class ProblemBody extends StatelessWidget {
  const ProblemBody({
    super.key,
    required this.problem,
  });

  final Problem problem;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bodyColor = isDark ? Colors.white : Colors.black87;
    final codeBg = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF0F0F0);
    final preBg = isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF5F5F5);

    final htmlStyle = {
      'body': Style(
        fontSize: FontSize(14),
        color: bodyColor,
        lineHeight: LineHeight.number(1.6),
        margin: Margins.zero,
        padding: HtmlPaddings.zero,
      ),
      'code': Style(
        backgroundColor: codeBg,
        fontFamily: 'monospace',
        fontSize: FontSize(13),
        padding: HtmlPaddings.symmetric(horizontal: 4, vertical: 2),
      ),
      'pre': Style(
        backgroundColor: preBg,
        padding: HtmlPaddings.all(12),
      ),
    };

    final examples = problem.examples ?? const <Example>[];
    final constraints = problem.constraints ?? const <String>[];

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Html(
              data: problem.description,
              style: htmlStyle,
            ),
            if (examples.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...examples.asMap().entries.map((entry) {
                final index = entry.key;
                final example = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.circular(8),
                    border: Border(
                      left: BorderSide(
                        color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFD0D0D0),
                        width: 3,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Example ${index + 1}:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: bodyColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _exampleRow('Input:', example.input ?? '', bodyColor),
                      _exampleRow('Output:', example.output ?? '', bodyColor),
                      if (example.explanation != null)
                        _exampleRow('Explanation:', example.explanation!, bodyColor),
                    ],
                  ),
                );
              }),
            ],
            if (constraints.isNotEmpty) ...[
              Text(
                'Constraints:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: bodyColor,
                ),
              ),
              const SizedBox(height: 8),
              ...constraints.map(
                (constraint) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: bodyColor,
                      ),
                    ),
                    Flexible(
                      child: Html(
                        data: constraint,
                        style: htmlStyle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _exampleRow(String label, String value, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                fontSize: 13,
                color: textColor,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
