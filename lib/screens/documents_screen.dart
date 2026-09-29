import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/saved_doc.dart';
import '../services/doc_store.dart';
import '../services/share_bytes.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/pdf_preview_page.dart';
import '../widgets/sync_sheet.dart';

enum _Filter { all, photos, pdfs }

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
  bool _loading = true;
  _Filter _filter = _Filter.all;
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
    if (!mounted) return;
    _thumbs.clear();
    setState(() {
      _files = files;
      _loading = false;
    });
  }

  List<SavedDoc> get _shown {
    final list = switch (_filter) {
      _Filter.all => [..._files],
      _Filter.photos => _files.where((f) => f.isImage).toList(),
      _Filter.pdfs => _files.where((f) => f.isPdf).toList(),
    };
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
    await DocStore.rename(doc, next);
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.sm),
            child: Wrap(
              spacing: Space.sm,
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _filter == _Filter.all,
                  onSelected: (_) => setState(() => _filter = _Filter.all),
                ),
                ChoiceChip(
                  label: const Text('Photos'),
                  selected: _filter == _Filter.photos,
                  onSelected: (_) => setState(() => _filter = _Filter.photos),
                ),
                ChoiceChip(
                  label: const Text('PDFs'),
                  selected: _filter == _Filter.pdfs,
                  onSelected: (_) => setState(() => _filter = _Filter.pdfs),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _shown.isEmpty
                    ? EmptyState(
                        image: 'assets/images/deco_folder.png',
                        title: 'Nothing saved yet',
                        message:
                            'Photos, signatures and PDFs you create will show up here.',
                        ctaLabel: widget.onBrowseTools == null
                            ? null
                            : 'Browse tools',
                        onCta: widget.onBrowseTools,
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            Space.lg,
                            4,
                            Space.lg,
                            20,
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
                                    '${dateLabel(f.modified)}  ·  '
                                    '${kbLabel(f.size)}',
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
