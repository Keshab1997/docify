import 'package:docify/models/doc_meta.dart';
import 'package:docify/models/doc_query.dart';
import 'package:docify/models/saved_doc.dart';
import 'package:flutter_test/flutter_test.dart';

SavedDoc _file(String name, {int size = 100}) => SavedDoc(
      id: name,
      name: name,
      mime: mimeFromName(name),
      size: size,
      modified: DateTime(2026),
    );

void main() {
  test('text matches across name words, ignoring case', () {
    final doc = _file('SSC_Photo.jpg');
    const meta = DocMeta();
    expect(
      const DocQuery(text: 'ssc photo').matches(doc, meta, 'Others'),
      isTrue,
    );
    expect(
      const DocQuery(text: 'ssc admit').matches(doc, meta, 'Others'),
      isFalse,
    );
  });

  test('type filters keep only their own kind', () {
    final pdf = _file('form.pdf');
    final photo = _file('photo.jpg');
    const meta = DocMeta();
    const onlyPdf = DocQuery(filter: DocFilter.pdf);
    expect(onlyPdf.matches(pdf, meta, 'Others'), isTrue);
    expect(onlyPdf.matches(photo, meta, 'Others'), isFalse);
    const onlyImages = DocQuery(filter: DocFilter.images);
    expect(onlyImages.matches(photo, meta, 'Others'), isTrue);
    expect(onlyImages.matches(pdf, meta, 'Others'), isFalse);
  });

  test('starred filter keeps only starred documents', () {
    final doc = _file('id.pdf');
    const query = DocQuery(filter: DocFilter.starred);
    const starred = DocMeta(starred: true);
    expect(query.matches(doc, starred, 'Others'), isTrue);
    expect(query.matches(doc, const DocMeta(), 'Others'), isFalse);
  });

  test('tag filter keeps only documents carrying the tag', () {
    final doc = _file('marksheet.pdf');
    const query = DocQuery(tag: 'ssc');
    const tagged = DocMeta(tags: ['ssc']);
    expect(query.matches(doc, tagged, 'Others'), isTrue);
    expect(query.matches(doc, const DocMeta(), 'Others'), isFalse);
  });

  test('free text looks in the folder, tags and recognised text', () {
    final doc = _file('scan.pdf');
    const meta = DocMeta(tags: ['ssc'], ocrText: 'Candidate certificate');
    const byFolder = DocQuery(text: 'certificates');
    expect(byFolder.matches(doc, meta, 'Certificates'), isTrue);
    expect(byFolder.matches(doc, meta, 'Others'), isFalse);
    const byTag = DocQuery(text: 'ssc');
    expect(byTag.matches(doc, meta, 'Others'), isTrue);
    const byOcr = DocQuery(text: 'candidate');
    expect(byOcr.matches(doc, meta, 'Others'), isTrue);
  });

  test('sortDocuments breaks modification ties by id', () {
    final b = _file('b.pdf');
    final a = _file('a.pdf');
    final sorted = sortDocuments([b, a], DocSort.newest);
    expect(sorted.map((doc) => doc.id), ['a.pdf', 'b.pdf']);
  });

  test('recentDocuments skips trash, the unopened and the overflow', () {
    final old = _file('old.pdf');
    final fresh = _file('fresh.pdf');
    final trashed = _file('trashed.pdf');
    final unseen = _file('unseen.pdf');
    const index = {
      'old.pdf': DocMeta(openedAt: 100),
      'fresh.pdf': DocMeta(openedAt: 200),
      'trashed.pdf': DocMeta(openedAt: 300, trashedAt: 400),
    };
    final recent = recentDocuments(
      [old, fresh, trashed, unseen],
      index,
      limit: 1,
    );
    expect(recent.map((doc) => doc.id), ['fresh.pdf']);
  });
}
