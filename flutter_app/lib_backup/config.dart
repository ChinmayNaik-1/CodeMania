import 'package:flutter/foundation.dart' show kIsWeb;

class Config {
  static const String apiBaseUrl = 'https://codemania-nysu.onrender.com';
  static const String socketUrl = 'https://codemania-nysu.onrender.com';

  // Token storage — set after Firebase login
  static String _currentToken = '';

  static String get currentToken => _currentToken;

  static void setToken(String token) {
    _currentToken = token;
  }

  // Platform detection
  static bool get isWeb => kIsWeb;

  static String getApiUrl(String endpoint) => '$apiBaseUrl$endpoint';

  static String getSocketUrl() => socketUrl;
}
