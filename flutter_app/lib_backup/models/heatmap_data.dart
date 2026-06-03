class HeatmapData {
  final int totalSubmissions;
  final int totalActiveDays;
  final int maxStreak;
  final Map<DateTime, int> heatmap;

  HeatmapData({
    required this.totalSubmissions,
    required this.totalActiveDays,
    required this.maxStreak,
    required this.heatmap,
  });

  factory HeatmapData.fromJson(Map<String, dynamic> json) {
    final rawMap = json['heatmap'] as Map<String, dynamic>;
    final parsed = <DateTime, int>{};
    rawMap.forEach((k, v) {
      final parts = k.split('-');
      parsed[DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]))] = v as int;
    });
    return HeatmapData(
      totalSubmissions: json['totalSubmissions'] as int? ?? 0,
      totalActiveDays: json['totalActiveDays'] as int? ?? 0,
      maxStreak: json['maxStreak'] as int? ?? 0,
      heatmap: parsed,
    );
  }
}
