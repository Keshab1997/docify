import 'doc_meta.dart';
import 'saved_doc.dart';

enum DocFilter { all, pdf, images, starred }
enum DocSort { newest, oldest, name, size }

class DocQuery {
  const DocQuery({this.text = '', this.filter = DocFilter.all, this.tag});

  final String text;
  final DocFilter filter;
  final String? tag;

  bool matches(SavedDoc doc, DocMeta meta, String folder) {
    if (filter == DocFilter.pdf && !doc.isPdf) return false;
    if (filter == DocFilter.images && !doc.isImage) return false;
    if (filter == DocFilter.starred && !meta.starred) return false;
    if (tag != null && !meta.tags.contains(tag)) return false;
    final haystack = [doc.name, folder, ...meta.tags, meta.ocrText ?? '']
        .join(' ').toLowerCase();
    return text.trim().toLowerCase().split(RegExp(r'\s+')).every(haystack.contains);
  }
}

List<SavedDoc> sortDocuments(Iterable<SavedDoc> files, DocSort sort) {
  final result = files.toList();
  result.sort((a, b) {
    final order = switch (sort) {
      DocSort.newest => b.modified.compareTo(a.modified),
      DocSort.oldest => a.modified.compareTo(b.modified),
      DocSort.name => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      DocSort.size => b.size.compareTo(a.size),
    };
    return order == 0 ? a.id.compareTo(b.id) : order;
  });
  return result;
}

List<SavedDoc> recentDocuments(
  Iterable<SavedDoc> files, Map<String, DocMeta> index, {int limit = 4}
) {
  final recent = files.where((doc) =>
      !(index[doc.id]?.inTrash ?? false) && index[doc.id]?.openedAt != null).toList();
  recent.sort((a, b) => index[b.id]!.openedAt!.compareTo(index[a.id]!.openedAt!));
  return recent.take(limit).toList();
}
