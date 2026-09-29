import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/requirement_check.dart';
import '../../models/saved_doc.dart';
import '../../services/gallery_save.dart';
import '../../services/image_bytes.dart';
import '../../services/share_bytes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/job_progress.dart';
import '../../widgets/requirement_check_card.dart';
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
  int _minKB = 10;
  RequirementCheck? _check;
  bool _busy = false;
  JobStage? _stage;

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
      _check = null;
    });
  }

  Future<void> _make() async {
    if (_input == null) {
      showJobSnack(context, 'Pick a photo first');
      return;
    }
    setState(() {
      _busy = true;
      _stage = JobStage.working;
    });
    try {
      final p = _presets[_preset];
      var work = _input!;
      var backgroundChanged = true;
      if (!_keepOriginalBg && _bg != -1) {
        final replaced = await ImageBytes.replaceBackgroundDetailed(
          bytes: work,
          color: _bg,
        );
        work = replaced.bytes;
        backgroundChanged = replaced.changed;
      }
      work = await ImageBytes.fitExact(bytes: work, width: p.w, height: p.h);
      final out = await ImageBytes.resizeToKb(
        bytes: work,
        targetKB: _targetKB,
        minKB: _minKB,
        targetWidth: p.w,
        targetHeight: p.h,
      );
      final format = ImageBytes.detectFormat(out);
      final info = await ImageBytes.info(out);
      final name = uniqueJobDocName(format == 'png' ? 'png' : 'jpg');
      if (mounted) setState(() => _stage = JobStage.saving);
      await GallerySave.saveImage(out, name, mime: mimeFromName(name));
      if (!mounted) return;
      final check = RequirementCheck.forFile(
        title: 'Passport photo check',
        sizeBytes: out.length,
        spec: FileSpec(
          minKb: _minKB,
          maxKb: _targetKB,
          width: p.w,
          height: p.h,
          format: 'jpg',
        ),
        width: info[0],
        height: info[1],
        format: format,
      );
      setState(() {
        _output = out;
        _check = check;
        _stage = JobStage.done;
      });
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      setState(() => _stage = null);
      if (!backgroundChanged) {
        showJobSnack(
          context,
          'Saved $name, but the background is not even, so it was left untouched. '
          'White / blue only works on a plain studio background.',
        );
      } else if (check.allPassed) {
        showJobSnack(context, 'Saved $name · ${kbLabel(out.length)}');
      } else {
        showJobSnack(
          context,
          'Saved $name · ${kbLabel(out.length)} — see the check list',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _stage = null);
      showJobSnack(context, 'Could not make photo: $e');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          if (_stage == JobStage.working || _stage == JobStage.saving) {
            _stage = null;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Passport Photo')),
      body: _stage != null
          ? JobProgressOverlay(
              stage: _stage!,
              title: _stage == JobStage.done
                  ? 'Photo ready'
                  : (_stage == JobStage.saving
                      ? 'Saving to gallery'
                      : 'Making the passport photo'),
              subtitle: _stage == JobStage.done
                  ? (_output == null ? null : kbLabel(_output!.length))
                  : (_keepOriginalBg
                      ? 'Fitting the frame and the KB range.'
                      : 'Replacing the background, then fitting the frame.'),
              photo: _output ?? _input,
              medallionIcon: Icons.person_rounded,
              saveIcon: Icons.photo_library_rounded,
              steps: const ['Frame', 'Resize', 'Save'],
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const HintBanner(
                  'Pixel presets at ~300 DPI. This is a preparation tool, not a government-approved photo. White / blue background only works when the picture already has a plain, even background, and JobDoc says so when it could not replace it.',
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
                        avatar: b.$2 == -1
                            ? const Icon(Icons.image_outlined, size: 16)
                            : Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Color(b.$2),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.black12),
                                ),
                              ),
                        label: Text(b.$1),
                        selected: b.$1 == 'Original'
                            ? _keepOriginalBg
                            : (!_keepOriginalBg && _bg == b.$2),
                        onSelected: (_) {
                          HapticFeedback.selectionClick();
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
                const SectionLabel('Maximum KB'),
                KbChips(
                  options: const [20, 50, 100],
                  selected: _targetKB,
                  onSelect: (v) => setState(() => _targetKB = v),
                ),
                const SizedBox(height: 8),
                const SectionLabel('Minimum KB (if the form asks for one)'),
                KbChips(
                  options: const [0, 10, 20],
                  selected: _minKB,
                  onSelect: (v) => setState(() => _minKB = v),
                ),
                const SizedBox(height: 16),
                PrimaryJobButton(
                  label: 'Make passport photo',
                  onPressed: _make,
                  busy: _busy,
                ),
                if (_output != null) ...[
                  const SizedBox(height: 16),
                  if (_check != null) ...[
                    RequirementCheckCard(check: _check!),
                    const SizedBox(height: 12),
                  ],
                  ResultCard(
                    label:
                        '${_presets[_preset].w}×${_presets[_preset].h} px · ${kbLabel(_output!.length)}',
                    onShare: () {
                      final ext = ImageBytes.detectFormat(_output!) == 'png'
                          ? 'png'
                          : 'jpg';
                      ShareBytes.share(
                        bytes: _output!,
                        name: 'passport.$ext',
                        mime: mimeFromName('passport.$ext'),
                      );
                    },
                    child: Image.memory(_output!, height: 180),
                  ),
                ],
              ],
            ),
    );
  }
}
