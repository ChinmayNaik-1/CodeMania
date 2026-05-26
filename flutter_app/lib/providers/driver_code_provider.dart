import 'package:codemania/config.dart';
import 'package:codemania/models/driver_code.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dioProvider = Provider<Dio>((ref) {
  final token = Config.currentToken;
  return Dio(
    BaseOptions(
      baseUrl: Config.apiBaseUrl,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
});

final driverCodeListProvider = FutureProvider.family<List<DriverCode>, int>(
  (ref, problemId) async {
    final dio = ref.read(dioProvider);
    final response = await dio.get('/api/admin/problems/$problemId/drivers');
    final list = response.data['drivers'] as List<dynamic>;
    return list
        .map((entry) => DriverCode.fromJson(entry as Map<String, dynamic>))
        .toList();
  },
);

Future<void> upsertDriverCode(Dio dio, int problemId, DriverCode driver) async {
  await dio.post(
    '/api/admin/problems/$problemId/driver',
    data: driver.toJson(),
  );
}

Future<void> deleteDriverCode(Dio dio, int problemId, String language) async {
  await dio.delete('/api/admin/problems/$problemId/driver/$language');
}
