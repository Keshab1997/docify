import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/saved_doc.dart';
import '../services/doc_store.dart';
import '../services/share_bytes.dart';
import '../theme/app_theme.dart';
import '../widgets/pdf_preview_page.dart';

enum _Filter { all, photos, pdfs }

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => DocumentsScreenState();
}

class DocumentsScreenState extends State<DocumentsScreen> {
  List<SavedDoc> _files = [];
  bool _loading = true;
  _Filter _filter = _Filter.all;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> reload() => _load();

  Future<void> _load() async {
    final files = await DocStore.list();
    if (!mounted) return;
    setState(() {
      _files = files;
      _loading = false;
    });
  }

  List<SavedDoc> get _shown {
    switch (_filter) {
      case _Filter.all:
        return _files;
      case _Filter.photos:
        return _files.where((f) => f.isImage).toList();
      case _Filter.pdfs:
        return _files.where((f) => f.isPdf).toList();
    }
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
        title: const Text('Delete file?'),
        content: Text(doc.name),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My documents')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Wrap(
              spacing: 8,
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
                ? _empty()
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                      itemCount: _shown.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (ctx, i) {
                        final f = _shown[i];
                        return Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            onTap: () => _open(f),
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: f.isPdf
                                    ? const Color(0xFFFFF1F2)
                                    : AppColors.photoResizeCard,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                f.isPdf
                                    ? Icons.picture_as_pdf_rounded
                                    : Icons.image_rounded,
                                color: f.isPdf
                                    ? AppColors.pdfBadge
                                    : AppColors.primaryButton,
                              ),
                            ),
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
                              kbLabel(f.size),
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
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/deco_folder.png',
              width: 120,
              height: 96,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            const Text(
              'Nothing saved yet',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 6),
            const Text(
              'Photos, signatures and PDFs you create will show up here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.mutedText, height: 1.4),
            ),
          ],
        ),
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
