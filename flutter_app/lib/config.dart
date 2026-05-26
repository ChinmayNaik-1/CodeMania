import 'package:flutter/foundation.dart' show kIsWeb;

class Config {
  static String get apiBaseUrl => _resolveBackendOrigin();
  static String get socketUrl => _resolveBackendOrigin();

  static String _resolveBackendOrigin() {
    if (!kIsWeb) {
      return 'http://localhost:3000';
    }

    final origin = Uri.base.origin;
    const localFrontendOrigins = {
      'http://localhost:5000',
      'http://localhost:5001',
      'http://127.0.0.1:5000',
      'http://127.0.0.1:5001',
    };

    if (localFrontendOrigins.contains(origin)) {
      return 'http://localhost:3000';
    }

    return origin;
  }

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
