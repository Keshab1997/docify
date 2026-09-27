import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../../services/gallery_save.dart';
import '../../services/image_bytes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/resize_show.dart';
import '../../widgets/tier_labels.dart';

class PhotoResizeScreen extends StatefulWidget {
  const PhotoResizeScreen({super.key});

  @override
  State<PhotoResizeScreen> createState() => _PhotoResizeScreenState();
}

class _PhotoResizeScreenState extends State<PhotoResizeScreen> {
  Uint8List? _inputBytes;
  Uint8List? _outputBytes;
  int _targetKB = 100;
  bool _processing = false;
  ResizeStage? _stage;
  double? _savedKb;

  final _kbOptions = [20, 50, 100, 200];
  final _customKb = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  String _preset = 'Original';

  @override
  void dispose() {
    _customKb.dispose();
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _applyPreset(String preset) {
    setState(() {
      _preset = preset;
      if (preset == '35×45 mm') {
        _widthController.text = '413';
        _heightController.text = '531';
        _targetKB = 100;
      } else if (preset == '2×2 inch') {
        _widthController.text = '600';
        _heightController.text = '600';
        _targetKB = 100;
      } else {
        _widthController.clear();
        _heightController.clear();
      }
    });
  }

  Future<void> _pick() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (x == null) return;
    final bytes = await x.readAsBytes();
    if (!mounted) return;
    setState(() {
      _inputBytes = bytes;
      _outputBytes = null;
      _savedKb = null;
    });
  }

  Future<void> _resize() async {
    if (_inputBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a photo first')),
      );
      return;
    }
    final custom = int.tryParse(_customKb.text);
    if (custom != null && custom > 0) _targetKB = custom;

    setState(() {
      _processing = true;
      _stage = ResizeStage.reading;
    });
    try {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      setState(() => _stage = ResizeStage.resizing);
      final out = await ImageBytes.resizeToKb(
        bytes: _inputBytes!,
        targetKB: _targetKB,
        targetWidth: int.tryParse(_widthController.text),
        targetHeight: int.tryParse(_heightController.text),
      );
      if (!mounted) return;
      setState(() => _stage = ResizeStage.saving);
      final name = 'JobDoc_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await Future.wait([
        GallerySave.saveJpeg(out, name),
        Future<void>.delayed(const Duration(milliseconds: 1700)),
      ]);
      if (!mounted) return;
      setState(() {
        _outputBytes = out;
        _savedKb = out.length / 1024;
        _stage = ResizeStage.saved;
      });
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      setState(() => _stage = null);
    } catch (e) {
      if (!mounted) return;
      setState(() => _stage = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $e')),
      );
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
        appBar: AppBar(
          title: Text(
            stage == null ? 'Photo Resize' : 'Photo Resize',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        body: stage != null
            ? ResizeShow(stage: stage, photo: _inputBytes, savedKb: _savedKb)
            : _form(),
      ),
    );
  }

  Widget _form() {
    final output = _outputBytes;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A2B4A), Color(0xFF0B1220)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0x66E8C872)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PremiumAdvancedLabels(),
                SizedBox(height: 10),
                Text(
                  'Photo Resize',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Pick a photo, choose the size, then watch it process and save to your gallery.',
                  style: TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _pick,
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: _inputBytes == null
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate, size: 40),
                        SizedBox(height: 8),
                        Text('Tap to pick a photo'),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.memory(_inputBytes!, fit: BoxFit.contain),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Form size',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final preset in ['Original', '35×45 mm', '2×2 inch'])
                ChoiceChip(
                  label: Text(preset),
                  selected: _preset == preset,
                  onSelected: (_) => _applyPreset(preset),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Target KB',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          Wrap(
            spacing: 8,
            children: [
              ..._kbOptions.map(
                (kb) => ChoiceChip(
                  label: Text('${kb}KB'),
                  selected: _targetKB == kb,
                  onSelected: (_) => setState(() => _targetKB = kb),
                ),
              ),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _customKb,
                  decoration: const InputDecoration(
                    hintText: 'Custom KB',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _widthController,
                  decoration: const InputDecoration(
                    labelText: 'Width px (optional)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _heightController,
                  decoration: const InputDecoration(
                    labelText: 'Height px (optional)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _processing ? null : _resize,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryButton,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Resize and save to gallery',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          if (output != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Image.memory(output, height: 150),
                  const SizedBox(height: 8),
                  Text(
                    'Saved to gallery · ${(output.length / 1024).toStringAsFixed(1)} KB',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => SharePlus.instance.share(
                        ShareParams(
                          files: [
                            XFile.fromData(
                              output,
                              mimeType: 'image/jpeg',
                              name: 'resized.jpg',
                            ),
                          ],
                        ),
                      ),
                      child: const Text('Share'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
