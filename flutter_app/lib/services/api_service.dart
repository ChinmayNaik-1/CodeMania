import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config.dart';

class ApiService {
  static late Dio _dio;

  static void init() {
    _dio = Dio(BaseOptions(
      baseUrl: Config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      validateStatus: (status) => status! < 500,
    ));

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = Config.currentToken;
          if (token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          if (kDebugMode) {
            print('📡 [REQUEST] ${options.method} '
                '${options.baseUrl}${options.path}');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            print('📡 [RESPONSE] ${response.statusCode} '
                '${response.requestOptions.path}');
          }
          return handler.next(response);
        },
        onError: (error, handler) {
          if (kDebugMode) {
            print('📡 [ERROR] ${error.message}');
            print('📡 [ERROR-TYPE] ${error.type}');
            print('📡 [ERROR-CODE] ${error.response?.statusCode}');
            if (error.requestOptions != null) {
              print('📡 [ERROR-URL] ${error.requestOptions?.path}');
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  static void setToken(String token) {
    Config.setToken(token);
  }

  static Future<Response> get(String path,
      {Map<String, dynamic>? params}) async {
    return _dio.get(path, queryParameters: params);
  }

  static Future<Response> post(String path, {dynamic data}) async {
    return _dio.post(path, data: data);
  }

  static Future<Response> put(String path, {dynamic data}) async {
    return _dio.put(path, data: data);
  }

  static Future<Response> delete(String path) async {
    return _dio.delete(path);
  }

  static Future<Response> googleStart(String idToken) async {
    return _dio.post('/auth/google/start', data: {'idToken': idToken});
  }

  static Future<Response> googleCompleteSignup(
    String signupToken,
    String username,
    String password,
  ) async {
    return _dio.post(
      '/auth/google/complete-signup',
      data: {
        'signupToken': signupToken,
        'username': username,
        'password': password,
      },
    );
  }
}
