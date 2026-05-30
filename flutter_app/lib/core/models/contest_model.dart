// ─── ContestModel ─────────────────────────────────────────────────────────────

class ContestModel {
  final int id;
  final String title;
  final String? description;
  final String contestType; // 'solo' | 'team'
  final int maxTeamSize;
  final DateTime startTime;
  final DateTime endTime;
  final String status; // 'draft'|'upcoming'|'live'|'ended'
  final int problemCount;
  final bool isRegistered;

  const ContestModel({
    required this.id,
    required this.title,
    this.description,
    required this.contestType,
    required this.maxTeamSize,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.problemCount,
    required this.isRegistered,
  });

  factory ContestModel.fromJson(Map<String, dynamic> json) {
    return ContestModel(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      contestType: json['contest_type'] as String? ?? 'solo',
      maxTeamSize: (json['max_team_size'] as num?)?.toInt() ?? 1,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      status: json['status'] as String? ?? 'upcoming',
      problemCount: (json['problem_count'] as num?)?.toInt() ?? 0,
      isRegistered: json['is_registered'] as bool? ?? false,
    );
  }
}

// ─── ContestProblemModel ──────────────────────────────────────────────────────

class ContestProblemModel {
  final int id;
  final String title;
  final String difficulty;
  final int points;
  final int problemOrder;
  final bool isSolvedByMe;
  final bool isSolvedByTeam;

  const ContestProblemModel({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.points,
    required this.problemOrder,
    required this.isSolvedByMe,
    required this.isSolvedByTeam,
  });

  factory ContestProblemModel.fromJson(Map<String, dynamic> json) {
    return ContestProblemModel(
      id: json['id'] as int,
      title: json['title'] as String,
      difficulty: json['difficulty'] as String? ?? 'medium',
      points: (json['points'] as num?)?.toInt() ?? 100,
      problemOrder: (json['problem_order'] as num?)?.toInt() ?? 1,
      isSolvedByMe: json['is_solved_by_me'] as bool? ?? false,
      isSolvedByTeam: json['is_solved_by_team'] as bool? ?? false,
    );
  }
}

// ─── TeamMemberModel ──────────────────────────────────────────────────────────

class TeamMemberModel {
  final int userId;
  final String username;
  final String? avatarUrl;

  const TeamMemberModel({
    required this.userId,
    required this.username,
    this.avatarUrl,
  });

  factory TeamMemberModel.fromJson(Map<String, dynamic> json) {
    return TeamMemberModel(
      userId: json['user_id'] as int,
      username: json['username'] as String,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

// ─── ContestTeamModel ─────────────────────────────────────────────────────────

class ContestTeamModel {
  final int id;
  final String name;
  final bool isLeader;
  final List<TeamMemberModel> members;

  const ContestTeamModel({
    required this.id,
    required this.name,
    required this.isLeader,
    required this.members,
  });

  factory ContestTeamModel.fromJson(Map<String, dynamic> json) {
    return ContestTeamModel(
      id: json['id'] as int,
      name: json['name'] as String,
      isLeader: json['is_leader'] as bool? ?? false,
      members: (json['members'] as List? ?? [])
          .map((m) => TeamMemberModel.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ─── MyRegistrationModel ─────────────────────────────────────────────────────

class MyRegistrationModel {
  final String type; // 'solo' | 'team'
  final ContestTeamModel? team;

  const MyRegistrationModel({required this.type, this.team});

  factory MyRegistrationModel.fromJson(Map<String, dynamic> json) {
    return MyRegistrationModel(
      type: json['type'] as String,
      team: json['team'] != null
          ? ContestTeamModel.fromJson(json['team'] as Map<String, dynamic>)
          : null,
    );
  }
}

// ─── TeamInvitationModel ─────────────────────────────────────────────────────

class TeamInvitationModel {
  final int id;
  final int teamId;
  final String teamName;
  final String inviterUsername;

  const TeamInvitationModel({
    required this.id,
    required this.teamId,
    required this.teamName,
    required this.inviterUsername,
  });

  factory TeamInvitationModel.fromJson(Map<String, dynamic> json) {
    return TeamInvitationModel(
      id: json['id'] as int,
      teamId: json['team_id'] as int,
      teamName: json['team_name'] as String,
      inviterUsername: json['inviter_username'] as String,
    );
  }
}

// ─── ContestDetailModel ───────────────────────────────────────────────────────

class ContestDetailModel extends ContestModel {
  final List<ContestProblemModel> problems;
  final MyRegistrationModel? myRegistration;
  final List<TeamInvitationModel> myTeamInvitations;

  const ContestDetailModel({
    required super.id,
    required super.title,
    super.description,
    required super.contestType,
    required super.maxTeamSize,
    required super.startTime,
    required super.endTime,
    required super.status,
    required super.problemCount,
    required super.isRegistered,
    required this.problems,
    this.myRegistration,
    required this.myTeamInvitations,
  });

  factory ContestDetailModel.fromJson(Map<String, dynamic> json) {
    return ContestDetailModel(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      contestType: json['contest_type'] as String? ?? 'solo',
      maxTeamSize: (json['max_team_size'] as num?)?.toInt() ?? 1,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      status: json['status'] as String? ?? 'upcoming',
      problemCount: (json['problem_count'] as num?)?.toInt() ?? 0,
      isRegistered: json['my_registration'] != null,
      problems: (json['problems'] as List? ?? [])
          .map((p) => ContestProblemModel.fromJson(p as Map<String, dynamic>))
          .toList(),
      myRegistration: json['my_registration'] != null
          ? MyRegistrationModel.fromJson(
              json['my_registration'] as Map<String, dynamic>)
          : null,
      myTeamInvitations: (json['my_team_invitations'] as List? ?? [])
          .map((i) =>
              TeamInvitationModel.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ─── MemberContributionModel ──────────────────────────────────────────────────

class MemberContributionModel {
  final int userId;
  final String username;
  final String? avatarUrl;
  final int problemsSolved;
  final int scoreContributed;

  const MemberContributionModel({
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.problemsSolved,
    required this.scoreContributed,
  });

  factory MemberContributionModel.fromJson(Map<String, dynamic> json) {
    return MemberContributionModel(
      userId: json['user_id'] as int,
      username: json['username'] as String,
      avatarUrl: json['avatar_url'] as String?,
      problemsSolved: (json['problems_solved'] as num?)?.toInt() ?? 0,
      scoreContributed: (json['score_contributed'] as num?)?.toInt() ?? 0,
    );
  }
}

// ─── LeaderboardEntryModel ────────────────────────────────────────────────────

class LeaderboardEntryModel {
  final int? userId;
  final int? teamId;
  final String displayName;
  final String? avatarUrl;
  final int totalScore;
  final int problemsSolved;
  final DateTime? lastAcceptedAt;
  final List<MemberContributionModel> members;

  const LeaderboardEntryModel({
    this.userId,
    this.teamId,
    required this.displayName,
    this.avatarUrl,
    required this.totalScore,
    required this.problemsSolved,
    this.lastAcceptedAt,
    this.members = const [],
  });

  factory LeaderboardEntryModel.fromJson(Map<String, dynamic> json) {
    final membersRaw = json['members'];
    final members = (membersRaw is List)
        ? membersRaw
            .map((m) =>
                MemberContributionModel.fromJson(m as Map<String, dynamic>))
            .toList()
        : <MemberContributionModel>[];

    return LeaderboardEntryModel(
      userId: json['user_id'] as int?,
      teamId: json['team_id'] as int?,
      displayName: (json['username'] ?? json['team_name'] ?? 'Unknown') as String,
      avatarUrl: json['avatar_url'] as String?,
      totalScore: (json['total_score'] as num?)?.toInt() ?? 0,
      problemsSolved: (json['problems_solved'] as num?)?.toInt() ?? 0,
      lastAcceptedAt: json['last_accepted_at'] != null
          ? DateTime.tryParse(json['last_accepted_at'] as String)
          : null,
      members: members,
    );
  }
}
