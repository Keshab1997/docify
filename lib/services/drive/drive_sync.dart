import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../doc_store.dart';
import '../models/saved_doc.dart';
import 'drive_api.dart';

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
  });

  final String folderId;
  final List<UploadAction> uploads;
  final List<DriveFile> downloads;
  final int uploadBytes;

  int get total => uploads.length + downloads.length;
  int get downloadBytes => downloads.fold(0, (sum, f) => sum + f.size);
  bool get isEmpty => total == 0;
}

/// Result of a completed run. `failed` files simply stay as they were.
class SyncOutcome {
  const SyncOutcome({
    required this.uploaded,
    required this.downloaded,
    required this.failed,
  });

  final int uploaded;
  final int downloaded;
  final int failed;

  bool get changed => downloaded > 0;
}

/// Two-way, idempotent reconcile between the app's local documents and the
/// `Docify/` folder in the user's own Google Drive.
///
/// Rules (the Drive listing is the only source of truth — no manifest):
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
class DriveSync {
  DriveSync._();

  static String md5Hex(Uint8List bytes) => md5.convert(bytes).toString();

  /// Reads local files + Drive listing and returns the actions to confirm.
  /// Only reads — nothing is written or removed.
  static Future<SyncPlan> plan(DriveApi api) async {
    final folderId = await api.ensureFolder();
    final driveFiles = await api.listFiles(folderId);
    final locals = await DocStore.list();

    final driveByName = <String, DriveFile>{
      for (final f in driveFiles) f.name: f,
    };
    final driveMd5 = <String>{
      for (final f in driveFiles)
        if (f.md5 != null && f.md5!.isNotEmpty) f.md5!,
    };

    final takenNames = <String>{for (final f in driveFiles) f.name};
    final localNames = <String>{};
    final localMd5 = <String>{};

    final uploads = <UploadAction>[];
    var uploadBytes = 0;

    for (final doc in locals) {
      localNames.add(doc.name);
      final bytes = await DocStore.read(doc);
      final digest = md5Hex(bytes);
      localMd5.add(digest);

      final onDrive = driveByName[doc.name];
      if (onDrive != null && onDrive.md5 == digest) continue; // identical
      if (driveMd5.contains(digest)) continue; // same content, other name
      final target = _uniqueName(doc.name, takenNames);
      takenNames.add(target);
      uploads.add(UploadAction(doc: doc, targetName: target));
      uploadBytes += bytes.length;
    }

    final downloads = <DriveFile>[
      for (final f in driveFiles)
        if (!localNames.contains(f.name) &&
            !(f.md5 != null && localMd5.contains(f.md5!)))
          f,
    ];

    return SyncPlan(
      folderId: folderId,
      uploads: uploads,
      downloads: downloads,
      uploadBytes: uploadBytes,
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
        final bytes = await DocStore.read(action.doc);
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

    for (final file in plan.downloads) {
      try {
        final bytes = await api.download(file.id);
        await DocStore.save(
          bytes: bytes,
          name: file.name,
          mime: mimeFromName(file.name),
        );
        downloaded++;
      } catch (_) {
        failed++;
      }
      done++;
      onProgress(done, total, file.name);
    }

    return SyncOutcome(
      uploaded: uploaded,
      downloaded: downloaded,
      failed: failed,
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
