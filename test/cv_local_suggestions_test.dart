import 'package:docify/screens/tools/cv/cv_local_suggestions.dart';
import 'package:docify/screens/tools/cv/widgets/cv_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CvLocalSuggestions', () {
    test('objective suggestions use the target role and selected skills', () {
      final suggestions = CvLocalSuggestions.objectives(
        role: 'Data Analyst',
        skills: 'Excel, SQL, Python, Git',
      );

      expect(suggestions, hasLength(3));
      expect(suggestions.first.label, 'Fresher');
      expect(suggestions.first.text, contains('Data Analyst'));
      expect(suggestions.first.text, contains('Excel, SQL, and Python'));
      expect(suggestions[1].text, contains('Experienced Data Analyst'));
    });

    test('objective suggestions have a useful fallback when details are blank',
        () {
      final suggestions = CvLocalSuggestions.objectives(role: '', skills: '');

      expect(suggestions.first.text, contains('entry-level candidate'));
      expect(suggestions.first.text, contains('my relevant skills'));
      expect(suggestions.last.text, contains('an opportunity'));
    });

    test('skills are selected from the profile details', () {
      final teacherSkills = CvLocalSuggestions.skillsForProfile(
        role: 'Primary School Teacher',
        education: 'B.Ed',
        experience: '',
      );
      final officeSkills = CvLocalSuggestions.skillsForProfile(
        role: '',
        education: 'Diploma in Office Administration',
        experience: '',
      );
      final flutterSkills = CvLocalSuggestions.skillsForProfile(
        role: 'Flutter Developer',
        education: '',
        experience: '',
      );

      expect(teacherSkills, contains('Lesson Planning'));
      expect(officeSkills, contains('Data Entry'));
      expect(flutterSkills, containsAll(['Flutter', 'Dart', 'Firebase']));
      expect(teacherSkills, isNot(contains('Flutter')));
    });

    test('work and project templates use editable fact placeholders', () {
      final work = CvLocalSuggestions.workExperienceEntry(
        role: 'Office Assistant',
      );

      expect(work, contains('Office Assistant'));
      expect(work, contains('[Company]'));
      expect(work, contains('[Achievement or result, if known]'));
      expect(CvLocalSuggestions.internshipEntry, contains('[Organization]'));
      expect(CvLocalSuggestions.projectEntry, contains('[Project name]'));
    });

    test('declaration suggestions can use the entered name', () {
      final suggestions = CvLocalSuggestions.declarations(name: 'Asha Roy');

      expect(suggestions.first.text, CvLocalSuggestions.standardDeclaration);
      expect(suggestions.last.label, 'With my name');
      expect(suggestions.last.text, startsWith('I, Asha Roy,'));
    });
  });

  testWidgets('append suggestion inserts its text in the target field', (
    tester,
  ) async {
    final controller = TextEditingController(text: '• Existing role');
    var changed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CvHelperChip(
            label: 'Job entry',
            text: '• [Job title] — [Company]',
            target: controller,
            onChanged: () => changed = true,
            append: true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('+ Job entry'));
    await tester.pump();

    expect(
      controller.text,
      '• Existing role\n\n• [Job title] — [Company]',
    );
    expect(controller.selection.extentOffset, controller.text.length);
    expect(changed, isTrue);
    controller.dispose();
  });

  testWidgets('skill suggestions match exact entries, not substrings', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'Digital Marketing');
    Widget buildChips() => MaterialApp(
          home: Scaffold(
            body: CvQuickChips(
              title: 'Skills',
              items: const ['Git'],
              controller: controller,
              onChanged: () {},
            ),
          ),
        );

    await tester.pumpWidget(buildChips());
    expect(find.text('+ Git'), findsOneWidget);

    await tester.tap(find.text('+ Git'));
    await tester.pumpWidget(buildChips());
    expect(controller.text, 'Digital Marketing, Git');
    expect(find.text('✓ Git'), findsOneWidget);

    await tester.tap(find.text('✓ Git'));
    await tester.pumpWidget(buildChips());
    expect(controller.text, 'Digital Marketing');
    expect(find.text('+ Git'), findsOneWidget);
    controller.dispose();
  });
}
