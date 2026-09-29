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

class CompressPdfScreen extends StatefulWidget {
  const CompressPdfScreen({super.key});

  @override
  State<CompressPdfScreen> createState() => _CompressPdfScreenState();
}

class _CompressPdfScreenState extends State<CompressPdfScreen> {
  NamedBytes? _input;
  Uint8List? _output;
  String? _outName;
  bool _busy = false;
  bool _keptOriginal = false;
  int _progress = 0;
  double _dpi = 110;
  JobStage? _stage;

  Future<void> _pick() async {
    final files = await PickBytes.pdfs(multiple: false);
    if (files.isEmpty) return;
    setState(() {
      _input = files.first;
      _output = null;
      _keptOriginal = false;
      _progress = 0;
    });
  }

  Future<void> _run() async {
    if (_input == null) {
      showJobSnack(context, 'Pick a PDF first');
      return;
    }
    setState(() {
      _busy = true;
      _progress = 0;
      _keptOriginal = false;
      _stage = JobStage.working;
    });
    try {
      final result = await PdfService.compressPdf(
        _input!.bytes,
        dpi: _dpi,
        onProgress: (pages) {
          if (mounted) setState(() => _progress = pages);
        },
      );
      if (!mounted) return;
      setState(() => _stage = JobStage.saving);
      final name = uniqueJobDocName('pdf');
      // Only write a new file when the re-rendered copy is actually smaller.
      if (!result.keptOriginal) {
        await SaveOut.pdf(result.bytes, name);
      }
      if (!mounted) return;
      setState(() {
        _output = result.bytes;
        _outName = name;
        _keptOriginal = result.keptOriginal;
        _stage = JobStage.done;
      });
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      setState(() => _stage = null);
      showJobSnack(
        context,
        result.keptOriginal
            ? 'Kept your original — re-rendering made it bigger, not smaller.'
            : 'Compressed · ${kbLabel(result.bytes.length)}',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _stage = null);
      showJobSnack(context, 'Could not compress: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// How much smaller the finished file is, for the result badge.
  double get _savedPercent {
    final input = _input;
    final output = _output;
    if (input == null || output == null || input.bytes.isEmpty) return 0;
    return ((1 - output.length / input.bytes.length) * 100).clamp(0, 100);
  }

  String get _stageTitle => switch (_stage) {
        JobStage.saving => 'Saving the smaller copy',
        JobStage.done => _keptOriginal ? 'Original kept' : 'Compressed',
        _ => 'Compressing PDF',
      };

  String? get _stageSubtitle => switch (_stage) {
        JobStage.saving => 'Writing the new file to My Documents.',
        JobStage.done => _keptOriginal
            ? 'Re-rendering made it bigger, so nothing was changed.'
            : _input == null || _output == null
                ? null
                : '${kbLabel(_input!.bytes.length)} → ${kbLabel(_output!.length)}',
        _ => _progress > 0
            ? 'Redrawing page $_progress — stays on this phone.'
            : 'Redrawing the pages at ${_dpi.round()} DPI.',
      };

  @override
  Widget build(BuildContext context) {
    final stage = _stage;
    return Scaffold(
      appBar: AppBar(title: const Text('Compress PDF')),
      body: stage != null
          ? JobProgressOverlay(
              stage: stage,
              title: _stageTitle,
              subtitle: _stageSubtitle,
              medallionIcon: Icons.compress_rounded,
              saveIcon: Icons.picture_as_pdf_rounded,
              steps: const ['Read', 'Redraw', 'Save'],
            )
          : _form(),
    );
  }

  Widget _form() {
    final quality = _dpi < 90
        ? 'Smaller file'
        : _dpi < 130
            ? 'Balanced'
            : 'Clearer pages';
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const HintBanner(
          'Pages are redrawn at a lower resolution. Great for scans and photo PDFs; on a text PDF pages become images and can get bigger, so JobDoc then keeps your original.',
          color: AppColors.mergePdfCard,
        ),
        const SizedBox(height: 14),
        ListTile(
          tileColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.chip),
          ),
          leading: const Icon(
            Icons.picture_as_pdf_rounded,
            color: AppColors.pdfBadge,
          ),
          title: Text(_input?.name ?? 'No PDF selected'),
          subtitle: Text(
            _input == null ? 'Tap to pick' : kbLabel(_input!.bytes.length),
          ),
          onTap: _pick,
        ),
        const SizedBox(height: 16),
        SectionLabel('Quality · $quality'),
        Slider(
          value: _dpi,
          min: 72,
          max: 160,
          divisions: 4,
          label: '${_dpi.round()} DPI',
          onChanged: (v) => setState(() => _dpi = v),
        ),
        PrimaryJobButton(label: 'Compress', onPressed: _run, busy: _busy),
        if (_busy && _progress > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Rendered $_progress page${_progress == 1 ? '' : 's'}…',
              style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
            ),
          ),
        if (_output != null) ...[
          const SizedBox(height: 16),
          AnimatedReveal(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.chip),
                  ),
                  leading: const Icon(
                    Icons.check_circle,
                    color: AppColors.successChip,
                  ),
                  title: Text(
                    _keptOriginal
                        ? 'Your original (already the smallest)'
                        : _outName ?? 'compressed.pdf',
                  ),
                  subtitle: Text(
                    _keptOriginal
                        ? '${kbLabel(_input!.bytes.length)} — nothing was changed'
                        : '${kbLabel(_input!.bytes.length)} → ${kbLabel(_output!.length)}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility_rounded),
                        onPressed: () => PdfPreviewPage.open(
                          context,
                          bytes: _output!,
                          name: _outName ?? 'compressed.pdf',
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.share_rounded),
                        onPressed: () => ShareBytes.share(
                          bytes: _output!,
                          name: _outName ?? 'compressed.pdf',
                          mime: 'application/pdf',
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_keptOriginal && _savedPercent >= 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Center(
                      child: AnimatedCount(
                        _savedPercent,
                        suffix: '% smaller',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.successChip,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
