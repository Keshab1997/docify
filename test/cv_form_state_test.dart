import 'dart:typed_data';

import 'package:docify/screens/tools/cv/cv_form_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A new form with the saved draft restored, as when the builder reopens.
Future<CvFormState> _reopen() async {
  final form = CvFormState();
  await form.load();
  return form;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('CvFormState saving', () {
    test('typing is saved without tapping Preview or Save', () async {
      final form = await _reopen();
      form.name.text = 'Keshab Sarkar';
      // Longer than the autosave delay.
      await Future<void>.delayed(const Duration(seconds: 1));
      expect((await _reopen()).name.text, 'Keshab Sarkar');
    });

    test('closing the builder saves the last keystrokes', () async {
      final form = await _reopen();
      form.skills.text = 'Flutter, Dart';
      form.dispose();
      // Let the write that dispose started finish.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect((await _reopen()).skills.text, 'Flutter, Dart');
    });

    test('the photo is still there when the builder reopens', () async {
      final form = await _reopen();
      form.photo = Uint8List.fromList([1, 2, 3, 4]);
      await form.persist();
      expect((await _reopen()).photo, [1, 2, 3, 4]);
    });

    test('removing the photo removes the saved copy too', () async {
      final form = await _reopen();
      form.photo = Uint8List.fromList([1, 2, 3, 4]);
      await form.persist();
      form.photo = null;
      await form.persist();
      expect((await _reopen()).photo, isNull);
    });

    test('a damaged saved photo does not stop the draft loading', () async {
      SharedPreferences.setMockInitialValues({
        'cv_photo': 'not base64!',
        'cv_name': 'Keshab Sarkar',
      });
      final form = await _reopen();
      expect(form.photo, isNull);
      expect(form.name.text, 'Keshab Sarkar');
    });

    test('a new draft starts with the default declaration', () async {
      final form = await _reopen();
      expect(form.declaration.text, startsWith('I hereby declare'));
    });
  });
}
