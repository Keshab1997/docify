import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/exam_preset.dart';
import '../../models/requirement_check.dart';
import '../../models/saved_doc.dart';
import '../../services/gallery_save.dart';
import '../../services/image_bytes.dart';
import '../../services/pdf_service.dart';
import '../../services/save_out.dart';
import '../../theme/app_theme.dart';
import '../../widgets/pdf_preview_page.dart';
import '../../widgets/doc_guard_scope.dart';
import '../../widgets/requirement_check_card.dart';
import '../../widgets/tool_ui.dart';
import 'crop_image_screen.dart';
import 'signature_screen.dart';

class JobFormAssistantScreen extends StatefulWidget {
  const JobFormAssistantScreen({super.key, this.initialExam, this.initialPhoto, this.initialSignature});
  final ExamPreset? initialExam;
  final Uint8List? initialPhoto;
  final Uint8List? initialSignature;

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
  RequirementCheck? _photoCheck;
  RequirementCheck? _sigCheck;
  bool _busy = false;
  bool _alsoPdf = true;

  final _photoMin = TextEditingController();
  final _photoMax = TextEditingController();
  final _photoW = TextEditingController();
  final _photoH = TextEditingController();
  final _sigMin = TextEditingController();
  final _sigMax = TextEditingController();
  final _sigW = TextEditingController();
  final _sigH = TextEditingController();

  @override
  void initState() {
    super.initState();
    _exam = widget.initialExam ?? _exam;
    _photo = widget.initialPhoto;
    _sig = widget.initialSignature;
    _fill(_exam);
  }

  @override
  void dispose() {
    _photoMin.dispose();
    _photoMax.dispose();
    _photoW.dispose();
    _photoH.dispose();
    _sigMin.dispose();
    _sigMax.dispose();
    _sigW.dispose();
    _sigH.dispose();
    super.dispose();
  }

  void _fill(ExamPreset p) {
    _photoMin.text = '${p.photoMinKb}';
    _photoMax.text = '${p.photoMaxKb}';
    _photoW.text = p.photoW?.toString() ?? '';
    _photoH.text = p.photoH?.toString() ?? '';
    _sigMin.text = '${p.sigMinKb}';
    _sigMax.text = '${p.sigMaxKb}';
    _sigW.text = p.sigW?.toString() ?? '';
    _sigH.text = p.sigH?.toString() ?? '';
  }

  int _n(TextEditingController c, int fallback) =>
      int.tryParse(c.text.trim()) ?? fallback;

  int? _nOpt(TextEditingController c) => int.tryParse(c.text.trim());

  Future<void> _pickPhoto() async {
    final bytes = await pickPhoto(context);
    if (bytes == null || !mounted) return;
    final w = _nOpt(_photoW);
    final h = _nOpt(_photoH);
    final cropped = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(
        builder: (_) => DocGuardScope.protect(context, CropBytesPage(
          image: bytes,
          lockedAspect: (w != null && h != null && h > 0) ? w / h : null,
          title: 'Crop photo',
        )),
      ),
    );
    if (!mounted) return;
    setState(() {
      _photo = cropped ?? bytes;
      _photoOut = null;
      _photoCheck = null;
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
        MaterialPageRoute(builder: (_) => DocGuardScope.protect(context, const CaptureSignaturePage())),
      );
      if (drawn == null || !mounted) return;
      setState(() {
        _sig = drawn;
        _sigOut = null;
        _sigCheck = null;
        _packPdf = null;
      });
      return;
    }
    final bytes = await pickPhoto(context);
    if (bytes == null || !mounted) return;
    setState(() {
      _sig = bytes;
      _sigOut = null;
      _sigCheck = null;
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
      final photoMin = _n(_photoMin, _exam.photoMinKb);
      final photoMax = _n(_photoMax, _exam.photoMaxKb);
      final sigMin = _n(_sigMin, _exam.sigMinKb);
      final sigMax = _n(_sigMax, _exam.sigMaxKb);
      final photo = await ImageBytes.resizeToKb(
        bytes: _photo!,
        targetKB: photoMax,
        minKB: photoMin,
        targetWidth: _nOpt(_photoW),
        targetHeight: _nOpt(_photoH),
      );
      final sig = await ImageBytes.extractSignature(
        bytes: _sig!,
        width: _nOpt(_sigW),
        height: _nOpt(_sigH),
      );
      final sigSized = await ImageBytes.resizeToKb(
        bytes: sig,
        targetKB: sigMax,
        minKB: sigMin,
        targetWidth: _nOpt(_sigW),
        targetHeight: _nOpt(_sigH),
      );
      // Check the finished files against the exam's own numbers, so a mismatch
      // is reported here instead of by the portal.
      final photoInfo = await ImageBytes.info(photo);
      final sigInfo = await ImageBytes.info(sigSized);
      final photoCheck = RequirementCheck.forFile(
        title: 'Photo check',
        sizeBytes: photo.length,
        spec: FileSpec(
          minKb: photoMin,
          maxKb: photoMax,
          width: _nOpt(_photoW),
          height: _nOpt(_photoH),
          format: 'jpg',
        ),
        width: photoInfo[0],
        height: photoInfo[1],
        format: ImageBytes.detectFormat(photo),
      );
      final sigCheck = RequirementCheck.forFile(
        title: 'Signature check',
        sizeBytes: sigSized.length,
        spec: FileSpec(
          minKb: sigMin,
          maxKb: sigMax,
          width: _nOpt(_sigW),
          height: _nOpt(_sigH),
          format: 'jpg',
        ),
        width: sigInfo[0],
        height: sigInfo[1],
        format: ImageBytes.detectFormat(sigSized),
      );

      final photoName = 'Docify_${_exam.id}_photo.jpg';
      final sigName = 'Docify_${_exam.id}_signature.jpg';
      await GallerySave.saveImage(
        photo,
        photoName,
        mime: mimeFromName(photoName),
      );
      await GallerySave.saveImage(
        sigSized,
        sigName,
        mime: mimeFromName(sigName),
      );
      Uint8List? pdf;
      if (_alsoPdf) {
        pdf = await PdfService.imagesToPdf([photo, sigSized]);
        await SaveOut.pdf(pdf, 'Docify_${_exam.id}_pack.pdf');
      }
      if (!mounted) return;
      setState(() {
        _photoOut = photo;
        _sigOut = sigSized;
        _packPdf = pdf;
        _photoCheck = photoCheck;
        _sigCheck = sigCheck;
      });
      final failed = photoCheck.failedCount + sigCheck.failedCount;
      showJobSnack(
        context,
        failed == 0
            ? 'Photo, signature${pdf == null ? '' : ' and PDF'} saved — every check passed'
            : 'Saved, but $failed check${failed == 1 ? '' : 's'} failed — see the lists below',
      );
    } catch (e) {
      if (!mounted) return;
      showJobSnack(context, 'Could not prepare: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareAll() async {
    if (_photoOut == null || _sigOut == null) return;
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(_photoOut!, name: 'photo.jpg', mimeType: 'image/jpeg'),
          XFile.fromData(
            _sigOut!,
            name: 'signature.jpg',
            mimeType: 'image/jpeg',
          ),
          if (_packPdf != null)
            XFile.fromData(
              _packPdf!,
              name: 'pack.pdf',
              mimeType: 'application/pdf',
            ),
        ],
      ),
    );
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
              'One exam, the right sizes. Photo and signature stay '
              'separate files — that is what portals ask for. Optional PDF '
              'pack if you want both on one sheet.',
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
                    _fill(p);
                    _photoOut = null;
                    _sigOut = null;
                    _photoCheck = null;
                    _sigCheck = null;
                    _packPdf = null;
                  }),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _exam.subtitle,
            style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
          ),
          if (_exam.sourceNote.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '${_exam.sourceNote}${_exam.asOf.isEmpty ? '' : ' · checked ${_exam.asOf}'}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.mutedText,
                ),
              ),
            ),
          const SizedBox(height: 12),
          const SectionLabel('Photo size'),
          _sizeRow(_photoMin, _photoMax, _photoW, _photoH),
          const SizedBox(height: 10),
          const SectionLabel('Signature size'),
          _sizeRow(_sigMin, _sigMax, _sigW, _sigH),
          const SizedBox(height: 14),
          _step(
            '1. Photo',
            '${_photoMin.text}–${_photoMax.text} KB',
            _photo,
            _photoOut,
            _pickPhoto,
          ),
          const SizedBox(height: 10),
          _step(
            '2. Signature',
            '${_sigMin.text}–${_sigMax.text} KB',
            _sig,
            _sigOut,
            _pickSig,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Also make a combined PDF',
              style: TextStyle(fontSize: 14),
            ),
            value: _alsoPdf,
            onChanged: (v) => setState(() => _alsoPdf = v),
          ),
          PrimaryJobButton(
            label: 'Prepare files',
            onPressed: _prepare,
            busy: _busy,
          ),
          if (_photoOut != null && _sigOut != null) ...[
            const SizedBox(height: 14),
            if (_photoCheck != null) ...[
              RequirementCheckCard(check: _photoCheck!),
              const SizedBox(height: 10),
            ],
            if (_sigCheck != null) ...[
              RequirementCheckCard(check: _sigCheck!),
              const SizedBox(height: 10),
            ],
            _doneRow('Photo', _photoOut!, 'image/jpeg', 'photo.jpg'),
            _doneRow('Signature', _sigOut!, 'image/jpeg', 'signature.jpg'),
            if (_packPdf != null)
              _doneRow(
                'PDF pack',
                _packPdf!,
                'application/pdf',
                'pack.pdf',
                image: false,
              ),
            FilledButton.tonalIcon(
              onPressed: _shareAll,
              icon: const Icon(Icons.share_rounded),
              label: const Text('Share all files'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sizeRow(
    TextEditingController min,
    TextEditingController max,
    TextEditingController w,
    TextEditingController h,
  ) {
    return Row(
      children: [
        Expanded(child: _tiny(min, 'Min KB')),
        const SizedBox(width: 8),
        Expanded(child: _tiny(max, 'Max KB')),
        const SizedBox(width: 8),
        Expanded(child: _tiny(w, 'W px')),
        const SizedBox(width: 8),
        Expanded(child: _tiny(h, 'H px')),
      ],
    );
  }

  Widget _tiny(TextEditingController c, String label) {
    return TextField(
      controller: c,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(isDense: true, labelText: label),
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
                child: Text(
                  target,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.mutedText,
                  ),
                ),
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
              child: Text(
                kbLabel(output.length),
                style: const TextStyle(fontSize: 12),
              ),
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

  Widget _doneRow(
    String title,
    Uint8List bytes,
    String mime,
    String name, {
    bool image = true,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: image
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                bytes,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            )
          : const Icon(Icons.picture_as_pdf_rounded, color: AppColors.pdfBadge),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
      subtitle: Text(kbLabel(bytes.length)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!image)
            IconButton(
              icon: const Icon(Icons.visibility_rounded),
              onPressed: () =>
                  PdfPreviewPage.open(context, bytes: bytes, name: name),
            ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () => SharePlus.instance.share(
              ShareParams(
                files: [XFile.fromData(bytes, name: name, mimeType: mime)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
