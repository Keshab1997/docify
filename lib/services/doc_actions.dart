import '../models/doc_meta.dart';
import '../models/saved_doc.dart';
import 'doc_deletions.dart';
import 'doc_folders.dart';
import 'doc_index.dart';
import 'doc_store.dart';

class DocActions {
  DocActions._();

  static const retention = Duration(days: 30);

  static Future<void> deleteFromDevice(SavedDoc doc) async {
    final digest = await documentDigest(await DocStore.read(doc));
    await DocDeletions.record(name: doc.name, digest: digest);
    await DocStore.delete(doc);
    await DocFolders.forget(doc.id);
    await DocIndex.forget(doc.id);
  }

  static Future<void> trash(SavedDoc doc) async {
    final digest = await documentDigest(await DocStore.read(doc));
    await DocDeletions.record(name: doc.name, digest: digest);
    await DocIndex.update(
        doc.id,
        (meta) => meta.copyWith(
              trashedAt: DateTime.now().millisecondsSinceEpoch,
              digest: digest,
              backupPending: false,
            ));
  }

  static Future<void> restore(SavedDoc doc) async {
    final meta = (await DocIndex.load())[doc.id] ?? const DocMeta();
    final digest =
        meta.digest ?? await documentDigest(await DocStore.read(doc));
    // Make it active before clearing its tombstone so a sync sees the existing
    // local copy, never a transient missing file that needs to be downloaded.
    await DocIndex.update(doc.id, (current) => current.copyWith(restore: true));
    await DocDeletions.allow(name: doc.name, digest: digest);
  }

  static Future<void> permanentlyDelete(SavedDoc doc) async {
    final meta = (await DocIndex.load())[doc.id] ?? const DocMeta();
    if (!meta.inTrash) throw StateError('Move this document to Trash first');
    final digest =
        meta.digest ?? await documentDigest(await DocStore.read(doc));
    await DocDeletions.record(name: doc.name, digest: digest);
    await DocStore.delete(doc);
    await DocFolders.forget(doc.id);
    await DocIndex.forget(doc.id);
  }

  static bool expired(DocMeta meta, DateTime now) =>
      meta.trashedAt != null &&
      now.difference(DateTime.fromMillisecondsSinceEpoch(meta.trashedAt!)) >=
          retention;

  static Future<void> purgeExpired() async {
    final index = await DocIndex.load();
    final now = DateTime.now();
    for (final doc in await DocStore.list(includeTrash: true)) {
      if (!expired(index[doc.id] ?? const DocMeta(), now)) continue;
      try {
        await permanentlyDelete(doc);
      } catch (_) {
        // Keep a recoverable copy when storage is unavailable; retry next visit.
      }
    }
  }
}
