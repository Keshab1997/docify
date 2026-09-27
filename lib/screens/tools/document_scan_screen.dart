import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/saved_doc.dart';
import '../../services/gallery_save.dart';
import '../../services/image_bytes.dart';
import '../../services/pdf_service.dart';
import '../../services/pick_bytes.dart';
import '../../services/save_out.dart';
import '../../services/share_bytes.dart';
import '../../widgets/pdf_preview_page.dart';
import '../../theme/app_theme.dart';
import '../../widgets/tool_ui.dart';
import 'crop_image_screen.dart';

class _Page {
  _Page(this.id, this.bytes);
  final String id;
  Uint8List bytes;
}

class DocumentScanScreen extends StatefulWidget {
  const DocumentScanScreen({super.key});

  @override
  State<DocumentScanScreen> createState() => _DocumentScanScreenState();
}

class _DocumentScanScreenState extends State<DocumentScanScreen> {
  final _pages = <_Page>[];
  bool _enhance = true;
  bool _busy = false;
  Uint8List? _pdf;

  Future<void> _capture({bool camera = true}) async {
    final bytes = await PickBytes.image(
      camera ? ImageSource.camera : ImageSource.gallery,
    );
    if (bytes == null || !mounted) return;
    final cropped = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(
        builder: (_) => CropBytesPage(image: bytes, title: 'Crop page'),
      ),
    );
    var page = cropped ?? bytes;
    if (_enhance) {
      page = await ImageBytes.enhanceDocument(page);
    }
    if (!mounted) return;
    setState(() {
      _pages.add(_Page('${DateTime.now().microsecondsSinceEpoch}', page));
      _pdf = null;
    });
  }

  Future<void> _toPdf() async {
    if (_pages.isEmpty) return;
    setState(() => _busy = true);
    try {
      final pdf = await PdfService.imagesToPdf([
        for (final p in _pages) p.bytes,
      ]);
      final name = uniqueJobDocName('pdf');
      await SaveOut.pdf(pdf, name);
      if (!mounted) return;
      setState(() => _pdf = pdf);
      showJobSnack(context, 'PDF saved · ${kbLabel(pdf.length)}');
    } catch (e) {
      if (!mounted) return;
      showJobSnack(context, 'Could not make PDF: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveImages() async {
    setState(() => _busy = true);
    try {
      for (var i = 0; i < _pages.length; i++) {
        await GallerySave.saveJpeg(_pages[i].bytes, 'JobDoc_scan_${i + 1}.jpg');
      }
      if (!mounted) return;
      showJobSnack(context, 'Saved ${_pages.length} page(s)');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Document Scan')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const HintBanner(
              'Capture, crop, optional B&W contrast, then save pages or one PDF. Nothing is uploaded.',
              color: AppColors.signatureCard,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Document look (contrast)',
                style: TextStyle(fontSize: 14),
              ),
              value: _enhance,
              onChanged: (v) => setState(() => _enhance = v),
            ),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _capture(camera: true),
                    icon: const Icon(Icons.photo_camera_rounded),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _capture(camera: false),
                    icon: const Icon(Icons.photo_library_rounded),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
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
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _pages.length,
                      itemBuilder: (_, i) => Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(
                              _pages[i].bytes,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 18,
                              ),
                              onPressed: () =>
                                  setState(() => _pages.removeAt(i)),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            if (_pages.isNotEmpty) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy ? null : _saveImages,
                      child: const Text('Save images'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: _busy ? null : _toPdf,
                      child: const Text('Make PDF'),
                    ),
                  ),
                ],
              ),
            ],
            if (_pdf != null)
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => PdfPreviewPage.open(
                        context,
                        bytes: _pdf!,
                        name: 'scan.pdf',
                      ),
                      icon: const Icon(Icons.visibility_rounded),
                      label: const Text('Preview'),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => ShareBytes.share(
                        bytes: _pdf!,
                        name: 'scan.pdf',
                        mime: 'application/pdf',
                      ),
                      icon: const Icon(Icons.share_rounded),
                      label: const Text('Share PDF'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
