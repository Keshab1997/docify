import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../models/exam_preset.dart';
import '../../models/saved_doc.dart';
import '../../services/doc_store.dart';
import '../../services/gallery_save.dart';
import '../../services/image_bytes.dart';
import '../../services/pdf_service.dart';
import '../../services/share_bytes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/tool_ui.dart';
import 'crop_image_screen.dart';
import 'signature_screen.dart';

class JobFormAssistantScreen extends StatefulWidget {
  const JobFormAssistantScreen({super.key});

  @override
  State<JobFormAssistantScreen> createState() => _JobFormAssistantScreenState();
}

class _JobFormAssistantScreenState extends State<JobFormAssistantScreen> {
  ExamPreset _exam = ExamPreset.all.first;
  Uint8List? _photo;
  Uint8List? _photoOut;
  Uint8List? _sig;
  Uint8List? _sigOut;
  Uint8List? _packPdf;
  bool _busy = false;
  bool _alsoPdf = true;

  Future<void> _pickPhoto() async {
    final bytes = await pickPhoto(context);
    if (bytes == null || !mounted) return;
    double? aspect;
    if (_exam.photoW != null && _exam.photoH != null) {
      aspect = _exam.photoW! / _exam.photoH!;
    }
    final cropped = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(
        builder: (_) => CropBytesPage(
          image: bytes,
          lockedAspect: aspect,
          title: 'Crop photo',
        ),
      ),
    );
    if (!mounted) return;
    setState(() {
      _photo = cropped ?? bytes;
      _photoOut = null;
      _packPdf = null;
    });
  }

  Future<void> _pickSig() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.draw_rounded),
              title: const Text('Draw signature'),
              onTap: () => Navigator.pop(ctx, 'draw'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Pick a photo'),
              onTap: () => Navigator.pop(ctx, 'photo'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == 'draw') {
      final drawn = await Navigator.push<Uint8List>(
        context,
        MaterialPageRoute(builder: (_) => const CaptureSignaturePage()),
      );
      if (drawn == null || !mounted) return;
      setState(() {
        _sig = drawn;
        _sigOut = null;
        _packPdf = null;
      });
      return;
    }
    final bytes = await pickPhoto(context);
    if (bytes == null || !mounted) return;
    setState(() {
      _sig = bytes;
      _sigOut = null;
      _packPdf = null;
    });
  }

  Future<void> _prepare() async {
    if (_photo == null || _sig == null) {
      showJobSnack(context, 'Add a photo and a signature first');
      return;
    }
    setState(() => _busy = true);
    try {
      final photo = await ImageBytes.resizeToKb(
        bytes: _photo!,
        targetKB: _exam.photoMaxKb,
        minKB: _exam.photoMinKb,
        targetWidth: _exam.photoW,
        targetHeight: _exam.photoH,
      );
      final sig = await ImageBytes.extractSignature(
        bytes: _sig!,
        width: _exam.sigW,
        height: _exam.sigH,
      );
      final sigSized = await ImageBytes.resizeToKb(
        bytes: sig,
        targetKB: _exam.sigMaxKb,
        minKB: _exam.sigMinKb,
        targetWidth: _exam.sigW,
        targetHeight: _exam.sigH,
      );
      final photoName = 'JobDoc_${_exam.id}_photo.jpg';
      final sigName = 'JobDoc_${_exam.id}_signature.jpg';
      await GallerySave.saveJpeg(photo, photoName);
      await GallerySave.saveJpeg(sigSized, sigName);
      Uint8List? pdf;
      if (_alsoPdf) {
        pdf = await PdfService.imagesToPdf([photo, sigSized]);
        await DocStore.save(
          bytes: pdf,
          name: 'JobDoc_${_exam.id}_pack.pdf',
          mime: 'application/pdf',
        );
      }
      if (!mounted) return;
      setState(() {
        _photoOut = photo;
        _sigOut = sigSized;
        _packPdf = pdf;
      });
      showJobSnack(context, 'Photo, signature${pdf == null ? '' : ' and PDF'} saved');
    } catch (e) {
      if (!mounted) return;
      showJobSnack(context, 'Could not prepare: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Job Form Assistant')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.jobFormStart, AppColors.jobFormEnd],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'One exam, the right sizes. Photo and signature stay separate files — that is what portals ask for. Optional PDF pack if you want both on one sheet.',
              style: TextStyle(fontSize: 12.5, height: 1.35),
            ),
          ),
          const SizedBox(height: 14),
          const SectionLabel('Exam'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in ExamPreset.all)
                ChoiceChip(
                  label: Text(p.name),
                  selected: _exam.id == p.id,
                  onSelected: (_) => setState(() {
                    _exam = p;
                    _photoOut = null;
                    _sigOut = null;
                    _packPdf = null;
                  }),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(_exam.subtitle, style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
          const SizedBox(height: 14),
          _step(
            '1. Photo',
            '${_exam.photoMinKb}–${_exam.photoMaxKb} KB'
                '${_exam.photoW != null ? ' · ${_exam.photoW}×${_exam.photoH} px' : ''}',
            _photo,
            _photoOut,
            _pickPhoto,
          ),
          const SizedBox(height: 10),
          _step(
            '2. Signature',
            '${_exam.sigMinKb}–${_exam.sigMaxKb} KB'
                '${_exam.sigW != null ? ' · ${_exam.sigW}×${_exam.sigH} px' : ''}',
            _sig,
            _sigOut,
            _pickSig,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Also make a combined PDF', style: TextStyle(fontSize: 14)),
            value: _alsoPdf,
            onChanged: (v) => setState(() => _alsoPdf = v),
          ),
          PrimaryJobButton(label: 'Prepare files', onPressed: _prepare, busy: _busy),
          if (_photoOut != null && _sigOut != null) ...[
            const SizedBox(height: 14),
            _doneRow('Photo', _photoOut!, 'image/jpeg', 'photo.jpg'),
            _doneRow('Signature', _sigOut!, 'image/jpeg', 'signature.jpg'),
            if (_packPdf != null)
              _doneRow('PDF pack', _packPdf!, 'application/pdf', 'pack.pdf', image: false),
          ],
        ],
      ),
    );
  }

  Widget _step(
    String title,
    String target,
    Uint8List? input,
    Uint8List? output,
    VoidCallback pick,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(target, style: const TextStyle(fontSize: 11, color: AppColors.mutedText)),
              ),
              const Spacer(),
              Icon(
                output != null ? Icons.check_circle : Icons.circle_outlined,
                color: output != null ? AppColors.successChip : Colors.grey,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _thumb(input, pick),
              const SizedBox(width: 10),
              if (output != null) _thumb(output, null),
              const Spacer(),
              FilledButton.tonal(onPressed: pick, child: const Text('Pick')),
            ],
          ),
          if (output != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(kbLabel(output.length), style: const TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _thumb(Uint8List? bytes, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.antiAlias,
        child: bytes == null
            ? const Icon(Icons.add_a_photo_rounded)
            : Image.memory(bytes, fit: BoxFit.cover),
      ),
    );
  }

  Widget _doneRow(String title, Uint8List bytes, String mime, String name, {bool image = true}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: image
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(bytes, width: 40, height: 40, fit: BoxFit.cover),
            )
          : const Icon(Icons.picture_as_pdf_rounded, color: AppColors.pdfBadge),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      subtitle: Text(kbLabel(bytes.length)),
      trailing: IconButton(
        icon: const Icon(Icons.share_rounded),
        onPressed: () => ShareBytes.share(bytes: bytes, name: name, mime: mime),
      ),
    );
  }
}
