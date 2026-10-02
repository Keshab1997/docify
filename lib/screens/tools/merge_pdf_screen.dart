import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../models/saved_doc.dart';
import '../../services/pdf_service.dart';
import '../../services/pick_bytes.dart';
import '../../services/save_out.dart';
import '../../services/share_bytes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animated_count.dart';
import '../../widgets/animated_reveal.dart';
import '../../widgets/job_progress.dart';
import '../../widgets/pdf_preview_page.dart';
import '../../widgets/tool_ui.dart';

class _PdfItem {
  _PdfItem(this.id, this.name, this.bytes);
  final String id;
  String name;
  Uint8List bytes;
}

class MergePdfScreen extends StatefulWidget {
  const MergePdfScreen({super.key, this.initialFiles = const []});
  final List<NamedBytes> initialFiles;

  @override
  State<MergePdfScreen> createState() => _MergePdfScreenState();
}

class _MergePdfScreenState extends State<MergePdfScreen> {
  final _files = <_PdfItem>[];
  Uint8List? _merged;
  String? _mergedName;
  bool _busy = false;
  bool _rasterized = false;
  JobStage? _stage;

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < widget.initialFiles.length; i++) {
      final file = widget.initialFiles[i];
      _files.add(_PdfItem('initial_$i', file.name, file.bytes));
    }
  }

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
    setState(() {
      _busy = true;
      _stage = JobStage.working;
    });
    try {
      final result = await PdfService.mergePdfs([
        for (final f in _files) f.bytes,
      ]);
      if (!mounted) return;
      setState(() => _stage = JobStage.saving);
      final name = uniqueDocifyName('pdf');
      await SaveOut.pdf(result.bytes, name);
      if (!mounted) return;
      setState(() {
        _merged = result.bytes;
        _mergedName = name;
        _rasterized = result.rasterized;
        _stage = JobStage.done;
      });
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      setState(() => _stage = null);
      showJobSnack(
        context,
        result.rasterized
            ? 'Merged as images (this PDF used a format we copy as pages). ${kbLabel(result.bytes.length)}'
            : 'Merged ${_files.length} files · ${kbLabel(result.bytes.length)}',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _stage = null);
      showJobSnack(context, 'Could not merge: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String get _stageTitle => switch (_stage) {
        JobStage.saving => 'Saving the merge',
        JobStage.done => 'Merged',
        _ => 'Merging PDFs',
      };

  String? get _stageSubtitle => switch (_stage) {
        JobStage.saving => 'Putting the finished PDF in My Documents.',
        JobStage.done => _merged == null
            ? null
            : '${_files.length} files · ${kbLabel(_merged!.length)}',
        _ => 'Combining ${_files.length} files on this phone.',
      };

  @override
  Widget build(BuildContext context) {
    final stage = _stage;
    return Scaffold(
      appBar: AppBar(title: const Text('Merge PDF')),
      body: stage != null
          ? JobProgressOverlay(
              stage: stage,
              title: _stageTitle,
              subtitle: _stageSubtitle,
              medallionIcon: Icons.picture_as_pdf_rounded,
              saveIcon: Icons.merge_type_rounded,
              steps: const ['Read', 'Merge', 'Save'],
            )
          : _form(),
    );
  }

  Widget _form() {
    return Padding(
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
              AnimatedCount(
                _files.length.toDouble(),
                suffix: ' file${_files.length == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
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
                    // ignore: deprecated_member_use
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
                        leading: const Icon(
                          Icons.picture_as_pdf_rounded,
                          color: AppColors.pdfBadge,
                        ),
                        title: Text(
                          f.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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
            AnimatedReveal(
              child: ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Radii.chip),
                ),
                leading: const Icon(
                  Icons.check_circle,
                  color: AppColors.successChip,
                ),
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
            ),
          ],
        ],
      ),
    );
  }
}
