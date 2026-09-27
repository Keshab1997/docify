import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../models/saved_doc.dart';
import '../../services/gallery_save.dart';
import '../../services/image_bytes.dart';
import '../../services/share_bytes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/tool_ui.dart';
import 'crop_image_screen.dart';

class _PassPreset {
  const _PassPreset(this.label, this.w, this.h, this.aspect);
  final String label;
  final int w;
  final int h;
  final double aspect;
}

class PassportPhotoScreen extends StatefulWidget {
  const PassportPhotoScreen({super.key});

  @override
  State<PassportPhotoScreen> createState() => _PassportPhotoScreenState();
}

class _PassportPhotoScreenState extends State<PassportPhotoScreen> {
  static const _presets = [
    _PassPreset('35×45 mm', 413, 531, 35 / 45),
    _PassPreset('2×2 inch', 600, 600, 1),
    _PassPreset('300×300', 300, 300, 1),
    _PassPreset('200×230', 200, 230, 200 / 230),
  ];

  static const _bgs = <(String, int)>[
    ('Original', -1),
    ('White', 0xFFFFFFFF),
    ('Blue', 0xFFB3D4F7),
    ('Red', 0xFFCC1F1F),
  ];

  Uint8List? _input;
  Uint8List? _output;
  int _preset = 0;
  int _bg = 0xFFFFFFFF;
  bool _keepOriginalBg = true;
  int _targetKB = 50;
  bool _busy = false;

  Future<void> _pick() async {
    final bytes = await pickPhoto(context);
    if (bytes == null || !mounted) return;
    final p = _presets[_preset];
    final cropped = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(
        builder: (_) => CropBytesPage(
          image: bytes,
          lockedAspect: p.aspect,
          title: 'Frame the face',
        ),
      ),
    );
    if (!mounted) return;
    setState(() {
      _input = cropped ?? bytes;
      _output = null;
    });
  }

  Future<void> _make() async {
    if (_input == null) {
      showJobSnack(context, 'Pick a photo first');
      return;
    }
    setState(() => _busy = true);
    try {
      final p = _presets[_preset];
      var work = _input!;
      if (!_keepOriginalBg && _bg != -1) {
        work = await ImageBytes.replaceBackground(bytes: work, color: _bg);
      }
      work = await ImageBytes.fitExact(bytes: work, width: p.w, height: p.h);
      final out = await ImageBytes.resizeToKb(
        bytes: work,
        targetKB: _targetKB,
        targetWidth: p.w,
        targetHeight: p.h,
      );
      final name = uniqueJobDocName('jpg');
      await GallerySave.saveJpeg(out, name);
      if (!mounted) return;
      setState(() => _output = out);
      showJobSnack(context, 'Saved $name · ${kbLabel(out.length)}');
    } catch (e) {
      if (!mounted) return;
      showJobSnack(context, 'Could not make photo: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Passport Photo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const HintBanner(
            'Pixel presets at ~300 DPI. This is a preparation tool, not a government-approved photo. White / blue background uses the studio-like corners of the picture.',
            color: AppColors.mergePdfCard,
          ),
          const SizedBox(height: 14),
          ImagePickBox(
            bytes: _output ?? _input,
            onTap: _pick,
            empty: 'Pick, then crop to the frame',
            height: 240,
          ),
          const SizedBox(height: 14),
          const SectionLabel('Size'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _presets.length; i++)
                ChoiceChip(
                  label: Text(_presets[i].label),
                  selected: _preset == i,
                  onSelected: (_) => setState(() => _preset = i),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const SectionLabel('Background'),
          Wrap(
            spacing: 8,
            children: [
              for (final b in _bgs)
                ChoiceChip(
                  label: Text(b.$1),
                  selected: b.$1 == 'Original'
                      ? _keepOriginalBg
                      : (!_keepOriginalBg && _bg == b.$2),
                  onSelected: (_) {
                    setState(() {
                      if (b.$2 == -1) {
                        _keepOriginalBg = true;
                      } else {
                        _keepOriginalBg = false;
                        _bg = b.$2;
                      }
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          const SectionLabel('Target KB'),
          KbChips(
            options: const [20, 50, 100],
            selected: _targetKB,
            onSelect: (v) => setState(() => _targetKB = v),
          ),
          const SizedBox(height: 16),
          PrimaryJobButton(
            label: 'Make passport photo',
            onPressed: _make,
            busy: _busy,
          ),
          if (_output != null) ...[
            const SizedBox(height: 16),
            ResultCard(
              label:
                  '${_presets[_preset].w}×${_presets[_preset].h} px · ${kbLabel(_output!.length)}',
              onShare: () => ShareBytes.share(
                bytes: _output!,
                name: 'passport.jpg',
                mime: 'image/jpeg',
              ),
              child: Image.memory(_output!, height: 180),
            ),
          ],
        ],
      ),
    );
  }
}
