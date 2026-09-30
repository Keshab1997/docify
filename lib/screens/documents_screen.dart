import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/saved_doc.dart';
import '../services/doc_categories.dart';
import '../services/doc_store.dart';
import '../services/pick_bytes.dart';
import '../services/share_bytes.dart';
import '../theme/app_theme.dart';
import '../widgets/doc_upload_sheet.dart';
import '../widgets/empty_state.dart';
import '../widgets/pdf_preview_page.dart';
import '../widgets/sync_sheet.dart';

enum _Sort { newest, oldest, name, size }

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key, this.onBrowseTools});

  /// Empty-state button; wired to the Tools tab by the shell.
  final VoidCallback? onBrowseTools;

  @override
  State<DocumentsScreen> createState() => DocumentsScreenState();
}

class DocumentsScreenState extends State<DocumentsScreen> {
  List<SavedDoc> _files = [];
  Map<String, DocCategory> _filed = {};
  bool _loading = true;

  /// The category being shown; null shows every file.
  DocCategory? _shelf;
  _Sort _sort = _Sort.newest;

  /// One read per file, reused across rebuilds; cleared on reload.
  final _thumbs = <String, Future<Uint8List?>>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> reload() => _load();

  Future<void> _load() async {
    final files = await DocStore.list();
    final filed = await DocCategories.load();
    if (!mounted) return;
    _thumbs.clear();
    setState(() {
      _files = files;
      _filed = filed;
      _loading = false;
    });
  }

  DocCategory _categoryOf(SavedDoc doc) => DocCategories.of(doc, _filed);

  List<SavedDoc> get _shown {
    final shelf = _shelf;
    final list = shelf == null
        ? [..._files]
        : _files.where((f) => _categoryOf(f) == shelf).toList();
    switch (_sort) {
      case _Sort.newest:
        list.sort((a, b) => b.modified.compareTo(a.modified));
      case _Sort.oldest:
        list.sort((a, b) => a.modified.compareTo(b.modified));
      case _Sort.name:
        list.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
      case _Sort.size:
        list.sort((a, b) => b.size.compareTo(a.size));
    }
    return list;
  }

  Future<void> _open(SavedDoc doc) async {
    final bytes = await DocStore.read(doc);
    if (!mounted) return;
    if (doc.isPdf) {
      await PdfPreviewPage.open(context, bytes: bytes, name: doc.name);
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ImagePreviewPage(name: doc.name, bytes: bytes),
      ),
    );
  }

  Future<void> _share(SavedDoc doc) async {
    final bytes = await DocStore.read(doc);
    await ShareBytes.share(bytes: bytes, name: doc.name, mime: doc.mime);
  }

  Future<void> _delete(SavedDoc doc) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.sheet),
        ),
        title: const Text('Delete file?'),
        content: Text(doc.name, style: AppText.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            // Red, because this is the one button here that destroys data.
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await DocStore.delete(doc);
    await DocCategories.forget(doc.id);
    await _load();
  }

  Future<void> _rename(SavedDoc doc) async {
    final ctrl = TextEditingController(text: doc.name);
    final next = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.sheet),
        ),
        title: const Text('Rename'),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (next == null || next.isEmpty || next == doc.name) return;
    final renamed = await DocStore.rename(doc, next);
    await DocCategories.move(doc.id, renamed.id);
    await _load();
  }

  /// Adds files from the phone, the gallery or the camera to a category, so
  /// application forms, certificates and ID proofs live here next to what
  /// the tools made.
  Future<void> _upload() async {
    final source = await showUploadSourceSheet(context);
    if (source == null) return;
    final picked = switch (source) {
      UploadSource.files => await PickBytes.documents(),
      UploadSource.gallery => await PickBytes.photos(ImageSource.gallery),
      UploadSource.camera => await PickBytes.photos(ImageSource.camera),
    };
    if (picked.isEmpty) return;
    if (!mounted) return;
    final single = picked.length == 1 ? picked.single : null;
    final filing = await showDocCategorySheet(
      context,
      title: single == null ? 'Save ${picked.length} files' : 'Save file',
      initial: _shelf,
      name: single == null ? null : nameStem(single.name),
    );
    if (filing == null) return;
    final ids = <String>[];
    for (final file in picked) {
      final doc = await DocStore.save(
        bytes: file.bytes,
        name: single == null
            ? file.name
            : renameKeepingExtension(file.name, filing.name),
      );
      ids.add(doc.id);
    }
    await DocCategories.file(ids, filing.category);
    if (!mounted) return;
    // Show where the files went.
    setState(() => _shelf = filing.category);
    await _load();
    if (!mounted) return;
    final where = filing.category.label;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ids.length == 1
              ? 'Saved to $where'
              : 'Saved ${ids.length} files to $where',
        ),
      ),
    );
  }

  Future<void> _move(SavedDoc doc) async {
    final filing = await showDocCategorySheet(
      context,
      title: 'Change category',
      initial: _categoryOf(doc),
    );
    if (filing == null) return;
    await DocCategories.file([doc.id], filing.category);
    await _load();
  }

  Future<Uint8List?> _thumbBytes(SavedDoc doc) =>
      _thumbs.putIfAbsent(doc.id, () async {
        try {
          return await DocStore.read(doc);
        } catch (_) {
          return null; // File vanished between list and read.
        }
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My documents'),
        actions: [
          IconButton(
            tooltip: 'Sync with Drive',
            icon: const Icon(Icons.cloud_sync_rounded),
            onPressed: () async {
              final changed = await showSyncSheet(context);
              if (changed && mounted) await _load();
            },
          ),
          PopupMenuButton<_Sort>(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sort',
            initialValue: _sort,
            onSelected: (s) => setState(() => _sort = s),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.card),
            ),
            itemBuilder: (_) => const [
              PopupMenuItem(value: _Sort.newest, child: Text('Newest first')),
              PopupMenuItem(value: _Sort.oldest, child: Text('Oldest first')),
              PopupMenuItem(value: _Sort.name, child: Text('Name A-Z')),
              PopupMenuItem(value: _Sort.size, child: Text('Largest first')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _upload,
        icon: const Icon(Icons.upload_file_rounded),
        label: const Text('Upload'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: Space.sm),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Space.lg),
              child: Row(
                children: [
                  _shelfChip(null, 'All'),
                  for (final shelf in DocCategory.values)
                    _shelfChip(shelf, shelf.label),
                ],
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _shown.isEmpty
                    ? _empty()
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            Space.lg,
                            4,
                            Space.lg,
                            // Keeps the last file clear of the Upload button.
                            96,
                          ),
                          itemCount: _shown.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: Space.md),
                          itemBuilder: (ctx, i) {
                            final f = _shown[i];
                            return DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(Radii.card),
                                boxShadow: Soft.card,
                              ),
                              child: Material(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(Radii.card),
                                child: ListTile(
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(Radii.card),
                                  ),
                                  onTap: () => _open(f),
                                  leading: _leading(f),
                                  title: Text(
                                    f.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: Text(
                                    [
                                      if (_shelf == null) _categoryOf(f).label,
                                      dateLabel(f.modified),
                                      kbLabel(f.size),
                                    ].join('  ·  '),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.mutedText,
                                    ),
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (v) {
                                      switch (v) {
                                        case 'open':
                                          _open(f);
                                        case 'share':
                                          _share(f);
                                        case 'rename':
                                          _rename(f);
                                        case 'move':
                                          _move(f);
                                        case 'delete':
                                          _delete(f);
                                      }
                                    },
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(
                                        value: 'open',
                                        child: Text('Open'),
                                      ),
                                      PopupMenuItem(
                                        value: 'share',
                                        child: Text('Share'),
                                      ),
                                      PopupMenuItem(
                                        value: 'rename',
                                        child: Text('Rename'),
                                      ),
                                      PopupMenuItem(
                                        value: 'move',
                                        child: Text('Change category'),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Delete'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _shelfChip(DocCategory? shelf, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: Space.sm),
      child: ChoiceChip(
        label: Text(label),
        selected: _shelf == shelf,
        onSelected: (_) => setState(() => _shelf = shelf),
      ),
    );
  }

  Widget _empty() {
    final shelf = _shelf;
    if (_files.isNotEmpty && shelf != null) {
      return EmptyState(
        icon: shelf.icon,
        title: 'Nothing in ${shelf.label} yet',
        message: '${shelf.examples}. Tap Upload to add them.',
      );
    }
    return EmptyState(
      image: 'assets/images/deco_folder.png',
      title: 'Nothing saved yet',
      message: 'Upload your job forms and documents, or make photos, '
          'signatures and PDFs with the tools.',
      ctaLabel: widget.onBrowseTools == null ? null : 'Browse tools',
      onCta: widget.onBrowseTools,
    );
  }

  /// Photos show a real thumbnail; PDFs keep the red badge.
  Widget _leading(SavedDoc f) {
    final decoration = BoxDecoration(
      color: f.isPdf ? AppColors.pdfTint : AppColors.photoResizeCard,
      borderRadius: BorderRadius.circular(Radii.chip),
    );
    if (!f.isImage) {
      return Container(
        width: 44,
        height: 44,
        decoration: decoration,
        child: Icon(
          f.isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
          color: f.isPdf ? AppColors.pdfBadge : AppColors.primaryButton,
        ),
      );
    }
    return Container(
      width: 44,
      height: 44,
      decoration: decoration,
      clipBehavior: Clip.antiAlias,
      child: FutureBuilder<Uint8List?>(
        future: _thumbBytes(f),
        builder: (context, snap) {
          final bytes = snap.data;
          if (bytes == null) {
            return const Icon(
              Icons.image_rounded,
              color: AppColors.primaryButton,
            );
          }
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            cacheWidth: 160,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.image_rounded, color: AppColors.primaryButton),
          );
        },
      ),
    );
  }
}

class _ImagePreviewPage extends StatelessWidget {
  const _ImagePreviewPage({required this.name, required this.bytes});
  final String name;
  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(name, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () => ShareBytes.share(
              bytes: bytes,
              name: name,
              mime: mimeFromName(name),
            ),
          ),
        ],
      ),
      body: InteractiveViewer(child: Center(child: Image.memory(bytes))),
    );
  }
}
