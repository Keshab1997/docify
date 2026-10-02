import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../../models/saved_doc.dart';
import '../doc_folders.dart';
import '../doc_deletions.dart';
import '../doc_store.dart';
import 'drive_api.dart';
import 'folder_backup.dart';

// NOTE: sync state types live here; sync_sheet only renders them.

/// One local document scheduled for upload, with its final Drive name
/// (uniquified when a different file already holds that name).
class UploadAction {
  const UploadAction({required this.doc, required this.targetName});

  final SavedDoc doc;
  final String targetName;
}

/// What a sync run will do, computed before anything moves so the user can
/// confirm with real numbers (count + MB) first.
class SyncPlan {
  const SyncPlan({
    required this.folderId,
    required this.uploads,
    required this.downloads,
    required this.uploadBytes,
    this.folders = const FolderSync(),
  });

  final String folderId;
  final List<UploadAction> uploads;
  final List<DriveFile> downloads;
  final int uploadBytes;

  /// Folders to bring back, and the folder backup to save.
  final FolderSync folders;

  int get total => uploads.length + downloads.length;
  int get downloadBytes => downloads.fold(0, (sum, f) => sum + f.size);
  bool get isEmpty => total == 0 && folders.isEmpty;
}

/// Result of a completed run. `failed` files simply stay as they were.
class SyncOutcome {
  const SyncOutcome({
    required this.uploaded,
    required this.downloaded,
    required this.failed,
    this.folders = 0,
    this.refiled = 0,
  });

  final int uploaded;
  final int downloaded;
  final int failed;

  /// Folders brought back from the backup.
  final int folders;

  /// Files put back in their folders.
  final int refiled;

  bool get changed => downloaded > 0 || folders > 0 || refiled > 0;
}

/// The documents on this phone as sync sees them: [DocStore] in the app,
/// and an in-memory store in tests, which have no device storage.
abstract class LocalDocs {
  const LocalDocs();

  Future<List<SavedDoc>> list();

  Future<Uint8List> read(SavedDoc doc);

  Future<SavedDoc> save({
    required Uint8List bytes,
    required String name,
    String? mime,
  });
}

class _DeviceDocs extends LocalDocs {
  const _DeviceDocs();

  @override
  Future<List<SavedDoc>> list() => DocStore.list();

  @override
  Future<Uint8List> read(SavedDoc doc) => DocStore.read(doc);

  @override
  Future<SavedDoc> save({
    required Uint8List bytes,
    required String name,
    String? mime,
  }) {
    return DocStore.save(bytes: bytes, name: name, mime: mime);
  }
}

/// Two-way, idempotent reconcile between the app's local documents and the
/// `Docify/` folder in the user's own Google Drive.
///
/// Rules for documents (the Drive listing is their only source of truth):
///  * upload when the local file's content (md5) is not on Drive yet;
///  * a name that exists on Drive with *different* content is never
///    overwritten — the local file uploads as `name (2).ext` instead;
///  * download when Drive has a file that is neither in the local name set
///    nor already present locally under another name (same md5);
///  * anything present locally under its own name is "already synced" —
///    local wins, nothing is replaced;
///  * deletions are local-only by design: removing a document from the app
///    never deletes the user's Drive copy.
///
/// Running the same plan twice is a no-op: uploaded content lands on Drive
/// with an md5 the second pass recognizes, downloaded content lands locally
/// with a name the second pass skips. Duplicate-free, overwrite-free.
///
/// Folders ride along in one small backup file next to the documents (see
/// [FolderBackup]), saved after the files, so a new phone gets its folders
/// back and every restored file lands in the folder it was in.
class DriveSync {
  DriveSync._();

  /// Where sync finds the documents on this phone.
  @visibleForTesting
  static LocalDocs docs = const _DeviceDocs();

  static String md5Hex(Uint8List bytes) => md5.convert(bytes).toString();

  /// Reads local files + Drive listing and returns the actions to confirm.
  /// Only reads — nothing is written or removed.
  static Future<SyncPlan> plan(DriveApi api) async {
    final folderId = await api.ensureFolder();
    final listed = await api.listFiles(folderId);
    final locals = await docs.list();

    // The folder backup sits with the documents but isn't one of them.
    DriveFile? backupFile;
    final driveFiles = <DriveFile>[];
    for (final f in listed) {
      if (f.name == FolderBackup.fileName) {
        backupFile ??= f;
      } else {
        driveFiles.add(f);
      }
    }

    final driveByName = <String, DriveFile>{
      for (final f in driveFiles) f.name: f,
    };
    final driveMd5 = <String>{
      for (final f in driveFiles)
        if (f.md5 != null && f.md5!.isNotEmpty) f.md5!,
    };

    // A document never takes the backup's name.
    final takenNames = <String>{
      FolderBackup.fileName,
      for (final f in driveFiles) f.name,
    };
    final localNames = <String>{};
    final localMd5 = <String>{};
    final md5ById = <String, String>{};

    final uploads = <UploadAction>[];
    var uploadBytes = 0;

    for (final doc in locals) {
      localNames.add(doc.name);
      final bytes = await docs.read(doc);
      final digest = md5Hex(bytes);
      localMd5.add(digest);
      md5ById[doc.id] = digest;

      final onDrive = driveByName[doc.name];
      if (onDrive != null && onDrive.md5 == digest) continue; // identical
      if (driveMd5.contains(digest)) continue; // same content, other name
      final target = _uniqueName(doc.name, takenNames);
      takenNames.add(target);
      uploads.add(UploadAction(doc: doc, targetName: target));
      uploadBytes += bytes.length;
    }

    final deleted = await DocDeletions.load();
    final downloads = <DriveFile>[
      for (final f in driveFiles)
        if (!deleted.contains(f.name, f.md5) &&
            !localNames.contains(f.name) &&
            !(f.md5 != null && localMd5.contains(f.md5!)))
          f,
    ];

    final folders = FolderSync.plan(
      onDrive: await _readBackup(api, backupFile),
      onDriveId: backupFile?.id,
      library: await DocFolders.load(),
      localMd5: md5ById,
      driveMd5: driveMd5,
    );

    return SyncPlan(
      folderId: folderId,
      uploads: uploads,
      downloads: downloads,
      uploadBytes: uploadBytes,
      folders: folders,
    );
  }

  /// Executes a confirmed plan. Progress reports each finished item; a
  /// single failure never aborts the rest — failures are counted and shown.
  static Future<SyncOutcome> run(
    DriveApi api,
    SyncPlan plan, {
    required void Function(int done, int total, String label) onProgress,
  }) async {
    var uploaded = 0;
    var downloaded = 0;
    var failed = 0;
    var done = 0;
    final total = plan.total;

    for (final action in plan.uploads) {
      try {
        final bytes = await docs.read(action.doc);
        await api.uploadFile(
          folderId: plan.folderId,
          name: action.targetName,
          bytes: bytes,
          mime: action.doc.mime,
        );
        uploaded++;
      } catch (_) {
        failed++;
      }
      done++;
      onProgress(done, total, action.targetName);
    }

    // Folder id by the name each downloaded file got on this phone.
    final filed = <String, String>{};
    for (final file in plan.downloads) {
      try {
        // A deletion can happen after the plan was confirmed (or during an
        // automatic run), so recheck just before writing restored bytes.
        final deleted = await DocDeletions.load();
        if (deleted.contains(file.name, file.md5)) {
          done++;
          onProgress(done, total, file.name);
          continue;
        }
        final bytes = await api.download(file.id);
        final current = await DocDeletions.load();
        if (current.contains(file.name, file.md5 ?? md5Hex(bytes))) {
          done++;
          onProgress(done, total, file.name);
          continue;
        }
        final saved = await docs.save(
          bytes: bytes,
          name: file.name,
          mime: mimeFromName(file.name),
        );
        downloaded++;
        final folder = plan.folders.byMd5[file.md5 ?? md5Hex(bytes)];
        if (folder != null) filed[saved.id] = folder;
      } catch (_) {
        failed++;
      }
      done++;
      onProgress(done, total, file.name);
    }

    final restore = plan.folders;
    final files = {...restore.assign, ...filed};
    var folders = 0;
    var refiled = 0;
    if (restore.create.isNotEmpty || files.isNotEmpty) {
      try {
        await DocFolders.restore(folders: restore.create, files: files);
        folders = restore.create.length;
        refiled = files.length;
      } catch (_) {
        failed++;
      }
    }

    // After the files: if the sync stops halfway, the old backup stays
    // and the next sync does this again.
    final backup = restore.backup;
    if (backup != null) {
      try {
        await _saveBackup(api, plan, backup);
      } catch (_) {
        failed++;
      }
    }

    return SyncOutcome(
      uploaded: uploaded,
      downloaded: downloaded,
      failed: failed,
      folders: folders,
      refiled: refiled,
    );
  }

  /// The folder backup on Drive, or null when there is none yet.
  static Future<FolderBackup?> _readBackup(DriveApi api, DriveFile? f) async {
    if (f == null) return null;
    return FolderBackup.parse(await api.download(f.id));
  }

  /// Saves [backup] as a new file the first time, then updates that file,
  /// so Drive keeps a single copy.
  static Future<void> _saveBackup(
    DriveApi api,
    SyncPlan plan,
    FolderBackup backup,
  ) {
    final id = plan.folders.backupId;
    final bytes = backup.toBytes();
    if (id != null) {
      return api.updateFile(fileId: id, bytes: bytes, mime: FolderBackup.mime);
    }
    return api.uploadFile(
      folderId: plan.folderId,
      name: FolderBackup.fileName,
      bytes: bytes,
      mime: FolderBackup.mime,
    );
  }

  /// `photo.jpg` → `photo (2).jpg` when Drive already holds a different
  /// `photo.jpg`; falls through to a fresh suffix if that is taken too.
  static String _uniqueName(String name, Set<String> taken) {
    if (!taken.contains(name)) return name;
    final dot = name.lastIndexOf('.');
    final hasExt = dot > 0;
    final stem = hasExt ? name.substring(0, dot) : name;
    final ext = hasExt ? name.substring(dot) : '';
    var i = 2;
    while (taken.contains('$stem ($i)$ext')) {
      i++;
    }
    return '$stem ($i)$ext';
  }
}
