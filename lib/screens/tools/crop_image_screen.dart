import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';

import '../../models/saved_doc.dart';
import '../../services/gallery_save.dart';
import '../../services/image_bytes.dart';
import '../../services/share_bytes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/tool_ui.dart';

class CropImageScreen extends StatefulWidget {
  const CropImageScreen({super.key});

  @override
  State<CropImageScreen> createState() => _CropImageScreenState();
}

class _CropImageScreenState extends State<CropImageScreen> {
  Uint8List? _input;
  Uint8List? _output;
  bool _busy = false;

  Future<void> _pick() async {
    final bytes = await pickPhoto(context);
    if (bytes == null || !mounted) return;
    final cropped = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(builder: (_) => CropBytesPage(image: bytes)),
    );
    if (cropped == null || !mounted) return;
    setState(() {
      _input = bytes;
      _output = cropped;
    });
  }

  Future<void> _recrop() async {
    final src = _output ?? _input;
    if (src == null) return;
    final cropped = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(builder: (_) => CropBytesPage(image: src)),
    );
    if (cropped == null || !mounted) return;
    setState(() => _output = cropped);
  }

  Future<void> _save() async {
    final out = _output;
    if (out == null) return;
    setState(() => _busy = true);
    try {
      // Name the file after the bytes we actually got from the cropper.
      final format = ImageBytes.detectFormat(out);
      final name = uniqueJobDocName(format == 'png' ? 'png' : 'jpg');
      await GallerySave.saveImage(out, name, mime: mimeFromName(name));
      if (!mounted) return;
      showJobSnack(context, 'Saved $name · ${kbLabel(out.length)}');
    } catch (e) {
      if (!mounted) return;
      showJobSnack(context, 'Could not save: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crop Image')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const HintBanner(
            'Trim edges with a locked ratio for forms: 35×45, 1:1 or free crop. Rotate if the photo is sideways.',
            color: AppColors.imageToPdfCard,
          ),
          const SizedBox(height: 16),
          ImagePickBox(
            bytes: _output ?? _input,
            onTap: _pick,
            empty: 'Tap to pick, then crop',
            height: 280,
          ),
          const SizedBox(height: 16),
          if (_output != null) ...[
            Text(
              'Cropped · ${kbLabel(_output!.length)}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _output == null ? null : _recrop,
                  child: const Text('Crop again'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _output == null || _busy ? null : _save,
                  child: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save'),
                ),
              ),
            ],
          ),
          if (_output != null) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => ShareBytes.share(
                bytes: _output!,
                name: 'cropped.jpg',
                mime: 'image/jpeg',
              ),
              icon: const Icon(Icons.share_rounded),
              label: const Text('Share'),
            ),
          ],
        ],
      ),
    );
  }
}

class CropBytesPage extends StatefulWidget {
  const CropBytesPage({
    super.key,
    required this.image,
    this.lockedAspect,
    this.title = 'Crop',
  });

  final Uint8List image;
  final double? lockedAspect;
  final String title;

  @override
  State<CropBytesPage> createState() => _CropBytesPageState();
}

class _CropBytesPageState extends State<CropBytesPage> {
  final _controller = CropController();
  late Uint8List _bytes;
  late double? _aspect;
  bool _busy = false;

  static const _presets = <(String, double?)>[
    ('Free', null),
    ('1:1', 1),
    ('35:45', 35 / 45),
    ('2:2', 1),
    ('3:4', 3 / 4),
    ('4:3', 4 / 3),
  ];

  @override
  void initState() {
    super.initState();
    _bytes = widget.image;
    _aspect = widget.lockedAspect;
  }

  Future<void> _rotate() async {
    setState(() => _busy = true);
    try {
      final next = await ImageBytes.rotate90(_bytes);
      if (!mounted) return;
      setState(() => _bytes = next);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onCropped(Uint8List cropped) {
    Navigator.pop(context, cropped);
  }

  @override
  Widget build(BuildContext context) {
    final lock = widget.lockedAspect != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'Rotate',
            onPressed: _busy ? null : _rotate,
            icon: const Icon(Icons.rotate_90_degrees_cw_rounded),
          ),
          TextButton(
            onPressed: () => _controller.crop(),
            child: const Text('Done'),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!lock)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Row(
                children: [
                  for (final p in _presets) ...[
                    ChoiceChip(
                      label: Text(p.$1),
                      selected:
                          _aspect == p.$2 || (p.$1 == '1:1' && _aspect == 1),
                      onSelected: (_) {
                        setState(() => _aspect = p.$2);
                        _controller.aspectRatio = p.$2;
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          Expanded(
            child: ColoredBox(
              color: const Color(0xFF0B1220),
              child: _busy
                  ? const Center(child: CircularProgressIndicator())
                  : Crop(
                      key: ValueKey(_bytes.length),
                      image: _bytes,
                      controller: _controller,
                      aspectRatio: _aspect,
                      onCropped: _onCropped,
                    ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: PrimaryJobButton(
                label: 'Crop',
                onPressed: () => _controller.crop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
