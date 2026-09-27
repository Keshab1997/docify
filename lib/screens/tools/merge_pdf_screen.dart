import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../models/saved_doc.dart';
import '../../services/pdf_service.dart';
import '../../services/pick_bytes.dart';
import '../../services/save_out.dart';
import '../../services/share_bytes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/pdf_preview_page.dart';
import '../../widgets/tool_ui.dart';

class _PdfItem {
  _PdfItem(this.id, this.name, this.bytes);
  final String id;
  String name;
  Uint8List bytes;
}

class MergePdfScreen extends StatefulWidget {
  const MergePdfScreen({super.key});

  @override
  State<MergePdfScreen> createState() => _MergePdfScreenState();
}

class _MergePdfScreenState extends State<MergePdfScreen> {
  final _files = <_PdfItem>[];
  Uint8List? _merged;
  String? _mergedName;
  bool _busy = false;
  bool _rasterized = false;

  Future<void> _pick() async {
    final picked = await PickBytes.pdfs();
    if (picked.isEmpty) return;
    setState(() {
      for (final p in picked) {
        _files.add(
          _PdfItem(
            '${DateTime.now().microsecondsSinceEpoch}_${p.name}',
            p.name,
            p.bytes,
          ),
        );
      }
      _merged = null;
    });
  }

  Future<void> _merge() async {
    if (_files.length < 2) {
      showJobSnack(context, 'Pick at least 2 PDFs');
      return;
    }
    setState(() => _busy = true);
    try {
      final result = await PdfService.mergePdfs([for (final f in _files) f.bytes]);
      final name = uniqueJobDocName('pdf');
      await SaveOut.pdf(result.bytes, name);
      if (!mounted) return;
      setState(() {
        _merged = result.bytes;
        _mergedName = name;
        _rasterized = result.rasterized;
      });
      showJobSnack(
        context,
        result.rasterized
            ? 'Merged as images (this PDF used a format we copy as pages). ${kbLabel(result.bytes.length)}'
            : 'Merged ${ _files.length} files · ${kbLabel(result.bytes.length)}',
      );
    } catch (e) {
      if (!mounted) return;
      showJobSnack(context, 'Could not merge: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Merge PDF')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const HintBanner(
              'Combine PDFs in order. Drag to reorder. Encrypted files cannot be merged.',
              color: AppColors.mergePdfCard,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton.tonal(
                  onPressed: _pick,
                  child: const Text('Add PDFs'),
                ),
                const Spacer(),
                Text('${_files.length} file${_files.length == 1 ? '' : 's'}'),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _files.isEmpty
                  ? const Center(
                      child: Text(
                        'No PDFs yet',
                        style: TextStyle(color: AppColors.mutedText),
                      ),
                    )
                  : ReorderableListView.builder(
                      itemCount: _files.length,
                      onReorder: (a, b) {
                        setState(() {
                          if (b > a) b -= 1;
                          final item = _files.removeAt(a);
                          _files.insert(b, item);
                        });
                      },
                      itemBuilder: (_, i) {
                        final f = _files[i];
                        return ListTile(
                          key: ValueKey(f.id),
                          leading: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.pdfBadge),
                          title: Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(kbLabel(f.bytes.length)),
                          trailing: IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => setState(() {
                              _files.removeAt(i);
                              _merged = null;
                            }),
                          ),
                        );
                      },
                    ),
            ),
            PrimaryJobButton(label: 'Merge', onPressed: _merge, busy: _busy),
            if (_merged != null) ...[
              const SizedBox(height: 8),
              ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                leading: const Icon(Icons.check_circle, color: AppColors.successChip),
                title: Text(_mergedName ?? 'merged.pdf'),
                subtitle: Text(
                  '${kbLabel(_merged!.length)}${_rasterized ? ' · page images' : ''}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility_rounded),
                      onPressed: () => PdfPreviewPage.open(
                        context,
                        bytes: _merged!,
                        name: _mergedName ?? 'merged.pdf',
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.share_rounded),
                      onPressed: () => ShareBytes.share(
                        bytes: _merged!,
                        name: _mergedName ?? 'merged.pdf',
                        mime: 'application/pdf',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
