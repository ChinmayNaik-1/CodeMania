import 'package:codemania/models/problem_model.dart';
import 'package:codemania/screens/problem_page/widgets/problem_body.dart';
import 'package:flutter/material.dart';

class DescriptionTab extends StatelessWidget {
  const DescriptionTab({
    super.key,
    required this.problem,
  });

  final Problem problem;

  @override
  Widget build(BuildContext context) {
    return ProblemBody(problem: problem);
  }
}
