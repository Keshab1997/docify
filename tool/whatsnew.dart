// Generates the Play Store "What's new" draft for the next release.
//
//   dart run tool/whatsnew.dart           append a draft for the new commits
//   dart run tool/whatsnew.dart --check   fail if the notes are stale or too long
//
// The builder cannot do this for you: play-whats-new-directory is only a path
// string that gets handed to the upload action, so the files have to exist in
// the repository before the run. This script writes that first draft from the
// commit messages since the last release tag, so the wording is the only part
// left for a human.
//
// It never rewrites lines it did not write. Anything already in a notes file is
// kept, and untranslated Bengali is marked so it cannot ship by accident.

import 'dart:io';

const enFile = 'distribution/whatsnew/whatsnew-en-US';
const bnFile = 'distribution/whatsnew/whatsnew-bn-BD';

/// Play rejects a release-notes entry over this length.
const playLimit = 500;

/// Conventional-commit prefixes that mean something a user would notice.
const userFacing = {'feat', 'feature', 'fix', 'bugfix', 'perf'};

/// Prefixes that are invisible to a user and must not reach the store.
const internal = {
  'chore',
  'build',
  'ci',
  'test',
  'refactor',
  'deps',
  'dep',
  'docs',
  'doc',
};

/// Commit prefixes that carry more weight in the notes, in the order Play
/// renders them.
const order = ['feat', 'fix', 'perf'];

void main(List<String> args) {
  if (args.contains('--check')) {
    exit(_check());
  }
  exit(_draft());
}

int _draft() {
  final commits = _commitsSinceLastTag();
  if (commits.isEmpty) {
    stderr.writeln(
        'No new commits since the last release tag. Nothing to write.');
    return 0;
  }

  final grouped = _group(commits);
  if (grouped.isEmpty) {
    stderr.writeln(
      'Found ${commits.length} new commit(s), but none are user-facing '
      '(all chore/ci/docs). The notes files are left untouched.',
    );
    return 0;
  }

  final version = _version();
  print('New commits since the last release:\n');
  for (final kind in order) {
    for (final line in grouped[kind] ?? const <String>[]) {
      print('  ${kind.padRight(4)}  $line');
    }
  }
  print('');

  _append(enFile, version, grouped, translate: false);
  _append(bnFile, version, grouped, translate: true);
  _warnLength(enFile);
  _warnLength(bnFile);

  print('\nWrote a draft. Read it, fix the wording, then commit both files.');
  return 0;
}

/// CI gate: run before a release so stale or oversized notes fail the build
/// instead of the Play upload.
int _check() {
  var failed = 0;
  final version = _version();

  for (final path in [enFile, bnFile]) {
    final file = File(path);
    if (!file.existsSync()) {
      stderr.writeln(
          '::error::$path is missing. Run: dart run tool/whatsnew.dart');
      failed = 1;
      continue;
    }
    final text = file.readAsStringSync();
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      stderr.writeln(
          '::error::$path is empty. The store listing would show nothing.');
      failed = 1;
      continue;
    }
    if (trimmed.length > playLimit) {
      stderr.writeln(
        '::error::$path is ${trimmed.length} characters. Play allows $playLimit.',
      );
      failed = 1;
    }
    if (trimmed.contains('TODO(bn)')) {
      stderr.writeln(
          '::error::$path still has TODO(bn) markers. Translate them first.');
      failed = 1;
    }
    if (!trimmed.contains(version)) {
      stderr.writeln(
        '::error::$path has no entry for $version. '
        'Run: dart run tool/whatsnew.dart',
      );
      failed = 1;
    }
  }

  if (failed == 0) {
    print('Release notes are present and valid for $version.');
  }
  return failed;
}

List<String> _commitsSinceLastTag() {
  final last = _lastTag();
  final range = last == null ? 'HEAD' : '$last..HEAD';
  final result = Process.runSync(
    'git',
    ['log', range, '--no-merges', '--format=%s'],
  );
  if (result.exitCode != 0) {
    stderr.writeln('git log failed:\n${result.stderr}');
    exit(1);
  }
  return (result.stdout as String)
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();
}

String? _lastTag() {
  final result = Process.runSync(
    'git',
    ['describe', '--tags', '--abbrev=0', '--match', 'v*'],
  );
  final out = (result.stdout as String).trim();
  return result.exitCode == 0 && out.isNotEmpty ? out : null;
}

String _version() {
  final pubspec = File('pubspec.yaml').readAsStringSync();
  final match =
      RegExp(r'^version:\s*(\S+)', multiLine: true).firstMatch(pubspec);
  if (match == null) {
    stderr.writeln('Could not read a version from pubspec.yaml.');
    exit(1);
  }
  return match.group(1)!.split('+').first;
}

/// Buckets the cleaned commit subjects by kind, dropping anything a user would
/// not notice.
Map<String, List<String>> _group(List<String> commits) {
  final prefix = RegExp(
    r'^(feat|feature|fix|bugfix|perf|performance|chore|build|ci|refactor|'
    r'test|deps?)(?:\([^)]*\))?!?:\s*',
    caseSensitive: false,
  );
  final grouped = <String, List<String>>{};
  for (final raw in commits) {
    final match = prefix.firstMatch(raw);
    final kind = (match?.group(1) ?? '').toLowerCase();
    if (internal.contains(kind)) continue;
    if (!userFacing.contains(kind)) continue;

    var subject = raw.replaceFirst(prefix, '').trim();
    if (subject.isEmpty) continue;
    subject = subject[0].toUpperCase() + subject.substring(1);
    // A commit that already reads as a full sentence needs no bullet mark.
    (grouped[kind] ??= <String>[]).add(subject);
  }
  return grouped;
}

void _append(
  String path,
  String version,
  Map<String, List<String>> grouped, {
  required bool translate,
}) {
  final file = File(path);
  file.parent.createSync(recursive: true);

  final buffer = StringBuffer();
  if (file.existsSync() && file.readAsStringSync().trim().isNotEmpty) {
    buffer.writeln();
    buffer.writeln();
  }
  buffer.writeln('--- $version ---');

  for (final kind in order) {
    for (final line in grouped[kind] ?? const <String>[]) {
      // Bengali is not machine-translated here. The English line is left in
      // place behind a marker so the missing translation is obvious instead of
      // silently reaching Bengali users.
      final text = translate ? 'TODO(bn) $line' : line;
      buffer.writeln('• $text');
    }
  }

  file.writeAsStringSync(buffer.toString(), mode: FileMode.append);
  print('${translate ? "Bengali" : "English"}: appended to $path');
}

void _warnLength(String path) {
  final length = File(path).readAsStringSync().trim().length;
  if (length > playLimit) {
    print(
      'WARNING: $path is $length characters, over the Play limit of $playLimit. '
      'Trim it to the few lines that matter.',
    );
  }
}
