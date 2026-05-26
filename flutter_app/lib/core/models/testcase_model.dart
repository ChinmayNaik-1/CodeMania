class TestCase {
  final String id;
  final String label;
  final Map<String, String> params;
  final String? expectedOutput;

  TestCase({
    required this.id,
    required this.label,
    required this.params,
    this.expectedOutput,
  });
}
