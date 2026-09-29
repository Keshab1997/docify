import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobdoc/theme/motion.dart';
import 'package:jobdoc/widgets/animated_count.dart';
import 'package:jobdoc/widgets/animated_reveal.dart';
import 'package:jobdoc/widgets/job_progress.dart';
import 'package:jobdoc/widgets/pressable.dart';

void main() {
  testWidgets('AnimatedCount counts up and lands on the final value', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: AnimatedCount(92.4, decimals: 1, suffix: ' KB'),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('92.4 KB'), findsOneWidget);
  });

  testWidgets('AnimatedReveal shows its child and settles', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AnimatedReveal(index: 3, child: Text('tool')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('tool'), findsOneWidget);
    expect(tester.widget<Opacity>(find.byType(Opacity).first).opacity, 1);
  });

  testWidgets('JobProgressOverlay names the job and its steps', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: JobProgressOverlay(
            stage: JobStage.working,
            title: 'Merging PDFs',
            subtitle: 'Combining 3 files on this phone.',
            steps: ['Read', 'Merge', 'Save'],
          ),
        ),
      ),
    );
    // Repeating controllers: pump a frame, never pumpAndSettle.
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Merging PDFs'), findsOneWidget);
    expect(find.text('Combining 3 files on this phone.'), findsOneWidget);
    expect(find.text('Read'), findsOneWidget);
    expect(find.text('Merge'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('JobProgressOverlay reports a finished job', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: JobProgressOverlay(
            stage: JobStage.done,
            title: 'Merged',
            subtitle: 'Combining 3 files on this phone.',
            doneSubtitle: '3 files · 1.2 MB',
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.text('Merged'), findsOneWidget);
    expect(find.text('3 files · 1.2 MB'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsWidgets);
  });

  testWidgets('Pressable leaves an inner InkWell to handle its own tap', (
    tester,
  ) async {
    var inner = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Pressable(
            child: Material(
              child: InkWell(
                onTap: () => inner++,
                child: const SizedBox(width: 80, height: 80),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(InkWell));
    await tester.pump(const Duration(milliseconds: 200));
    expect(inner, 1);
  });

  testWidgets('Pressable fires its own tap once', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Pressable(
              onTap: () => taps++,
              child: const SizedBox(width: 60, height: 60),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(Pressable));
    await tester.pump(const Duration(milliseconds: 200));
    expect(taps, 1);
  });

  testWidgets('Motion.of hides animation when the device asks for less', (
    tester,
  ) async {
    late Duration seen;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (context) {
              seen = Motion.of(context, Motion.long);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    expect(seen, Duration.zero);
  });
}
