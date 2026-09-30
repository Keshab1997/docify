import 'dart:convert';

import 'package:docify/services/doc_folders.dart';
import 'package:docify/services/drive/folder_backup.dart';
import 'package:flutter_test/flutter_test.dart';

const _wbssc = DocFolder(id: 'f1', name: 'WBSSC 2026');
const _railway = DocFolder(id: 'f2', name: 'Railway Form');

FolderSync _plan({
  FolderBackup? onDrive,
  DocLibrary library = const DocLibrary(),
  Map<String, String> localMd5 = const {},
  Set<String>? driveMd5,
}) {
  return FolderSync.plan(
    onDrive: onDrive,
    library: library,
    localMd5: localMd5,
    // Unless a test says otherwise, every file in the backup is on Drive.
    driveMd5: driveMd5 ?? <String>{...?onDrive?.files.keys},
  );
}

void main() {
  group('FolderBackup', () {
    test('reads back what it wrote', () {
      const backup = FolderBackup(
        folders: [_wbssc],
        files: {'md5-a': 'f1', 'md5-b': 'idProof'},
      );
      final read = FolderBackup.parse(backup.toBytes());
      expect(read.sameAs(backup), isTrue);
      expect(read.folders.single.name, 'WBSSC 2026');
    });

    test('a damaged file reads as an empty backup', () {
      expect(FolderBackup.parse(utf8.encode('{not json')).isEmpty, isTrue);
      expect(FolderBackup.parse(utf8.encode('[1, 2]')).isEmpty, isTrue);
    });

    test('bad entries are skipped and the rest kept', () {
      final bytes = utf8.encode(
        jsonEncode({
          'folders': [
            {'id': 'f1', 'name': ' WBSSC 2026 '},
            {'id': 'f1', 'name': 'Twice'},
            {'id': 'others', 'name': 'Others'},
            {'id': 'f3', 'name': '  '},
            {'name': 'No id'},
            'junk',
          ],
          'files': {'md5-a': 'f1', 'md5-b': 7},
        }),
      );
      final read = FolderBackup.parse(bytes);
      expect([for (final f in read.folders) f.name], ['WBSSC 2026']);
      expect(read.files, {'md5-a': 'f1'});
    });

    test('a renamed folder counts as a change', () {
      const before = FolderBackup(folders: [_wbssc]);
      const after = FolderBackup(folders: [DocFolder(id: 'f1', name: 'SSC')]);
      expect(before.sameAs(after), isFalse);
      expect(before.sameAs(const FolderBackup(folders: [_wbssc])), isTrue);
    });
  });

  group('FolderSync', () {
    test('a new phone gets every folder back, empty ones too', () {
      final sync = _plan(
        onDrive: const FolderBackup(
          folders: [_wbssc, _railway],
          files: {'md5-a': 'f1', 'md5-b': 'idProof'},
        ),
      );
      final names = [for (final f in sync.create) f.name];
      expect(names, ['WBSSC 2026', 'Railway Form']);
      expect(sync.byMd5, {'md5-a': 'f1', 'md5-b': 'idProof'});
      // Drive already has the backup this phone will match.
      expect(sync.backup, isNull);
    });

    test('a backup folder joins one here with the same name', () {
      const mine = DocFolder(id: 'f9', name: 'wbssc 2026');
      final sync = _plan(
        onDrive: const FolderBackup(
          folders: [_wbssc],
          files: {'md5-a': 'f1'},
        ),
        library: const DocLibrary(custom: [mine]),
      );
      expect(sync.create, isEmpty);
      expect(sync.byMd5, {'md5-a': 'f9'});
      expect(sync.backup!.folders.single.id, 'f9');
      expect(sync.backup!.files, {'md5-a': 'f9'});
    });

    test('a folder deleted on this phone does not come back', () {
      final sync = _plan(
        onDrive: const FolderBackup(
          folders: [_wbssc],
          files: {'md5-a': 'f1'},
        ),
        library: const DocLibrary(deleted: {'f1'}),
      );
      expect(sync.create, isEmpty);
      expect(sync.byMd5, isEmpty);
      expect(sync.backup!.isEmpty, isTrue);
    });

    test('a file already in a folder here stays there', () {
      final sync = _plan(
        onDrive: const FolderBackup(
          files: {'md5-a': 'idProof', 'md5-b': 'idProof'},
        ),
        library: const DocLibrary(filed: {'a.pdf': 'jobForms'}),
        localMd5: const {'a.pdf': 'md5-a', 'b.pdf': 'md5-b'},
      );
      expect(sync.assign, {'b.pdf': 'idProof'});
      expect(sync.restores, isTrue);
      expect(sync.backup!.files, {'md5-a': 'jobForms', 'md5-b': 'idProof'});
    });

    test('a file whose folder is gone goes where the backup has it', () {
      final sync = _plan(
        onDrive: const FolderBackup(files: {'md5-a': 'idProof'}),
        library: const DocLibrary(filed: {'a.pdf': 'f404'}),
        localMd5: const {'a.pdf': 'md5-a'},
      );
      expect(sync.assign, {'a.pdf': 'idProof'});
    });

    test('files no longer on Drive drop out of the backup', () {
      final sync = _plan(
        onDrive: const FolderBackup(
          folders: [_wbssc],
          files: {'md5-a': 'f1', 'md5-gone': 'f1'},
        ),
        driveMd5: const {'md5-a'},
      );
      expect(sync.backup!.files, {'md5-a': 'f1'});
    });

    test('with no folders and nothing filed there is nothing to do', () {
      final sync = _plan(localMd5: const {'a.pdf': 'md5-a'});
      expect(sync.isEmpty, isTrue);
    });

    test('a saved backup leaves nothing for the next sync', () {
      const library = DocLibrary(
        custom: [_wbssc],
        filed: {'a.pdf': 'f1'},
      );
      const localMd5 = {'a.pdf': 'md5-a'};
      final first = _plan(library: library, localMd5: localMd5);
      expect(first.backup!.files, {'md5-a': 'f1'});

      final next = _plan(
        onDrive: FolderBackup.parse(first.backup!.toBytes()),
        library: library,
        localMd5: localMd5,
      );
      expect(next.isEmpty, isTrue);
    });
  });
}
