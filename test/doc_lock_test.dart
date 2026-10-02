import 'package:docify/services/doc_lock.dart';
import 'package:docify/widgets/doc_lock_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stands in for the phone's lock: [canLock] says whether the phone has one,
/// and every prompt answers [answer].
class _FakeAuth implements DeviceAuth {
  _FakeAuth({this.canLock = true});

  final bool canLock;
  UnlockResult answer = UnlockResult.unlocked;
  int prompts = 0;
  bool checkFails = false;

  @override
  Future<bool> available() async {
    if (checkFails) throw StateError('temporary platform error');
    return canLock;
  }

  @override
  Future<UnlockResult> unlock(String reason) async {
    prompts++;
    return answer;
  }
}

Future<GlobalKey<DocLockGateState>> _pumpGate(
  WidgetTester tester,
  DeviceAuth auth,
) async {
  final key = GlobalKey<DocLockGateState>();
  await tester.pumpWidget(
    MaterialApp(
      home: DocLockGate(
        key: key,
        auth: auth,
        // A Scaffold like the real page, so the gate's snackbars have
        // somewhere to show.
        builder: (_, __) => const Scaffold(body: Text('secret files')),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return key;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('LockSession', () {
    late DateTime now;
    late LockSession session;

    setUp(() {
      now = DateTime(2026, 9, 30, 10);
      session = LockSession(now: () => now);
    });

    test('starts locked and opens on unlock', () {
      expect(session.unlocked, isFalse);
      session.unlock();
      expect(session.unlocked, isTrue);
    });

    test('a quick trip to the file picker keeps it open', () {
      session.unlock();
      session.left();
      now = now.add(const Duration(seconds: 40));
      session.returned();
      expect(session.unlocked, isTrue);
    });

    test('a longer time away locks it again', () {
      session.unlock();
      session.left();
      now = now.add(const Duration(minutes: 3));
      session.returned();
      expect(session.unlocked, isFalse);
    });
  });

  test('only a phone that cannot check opens the files', () {
    expect(
      unlockResultFor(LocalAuthExceptionCode.userCanceled),
      UnlockResult.cancelled,
    );
    expect(
      unlockResultFor(LocalAuthExceptionCode.temporaryLockout),
      UnlockResult.lockedOut,
    );
    expect(
      unlockResultFor(LocalAuthExceptionCode.noCredentialsSet),
      UnlockResult.unavailable,
    );
  });

  group('DocLockGate', () {
    testWidgets('the files stay hidden until unlocked', (tester) async {
      final auth = _FakeAuth();
      await _pumpGate(tester, auth);
      expect(find.text('secret files'), findsNothing);
      expect(find.text('My documents is locked'), findsOneWidget);

      await tester.tap(find.text('Unlock'));
      await tester.pumpAndSettle();
      expect(find.text('secret files'), findsOneWidget);
    });

    testWidgets('a closed prompt keeps it locked', (tester) async {
      final auth = _FakeAuth()..answer = UnlockResult.cancelled;
      await _pumpGate(tester, auth);
      await tester.tap(find.text('Unlock'));
      await tester.pumpAndSettle();
      expect(find.text('secret files'), findsNothing);
      expect(auth.prompts, 1);
    });

    testWidgets('an authentication error never opens the files', (tester) async {
      final auth = _FakeAuth()..answer = UnlockResult.unavailable;
      await _pumpGate(tester, auth);
      await tester.tap(find.text('Unlock'));
      await tester.pumpAndSettle();
      expect(find.text('secret files'), findsNothing);
      expect(find.text('My documents is locked'), findsOneWidget);
    });

    testWidgets('a failed availability check is fail-closed', (tester) async {
      final auth = _FakeAuth()..checkFails = true;
      await _pumpGate(tester, auth);
      expect(find.text('secret files'), findsNothing);
      expect(find.text('My documents is locked'), findsOneWidget);
    });

    testWidgets('a preview shares the lock and is covered on lockNow', (tester) async {
      final auth = _FakeAuth();
      final key = await _pumpGate(tester, auth);
      await tester.tap(find.text('Unlock'));
      await tester.pumpAndSettle();
      final context = tester.element(find.text('secret files'));
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => key.currentState!.guard(
          const Scaffold(body: Text('private preview')),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('private preview'), findsOneWidget);
      key.currentState!.lockNow();
      await tester.pumpAndSettle();
      expect(find.text('private preview'), findsNothing);
      expect(find.text('My documents is locked'), findsOneWidget);
    });

    testWidgets('opening the tab asks straight away', (tester) async {
      final auth = _FakeAuth();
      final gate = await _pumpGate(tester, auth);
      await gate.currentState!.shown();
      await tester.pumpAndSettle();
      expect(auth.prompts, 1);
      expect(find.text('secret files'), findsOneWidget);
    });

    testWidgets('a phone without a screen lock stays open', (tester) async {
      final auth = _FakeAuth(canLock: false);
      final gate = await _pumpGate(tester, auth);
      await gate.currentState!.shown();
      await tester.pumpAndSettle();
      expect(find.text('secret files'), findsOneWidget);
      expect(auth.prompts, 0);
    });

    testWidgets('turning the lock off needs the owner', (tester) async {
      final auth = _FakeAuth();
      final gate = await _pumpGate(tester, auth);
      await tester.tap(find.text('Unlock'));
      await tester.pumpAndSettle();

      auth.answer = UnlockResult.cancelled;
      await gate.currentState!.toggle();
      await tester.pumpAndSettle();
      expect(gate.currentState!.lockOn, isTrue);

      auth.answer = UnlockResult.unlocked;
      await gate.currentState!.toggle();
      await tester.pumpAndSettle();
      expect(gate.currentState!.lockOn, isFalse);
      expect(await DocLock.enabled(), isFalse);
    });

    testWidgets('turned off, it opens without asking', (tester) async {
      SharedPreferences.setMockInitialValues({'doc_lock': false});
      final auth = _FakeAuth();
      await _pumpGate(tester, auth);
      expect(find.text('secret files'), findsOneWidget);
      expect(auth.prompts, 0);
    });
  });
}
