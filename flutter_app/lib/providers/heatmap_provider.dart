import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:codemania/models/heatmap_data.dart';
import 'package:codemania/services/api_service.dart';

final heatmapProvider = FutureProvider.family<HeatmapData, String>((ref, userId) async {
  final response = await ApiService.get('/api/users/$userId/submission-heatmap');
  if (response.statusCode == 200) {
    return HeatmapData.fromJson(response.data);
  } else {
    throw Exception('Failed to load heatmap data');
  }
});
