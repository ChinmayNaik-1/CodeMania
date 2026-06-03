class SubmissionModel {
  final int id;
  final String userId;
  final int problemId;
  final String verdict;
  final String language;
  final int passedCases;
  final int totalCases;
  final DateTime createdAt;
  final int? timeMs;
  final int? memoryKb;

  SubmissionModel({
    required this.id,
    required this.userId,
    required this.problemId,
    required this.verdict,
    required this.language,
    required this.passedCases,
    required this.totalCases,
    required this.createdAt,
    this.timeMs,
    this.memoryKb,
  });

  factory SubmissionModel.fromJson(Map<String, dynamic> json) {
    return SubmissionModel(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as String? ?? '',
      problemId: json['problem_id'] as int? ?? 0,
      verdict: json['verdict'] as String? ?? json['status'] as String? ?? 'unknown',
      language: json['language'] as String? ?? '',
      passedCases: json['passed_cases'] as int? ?? 0,
      totalCases: json['total_cases'] as int? ?? 0,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()) : DateTime.now(),
      timeMs: (json['time_ms'] ?? json['runtime_ms']) as int?,
      memoryKb: json['memory_kb'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'problem_id': problemId,
      'verdict': verdict,
      'language': language,
      'passed_cases': passedCases,
      'total_cases': totalCases,
      'created_at': createdAt.toIso8601String(),
      'time_ms': timeMs,
      'memory_kb': memoryKb,
    };
  }

  bool get isAccepted => verdict == 'accepted';

  String get statusText {
    switch (verdict) {
      case 'accepted':
        return 'Accepted';
      case 'wrong_answer':
        return 'Wrong Answer';
      case 'runtime_error':
        return 'Runtime Error';
      case 'time_limit_exceeded':
        return 'Time Limit Exceeded';
      case 'compilation_error':
        return 'Compilation Error';
      default:
        return 'Pending';
    }
  }
}

class TeamScoreModel {
  final int teamId;
  final String teamName;
  final int score;
  final int solvedCount;
  final List<String> members;

  TeamScoreModel({
    required this.teamId,
    required this.teamName,
    required this.score,
    required this.solvedCount,
    required this.members,
  });

  factory TeamScoreModel.fromJson(Map<String, dynamic> json) {
    return TeamScoreModel(
      teamId: json['teamId'] as int,
      teamName: json['teamName'] as String,
      score: json['score'] as int? ?? 0,
      solvedCount: json['solvedCount'] as int? ?? 0,
      members: List<String>.from(json['members'] as List? ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'teamId': teamId,
      'teamName': teamName,
      'score': score,
      'solvedCount': solvedCount,
      'members': members,
    };
  }
}
