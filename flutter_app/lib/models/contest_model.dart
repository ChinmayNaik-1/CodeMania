class ContestModel {
  final int id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final String status;
  final DateTime createdAt;
  final List<ContestProblem>? problems;
  final List<TeamModel>? teams;

  ContestModel({
    required this.id,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.createdAt,
    this.problems,
    this.teams,
  });

  factory ContestModel.fromJson(Map<String, dynamic> json) {
    return ContestModel(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      problems: (json['problems'] as List?)
          ?.map((p) => ContestProblem.fromJson(p as Map<String, dynamic>))
          .toList(),
      teams: (json['teams'] as List?)
          ?.map((t) => TeamModel.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'problems': problems?.map((p) => p.toJson()).toList(),
      'teams': teams?.map((t) => t.toJson()).toList(),
    };
  }

  bool get isRunning {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  bool get hasEnded => DateTime.now().isAfter(endTime);

  Duration get timeRemaining {
    return endTime.difference(DateTime.now());
  }
}

class ContestProblem {
  final int id;
  final String title;
  final String difficulty;
  final int points;
  final int problemOrder;

  ContestProblem({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.points,
    required this.problemOrder,
  });

  factory ContestProblem.fromJson(Map<String, dynamic> json) {
    return ContestProblem(
      id: json['id'] as int,
      title: json['title'] as String,
      difficulty: json['difficulty'] as String,
      points: json['points'] as int? ?? 100,
      problemOrder: json['problem_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'difficulty': difficulty,
      'points': points,
      'problem_order': problemOrder,
    };
  }
}

class TeamModel {
  final int id;
  final int contestId;
  final String name;
  final String joinCode;
  final DateTime createdAt;

  TeamModel({
    required this.id,
    required this.contestId,
    required this.name,
    required this.joinCode,
    required this.createdAt,
  });

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    return TeamModel(
      id: json['id'] as int,
      contestId: json['contest_id'] as int,
      name: json['name'] as String,
      joinCode: json['join_code'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contest_id': contestId,
      'name': name,
      'join_code': joinCode,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
