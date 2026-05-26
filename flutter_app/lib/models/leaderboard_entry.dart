class LeaderboardEntry {
  final int rank;
  final int teamId;
  final String teamName;
  final List<String> memberUsernames;
  final int problemsSolved;
  final int totalPenalty;

  const LeaderboardEntry({
    required this.rank,
    required this.teamId,
    required this.teamName,
    required this.memberUsernames,
    required this.problemsSolved,
    required this.totalPenalty,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    final membersRaw = (json['members'] as List?) ?? const [];
    return LeaderboardEntry(
      rank: json['rank'],
      teamId: json['teamId'],
      teamName: json['teamName'],
      memberUsernames: membersRaw.map((m) => m.toString()).toList(),
      problemsSolved: json['problemsSolved'],
      totalPenalty: json['totalPenalty'],
    );
  }
}
