import 'dart:convert';
import 'dart:typed_data';

import '../doc_folders.dart';

/// Which file is in which folder, kept on Drive next to the files.
///
/// Drive holds one flat list of files, so without this a restore on a new
/// phone would leave every file in Others. Files are known by content
/// (md5), not by name: a file can sit on Drive as `name (2).ext`, and a
/// restored one can land under a new name on the phone.
class FolderBackup {
  const FolderBackup({this.folders = const [], this.files = const {}});

  /// Its name in the Docify folder on Drive. Sync never treats it as a
  /// document: it isn't downloaded, counted or shown.
  static const fileName = '.docify-folders.json';

  static const mime = 'application/json';

  /// The user's own folders; the built-in ones are on every phone.
  final List<DocFolder> folders;

  /// Folder id by file md5, for files the user put in a folder.
  final Map<String, String> files;

  bool get isEmpty => folders.isEmpty && files.isEmpty;

  /// Reads a backup, keeping whatever makes sense in it. A damaged file
  /// reads as an empty backup, so it can't stop a sync, and the next
  /// backup replaces it.
  factory FolderBackup.parse(List<int> bytes) {
    try {
      final data = jsonDecode(utf8.decode(bytes, allowMalformed: true));
      if (data is! Map) return const FolderBackup();
      return FolderBackup(
        folders: _foldersOf(data['folders']),
        files: _filesOf(data['files']),
      );
    } catch (_) {
      return const FolderBackup();
    }
  }

  Uint8List toBytes() {
    return Uint8List.fromList(
      utf8.encode(
        jsonEncode({
          'version': 1,
          'folders': [
            for (final f in folders) {'id': f.id, 'name': f.name},
          ],
          'files': files,
        }),
      ),
    );
  }

  /// The same folders, names included, and the same files in them.
  bool sameAs(FolderBackup other) {
    if (folders.length != other.folders.length ||
        files.length != other.files.length) {
      return false;
    }
    final names = {for (final f in other.folders) f.id: f.name};
    for (final f in folders) {
      if (names[f.id] != f.name) return false;
    }
    for (final entry in files.entries) {
      if (other.files[entry.key] != entry.value) return false;
    }
    return true;
  }

  static List<DocFolder> _foldersOf(Object? raw) {
    if (raw is! List) return [];
    final builtIn = {for (final b in BuiltInFolder.values) b.name};
    final seen = <String>{};
    final folders = <DocFolder>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final id = item['id'];
      final name = item['name'];
      if (id is! String || name is! String || name.trim().isEmpty) continue;
      // Built-in folders are on every phone already.
      if (id.isEmpty || builtIn.contains(id) || !seen.add(id)) continue;
      folders.add(DocFolder(id: id, name: name.trim()));
    }
    return folders;
  }

  static Map<String, String> _filesOf(Object? raw) {
    final files = <String, String>{};
    if (raw is! Map) return files;
    for (final entry in raw.entries) {
      final md5 = entry.key;
      final folder = entry.value;
      if (md5 is String && folder is String) files[md5] = folder;
    }
    return files;
  }
}

/// The folder side of one sync: what comes back to this phone from the
/// backup on Drive, and the backup to leave there afterwards.
class FolderSync {
  const FolderSync({
    this.create = const [],
    this.assign = const {},
    this.byMd5 = const {},
    this.backup,
    this.backupId,
  });

  /// Backup folders this phone doesn't have, empty ones too.
  final List<DocFolder> create;

  /// Files on this phone that were never put in a folder but are in one
  /// in the backup: folder id by file id.
  final Map<String, String> assign;

  /// Folder id on this phone by md5, for the files the backup has in a
  /// folder. Files that come down from Drive are put in folders by this.
  final Map<String, String> byMd5;

  /// The backup to save to Drive, or null when Drive has it already.
  final FolderBackup? backup;

  /// The backup file on Drive, which is updated in place. Null means
  /// there is none yet.
  final String? backupId;

  /// Whether this phone gets folders, or files put in folders, back.
  bool get restores => create.isNotEmpty || assign.isNotEmpty;

  bool get isEmpty => !restores && backup == null;

  /// Works out the folder side of a sync without writing anything.
  ///
  /// [onDrive] is the backup found on Drive, null if there is none.
  /// [localMd5] is md5 by file id for the files on this phone, and
  /// [driveMd5] holds the md5s of the documents on Drive.
  ///
  /// What the user set on this phone always wins: its folders keep their
  /// names, a backup folder with the same name as one here joins it, and
  /// a file already in a folder stays there. Folders deleted on this phone
  /// don't come back.
  factory FolderSync.plan({
    required FolderBackup? onDrive,
    required DocLibrary library,
    required Map<String, String> localMd5,
    required Set<String> driveMd5,
    String? onDriveId,
  }) {
    final backup = onDrive ?? const FolderBackup();

    // Backup folder id to the folder here that takes its files.
    final ids = {for (final f in library.folders) f.id: f.id};
    final byName = {
      for (final f in library.folders) f.name.toLowerCase(): f.id,
    };
    final create = <DocFolder>[];
    for (final folder in backup.folders) {
      if (ids.containsKey(folder.id) || library.deleted.contains(folder.id)) {
        continue;
      }
      final name = folder.name.toLowerCase();
      final same = byName[name];
      if (same != null) {
        ids[folder.id] = same;
      } else {
        create.add(folder);
        ids[folder.id] = folder.id;
        byName[name] = folder.id;
      }
    }

    final byMd5 = <String, String>{};
    for (final entry in backup.files.entries) {
      final id = ids[entry.value];
      if (id != null) byMd5[entry.key] = id;
    }

    final assign = <String, String>{};
    for (final entry in localMd5.entries) {
      final current = library.filed[entry.key];
      if (current != null && library.byId(current) != null) continue;
      final id = byMd5[entry.value];
      if (id != null) assign[entry.key] = id;
    }

    // The backup to leave on Drive: this phone's folders and files, plus
    // what the old backup knows about documents on Drive that aren't here.
    final folders = [...library.custom, ...create];
    final kept = {
      for (final b in BuiltInFolder.values) b.name,
      for (final f in folders) f.id,
    };
    final files = <String, String>{
      for (final entry in byMd5.entries)
        if (driveMd5.contains(entry.key)) entry.key: entry.value,
    };
    for (final entry in localMd5.entries) {
      final id = assign[entry.key] ?? library.filed[entry.key];
      if (id != null && kept.contains(id)) files[entry.value] = id;
    }
    final next = FolderBackup(folders: folders, files: files);
    final write = onDrive == null ? !next.isEmpty : !next.sameAs(onDrive);

    return FolderSync(
      create: create,
      assign: assign,
      byMd5: byMd5,
      backup: write ? next : null,
      backupId: onDriveId,
    );
  }
}
