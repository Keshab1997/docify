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
  double _dpi = 110;

  Future<void> _pick() async {
    final files = await PickBytes.pdfs(multiple: false);
    if (files.isEmpty) return;
    setState(() {
      _input = files.first;
      _output = null;
    });
  }

  Future<void> _run() async {
    if (_input == null) {
      showJobSnack(context, 'Pick a PDF first');
      return;
    }
    setState(() => _busy = true);
    try {
      final out = await PdfService.compressPdf(_input!.bytes, dpi: _dpi);
      final name = uniqueJobDocName('pdf');
      await SaveOut.pdf(out, name);
      if (!mounted) return;
      setState(() {
        _output = out;
        _outName = name;
      });
      showJobSnack(context, 'Compressed · ${kbLabel(out.length)}');
    } catch (e) {
      if (!mounted) return;
      showJobSnack(context, 'Could not compress: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quality = _dpi < 90
        ? 'Smaller file'
        : _dpi < 130
            ? 'Balanced'
            : 'Clearer pages';
    return Scaffold(
      appBar: AppBar(title: const Text('Compress PDF')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const HintBanner(
            'Pages are redrawn at a lower resolution so the file shrinks. Fine for scans and photo PDFs.',
            color: AppColors.mergePdfCard,
          ),
          const SizedBox(height: 14),
          ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
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
          if (_output != null) ...[
            const SizedBox(height: 16),
            ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              leading: const Icon(
                Icons.check_circle,
                color: AppColors.successChip,
              ),
              title: Text(_outName ?? 'compressed.pdf'),
              subtitle: Text(
                '${kbLabel(_input!.bytes.length)} → ${kbLabel(_output!.length)}',
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
          ],
        ],
      ),
    );
  }
}
