void main() {
  final target = DateTime.parse('2026-06-24T12:25:00.000Z');
  final now = DateTime.parse('2026-06-24T12:14:00.000Z');
  final diff = target.toUtc().difference(now.toUtc());
  print(diff);
  print(diff.isNegative);
}
