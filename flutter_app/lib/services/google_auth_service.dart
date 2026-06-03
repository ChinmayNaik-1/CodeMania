import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';

bool _registerWebJsBridge() {
  if (!kIsWeb) return false;
  // JS bridge registration is handled via a separate web-only file
  return false;
}

final bool _webJsBridgeInitialized = _registerWebJsBridge();

class GoogleAuthService {
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  
  static Completer<String?>? _webSignInCompleter;

  factory GoogleAuthService() {
    return _instance;
  }

  GoogleAuthService._internal() {
    if (kIsWeb) {
      _setupWebCallbacks();
    }
  }

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId:
        '745626973988-s5f7s7fo4ea28s430354odulsagdjlcm.apps.googleusercontent.com',
  );

  static void _setupWebCallbacks() {
    if (!kIsWeb) return;
    _registerWebJsBridge();
  }

  Future<String?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        return await _signInWithGISWeb();
      } else {
        return await _signInWithGoogleSignInNative();
      }
    } catch (e) {
      if (kDebugMode) print('🔐 [GOOGLE-AUTH-ERROR] $e');
      return null;
    }
  }

  Future<String?> _signInWithGISWeb() async {
    try {
      if (kDebugMode) print('🔐 [GOOGLE-LOGIN] Starting GIS sign-in (web)');
      
      _webSignInCompleter = Completer<String?>();
     
      _callJSFunction();
      
      final result = await _webSignInCompleter!.future.timeout(
        Duration(minutes: 5),
        onTimeout: () {
          if (kDebugMode) print('🔐 [GOOGLE-AUTH] Sign-in timeout');
          return null;
        },
      );
      
      _webSignInCompleter = null;
      return result;
    } catch (e) {
      if (kDebugMode) print('🔐 [GOOGLE-AUTH-ERROR-GIS] $e');
      _webSignInCompleter = null;
      return null;
    }
  }

  static void _callJSFunction() {
    if (!kIsWeb) return;
    // no-op on non-web; web uses HtmlElementView + JS interop separately
  }

  // These static methods are called by JavaScript
  static void completeWebSignIn(String idToken) {
    if (kDebugMode) {
      final preview = idToken.length > 20 ? idToken.substring(0, 20) : idToken;
      print('🔐 [GOOGLE-AUTH] GIS returned token: $preview...');
    }
    if (_webSignInCompleter != null && !_webSignInCompleter!.isCompleted) {
      _webSignInCompleter!.complete(idToken);
    }
  }

  static void cancelWebSignIn(String? reason) {
    if (kDebugMode) print('🔐 [GOOGLE-AUTH] Sign-in cancelled: $reason');
    if (_webSignInCompleter != null && !_webSignInCompleter!.isCompleted) {
      _webSignInCompleter!.complete(null);
    }
  }

  Future<String?> _signInWithGoogleSignInNative() async {
    try {
      if (kDebugMode) print('🔐 [GOOGLE-LOGIN] Starting google_sign_in (native)');

      final account = await _googleSignIn.signIn();
      if (account == null) {
        if (kDebugMode) print('🔐 [GOOGLE-AUTH] Sign-in cancelled');
        return null;
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;

      if (idToken == null) {
        if (kDebugMode) print('🔐 [GOOGLE-AUTH] Failed to get idToken');
        return null;
      }

      if (kDebugMode) print('🔐 [GOOGLE-AUTH] Got idToken for ${account.email}');
      return idToken;
    } catch (e) {
      if (kDebugMode) print('🔐 [GOOGLE-AUTH-ERROR] $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }
      if (kDebugMode) print('🔐 [GOOGLE-AUTH] Signed out');
    } catch (e) {
      if (kDebugMode) print('🔐 [GOOGLE-AUTH-ERROR] Sign out failed: $e');
    }
  }

  Future<GoogleSignInAccount?> get currentUser async {
    if (kIsWeb) return null;
    return _googleSignIn.currentUser;
  }

  Future<bool> isSignedIn() async {
    if (kIsWeb) return false;
    return _googleSignIn.isSignedIn();
  }
}

