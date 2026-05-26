class Team {
  final int id;
  final int contestId;
  final String name;
  final int leaderId;
  final List<TeamMember> members;

  const Team({
    required this.id,
    required this.contestId,
    required this.name,
    required this.leaderId,
    required this.members,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    final membersRaw = (json['members'] as List?) ?? const [];
    return Team(
      id: json['id'],
      contestId: json['contest_id'],
      name: json['name'],
      leaderId: json['leader_id'],
      members: membersRaw
          .whereType<Map>()
          .map((m) => TeamMember.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
    );
  }
}

class TeamMember {
  final int userId;
  final String username;
  final DateTime joinedAt;

  const TeamMember({
    required this.userId,
    required this.username,
    required this.joinedAt,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      userId: json['user_id'],
      username: json['username'],
      joinedAt: DateTime.parse(json['joined_at']),
    );
  }
}
