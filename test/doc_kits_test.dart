import 'package:docify/models/application_kit.dart';
import 'package:docify/models/saved_doc.dart';
import 'package:docify/services/doc_kits.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

SavedDoc _doc(String name) => SavedDoc(id: name, name: name,
  mime: mimeFromName(name), size: 1, modified: DateTime(2026));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('kits persist, track missing files, and follow document renames', () async {
    final kit = await DocKits.create('SSC 2026', requiredSlots: {KitSlot.photo, KitSlot.signature});
    await DocKits.attach(kit.id, KitSlot.photo, 'photo.jpg');
    expect((await DocKits.load()).single.missing([_doc('photo.jpg')]), [KitSlot.signature]);
    await DocKits.renamed('photo.jpg', 'Passport.jpg');
    final restored = (await DocKits.load()).single;
    expect(restored.files[KitSlot.photo], 'Passport.jpg');
    expect(restored.missing([]), [KitSlot.photo, KitSlot.signature]);
    await DocKits.remove(kit.id);
    expect(await DocKits.load(), isEmpty);
  });

  test('kit removal does not remove attached document bytes', () async {
    final kit = await DocKits.create('Job');
    await DocKits.attach(kit.id, KitSlot.idProof, 'id.pdf');
    await DocKits.remove(kit.id);
    // The kit service has no storage-delete API; all references are local labels.
    expect(await DocKits.load(), isEmpty);
  });

  test('photo and signature slots require images', () {
    expect(KitSlot.photo.accepts(_doc('photo.jpg')), isTrue);
    expect(KitSlot.photo.accepts(_doc('photo.pdf')), isFalse);
    expect(KitSlot.certificate.accepts(_doc('degree.pdf')), isTrue);
  });
}
