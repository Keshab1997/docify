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
///
/// Sign-in is strictly opt-in: opening the app never triggers any Google
/// authentication UI. The only entry points are explicit user taps — the
/// "Sign in with Google" button on the Profile tab and the Drive sync sheet.
class AppAuth {
  AppAuth._();

  /// True once [Firebase.initializeApp] succeeded (google-services.json was
  /// present and valid at startup).
  static bool firebaseReady = false;

  static bool _googleReady = false;

  static final GoogleSignIn _google = GoogleSignIn.instance;

  /// Called once from main() before runApp. Never throws.
  ///
  /// Deliberately performs NO Google authentication: opening the app must
  /// never show an account chooser or sign-in prompt (the old silent
  /// re-attach could pop one on first launch in Firebase-enabled builds).
  /// Returning users still stay signed in — Firebase persists the session
  /// locally, so [user] is non-null on restart without any startup call.
  /// Signing in (or back in) happens only from an explicit tap: the
  /// Profile tab button or the Drive sync sheet.
  static Future<void> bootstrap() async {
    try {
      await Firebase.initializeApp();
      firebaseReady = true;
    } catch (e) {
      debugPrint('AppAuth: Firebase not configured, staying guest ($e)');
    }
    await _initGoogle();
  }

  static Future<void> _initGoogle() async {
    if (_googleReady) return;
    try {
      // Web client id (the "Web application (auto-created by Google)" OAuth
      // client of the Firebase/Cloud project) makes the ID token verifiable.
      // Optional: builds without it sign in without it.
      const serverClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
      await _google.initialize(
        serverClientId: serverClientId.isEmpty ? null : serverClientId,
      );
      _googleReady = true;
    } catch (e) {
      debugPrint('AppAuth: GoogleSignIn init failed ($e)');
    }
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
      throw StateError('Sign-in is not set up on this build yet.');
    }
    await _initGoogle();
    final account = await _google.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw StateError('Google did not return an ID token.');
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
