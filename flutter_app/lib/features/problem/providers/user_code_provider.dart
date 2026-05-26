import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:codemania/config.dart';

final currentCodeProvider =
    StateProvider.family<String, String>((ref, problemId) => '');

enum SaveStatus { idle, saving, saved }

final saveStatusProvider =
    StateProvider.family<SaveStatus, String>((ref, problemId) => SaveStatus.idle);

class UserCodeService {
  String _localKey(String problemId, String language) {
    return 'user_code_${problemId}_$language';
  }

  Future<void> _saveLocal(String problemId, String language, String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localKey(problemId, language), code);
  }

  Future<String?> _loadLocal(String problemId, String language) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_localKey(problemId, language));
  }

  Dio _client(String jwt) {
    return Dio(
      BaseOptions(
        baseUrl: Config.apiBaseUrl,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (jwt.isNotEmpty) 'Authorization': 'Bearer $jwt',
        },
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
  }

  Future<String> loadCode(
    String problemId,
    String language,
    String jwt, {
    String? fallbackCode,
  }) async {
    final localCode = await _loadLocal(problemId, language);

    try {
      final dio = _client(jwt);
      final response = await dio.get(
        '/api/usercode/$problemId',
        queryParameters: {'language': language},
      );

      final data = response.data;
      if (data is Map && data['code'] is String) {
        final saved = (data['code'] as String).trimRight();
        if (saved.isNotEmpty) {
          await _saveLocal(problemId, language, saved);
          return saved;
        }
      }
    } catch (_) {
      // Ignore backend failures and fall back to local persistence.
    }

    final normalizedFallback = (fallbackCode ?? '').trimRight();
    final defaultCode = defaultTemplate(language).trimRight();

    if (localCode != null && localCode.trimRight().isNotEmpty) {
      final trimmedLocal = localCode.trimRight();
      if (normalizedFallback.isNotEmpty && trimmedLocal == defaultCode) {
        return normalizedFallback;
      }
      return trimmedLocal;
    }

    if (normalizedFallback.isNotEmpty) {
      return normalizedFallback;
    }

    return defaultCode;
  }

  Future<void> saveCode(
    String problemId,
    String language,
    String code,
    String jwt,
  ) async {
    await _saveLocal(problemId, language, code);

    try {
      final dio = _client(jwt);
      await dio.post(
        '/api/usercode/$problemId',
        data: {
          'language': language,
          'code': code,
        },
      );
    } catch (_) {
      // Keep local save as source of truth when backend is unavailable.
    }
  }

  String defaultTemplate(String language) {
    switch (language) {
      case 'cpp':
        return 'class Solution {\npublic:\n    // Write your solution here\n};\n';
      case 'python':
        return 'class Solution:\n    def solve(self):\n        # Write your solution here\n        pass\n';
      case 'java':
        return 'class Solution {\n    // Write your solution here\n}\n';
      default:
        return '// Write your solution here\n';
    }
  }
}

final userCodeServiceProvider = Provider<UserCodeService>((ref) {
  return UserCodeService();
});
