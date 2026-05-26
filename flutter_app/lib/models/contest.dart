class Contest {
  final int id;
  final String title;
  final String? description;
  final String status;
  final int maxTeamSize;
  final int penaltyMinutes;
  final DateTime startsAt;
  final DateTime endsAt;

  const Contest({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.maxTeamSize,
    required this.penaltyMinutes,
    required this.startsAt,
    required this.endsAt,
  });

  factory Contest.fromJson(Map<String, dynamic> json) {
    return Contest(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      status: json['status'],
      maxTeamSize: json['max_team_size'],
      penaltyMinutes: json['penalty_minutes'],
      startsAt: DateTime.parse(json['starts_at']),
      endsAt: DateTime.parse(json['ends_at']),
    );
  }
}

class ContestProblem {
  final int id;
  final String title;
  final int points;

  const ContestProblem({
    required this.id,
    required this.title,
    required this.points,
  });

  factory ContestProblem.fromJson(Map<String, dynamic> json) {
    return ContestProblem(
      id: json['id'],
      title: json['title'],
      points: (json['points'] as num?)?.toInt() ?? 0,
    );
  }
}

class ContestDetail {
  final Contest contest;
  final List<ContestProblem> problems;

  const ContestDetail({
    required this.contest,
    required this.problems,
  });

  factory ContestDetail.fromJson(Map<String, dynamic> json) {
    final contestJson = json['contest'] as Map<String, dynamic>;
    final problemsRaw = (json['problems'] as List?) ?? const [];
    return ContestDetail(
      contest: Contest.fromJson(contestJson),
      problems: problemsRaw
          .whereType<Map>()
          .map((p) => ContestProblem.fromJson(Map<String, dynamic>.from(p)))
          .toList(),
    );
  }
}
