import 'dart:convert';
import 'dart:typed_data';

import '../models/import_file.dart';
import '../models/saved_doc.dart';
import 'doc_deletions.dart';
import 'doc_folders.dart';
import 'doc_index.dart';
import 'doc_store.dart';

enum DuplicateChoice { skip, keepBoth }

class ImportFailure {
  const ImportFailure(this.source, this.reason, {this.retryable = true});
  final bool retryable;
  final ImportFile source;
  final String reason;
}

class ImportOutcome {
  const ImportOutcome({required this.saved, required this.skipped, required this.failed});
  final List<SavedDoc> saved;
  final int skipped;
  final List<ImportFailure> failed;
}

abstract class DocumentImportStore {
  const DocumentImportStore();
  Future<List<SavedDoc>> list();
  Future<Uint8List> read(SavedDoc doc);
  Future<SavedDoc> save(Uint8List bytes, String name);
}

class _DeviceImportStore extends DocumentImportStore {
  const _DeviceImportStore();
  @override
  Future<List<SavedDoc>> list() => DocStore.list();
  @override
  Future<Uint8List> read(SavedDoc doc) => DocStore.read(doc);
  @override
  Future<SavedDoc> save(Uint8List bytes, String name) => DocStore.save(bytes: bytes, name: name);
}

/// Sequential, bounded, partial-success imports. Duplicate detection is local;
/// no bytes, checksums or names are sent to any server by this service.
class DocImport {
  DocImport._();
  static const maxBytes = 30 * 1024 * 1024;
  static const maxFiles = 50;

  static String? format(Uint8List bytes) {
    if (bytes.length >= 5 && latin1.decode(bytes.sublist(0, bytes.length.clamp(0, 1024).toInt())).contains('%PDF-')) { return 'pdf'; }
    if (bytes.length >= 8 && bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4e && bytes[3] == 0x47) { return 'png'; }
    if (bytes.length >= 3 && bytes[0] == 0xff && bytes[1] == 0xd8 && bytes[2] == 0xff) { return 'jpg'; }
    if (bytes.length >= 12 && latin1.decode(bytes.sublist(0, 4)) == 'RIFF' && latin1.decode(bytes.sublist(8, 12)) == 'WEBP') { return 'webp'; }
    return null;
  }

  static Future<ImportOutcome> run({
    required List<ImportFile> files,
    required DocFolder folder,
    String? singleName,
    required Future<DuplicateChoice> Function(ImportFile incoming, SavedDoc existing) onDuplicate,
    required void Function(int done, int total, String label) onProgress,
    DocumentImportStore store = const _DeviceImportStore(),
  }) async {
    final saved = <SavedDoc>[];
    final failed = <ImportFailure>[];
    var skipped = 0;
    final known = <String, SavedDoc>{};
    final index = await DocIndex.load();
    for (final doc in await store.list()) {
      try {
        final digest = index[doc.id]?.digest ?? await documentDigest(await store.read(doc));
        known[digest] = doc;
        if (index[doc.id]?.digest == null) {
          await DocIndex.update(doc.id, (meta) => meta.copyWith(digest: digest));
        }
      } catch (_) {
        // An unreadable old file should not prevent adding an intact new one.
      }
    }
    for (var i = 0; i < files.length; i++) {
      final source = files[i];
      onProgress(i, files.length, source.name);
      try {
        if (i >= maxFiles) { throw const FormatException('Add at most 50 files at a time.'); }
        if ((source.size ?? 0) > maxBytes) { throw const FormatException('This file exceeds the 30 MB import limit.'); }
        final bytes = await source.read();
        if (bytes.isEmpty) { throw const FormatException('This file is empty or could not be read.'); }
        if (bytes.length > maxBytes) { throw const FormatException('This file exceeds the 30 MB import limit.'); }
        final extension = format(bytes);
        if (extension == null) { throw const FormatException('Use an intact PDF, JPG, PNG or WebP file.'); }
        final digest = await documentDigest(bytes);
        final duplicate = known[digest];
        if (duplicate != null && await onDuplicate(source, duplicate) == DuplicateChoice.skip) {
          skipped++;
          continue;
        }
        var name = source.name;
        final actual = mimeFromName(name);
        final expected = mimeFromName('file.$extension');
        if (actual != expected) { name = '${nameStem(name)}.$extension'; }
        if (files.length == 1 && singleName != null) { name = renameKeepingExtension(name, singleName); }
        final doc = await store.save(bytes, name);
        saved.add(doc);
        known[digest] = doc;
        try {
          await DocIndex.update(doc.id, (meta) => meta.copyWith(digest: digest));
          await DocFolders.file([doc.id], folder);
          await DocDeletions.allow(name: doc.name, digest: digest);
        } catch (_) {
          // Bytes are already safely saved; do not retry and create another copy.
          failed.add(ImportFailure(source, 'Saved ${doc.name}, but could not finish filing it. Move it manually.', retryable: false));
        }
      } on FormatException catch (error) {
        failed.add(ImportFailure(source, error.message));
      } catch (_) {
        failed.add(ImportFailure(source, 'Could not read or save this file. Try again.'));
      } finally {
        onProgress(i + 1, files.length, source.name);
      }
    }
    return ImportOutcome(saved: saved, skipped: skipped, failed: failed);
  }
}
