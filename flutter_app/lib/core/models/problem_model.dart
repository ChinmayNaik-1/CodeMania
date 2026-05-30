import 'package:flutter/material.dart';

class Problem {
  final int id;
  final String title;
  final String difficulty;
  final String description;
  final List<ExampleModel> examples;
  final String? constraints;
  final List<String> topics;
  final List<String> hints;
  final String? followUp;
  final List<String> companies;
  final List<String> inputFormat;
  final List<TestCase> testCases;
  final String? hint;
  final CodeStubs? codeStubs;
  final bool? isSolved;
  final bool isContestExclusive;

  Problem({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.description,
    this.examples = const [],
    this.constraints,
    this.topics = const [],
    this.hints = const [],
    this.followUp,
    this.companies = const [],
    this.inputFormat = const [],
    this.testCases = const [],
    this.hint,
    this.codeStubs,
    this.isSolved,
    this.isContestExclusive = false,
  });

  factory Problem.fromJson(Map<String, dynamic> json) {
    final rawExamples = (json['examples'] as List?) ?? const [];
    final parsedExamples = rawExamples
      .whereType<Map>()
      .map((e) => ExampleModel.fromJson(Map<String, dynamic>.from(e)))
      .toList();

    final rawInputFormat = json['input_format'] as List?;
    final parsedInputFormat = rawInputFormat?.map((e) => e.toString()).toList() ?? const <String>[];

    final rawTestCases = (json['test_cases'] as List?) ?? const [];
    final parsedTestCases = rawTestCases
        .whereType<Map>()
        .map((e) => TestCase.fromJson(Map<String, dynamic>.from(e), parsedInputFormat))
        .toList();

    final rawTopics = (json['topics'] as List?) ?? (json['tags'] as List?);
    String? parsedConstraints;
    if (json['constraints'] is List) {
      parsedConstraints = (json['constraints'] as List)
          .map((c) => c.toString())
          .join('\n');
    } else if (json['constraints'] is String) {
      parsedConstraints = json['constraints'] as String;
    }

    return Problem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] as String?) ?? 'Untitled Problem',
      difficulty: (json['difficulty'] as String?) ?? 'Easy',
      description: (json['description'] as String?) ?? '',
      examples: parsedExamples,
        constraints: parsedConstraints,
      topics: rawTopics
          ?.map((t) => t.toString())
          .toList() ?? const <String>[],
        hints: (json['hints'] as List?)?.map((h) => h.toString()).toList() ?? const <String>[],
        followUp: json['follow_up'] as String?,
      companies: (json['companies'] as List?)
          ?.map((c) => c.toString())
          .toList() ?? const <String>[],
      inputFormat: parsedInputFormat,
      testCases: parsedTestCases,
      hint: json['hint'] as String?,
      codeStubs: json['code_stubs'] is Map<String, dynamic>
          ? CodeStubs.fromJson(json['code_stubs'] as Map<String, dynamic>)
          : null,
      isSolved: json['is_solved'] as bool?,
      isContestExclusive: json['is_contest_exclusive'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'difficulty': difficulty,
      'description': description,
      'examples': examples.map((e) => e.toJson()).toList(),
      'constraints': constraints,
      'topics': topics,
      'hints': hints,
      'follow_up': followUp,
      'companies': companies,
      'input_format': inputFormat,
      'test_cases': testCases.map((e) => e.toJson()).toList(),
      'hint': hint,
      'code_stubs': codeStubs?.toJson(),
      'is_solved': isSolved,
      'is_contest_exclusive': isContestExclusive,
    };
  }

  Color get difficultyColor {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return const Color(0xFF2CBB5D);
      case 'medium':
        return const Color(0xFFFFA116);
      case 'hard':
        return const Color(0xFFEF4743);
      default:
        return const Color(0xFFEF4743);
    }
  }

  Color get difficultyBgColor => difficultyColor.withOpacity(0.1);

  // Compatibility getters for existing UI/provider usage.
  List<String> get tags => topics;
}

class CodeStubs {
  final String? python;
  final String? cpp;
  final String? java;
  final String? javascript;

  CodeStubs({
    this.python,
    this.cpp,
    this.java,
    this.javascript,
  });

  factory CodeStubs.fromJson(Map<String, dynamic> json) {
    return CodeStubs(
      python: json['python'] as String?,
      cpp: json['cpp'] as String?,
      java: json['java'] as String?,
      javascript: json['javascript'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'python': python,
      'cpp': cpp,
      'java': java,
      'javascript': javascript,
    };
  }
}

class ExampleModel {
  final int id;
  final String input;
  final String expectedOutput;
  final String? explanation;
  final String? imageUrl;

  ExampleModel({
    required this.id,
    required this.input,
    required this.expectedOutput,
    this.explanation,
    this.imageUrl,
  });

  factory ExampleModel.fromJson(Map<String, dynamic> json) {
    return ExampleModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      input: (json['input'] ?? '').toString(),
      expectedOutput: (json['expected_output'] ?? '').toString(),
      explanation: json['explanation'] as String?,
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'input': input,
      'expected_output': expectedOutput,
      'explanation': explanation,
      'image_url': imageUrl,
    };
  }
}

// Backward compatibility with current provider type references.
typedef ProblemModel = Problem;

class TestCase {
  final String id;
  final String label;
  final Map<String, String> inputs;
  final String expectedOutput;
  final String? explanation;

  TestCase({
    required this.id,
    required this.label,
    required this.inputs,
    required this.expectedOutput,
    this.explanation,
  });

  factory TestCase.fromJson(Map<String, dynamic> json, List<String> inputFormat) {
    final rawInputs = json['inputs'];
    final parsedInputs = <String, String>{};

    if (rawInputs is Map) {
      for (final entry in rawInputs.entries) {
        parsedInputs[entry.key.toString()] = entry.value?.toString() ?? '';
      }
    } else {
      final rawInputText = (json['input'] ?? '').toString();
      final lines = rawInputText
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();

      if (inputFormat.isNotEmpty) {
        for (int i = 0; i < inputFormat.length; i++) {
          parsedInputs[inputFormat[i]] = i < lines.length ? lines[i] : '';
        }
      } else {
        for (int i = 0; i < lines.length; i++) {
          parsedInputs['input${i + 1}'] = lines[i];
        }
      }
    }

    final parsedId = (json['id'] ?? '').toString();
    final parsedLabel = (json['label'] ?? '').toString();

    return TestCase(
      id: parsedId,
      label: parsedLabel.isNotEmpty ? parsedLabel : 'Case ${parsedId.isNotEmpty ? parsedId : ''}',
      inputs: parsedInputs,
      expectedOutput: (json['expected_output'] ?? json['output'] ?? '').toString(),
      explanation: json['explanation']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'inputs': inputs,
      'expected_output': expectedOutput,
      'explanation': explanation,
    };
  }
}
