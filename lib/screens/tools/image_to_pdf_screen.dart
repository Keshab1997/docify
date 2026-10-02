import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/saved_doc.dart';
import '../../services/pdf_service.dart';
import '../../services/pick_bytes.dart';
import '../../services/save_out.dart';
import '../../services/share_bytes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animated_reveal.dart';
import '../../widgets/job_progress.dart';
import '../../widgets/pdf_preview_page.dart';
import '../../widgets/tool_ui.dart';

class _Img {
  _Img(this.id, this.bytes);
  final String id;
  final Uint8List bytes;
}

class ImageToPdfScreen extends StatefulWidget {
  const ImageToPdfScreen({super.key, this.initialImages = const []});
  final List<Uint8List> initialImages;

  @override
  State<ImageToPdfScreen> createState() => _ImageToPdfScreenState();
}

class _ImageToPdfScreenState extends State<ImageToPdfScreen> {
  final _images = <_Img>[];
  Uint8List? _pdf;
  String? _pdfName;
  bool _busy = false;
  String _page = 'a4';
  bool _landscape = false;
  JobStage? _stage;

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < widget.initialImages.length; i++) {
      _images.add(_Img('initial_$i', widget.initialImages[i]));
    }
  }

  Future<void> _pick() async {
    final src = await pickSourceSheet(context);
    List<Uint8List> got = const [];
    if (src == ImageSource.camera) {
      final one = await PickBytes.image(ImageSource.camera);
      if (one != null) got = [one];
    } else if (src == ImageSource.gallery) {
      got = await PickBytes.images();
      if (got.isEmpty) {
        final one = await PickBytes.image(ImageSource.gallery);
        if (one != null) got = [one];
      }
    }
    if (got.isEmpty) return;
    setState(() {
      for (final b in got) {
        _images.add(
          _Img('${DateTime.now().microsecondsSinceEpoch}_${b.length}', b),
        );
      }
      _pdf = null;
    });
  }

  Future<void> _create() async {
    if (_images.isEmpty) return;
    setState(() {
      _busy = true;
      _stage = JobStage.working;
    });
    try {
      final pdf = await PdfService.imagesToPdf(
        [for (final i in _images) i.bytes],
        page: _page,
        landscape: _landscape,
      );
      if (!mounted) return;
      setState(() => _stage = JobStage.saving);
      final name = uniqueDocifyName('pdf');
      await SaveOut.pdf(pdf, name);
      if (!mounted) return;
      setState(() {
        _pdf = pdf;
        _pdfName = name;
        _stage = JobStage.done;
      });
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      setState(() => _stage = null);
      showJobSnack(context, 'PDF saved · ${kbLabel(pdf.length)}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _stage = null);
      showJobSnack(context, 'Could not create PDF: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String get _stageTitle => switch (_stage) {
        JobStage.saving => 'Saving the PDF',
        JobStage.done => 'PDF ready',
        _ => 'Building the PDF',
      };

  String? get _stageSubtitle => switch (_stage) {
        JobStage.saving => 'Putting the finished PDF in My Documents.',
        JobStage.done => _pdf == null
            ? null
            : '${_images.length} pages · ${kbLabel(_pdf!.length)}',
        _ =>
          'Laying out ${_images.length} pictures on ${_page.toUpperCase()} pages.',
      };

  @override
  Widget build(BuildContext context) {
    final stage = _stage;
    return Scaffold(
      appBar: AppBar(title: const Text('Image → PDF')),
      body: stage != null
          ? JobProgressOverlay(
              stage: stage,
              title: _stageTitle,
              subtitle: _stageSubtitle,
              medallionIcon: Icons.photo_library_rounded,
              saveIcon: Icons.picture_as_pdf_rounded,
              steps: const ['Read', 'Build', 'Save'],
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
            'Add several pictures, drag to reorder, then make one PDF. A4 or Letter, on this phone.',
            color: AppColors.imageToPdfCard,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ChoiceChip(
                label: const Text('A4'),
                selected: _page == 'a4',
                onSelected: (_) => setState(() => _page = 'a4'),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Letter'),
                selected: _page == 'letter',
                onSelected: (_) => setState(() => _page = 'letter'),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Landscape'),
                selected: _landscape,
                onSelected: (v) => setState(() => _landscape = v),
              ),
              const Spacer(),
              FilledButton.tonal(onPressed: _pick, child: const Text('Add')),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _images.isEmpty
                ? const Center(
                    child: Text(
                      'No images yet',
                      style: TextStyle(color: AppColors.mutedText),
                    ),
                  )
                : ReorderableListView.builder(
                    itemCount: _images.length,
                    // ignore: deprecated_member_use
                    onReorder: (a, b) {
                      setState(() {
                        if (b > a) b -= 1;
                        final item = _images.removeAt(a);
                        _images.insert(b, item);
                      });
                    },
                    itemBuilder: (_, i) {
                      final img = _images[i];
                      return ListTile(
                        key: ValueKey(img.id),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(Radii.sm),
                          child: Image.memory(
                            img.bytes,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text('Page ${i + 1}'),
                        subtitle: Text(kbLabel(img.bytes.length)),
                        trailing: IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => setState(() {
                            _images.removeAt(i);
                            _pdf = null;
                          }),
                        ),
                      );
                    },
                  ),
          ),
          PrimaryJobButton(
            label: 'Create PDF',
            onPressed: _create,
            busy: _busy,
          ),
          if (_pdf != null)
            AnimatedReveal(
              child: ListTile(
                leading: const Icon(
                  Icons.picture_as_pdf,
                  color: AppColors.pdfBadge,
                ),
                title: Text(_pdfName ?? 'document.pdf'),
                subtitle: Text(kbLabel(_pdf!.length)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility_rounded),
                      onPressed: () => PdfPreviewPage.open(
                        context,
                        bytes: _pdf!,
                        name: _pdfName ?? 'document.pdf',
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: () => ShareBytes.share(
                        bytes: _pdf!,
                        name: _pdfName ?? 'document.pdf',
                        mime: 'application/pdf',
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
