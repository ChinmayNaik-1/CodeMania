import 'package:codemania/services/api_service.dart';

class RuntimeService {
  static final Map<String, String> _versionOverrides = {};
  static bool _loaded = false;

  static Future<void> refresh({bool force = false}) async {
    if (_loaded && !force) {
      return;
    }

    try {
      final response = await ApiService.get('/submit/runtimes');
      final payload = response.data;
      final runtimes = payload is Map<String, dynamic> ? payload['runtimes'] : null;

      if (runtimes is List) {
        final nextOverrides = <String, String>{};

        for (final runtime in runtimes) {
          if (runtime is! Map) continue;
          final language = _normalizeLanguage(runtime['language']?.toString() ?? '');
          final version = runtime['version']?.toString() ?? '';
          if (language.isEmpty || version.isEmpty) {
            continue;
          }

          final current = nextOverrides[language];
          if (current == null || _compareVersions(version, current) > 0) {
            nextOverrides[language] = version;
          }
        }

        _versionOverrides
          ..clear()
          ..addAll(nextOverrides);
      }
    } catch (_) {
      // Ignore runtime sync failures and fallback to defaults.
    } finally {
      _loaded = true;
    }
  }

  static String resolveVersion(String language) {
    final normalized = _normalizeLanguage(language);
    return _versionOverrides[normalized] ?? _defaultVersion(normalized);
  }

  static String _normalizeLanguage(String language) {
    final normalized = language.toLowerCase().trim();
    if (normalized == 'c++') return 'cpp';
    if (normalized == 'py') return 'python';
    if (normalized == 'node' || normalized == 'js') return 'javascript';
    return normalized;
  }

  static String _defaultVersion(String language) {
    switch (language) {
      case 'cpp':
        return '10.2.0';
      case 'java':
        return '15.0.2';
      case 'javascript':
        return '18.15.0';
      case 'python':
      default:
        return '3.10.0';
    }
  }

  static int _compareVersions(String left, String right) {
    final leftParts = _parseVersion(left);
    final rightParts = _parseVersion(right);
    final maxLen = leftParts.length > rightParts.length ? leftParts.length : rightParts.length;

    for (var i = 0; i < maxLen; i += 1) {
      final leftValue = i < leftParts.length ? leftParts[i] : 0;
      final rightValue = i < rightParts.length ? rightParts[i] : 0;
      if (leftValue > rightValue) return 1;
      if (leftValue < rightValue) return -1;
    }

    return 0;
  }

  static List<int> _parseVersion(String value) {
    return value
        .split(RegExp(r'[^0-9]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => int.tryParse(part) ?? 0)
        .toList();
  }
}
