import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:signature/signature.dart';

import '../../models/exam_preset.dart';
import '../../models/requirement_check.dart';
import '../../models/saved_doc.dart';
import '../../services/gallery_save.dart';
import '../../services/image_bytes.dart';
import '../../services/share_bytes.dart';
import '../../theme/app_theme.dart';
import '../../theme/motion.dart';
import '../../widgets/job_progress.dart';
import '../../widgets/requirement_check_card.dart';
import '../../widgets/tool_ui.dart';

class SignatureScreen extends StatefulWidget {
  const SignatureScreen({super.key});

  @override
  State<SignatureScreen> createState() => _SignatureScreenState();
}

class _SignatureScreenState extends State<SignatureScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late SignatureController _pad;
  double _pen = 3;
  bool _blueInk = false;
  bool _transparent = false;
  bool _busy = false;
  JobStage? _stage;
  int _lastTab = 0;
  Uint8List? _photo;
  Uint8List? _output;
  RequirementCheck? _check;
  String _presetId = 'custom';
  int _minKB = 10;
  int _maxKB = 20;
  int _threshold = 168;
  final _wCtrl = TextEditingController();
  final _hCtrl = TextEditingController();
  final _minCtrl = TextEditingController(text: '10');
  final _maxCtrl = TextEditingController(text: '20');

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this)..addListener(_onTabChanged);
    _pad = _makePad();
  }

  Color get _ink => _blueInk ? const Color(0xFF1D4ED8) : Colors.black;

  /// Diameter of the live pen preview dot, mapped from the stroke width.
  double get _penDot => (4 + _pen * 2.4).clamp(4.0, 24.0).toDouble();

  void _onTabChanged() {
    if (_tabs.index == _lastTab) return;
    _lastTab = _tabs.index;
    HapticFeedback.selectionClick();
  }

  String get _stageTitle => _stage == JobStage.done
      ? 'Saved to gallery'
      : (_tabs.index == 0 ? 'Resizing the signature' : 'Cleaning the photo');

  String? get _stageSubtitle => _stage == JobStage.done
      ? (_output == null
          ? null
          : '${kbLabel(_output!.length)} is now in your gallery.')
      : 'Fitting the ink into the KB range you chose, on this phone.';

  SignatureController _makePad([List<Point>? points]) {
    return SignatureController(
      points: points,
      penStrokeWidth: _pen,
      penColor: _ink,
      exportBackgroundColor: _transparent ? Colors.transparent : Colors.white,
    );
  }

  void _syncPad() {
    final strokes = List<Point>.from(_pad.points);
    _pad.dispose();
    _pad = _makePad(strokes);
    setState(() {});
  }

  @override
  void dispose() {
    _tabs.dispose();
    _pad.dispose();
    _wCtrl.dispose();
    _hCtrl.dispose();
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final bytes = await pickPhoto(context);
    if (bytes == null || !mounted) return;
    setState(() {
      _photo = bytes;
      _output = null;
      _check = null;
    });
  }

  void _applyPreset(ExamPreset p) {
    setState(() {
      _presetId = p.id;
      _minKB = p.sigMinKb;
      _maxKB = p.sigMaxKb;
      _minCtrl.text = '${p.sigMinKb}';
      _maxCtrl.text = '${p.sigMaxKb}';
      if (p.sigW != null) _wCtrl.text = '${p.sigW}';
      if (p.sigH != null) _hCtrl.text = '${p.sigH}';
      if (p.id == 'custom') {
        _wCtrl.clear();
        _hCtrl.clear();
      }
    });
  }

  void _readEdits() {
    _minKB = int.tryParse(_minCtrl.text.trim()) ?? _minKB;
    _maxKB = int.tryParse(_maxCtrl.text.trim()) ?? _maxKB;
    if (_maxKB < 1) _maxKB = 1;
    if (_minKB < 0) _minKB = 0;
    if (_minKB > _maxKB) _minKB = _maxKB;
  }

  Future<void> _saveDraw() async {
    if (_pad.isEmpty) {
      showJobSnack(context, 'Draw a signature first');
      return;
    }
    setState(() {
      _busy = true;
      _stage = JobStage.working;
    });
    try {
      final raw = await _pad.toPngBytes();
      if (raw == null) return;
      await _finish(raw, fromPng: true);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          if (_stage == JobStage.working) _stage = null;
        });
      }
    }
  }

  Future<void> _savePhoto() async {
    if (_photo == null) {
      showJobSnack(context, 'Pick a signature photo first');
      return;
    }
    setState(() {
      _busy = true;
      _stage = JobStage.working;
    });
    try {
      final cleaned = await ImageBytes.extractSignature(
        bytes: _photo!,
        threshold: _threshold,
        transparent: _transparent,
        width: int.tryParse(_wCtrl.text),
        height: int.tryParse(_hCtrl.text),
      );
      await _finish(cleaned, fromPng: _transparent);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          if (_stage == JobStage.working) _stage = null;
        });
      }
    }
  }

  Future<void> _finish(Uint8List raw, {required bool fromPng}) async {
    _readEdits();
    final w = int.tryParse(_wCtrl.text.trim());
    final h = int.tryParse(_hCtrl.text.trim());

    Uint8List out;
    if (_transparent) {
      // Transparency only survives in PNG, so this path must never fall into
      // the JPEG encoder - that used to save JPEG bytes under a .png name.
      out = fromPng ? raw : await ImageBytes.toPng(raw);
      final overMax = out.length > _maxKB * 1024;
      final underMin = out.length < _minKB * 1024;
      if (overMax || underMin) {
        out = await ImageBytes.resizeToKb(
          bytes: out,
          targetKB: _maxKB,
          minKB: _minKB,
          targetWidth: w,
          targetHeight: h,
          png: true,
        );
      }
    } else {
      out = await ImageBytes.resizeToKb(
        bytes: raw,
        targetKB: _maxKB,
        minKB: _minKB,
        targetWidth: w,
        targetHeight: h,
      );
    }

    // Name and MIME follow the bytes we actually produced, never a guess.
    final format = ImageBytes.detectFormat(out);
    final info = await ImageBytes.info(out);
    final name = uniqueDocifyName(format == 'png' ? 'png' : 'jpg');
    await GallerySave.saveImage(out, name, mime: mimeFromName(name));
    if (!mounted) return;
    final check = RequirementCheck.forFile(
      title: _transparent ? 'Transparent signature' : 'Signature',
      sizeBytes: out.length,
      spec: FileSpec(
        minKb: _minKB,
        maxKb: _maxKB,
        width: w,
        height: h,
        format: _transparent ? 'png' : 'jpg',
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
    showJobSnack(
      context,
      check.allPassed
          ? 'Saved $name · ${kbLabel(out.length)}'
          : 'Saved $name · ${kbLabel(out.length)} — see the check list',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Signature'),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primaryButton,
          tabs: const [
            Tab(text: 'Draw'),
            Tab(text: 'From photo'),
          ],
        ),
      ),
      body: _stage != null
          ? JobProgressOverlay(
              stage: _stage!,
              title: _stageTitle,
              subtitle: _stageSubtitle,
              photo: _tabs.index == 0 ? null : _photo,
              medallionIcon: Icons.draw_rounded,
              saveIcon: Icons.photo_library_rounded,
              steps: const ['Ink', 'Resize', 'Save'],
            )
          : Column(
              children: [
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [_drawTab(), _photoTab()],
                  ),
                ),
                _controls(),
              ],
            ),
    );
  }

  Widget _drawTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const HintBanner(
          'Draw in black or blue ink. Docify then checks the file against the KB range the form asks for.',
          color: AppColors.signatureCard,
        ),
        const SizedBox(height: 12),
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          clipBehavior: Clip.antiAlias,
          child: Signature(controller: _pad, backgroundColor: Colors.white),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Text('Pen', style: TextStyle(fontWeight: FontWeight.w700)),
            Expanded(
              child: Slider(
                value: _pen,
                min: 1.5,
                max: 8,
                onChanged: (v) {
                  _pen = v;
                  _syncPad();
                },
              ),
            ),
            // Live preview of the stroke the slider is setting.
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              child: AnimatedContainer(
                duration: Motion.of(context, Motion.short),
                curve: Motion.enter,
                width: _penDot,
                height: _penDot,
                decoration: BoxDecoration(color: _ink, shape: BoxShape.circle),
              ),
            ),
            const SizedBox(width: 6),
            ChoiceChip(
              label: const Text('Black'),
              selected: !_blueInk,
              onSelected: (_) {
                HapticFeedback.selectionClick();
                _blueInk = false;
                _syncPad();
              },
            ),
            const SizedBox(width: 6),
            ChoiceChip(
              label: const Text('Blue'),
              selected: _blueInk,
              onSelected: (_) {
                HapticFeedback.selectionClick();
                _blueInk = true;
                _syncPad();
              },
            ),
            const SizedBox(width: 6),
            TextButton(onPressed: _pad.clear, child: const Text('Clear')),
          ],
        ),
        ..._resultSection(),
      ],
    );
  }

  Widget _photoTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const HintBanner(
          'Photograph a signature on white paper. Ink is kept, the page is cleaned to white (or transparent PNG).',
          color: AppColors.signatureCard,
        ),
        const SizedBox(height: 12),
        ImagePickBox(
          bytes: _photo,
          onTap: _pickPhoto,
          empty: 'Pick a signature photo',
          height: 180,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('Ink', style: TextStyle(fontWeight: FontWeight.w700)),
            Expanded(
              child: Slider(
                value: _threshold.toDouble(),
                min: 80,
                max: 220,
                onChanged: (v) => setState(() => _threshold = v.round()),
              ),
            ),
          ],
        ),
        ..._resultSection(),
      ],
    );
  }

  List<Widget> _resultSection() {
    final output = _output;
    final check = _check;
    if (output == null) return const [];
    return [
      const SizedBox(height: 16),
      if (check != null) ...[
        RequirementCheckCard(check: check),
        const SizedBox(height: 12),
      ],
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            SizedBox(height: 90, child: Image.memory(output)),
            const SizedBox(height: 6),
            Text(
              kbLabel(output.length),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: () {
          final ext = ImageBytes.detectFormat(output) == 'png' ? 'png' : 'jpg';
          ShareBytes.share(
            bytes: output,
            name: 'signature.$ext',
            mime: mimeFromName('signature.$ext'),
          );
        },
        icon: const Icon(Icons.share_rounded, size: 16),
        label: const Text('Share'),
      ),
    ];
  }

  Widget _controls() {
    return Material(
      color: Colors.white,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final p in ExamPreset.all) ...[
                      ChoiceChip(
                        label: Text(p.name),
                        selected: _presetId == p.id,
                        onSelected: (_) {
                          HapticFeedback.selectionClick();
                          _applyPreset(p);
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        isDense: true,
                        labelText: 'Min KB',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _maxCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        isDense: true,
                        labelText: 'Max KB',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Transparent'),
                    selected: _transparent,
                    onSelected: (v) {
                      HapticFeedback.selectionClick();
                      _transparent = v;
                      _syncPad();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _wCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        isDense: true,
                        labelText: 'Width px',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _hCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        isDense: true,
                        labelText: 'Height px',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              PrimaryJobButton(
                label: 'Save signature',
                busy: _busy,
                onPressed: () {
                  if (_tabs.index == 0) {
                    _saveDraw();
                  } else {
                    _savePhoto();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Returns PNG bytes of a drawn signature, or null if cancelled.
class CaptureSignaturePage extends StatefulWidget {
  const CaptureSignaturePage({super.key});

  @override
  State<CaptureSignaturePage> createState() => _CaptureSignaturePageState();
}

class _CaptureSignaturePageState extends State<CaptureSignaturePage> {
  final _pad = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  @override
  void dispose() {
    _pad.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Draw signature'),
        actions: [
          TextButton(onPressed: _pad.clear, child: const Text('Clear')),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              clipBehavior: Clip.antiAlias,
              child: Signature(controller: _pad, backgroundColor: Colors.white),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: PrimaryJobButton(
                label: 'Use this signature',
                onPressed: () async {
                  if (_pad.isEmpty) return;
                  final data = await _pad.toPngBytes();
                  if (data == null || !context.mounted) return;
                  Navigator.pop(context, data);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
