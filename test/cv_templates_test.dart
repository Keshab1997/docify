import 'package:flutter_test/flutter_test.dart';
import 'package:docify/models/cv_template_info.dart';
import 'package:docify/services/cv/cv_fit.dart';
import 'package:docify/services/cv/cv_text_sanitizer.dart';
import 'package:docify/services/cv_pdf_templates.dart';

CvData _data({int template = 0, String? name, String? education}) => CvData(
      template: template,
      name: name ?? 'Keshab Sarkar',
      title: 'Software Engineer & Flutter Developer',
      email: 'keshabsarkar2018@gmail.com',
      phone: '+91 9382284190',
      address:
          'Simla, Mertala, Tita, Purbasthali-2 Block, Purba Bardhaman - 713513',
      dob: '25/07/1997',
      father: 'Krishna Sarkar',
      objective: 'Passionate software engineer building cross-platform apps.',
      education: education ?? '• B.Tech CSE — MAKAUT (2020), 8.4',
      experience: '• Senior Developer at TechNova (2022 - Present)',
      skills: 'Flutter, Dart, Firebase',
      languages: 'English, Bengali, Hindi',
      declaration: 'I hereby declare that the above information is true.',
    );

/// A CV whose experience section runs to [bullets] one-line bullets.
CvData _long(int bullets, {int template = 0}) => CvData(
      template: template,
      name: 'Keshab Sarkar',
      email: 'keshabsarkar2018@gmail.com',
      phone: '+91 9382284190',
      objective: 'Passionate software engineer building cross-platform apps.',
      education: '• B.Tech CSE - MAKAUT (2020), 8.4',
      experience: '• Shipped features for a large app.\n' * bullets,
      skills: 'Flutter, Dart, Firebase',
      declaration: 'I hereby declare that the above information is true.',
    );

void main() {
  // Matches pdf_merge_test.dart: PDF generation in this project runs under the
  // test binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CvTextSanitizer', () {
    test('maps typographic characters the built-in font cannot draw', () {
      // The templates render with Helvetica, which only covers Latin-1; every
      // one of these used to reach the page as an empty box.
      expect(CvTextSanitizer.clean('A — B'), 'A - B');
      expect(CvTextSanitizer.clean('A – B'), 'A - B');
      expect(CvTextSanitizer.clean('• item'), '\u00B7 item');
      expect(CvTextSanitizer.clean('\u2018a\u2019'), "'a'");
      expect(CvTextSanitizer.clean('\u201Cb\u201D'), '"b"');
      expect(CvTextSanitizer.clean('wait\u2026'), 'wait...');
      expect(CvTextSanitizer.clean('Rs \u20B9 500'), 'Rs Rs. 500');
      expect(CvTextSanitizer.clean('a \u2192 b'), 'a -> b');
      expect(CvTextSanitizer.clean('\u2713 done'), '+ done');
    });

    test('keeps characters the font does cover', () {
      expect(CvTextSanitizer.clean('a \u00B7 b'), 'a \u00B7 b');
      expect(CvTextSanitizer.clean('caf\u00E9 na\u00EFve'),
          'caf\u00E9 na\u00EFve');
      expect(CvTextSanitizer.clean('a\u00A0b'), 'a b');
    });

    test('drops what cannot be drawn instead of printing a box', () {
      // Bengali would be tofu on every page today, so it is removed rather
      // than rendered as boxes. If a Unicode font is bundled later, this test
      // is the one that should change.
      expect(CvTextSanitizer.clean('বাংলা'), '');
    });

    test('leaves layout characters alone', () {
      expect(CvTextSanitizer.clean('a\nb'), 'a\nb');
      expect(CvTextSanitizer.clean('plain ASCII 123'), 'plain ASCII 123');
      expect(CvTextSanitizer.clean(''), '');
    });

    test('cleanData leaves no undrawable character in any field', () {
      const dirty = CvData(
        template: 0,
        name: 'Keshab \u2014 Sarkar',
        email: 'a\u2019b@x.com',
        phone: '+91 \u20B9 9382284190',
        education: '• B.Tech \u2192 MAKAUT\u2026',
        experience: '• Dev \u2013 TechNova',
        skills: 'Flutter \u00B7 Dart \u2022 Firebase',
      );
      final clean = CvTextSanitizer.cleanData(dirty);
      for (final field in [
        clean.name,
        clean.title,
        clean.email,
        clean.phone,
        clean.address,
        clean.dob,
        clean.father,
        clean.objective,
        clean.education,
        clean.experience,
        clean.skills,
        clean.languages,
        clean.declaration,
      ]) {
        for (final rune in field.runes) {
          expect(
            rune <= 0xFF || rune == 0x0A,
            isTrue,
            reason: 'U+${rune.toRadixString(16).toUpperCase()} in "$field"',
          );
        }
      }
    });

    test('names the fields that would silently lose text', () {
      expect(CvTextSanitizer.undrawableFields(_data()), isEmpty);
      expect(
        CvTextSanitizer.undrawableFields(
            _data(name: '\u0995\u09C7\u09B6\u09AC')),
        ['Full Name'],
      );
      expect(
        CvTextSanitizer.undrawableFields(
          _data(
              name: '\u0995\u09C7\u09B6\u09AC',
              education: '\u09AC\u09BF.\u099F\u09C7\u0995'),
        ),
        ['Full Name', 'Education'],
      );
    });

    test('reports only characters that are dropped, not ones that are mapped',
        () {
      // An em dash is rewritten to a hyphen, which the user never needs to
      // hear about; a Bengali letter disappears entirely, which they do.
      expect(CvTextSanitizer.lostChar('A \u2014 B'), isNull);
      expect(CvTextSanitizer.lostChar('plain ASCII'), isNull);
      expect(
          CvTextSanitizer.lostChar('\u09AC\u09BE\u0982\u09B2\u09BE'), '\u09AC');
      expect(CvTextSanitizer.lostChar('Engineer \u{1F680}'), '\u{1F680}');
    });
  });

  group('CvPdfTemplates', () {
    test('every design in kCvTemplates renders a PDF', () async {
      expect(kCvTemplates.length, greaterThan(0));
      for (final t in kCvTemplates) {
        final bytes = await CvPdfTemplates.generate(_data(template: t.id));
        expect(bytes.length, greaterThan(1000), reason: 'template ${t.id}');
        expect(
          String.fromCharCodes(bytes.take(5)),
          '%PDF-',
          reason: 'template ${t.id}',
        );
      }
    });

    test('an unknown template id falls back instead of throwing', () async {
      final bytes = await CvPdfTemplates.generate(_data(template: 999));
      expect(bytes.length, greaterThan(1000));
    });

    test('an empty CV still renders', () async {
      final bytes = await CvPdfTemplates.generate(
        const CvData(
            name: '',
            email: '',
            phone: '',
            education: '',
            experience: '',
            skills: ''),
      );
      expect(bytes.length, greaterThan(1000));
    });

    test('dirty input still produces a valid PDF', () async {
      // The PDF streams are compressed, so the bytes cannot be searched for the
      // offending characters. What this guards is that generation does not
      // throw on text pasted from Word or WhatsApp; the mapping itself is
      // covered by the CvTextSanitizer tests above.
      final bytes = await CvPdfTemplates.generate(
        _data(
            name: 'Keshab \u2014 Sarkar', education: '• B.Tech \u2192 MAKAUT'),
      );
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(bytes.length, greaterThan(1000));
    });
  });

  group('CvFit', () {
    test('a short CV is scaled up to fill the page', () async {
      // The empty band a short CV used to leave in the middle of the page is
      // what this engine exists to remove.
      for (final t in kCvTemplates) {
        final render = await CvPdfTemplates.render(_data(template: t.id));
        expect(render.scale, greaterThan(1), reason: 'template ${t.id}');
        expect(render.cutOff, isFalse, reason: 'template ${t.id}');
      }
    });

    test('a CV too long for full size shrinks instead of being cut', () async {
      // Add one line of experience at a time until the page has to shrink:
      // the first CV that no longer fits at full size must still fit whole.
      var bullets = 10;
      var render = await CvPdfTemplates.render(_long(bullets));
      while (render.scale >= 1 && bullets < 150) {
        bullets++;
        render = await CvPdfTemplates.render(_long(bullets));
      }
      expect(render.scale, lessThan(1));
      expect(render.scale, greaterThanOrEqualTo(CvFit.minScale));
      expect(render.cutOff, isFalse);
    });

    test('a CV too long for any scale is reported as cut off', () async {
      for (final t in kCvTemplates) {
        final render = await CvPdfTemplates.render(_long(200, template: t.id));
        expect(render.cutOff, isTrue, reason: 'template ${t.id}');
        expect(render.scale, CvFit.minScale, reason: 'template ${t.id}');
      }
    });
  });
}
