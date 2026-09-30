import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// The only Drive scope we ask for: files this app creates or opens with its
/// own file picker. It never exposes the rest of the user's Drive.
const String driveScope = 'https://www.googleapis.com/auth/drive.file';

/// Firebase sign-in + Google Drive tokens.
///
/// The app is a fully working guest app before this is configured: the repo
/// ships without `android/app/google-services.json`, so [bootstrap] catches
/// the failure and flips [firebaseReady] to false instead of crashing the
/// app. Sign-in UI reads that flag and stays out of the way.
class AppAuth {
  AppAuth._();

  /// True once [Firebase.initializeApp] succeeded (google-services.json was
  /// present and valid at startup).
  static bool firebaseReady = false;

  static bool _googleReady = false;

  /// Why Google Sign-In cannot start on this build, or null when it can.
  ///
  /// Filled in by [_initGoogle] so the UI can show the console steps that fix
  /// the build instead of the plugin's terse `clientConfigurationError`.
  static String? get configurationProblem => _configProblem;

  static String? _configProblem;

  static final GoogleSignIn _google = GoogleSignIn.instance;

  /// Called once from main() before runApp. Never throws.
  static Future<void> bootstrap() async {
    try {
      await Firebase.initializeApp();
      firebaseReady = true;
    } catch (e) {
      debugPrint('AppAuth: Firebase not configured, staying guest ($e)');
    }
    await _initGoogle();
    if (firebaseReady) {
      try {
        // Silent: re-attach the account from last time if one exists.
        await _google.attemptLightweightAuthentication();
      } catch (_) {
        // No remembered account — normal guest state.
      }
    }
  }

  static Future<void> _initGoogle() async {
    if (_googleReady) return;
    // Web client id (the "Web application (auto-created by Google)" OAuth
    // client of the Firebase/Cloud project) makes the ID token verifiable.
    // On Android this is NOT optional: it is the client the ID token is minted
    // for. When the define is empty the plugin falls back to the
    // `default_web_client_id` resource that the google-services Gradle plugin
    // generates -- but only if google-services.json carries a Web OAuth client
    // (client_type 3). Lacking both is the clientConfigurationError below.
    const serverClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
    try {
      await _google.initialize(
        serverClientId: serverClientId.isEmpty ? null : serverClientId,
      );
      _googleReady = true;
      _configProblem = null;
    } on GoogleSignInException catch (e) {
      _configProblem = _explainInitFailure(e);
      debugPrint('AppAuth: GoogleSignIn init failed ($e)');
    } catch (e) {
      _configProblem = 'Google Sign-In could not start on this build: $e';
      debugPrint('AppAuth: GoogleSignIn init failed ($e)');
    }
  }

  /// Expands the plugin's one-line `clientConfigurationError` into the console
  /// steps that actually fix it.
  static String _explainInitFailure(GoogleSignInException e) {
    if (e.code != GoogleSignInExceptionCode.clientConfigurationError) {
      return 'Google Sign-In is not configured on this build ($e).';
    }
    const serverClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
    final compiled = serverClientId.isEmpty ? 'none' : serverClientId;
    return 'This build has no Google web client id (serverClientId: '
        '$compiled), so Sign-In cannot start. Fix: Firebase console -> '
        'Authentication -> Sign-in method -> Google -> Enable, then add a Web '
        'app under Project settings, re-download google-services.json and '
        're-set the GOOGLE_SERVICES_JSON_BASE64 secret -- or set the '
        'GOOGLE_SERVER_CLIENT_ID repository variable to that '
        '<id>.apps.googleusercontent.com value -- and rebuild.';
  }

  /// The signed-in Firebase user, or null (guest / not configured).
  static User? get user =>
      firebaseReady ? FirebaseAuth.instance.currentUser : null;

  /// Initial emit + every auth change, safe on unconfigured builds.
  static Stream<User?> watchUser() async* {
    if (!firebaseReady) {
      yield null;
      return;
    }
    yield FirebaseAuth.instance.currentUser;
    yield* FirebaseAuth.instance.authStateChanges();
  }

  /// Google sign-in + Firebase credential. Call only from a button tap (the
  /// platform may require a user gesture for the account chooser).
  static Future<User> signIn() async {
    if (!firebaseReady) {
      throw StateError(
        'Sign-in is not set up on this build yet: '
        'android/app/google-services.json was missing or invalid at build '
        'time, so Firebase never initialised. See docs/sync_setup.md step 2.',
      );
    }
    await _initGoogle();
    if (!_googleReady) {
      throw StateError(
        _configProblem ?? 'Google Sign-In is not configured on this build.',
      );
    }
    final account = await _google.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw StateError(
        'Google did not return an ID token. This build has no web client id: '
        'google-services.json must carry a Web OAuth client (client_type 3), '
        'or GOOGLE_SERVER_CLIENT_ID must be compiled in. See '
        'docs/sync_setup.md step 6.',
      );
    }
    final cred = await FirebaseAuth.instance.signInWithCredential(
      GoogleAuthProvider.credential(idToken: idToken),
    );
    final user = cred.user;
    if (user == null) throw StateError('Sign-in returned no user.');
    return user;
  }

  /// Access token for [driveScope], silently if already granted.
  /// Returns null when the user has not granted Drive access yet.
  static Future<String?> driveTokenIfGranted() async {
    if (!firebaseReady) return null;
    await _initGoogle();
    final auth =
        await _google.authorizationClient.authorizationForScopes([driveScope]);
    return auth?.accessToken;
  }

  /// Drive token, prompting the permission sheet if needed. Only from a tap.
  static Future<String> driveToken() async {
    await _initGoogle();
    final existing = await driveTokenIfGranted();
    if (existing != null) return existing;
    final granted =
        await _google.authorizationClient.authorizeScopes([driveScope]);
    return granted.accessToken;
  }

  /// Local + Firebase session only. Drive files the user already uploaded
  /// are theirs and are never touched on sign-out.
  static Future<void> signOut() async {
    if (firebaseReady) {
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {
        // Best effort: local session clearing can still proceed.
      }
    }
    try {
      await _google.signOut();
    } catch (_) {
      // Same.
    }
  }
}

/// Firebase auth state as a Riverpod stream (null = guest).
final StreamProvider<User?> authStateProvider = StreamProvider<User?>(
  (ref) => AppAuth.watchUser(),
);
