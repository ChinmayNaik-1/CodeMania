import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:codemania/core/models/profile_model.dart';
import 'package:codemania/services/api_service.dart';

final profileProvider = FutureProvider.family<UserProfileModel, int>((ref, userId) async {
  final response = await ApiService.get('/api/profile/$userId');
  if (response.statusCode == 200) {
    return UserProfileModel.fromJson(response.data);
  } else {
    throw Exception(response.data['error'] ?? 'Failed to load profile');
  }
});
