import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../models/exam_preset.dart';
import '../../models/saved_doc.dart';
import '../../services/gallery_save.dart';
import '../../services/image_bytes.dart';
import '../../services/share_bytes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/resize_show.dart';
import '../../widgets/tool_ui.dart';
import 'crop_image_screen.dart';

class PhotoResizeScreen extends StatefulWidget {
  const PhotoResizeScreen({super.key});

  @override
  State<PhotoResizeScreen> createState() => _PhotoResizeScreenState();
}

class _PhotoResizeScreenState extends State<PhotoResizeScreen> {
  Uint8List? _inputBytes;
  Uint8List? _outputBytes;
  int _minKB = 20;
  int _maxKB = 100;
  bool _processing = false;
  bool _lockAspect = true;
  ResizeStage? _stage;
  double? _savedKb;
  List<int>? _inSize;
  List<int>? _outSize;
  String _presetId = 'custom';

  final _minCtrl = TextEditingController(text: '20');
  final _maxCtrl = TextEditingController(text: '100');
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _applyExam(ExamPreset p) {
    setState(() {
      _presetId = p.id;
      _minKB = p.photoMinKb;
      _maxKB = p.photoMaxKb;
      _minCtrl.text = '${p.photoMinKb}';
      _maxCtrl.text = '${p.photoMaxKb}';
      if (p.photoW != null) _widthController.text = '${p.photoW}';
      if (p.photoH != null) _heightController.text = '${p.photoH}';
      if (p.id == 'custom') {
        _widthController.clear();
        _heightController.clear();
      }
    });
  }

  Future<void> _pick() async {
    final bytes = await pickPhoto(context);
    if (bytes == null || !mounted) return;
    final info = await ImageBytes.info(bytes);
    if (!mounted) return;
    setState(() {
      _inputBytes = bytes;
      _outputBytes = null;
      _savedKb = null;
      _inSize = info;
      _outSize = null;
    });
  }

  Future<void> _crop() async {
    final src = _inputBytes;
    if (src == null) return;
    double? aspect;
    final w = int.tryParse(_widthController.text);
    final h = int.tryParse(_heightController.text);
    if (w != null && h != null && w > 0 && h > 0) aspect = w / h;
    final cropped = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(
        builder: (_) => CropBytesPage(image: src, lockedAspect: aspect),
      ),
    );
    if (cropped == null || !mounted) return;
    final info = await ImageBytes.info(cropped);
    if (!mounted) return;
    setState(() {
      _inputBytes = cropped;
      _inSize = info;
      _outputBytes = null;
    });
  }

  void _onWidth(String v) {
    if (!_lockAspect || _inSize == null) return;
    final w = int.tryParse(v);
    if (w == null || w <= 0) return;
    final h = (w * _inSize![1] / _inSize![0]).round();
    _heightController.text = '$h';
  }

  Future<void> _resize() async {
    if (_inputBytes == null) {
      showJobSnack(context, 'Pick a photo first');
      return;
    }
    _minKB = int.tryParse(_minCtrl.text) ?? _minKB;
    _maxKB = int.tryParse(_maxCtrl.text) ?? _maxKB;
    if (_maxKB < 5) _maxKB = 5;
    if (_minKB < 0) _minKB = 0;
    if (_minKB > _maxKB) _minKB = _maxKB;

    setState(() {
      _processing = true;
      _stage = ResizeStage.reading;
    });
    try {
      setState(() => _stage = ResizeStage.resizing);
      final out = await ImageBytes.resizeToKb(
        bytes: _inputBytes!,
        targetKB: _maxKB,
        minKB: _minKB,
        targetWidth: int.tryParse(_widthController.text),
        targetHeight: int.tryParse(_heightController.text),
      );
      if (!mounted) return;
      setState(() => _stage = ResizeStage.saving);
      final name = uniqueDocifyName('jpg');
      await GallerySave.saveJpeg(out, name);
      final info = await ImageBytes.info(out);
      if (!mounted) return;
      setState(() {
        _outputBytes = out;
        _outSize = info;
        _savedKb = out.length / 1024;
        _stage = ResizeStage.saved;
      });
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      setState(() => _stage = null);
      final below = out.length < _minKB * 1024;
      showJobSnack(
        context,
        below
            ? 'Saved ${kbLabel(out.length)} — under the $_minKB KB minimum some forms ask for.'
            : 'Saved ${kbLabel(out.length)} to gallery and My Documents',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _stage = null);
      showJobSnack(context, 'Could not save: $e');
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stage = _stage;
    return PopScope(
      canPop: stage == null,
      child: Scaffold(
        appBar: AppBar(title: const Text('Photo Resize')),
        body: stage != null
            ? ResizeShow(stage: stage, photo: _inputBytes, savedKb: _savedKb)
            : _form(),
      ),
    );
  }

  Widget _form() {
    final output = _outputBytes;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const HintBanner(
          'Resize to the KB range a job or exam form asks for. Crop first if you need a passport box. Everything stays on this phone.',
        ),
        const SizedBox(height: 14),
        const SectionLabel('Exam preset'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in ExamPreset.all)
              ChoiceChip(
                label: Text(p.name),
                selected: _presetId == p.id,
                onSelected: (_) => _applyExam(p),
              ),
          ],
        ),
        const SizedBox(height: 14),
        ImagePickBox(bytes: _inputBytes, onTap: _pick),
        if (_inSize != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Original ${_inSize![0]}×${_inSize![1]} px · ${kbLabel(_inputBytes!.length)}',
              style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
            ),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _inputBytes == null ? null : _crop,
                icon: const Icon(Icons.crop_rounded, size: 18),
                label: const Text('Crop'),
              ),
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Lock ratio'),
              selected: _lockAspect,
              onSelected: (v) => setState(() => _lockAspect = v),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const SectionLabel('Target KB'),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _minCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Min KB'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _maxCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Max KB'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        KbChips(
          options: const [20, 50, 100, 200],
          selected: _maxKB,
          onSelect: (kb) {
            setState(() {
              _maxKB = kb;
              _maxCtrl.text = '$kb';
              _presetId = 'custom';
            });
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _widthController,
                onChanged: _onWidth,
                decoration: const InputDecoration(labelText: 'Width px'),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _heightController,
                decoration: const InputDecoration(labelText: 'Height px'),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        PrimaryJobButton(
          label: 'Resize and save',
          onPressed: _resize,
          busy: _processing,
        ),
        if (output != null) ...[
          const SizedBox(height: 16),
          ResultCard(
            label: _outSize == null
                ? 'Saved · ${kbLabel(output.length)}'
                : 'Saved ${_outSize![0]}×${_outSize![1]} px · ${kbLabel(output.length)}',
            onShare: () => ShareBytes.share(
              bytes: output,
              name: 'resized.jpg',
              mime: 'image/jpeg',
            ),
            child: Image.memory(output, height: 160),
          ),
        ],
      ],
    );
  }
}
