import 'package:flutter/material.dart';

class SubmissionModel {
  const SubmissionModel({
    required this.id,
    required this.status,
    required this.language,
    required this.runtimeMs,
    required this.memoryKb,
    required this.createdAt,
  });

  final String id;
  final String status;
  final String language;
  final int? runtimeMs;
  final int? memoryKb;
  final DateTime createdAt;

  factory SubmissionModel.fromJson(Map<String, dynamic> json) {
    final rawCreatedAt = (json['created_at'] ?? '').toString();
    final parsedCreatedAt = DateTime.tryParse(rawCreatedAt);

    return SubmissionModel(
      id: (json['id'] ?? '').toString(),
      status: (json['status'] ?? json['verdict'] ?? 'Pending').toString(),
      language: (json['language'] ?? '').toString(),
      runtimeMs: _toInt(json['runtime_ms'] ?? json['time_ms']),
      memoryKb: _toInt(json['memory_kb']),
      createdAt: parsedCreatedAt == null
          ? DateTime.now().toUtc()
          : (parsedCreatedAt.isUtc ? parsedCreatedAt : parsedCreatedAt.toUtc()),
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  String get normalizedStatus => status.trim().toLowerCase();

  bool get isAccepted => normalizedStatus == 'accepted';

  Color get statusColor {
    switch (normalizedStatus) {
      case 'accepted':
        return const Color(0xFF2EAF57);
      case 'wrong answer':
      case 'compile error':
      case 'runtime error':
        return const Color(0xFFEF4444);
      case 'time limit exceeded':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  IconData get statusIcon {
    switch (normalizedStatus) {
      case 'accepted':
        return Icons.check_circle;
      case 'wrong answer':
        return Icons.cancel;
      case 'compile error':
        return Icons.error;
      case 'runtime error':
        return Icons.warning_amber_rounded;
      case 'time limit exceeded':
        return Icons.timer_off;
      default:
        return Icons.hourglass_top_rounded;
    }
  }
}

class SubmissionDetailModel extends SubmissionModel {
  const SubmissionDetailModel({
    required super.id,
    required super.status,
    required super.language,
    required super.runtimeMs,
    required super.memoryKb,
    required super.createdAt,
    required this.code,
    required this.errorMessage,
    required this.stderr,
    required this.errorLine,
    this.passed,
    this.total,
    this.input,
    this.expectedOutput,
    this.yourOutput,
  });

  final String code;
  final String? errorMessage;
  final String? stderr;
  final int? errorLine;
  final int? passed;
  final int? total;
  final String? input;
  final String? expectedOutput;
  final String? yourOutput;

  factory SubmissionDetailModel.fromJson(Map<String, dynamic> json) {
    final rawCreatedAt = (json['created_at'] ?? '').toString();
    final parsedCreatedAt = DateTime.tryParse(rawCreatedAt);

    return SubmissionDetailModel(
      id: (json['id'] ?? '').toString(),
      status: (json['status'] ?? json['verdict'] ?? 'Pending').toString(),
      language: (json['language'] ?? '').toString(),
      runtimeMs: SubmissionModel._toInt(json['runtime_ms'] ?? json['time_ms']),
      memoryKb: SubmissionModel._toInt(json['memory_kb']),
      createdAt: parsedCreatedAt == null
          ? DateTime.now().toUtc()
          : (parsedCreatedAt.isUtc ? parsedCreatedAt : parsedCreatedAt.toUtc()),
      code: (json['code'] ?? '').toString(),
      errorMessage: json['error_message']?.toString(),
      stderr: json['stderr']?.toString(),
      errorLine: SubmissionModel._toInt(json['error_line']),
      passed: SubmissionModel._toInt(json['passed'] ?? json['passed_cases']),
      total: SubmissionModel._toInt(json['total'] ?? json['total_cases']),
      input: json['failed_input']?.toString() ?? json['input']?.toString(),
      expectedOutput: json['expected_output']?.toString() ?? json['expected']?.toString(),
      yourOutput: json['actual_output']?.toString() ?? json['your_output']?.toString() ?? json['actual']?.toString(),
    );
  }
}
