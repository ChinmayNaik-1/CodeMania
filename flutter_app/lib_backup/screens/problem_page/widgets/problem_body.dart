import 'package:cached_network_image/cached_network_image.dart';
import 'package:codemania/models/problem_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

class ProblemBody extends StatelessWidget {
  const ProblemBody({
    super.key,
    required this.problem,
  });

  final Problem problem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textPrimary = theme.textTheme.bodyMedium?.color ?? Colors.white;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${problem.problemNumber ?? problem.id}. ${problem.title}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _DifficultyBadge(difficulty: problem.difficulty),
                ...problem.topics.map((topic) => _TopicChip(label: topic)),
              ],
            ),
            const SizedBox(height: 16),
            MarkdownBody(
              data: problem.description,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(fontSize: 14, height: 1.7, color: textPrimary),
                strong: const TextStyle(fontWeight: FontWeight.bold),
                code: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  backgroundColor: Color(0xFF2D2D2D),
                  color: Color(0xFFE6E6E6),
                ),
                codeblockDecoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              imageBuilder: (uri, title, alt) => CachedNetworkImage(
                imageUrl: uri.toString(),
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 20),
            ...problem.examples.asMap().entries.map((entry) {
              final index = entry.key;
              final example = entry.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Example ${index + 1}:',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  if (example.imageUrl != null) ...[
                    CachedNetworkImage(
                      imageUrl: example.imageUrl!,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 6),
                  ],
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ExampleRow(label: 'Input:', value: example.input),
                        const SizedBox(height: 4),
                        _ExampleRow(label: 'Output:', value: example.expectedOutput),
                        if (example.explanation != null) ...[
                          const SizedBox(height: 4),
                          _ExampleRow(
                            label: 'Explanation:',
                            value: example.explanation!,
                            isCode: false,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              );
            }),
            if (problem.constraints != null && problem.constraints!.isNotEmpty) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Constraints:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  MarkdownBody(
                    data: problem.constraints!,
                    styleSheet: MarkdownStyleSheet(
                      listBullet: const TextStyle(fontSize: 13, color: Color(0xFFD1D5DB)),
                      p: const TextStyle(fontSize: 13, height: 1.6, color: Color(0xFFD1D5DB)),
                      code: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        backgroundColor: Color(0xFF2D2D2D),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ],
            if (problem.followUp != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[700] ?? const Color(0xFF374151)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Follow-up', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      problem.followUp!,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (problem.hints.isNotEmpty) _HintsSection(hints: problem.hints),
          ],
        ),
      ),
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  const _DifficultyBadge({required this.difficulty});

  final String difficulty;

  Color _difficultyColor(String value) {
    switch (value.toLowerCase()) {
      case 'easy':
        return const Color(0xFF00B8A3);
      case 'medium':
        return const Color(0xFFFFA116);
      case 'hard':
        return const Color(0xFFFF375F);
      default:
        return const Color(0xFF00B8A3);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _difficultyColor(difficulty);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        difficulty,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TopicChip extends StatelessWidget {
  const _TopicChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, color: Colors.grey[400]),
      ),
    );
  }
}

class _ExampleRow extends StatelessWidget {
  const _ExampleRow({
    required this.label,
    required this.value,
    this.isCode = true,
  });

  final String label;
  final String value;
  final bool isCode;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label  ',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Colors.white,
            ),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              fontFamily: isCode ? 'monospace' : null,
              fontSize: 13,
              color: Colors.grey[300],
            ),
          ),
        ],
      ),
    );
  }
}

class _HintsSection extends StatefulWidget {
  const _HintsSection({required this.hints});

  final List<String> hints;

  @override
  State<_HintsSection> createState() => _HintsSectionState();
}

class _HintsSectionState extends State<_HintsSection> {
  int _revealedCount = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hints',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        ...List.generate(_revealedCount, (i) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D2D),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Hint ${i + 1}: ${widget.hints[i]}',
              style: const TextStyle(fontSize: 13, color: Color(0xFFD1D5DB)),
            ),
          );
        }),
        if (_revealedCount < widget.hints.length)
          TextButton(
            onPressed: () => setState(() => _revealedCount++),
            child: Text(
              _revealedCount == 0 ? 'Show Hint' : 'Show Next Hint',
              style: const TextStyle(color: Color(0xFFFFA116)),
            ),
          ),
      ],
    );
  }
}
