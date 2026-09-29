import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../models/saved_doc.dart';
import '../../services/gallery_save.dart';
import '../../services/image_bytes.dart';
import '../../services/share_bytes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/job_progress.dart';
import '../../widgets/tool_ui.dart';

class JpgPngScreen extends StatefulWidget {
  const JpgPngScreen({super.key});

  @override
  State<JpgPngScreen> createState() => _JpgPngScreenState();
}

class _JpgPngScreenState extends State<JpgPngScreen> {
  Uint8List? _input;
  Uint8List? _output;
  String? _outName;
  String? _outMime;
  bool _busy = false;
  int _quality = 90;
  JobStage? _stage;
  String _toFormat = 'jpg';

  Future<void> _pick() async {
    final bytes = await pickPhoto(context);
    if (bytes == null || !mounted) return;
    setState(() {
      _input = bytes;
      _output = null;
    });
  }

  Future<void> _convert(String ext) async {
    if (_input == null) return;
    setState(() {
      _busy = true;
      _toFormat = ext;
      _stage = JobStage.working;
    });
    try {
      late Uint8List out;
      late String mime;
      if (ext == 'png') {
        out = await ImageBytes.toPng(_input!);
        mime = 'image/png';
      } else {
        out = await ImageBytes.toJpg(_input!, quality: _quality);
        mime = 'image/jpeg';
      }
      if (!mounted) return;
      setState(() => _stage = JobStage.saving);
      final name = uniqueDocifyName(ext);
      if (ext == 'png') {
        await GallerySave.savePng(out, name);
      } else {
        await GallerySave.saveJpeg(out, name);
      }
      if (!mounted) return;
      setState(() {
        _output = out;
        _outName = name;
        _outMime = mime;
        _stage = JobStage.done;
      });
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      setState(() => _stage = null);
      showJobSnack(context, 'Saved $name · ${kbLabel(out.length)}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _stage = null);
      showJobSnack(context, 'Could not convert: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String get _stageTitle => switch (_stage) {
        JobStage.saving => 'Saving to gallery',
        JobStage.done => 'Saved to gallery',
        _ => _toFormat == 'png' ? 'Making a PNG' : 'Making a JPG',
      };

  String? get _stageSubtitle => switch (_stage) {
        JobStage.saving => 'Putting the finished image in your gallery.',
        JobStage.done => _output == null
            ? null
            : '${kbLabel(_output!.length)} is now in your gallery.',
        _ => _toFormat == 'png'
            ? 'Keeping every sharp edge and any transparency.'
            : 'Compressing at quality $_quality.',
      };

  @override
  Widget build(BuildContext context) {
    final stage = _stage;
    return Scaffold(
      appBar: AppBar(title: const Text('JPG ↔ PNG')),
      body: stage != null
          ? JobProgressOverlay(
              stage: stage,
              title: _stageTitle,
              subtitle: _stageSubtitle,
              photo: _input,
              medallionIcon: Icons.image_rounded,
              saveIcon: Icons.photo_library_rounded,
              steps: const ['Read', 'Convert', 'Save'],
            )
          : _form(),
    );
  }

  Widget _form() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const HintBanner(
          'Change format on this phone. JPG is smaller. PNG keeps sharp edges and transparency.',
          color: AppColors.photoResizeCard,
        ),
        const SizedBox(height: 14),
        ImagePickBox(bytes: _input, onTap: _pick),
        if (_input != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Source · ${kbLabel(_input!.length)}',
              style: const TextStyle(color: AppColors.mutedText),
            ),
          ),
        const SizedBox(height: 12),
        const SectionLabel('JPG quality'),
        Slider(
          value: _quality.toDouble(),
          min: 40,
          max: 95,
          divisions: 11,
          label: '$_quality',
          onChanged: (v) => setState(() => _quality = v.round()),
        ),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: _busy ? null : () => _convert('jpg'),
                child: const Text('To JPG'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.tonal(
                onPressed: _busy ? null : () => _convert('png'),
                child: const Text('To PNG'),
              ),
            ),
          ],
        ),
        if (_output != null) ...[
          const SizedBox(height: 16),
          ResultCard(
            label: '${_outName ?? ''} · ${kbLabel(_output!.length)}',
            onShare: () => ShareBytes.share(
              bytes: _output!,
              name: _outName ?? 'converted',
              mime: _outMime ?? 'image/jpeg',
            ),
            child: Image.memory(_output!, height: 160),
          ),
        ],
      ],
    );
  }
}
