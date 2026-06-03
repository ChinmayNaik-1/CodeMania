import 'dart:js_util' as js_util;

import 'package:flutter/foundation.dart';

class MonacoErrorHelper {
  /// Sets a red error squiggly on the given line in Monaco.
  /// errorLine is 1-indexed. Pass null to clear all markers.
  static void setErrorMarker(int? errorLine, String? message) {
    if (!kIsWeb) return;

    try {
      js_util.callMethod<dynamic>(
        js_util.globalThis,
        'setMonacoErrorMarker',
        [errorLine, message],
      );
    } catch (_) {
      // Monaco may not be ready yet; ignore silently to avoid breaking submit flow.
    }
  }

  /// Clears all error markers from Monaco.
  static void clearMarkers() => setErrorMarker(null, null);

  static int? parseErrorLine(String? errorMessage) {
    if (errorMessage == null) return null;
    final match = RegExp(r':(\d+):\d+:').firstMatch(errorMessage);
    if (match == null) return null;
    return int.tryParse(match.group(1) ?? '');
  }
}
