import 'package:flutter_test/flutter_test.dart';
import 'package:docify/models/exam_preset.dart';
import 'package:docify/models/saved_doc.dart';

void main() {
  test('exam presets cover the Indian form set', () {
    final ids = ExamPreset.all.map((e) => e.id).toSet();
    expect(
      ids,
      containsAll(['ssc', 'ibps', 'rail', 'upsc', 'passport', 'custom']),
    );
    final ssc = ExamPreset.byId('ssc');
    expect(ssc.photoMinKb, 20);
    expect(ssc.photoMaxKb, 50);
    expect(ssc.sigMaxKb, 20);
    expect(ExamPreset.byId('missing').id, 'custom');
  });

  test('mime and kb helpers', () {
    expect(mimeFromName('a.JPG'), 'image/jpeg');
    expect(mimeFromName('sign.png'), 'image/png');
    expect(mimeFromName('pack.pdf'), 'application/pdf');
    expect(kbLabel(2048), '2.0 KB');
    expect(uniqueDocifyName('jpg').endsWith('.jpg'), isTrue);
    final doc = SavedDoc(
      id: 'x.pdf',
      name: 'x.pdf',
      mime: 'application/pdf',
      size: 10,
      modified: DateTime(2026, 9, 27),
    );
    expect(doc.isPdf, isTrue);
    expect(doc.isImage, isFalse);
  });
}
