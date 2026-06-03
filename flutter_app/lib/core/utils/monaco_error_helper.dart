import 'package:flutter/foundation.dart';

class MonacoErrorHelper {
  static void setErrorMarker(int? line, String? message) {
    if (!kIsWeb) return;
    _setMarkerWeb(line, message);
  }

  static void clearMarkers() => setErrorMarker(null, null);

  static int? parseErrorLine(String? errorMessage) {
    if (errorMessage == null) return null;
    final match = RegExp(r':(\d+):\d+:').firstMatch(errorMessage);
    if (match == null) return null;
    return int.tryParse(match.group(1) ?? '');
  }

  static void _setMarkerWeb(int? line, String? message) {
    // web implementation — no-op on Android
  }
}
