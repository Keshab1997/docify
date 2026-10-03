import 'package:flutter_test/flutter_test.dart';

import 'package:docify/services/app_update_policy.dart';

UpdateInfo info({
  bool available = true,
  bool flexibleAllowed = true,
  bool immediateAllowed = true,
  int priority = 0,
  int? stalenessDays,
  bool downloaded = false,
}) {
  return UpdateInfo(
    available: available,
    flexibleAllowed: flexibleAllowed,
    immediateAllowed: immediateAllowed,
    priority: priority,
    stalenessDays: stalenessDays,
    downloaded: downloaded,
  );
}

void main() {
  test('no update, no prompt', () {
    expect(decideUpdate(info(available: false)), UpdateDecision.none);
    expect(decideUpdate(null), UpdateDecision.none);
  });

  test('an ordinary update waits for the flexible flow', () {
    expect(decideUpdate(info(priority: 2)), UpdateDecision.flexible);
  });

  test('a priority 4 release gets the immediate flow', () {
    expect(decideUpdate(info(priority: 4)), UpdateDecision.immediate);
  });

  test('priority 4 without Play permission falls back to flexible', () {
    expect(
      decideUpdate(info(priority: 4, immediateAllowed: false)),
      UpdateDecision.flexible,
    );
  });

  test('a priority 3 update escalates after a week of being ignored', () {
    expect(
      decideUpdate(info(priority: 3, stalenessDays: 6)),
      UpdateDecision.flexible,
    );
    expect(
      decideUpdate(info(priority: 3, stalenessDays: 7)),
      UpdateDecision.immediate,
    );
  });

  test('low priority never gets a blocking prompt, however stale', () {
    expect(
      decideUpdate(info(priority: 2, stalenessDays: 30)),
      UpdateDecision.flexible,
    );
  });

  test(
      'a non-urgent update is skipped when only the blocking flow is '
      'allowed', () {
    expect(
      decideUpdate(info(priority: 1, flexibleAllowed: false)),
      UpdateDecision.none,
    );
  });

  test('nothing is offered when Play allows no flow at all', () {
    expect(
      decideUpdate(
        info(priority: 5, flexibleAllowed: false, immediateAllowed: false),
      ),
      UpdateDecision.none,
    );
  });

  test('a finished download does not change the decision', () {
    // The restart prompt is the caller's job; the decision is only about
    // availability and urgency.
    expect(
      decideUpdate(info(priority: 2, downloaded: true)),
      UpdateDecision.flexible,
    );
  });
}
