import '../models/saved_doc.dart';
import 'doc_deletions.dart';
import 'doc_folders.dart';
import 'doc_store.dart';

class DocActions {
  DocActions._();

  static Future<void> deleteFromDevice(SavedDoc doc) async {
    final digest = await documentDigest(await DocStore.read(doc));
    // Persist first: a concurrent or later Drive run must not resurrect the file.
    await DocDeletions.record(name: doc.name, digest: digest);
    await DocStore.delete(doc);
    await DocFolders.forget(doc.id);
  }
}
