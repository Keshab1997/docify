import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../models/saved_doc.dart';
import '../../services/gallery_save.dart';
import '../../services/pdf_service.dart';
import '../../services/pick_bytes.dart';
import '../../services/share_bytes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/tool_ui.dart';

class PdfToImagesScreen extends StatefulWidget {
  const PdfToImagesScreen({super.key});

  @override
  State<PdfToImagesScreen> createState() => _PdfToImagesScreenState();
}

class _PdfToImagesScreenState extends State<PdfToImagesScreen> {
  NamedBytes? _input;
  List<Uint8List> _pages = const [];
  bool _busy = false;
  double _dpi = 140;

  Future<void> _pick() async {
    final files = await PickBytes.pdfs(multiple: false);
    if (files.isEmpty) return;
    setState(() {
      _input = files.first;
      _pages = const [];
    });
  }

  Future<void> _run() async {
    if (_input == null) {
      showJobSnack(context, 'Pick a PDF first');
      return;
    }
    setState(() => _busy = true);
    try {
      final pages = await PdfService.pdfToImages(_input!.bytes, dpi: _dpi);
      if (!mounted) return;
      setState(() => _pages = pages);
      showJobSnack(context, '${pages.length} page(s)');
    } catch (e) {
      if (!mounted) return;
      showJobSnack(context, 'Could not read PDF: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveAll() async {
    setState(() => _busy = true);
    try {
      for (var i = 0; i < _pages.length; i++) {
        await GallerySave.saveJpeg(_pages[i], 'JobDoc_page_${i + 1}.jpg');
      }
      if (!mounted) return;
      showJobSnack(context, 'Saved ${_pages.length} image(s)');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PDF → Images')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const HintBanner(
              'Turn each PDF page into a JPG. Save them to the gallery or share one page.',
              color: AppColors.photoResizeCard,
            ),
            const SizedBox(height: 12),
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
            Row(
              children: [
                const Text(
                  'DPI',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                Expanded(
                  child: Slider(
                    value: _dpi,
                    min: 72,
                    max: 200,
                    divisions: 4,
                    label: '${_dpi.round()}',
                    onChanged: (v) => setState(() => _dpi = v),
                  ),
                ),
              ],
            ),
            PrimaryJobButton(
              label: 'Convert pages',
              onPressed: _run,
              busy: _busy,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _pages.isEmpty
                  ? const Center(
                      child: Text(
                        'No pages yet',
                        style: TextStyle(color: AppColors.mutedText),
                      ),
                    )
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _pages.length,
                      itemBuilder: (_, i) => Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => ShareBytes.share(
                            bytes: _pages[i],
                            name: 'page_${i + 1}.jpg',
                            mime: 'image/jpeg',
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: Image.memory(
                                    _pages[i],
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(
                                  'Page ${i + 1} · ${kbLabel(_pages[i].length)}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
            if (_pages.isNotEmpty)
              FilledButton.tonal(
                onPressed: _busy ? null : _saveAll,
                child: const Text('Save all to gallery'),
              ),
          ],
        ),
      ),
    );
  }
}
