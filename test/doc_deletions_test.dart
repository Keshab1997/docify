import 'package:docify/services/doc_deletions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('content suppression survives a renamed Drive copy', () async {
    await DocDeletions.record(name: 'id.pdf', digest: 'a');
    final deleted = await DocDeletions.load();
    expect(deleted.contains('renamed.pdf', 'a'), isTrue);
    expect(deleted.contains('id.pdf', 'different'), isFalse);
    expect(deleted.contains('id.pdf', null), isTrue);
  });

  test('concurrent deletions are not lost and explicit restore is allowed',
      () async {
    await Future.wait([
      DocDeletions.record(name: 'a.pdf', digest: 'a'),
      DocDeletions.record(name: 'b.pdf', digest: 'b'),
    ]);
    expect((await DocDeletions.load()).digests, {'a', 'b'});
    await DocDeletions.allow(name: 'a.pdf', digest: 'a');
    expect((await DocDeletions.load()).digests, {'b'});
  });
}
