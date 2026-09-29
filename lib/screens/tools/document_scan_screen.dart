import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../widgets/animated_count.dart';
import '../../widgets/animated_reveal.dart';
import '../../widgets/job_progress.dart';
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

class _DocumentScanScreenState extends State<DocumentScanScreen>
    with SingleTickerProviderStateMixin {
  final _pages = <_Page>[];
  bool _enhance = true;
  bool _busy = false;
  Uint8List? _pdf;
  JobStage? _stage;
  bool _savingImages = false;

  // A shortwhite shutter flash makes a capture feel like a capture; it is
  // driven by one controller and never repeats.
  late final AnimationController _shutter;
  late final Animation<double> _shutterCurve;

  @override
  void initState() {
    super.initState();
    _shutter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _shutterCurve = TweenSequence<double>([
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0, end: 0.85)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.85, end: 0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 70,
      ),
    ]).animate(_shutter);
  }

  @override
  void dispose() {
    _shutter.dispose();
    super.dispose();
  }

  void _fireShutter() {
    if (MediaQuery.of(context).disableAnimations) return;
    HapticFeedback.mediumImpact();
    _shutter.forward(from: 0);
  }

  Future<void> _capture({bool camera = true}) async {
    if (camera) _fireShutter();
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
    HapticFeedback.lightImpact();
  }

  Future<void> _toPdf() async {
    if (_pages.isEmpty) return;
    setState(() {
      _busy = true;
      _stage = JobStage.working;
    });
    try {
      final pdf = await PdfService.imagesToPdf([
        for (final p in _pages) p.bytes,
      ]);
      if (!mounted) return;
      setState(() => _stage = JobStage.saving);
      final name = uniqueDocifyName('pdf');
      await SaveOut.pdf(pdf, name);
      if (!mounted) return;
      setState(() {
        _pdf = pdf;
        _stage = JobStage.done;
      });
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      setState(() => _stage = null);
      showJobSnack(context, 'PDF saved · ${kbLabel(pdf.length)}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _stage = null);
      showJobSnack(context, 'Could not make PDF: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveImages() async {
    setState(() {
      _busy = true;
      _savingImages = true;
      _stage = JobStage.saving;
    });
    try {
      for (var i = 0; i < _pages.length; i++) {
        // Scan pages come out of the crop step as PNG, so encode to JPEG here
        // rather than saving PNG bytes under a .jpg name.
        final jpg = await ImageBytes.toJpg(_pages[i].bytes, quality: 88);
        await GallerySave.saveImage(
          jpg,
          'Docify_scan_${i + 1}.jpg',
          mime: 'image/jpeg',
        );
      }
      if (!mounted) return;
      setState(() => _stage = JobStage.done);
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      setState(() => _stage = null);
      showJobSnack(context, 'Saved ${_pages.length} page(s)');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _savingImages = false;
        });
      }
    }
  }

  String get _stageTitle {
    if (_stage == JobStage.done) {
      return _savingImages ? 'Saved to gallery' : 'PDF ready';
    }
    return _savingImages ? 'Saving pages' : 'Building the scan PDF';
  }

  String? get _stageSubtitle {
    if (_stage == JobStage.done) {
      return _savingImages
          ? '${_pages.length} page(s) are in your gallery.'
          : _pdf == null
              ? null
              : '${_pages.length} pages · ${kbLabel(_pdf!.length)}';
    }
    return _savingImages
        ? 'Putting ${_pages.length} page(s) in your gallery.'
        : 'Combining ${_pages.length} scanned pages on this phone.';
  }

  @override
  Widget build(BuildContext context) {
    final stage = _stage;
    return Scaffold(
      appBar: AppBar(title: const Text('Document Scan')),
      body: stage != null
          ? JobProgressOverlay(
              stage: stage,
              title: _stageTitle,
              subtitle: _stageSubtitle,
              medallionIcon: Icons.document_scanner_rounded,
              saveIcon: _savingImages
                  ? Icons.photo_library_rounded
                  : Icons.picture_as_pdf_rounded,
              steps: const ['Capture', 'Build', 'Save'],
            )
          : Stack(
              children: [
                _form(),
                // The shutter flash sits above everything, but never eats taps.
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _shutterCurve,
                      builder: (context, _) => ColoredBox(
                        color: Colors.white.withValues(
                          alpha: _shutterCurve.value,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _form() {
    return Padding(
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
            onChanged: (v) {
              HapticFeedback.selectionClick();
              setState(() => _enhance = v);
            },
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
          if (_pages.isNotEmpty) ...[
            const SizedBox(height: 10),
            AnimatedCount(
              _pages.length.toDouble(),
              suffix: _pages.length == 1 ? ' page scanned' : ' pages scanned',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
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
                    itemBuilder: (_, i) => AnimatedReveal(
                      index: i,
                      duration: const Duration(milliseconds: 280),
                      child: Stack(
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
            AnimatedReveal(
              child: Row(
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
            ),
        ],
      ),
    );
  }
}
