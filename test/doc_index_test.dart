import 'package:docify/models/doc_meta.dart';
import 'package:docify/models/doc_query.dart';
import 'package:docify/models/saved_doc.dart';
import 'package:docify/services/doc_index.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

SavedDoc _file(String name) => SavedDoc(
      id: name,
      name: name,
      mime: mimeFromName(name),
      size: 100,
      modified: DateTime(2026),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('stars, tags and recent timestamps persist across rename', () async {
    await Future.wait([
      DocIndex.starred('id.pdf', true),
      DocIndex.tags('id.pdf', [' PAN ', 'pan', 'Exam'])
    ]);
    await DocIndex.opened('id.pdf');
    await DocIndex.renamed('id.pdf', 'PAN.pdf');
    final index = await DocIndex.load();
    expect(index['id.pdf'], isNull);
    expect(index['PAN.pdf']!.starred, isTrue);
    expect(index['PAN.pdf']!.tags, ['pan', 'exam']);
    expect(index['PAN.pdf']!.openedAt, isNotNull);
  });

  test('search includes tags, folder and locally recognised text', () {
    final pdf = _file('scan.pdf');
    const meta =
        DocMeta(starred: true, tags: ['ssc'], ocrText: 'Candidate certificate');
    expect(
        const DocQuery(text: 'SSC candidate', filter: DocFilter.pdf)
            .matches(pdf, meta, 'Certificates'),
        isTrue);
    expect(
        const DocQuery(filter: DocFilter.images)
            .matches(pdf, meta, 'Certificates'),
        isFalse);
    expect(
        const DocQuery(filter: DocFilter.starred)
            .matches(pdf, meta, 'Certificates'),
        isTrue);
  });

  test('recents ignore trashed files and use opened time, not modified time',
      () {
    final docs = [_file('a.pdf'), _file('b.pdf'), _file('c.pdf')];
    final index = {
      'a.pdf': const DocMeta(openedAt: 5),
      'b.pdf': const DocMeta(openedAt: 10, trashedAt: 11),
      'c.pdf': const DocMeta(openedAt: 7),
    };
    expect(recentDocuments(docs, index).map((d) => d.name), ['c.pdf', 'a.pdf']);
  });

  test('backup state is backed up only for the current digest', () {
    const meta = DocMeta(digest: 'new', backupDigest: 'old');
    expect(meta.backupState, DocBackupState.pending);
    expect(meta.copyWith(backupDigest: 'new').backupState,
        DocBackupState.backedUp);
    expect(meta.copyWith(backupError: 'failed').backupState,
        DocBackupState.failed);
  });
}
