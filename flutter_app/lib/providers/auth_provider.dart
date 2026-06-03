import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/google_auth_service.dart';

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;
  final bool pendingGoogleSignup;
  final String? googleSignupToken;
  final String? googleEmail;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.pendingGoogleSignup = false,
    this.googleSignupToken,
    this.googleEmail,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? pendingGoogleSignup,
    String? googleSignupToken,
    String? googleEmail,
    bool clearGoogleSignup = false,
  }) =>
      AuthState(
        user: user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        pendingGoogleSignup: pendingGoogleSignup ?? this.pendingGoogleSignup,
        googleSignupToken: clearGoogleSignup
            ? null
            : (googleSignupToken ?? this.googleSignupToken),
        googleEmail:
            clearGoogleSignup ? null : (googleEmail ?? this.googleEmail),
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _loadStoredUser();
  }

  Future<void> _setAuthenticated(String token, UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
    ApiService.setToken(token);
    state = AuthState(user: user);
  }

  Future<void> _loadStoredUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        return;
      }

      // Don't show loading indicator on app startup - silent token validation
      ApiService.setToken(token);

      try {
        final response = await ApiService.get('/auth/me');
        if (response.statusCode == 200) {
          final user = UserModel.fromJson(response.data['user']);
          state = AuthState(user: user);
        } else {
          await prefs.remove('jwt_token');
          state = const AuthState();
        }
      } catch (_) {
        await prefs.remove('jwt_token');
        state = const AuthState();
      }
    } catch (_) {
      state = const AuthState();
    }
  }

  Future<String?> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await ApiService.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final token = response.data['token'] as String;
        final user = UserModel.fromJson(response.data['user']);

        await _setAuthenticated(token, user);
        return null;
      } else {
        final msg = response.data['error'] ?? 'Login failed';
        state = state.copyWith(error: msg, isLoading: false);
        return msg;
      }
    } catch (e) {
      final msg = 'Login failed. Check your credentials.';
      state = state.copyWith(error: msg);
      return msg;
    }
  }

  Future<String?> register(
    String username,
    String email,
    String password,
  ) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await ApiService.post(
        '/auth/register',
        data: {
          'username': username,
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 201) {
        final token = response.data['token'] as String;
        final user = UserModel.fromJson(response.data['user']);

        await _setAuthenticated(token, user);
        return null;
      } else {
        final msg = response.data['error'] ?? 'Registration failed';
        state = state.copyWith(error: msg, isLoading: false);
        return msg;
      }
    } catch (e) {
      const msg = 'Registration failed. Try a different username or email.';
      state = state.copyWith(error: msg, isLoading: false);
      return msg;
    }
  }

  Future<String?> loginWithGoogle() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearGoogleSignup: true,
      pendingGoogleSignup: false,
    );

    try {
      final idToken = await GoogleAuthService().signInWithGoogle();

      if (idToken == null) {
        const msg = 'Google sign-in was cancelled';
        state = state.copyWith(error: msg, isLoading: false);
        return msg;
      }

      final response = await ApiService.googleStart(idToken);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = response.data['token'] as String;
        final user = UserModel.fromJson(response.data['user']);
        await _setAuthenticated(token, user);
        return null;
      }

      if (response.statusCode == 202 &&
          response.data['signup_required'] == true) {
        state = state.copyWith(
          isLoading: false,
          clearError: true,
          pendingGoogleSignup: true,
          googleSignupToken: response.data['signup_token'] as String?,
          googleEmail: response.data['email'] as String?,
        );
        return null;
      }

      final msg = response.data['error'] ?? 'Google authentication failed';
      state = state.copyWith(error: msg, isLoading: false);
      return msg;
    } catch (e) {
      String msg = 'Google authentication failed';
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map<String, dynamic> && data['error'] is String) {
          msg = data['error'] as String;
        }
      }
      state = state.copyWith(error: msg, isLoading: false);
      return msg;
    }
  }

  Future<String?> completeGoogleSignup(String username, String password) async {
    final signupToken = state.googleSignupToken;
    if (signupToken == null || signupToken.isEmpty) {
      const msg =
          'Google signup session expired. Please sign in with Google again.';
      state = state.copyWith(error: msg, isLoading: false);
      return msg;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await ApiService.googleCompleteSignup(
        signupToken,
        username,
        password,
      );

      if (response.statusCode == 201) {
        final token = response.data['token'] as String;
        final user = UserModel.fromJson(response.data['user']);
        await _setAuthenticated(token, user);
        return null;
      }

      final msg = response.data['error'] ?? 'Failed to complete Google signup';
      state = state.copyWith(error: msg, isLoading: false);
      return msg;
    } catch (e) {
      const msg = 'Failed to complete Google signup';
      state = state.copyWith(error: msg, isLoading: false);
      return msg;
    }
  }

  Future<void> logout() async {
    try {
      await GoogleAuthService().signOut();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwt_token');
      ApiService.setToken('');
      state = const AuthState();
    } catch (_) {
      state = const AuthState();
    }
  }

  void updateUser(UserModel updatedUser) {
    state = state.copyWith(user: updatedUser);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
