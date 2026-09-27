import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/image_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';

class PassportPhotoScreen extends StatefulWidget {
  const PassportPhotoScreen({super.key});

  @override
  State<PassportPhotoScreen> createState() => _PassportPhotoScreenState();
}

class _PassportPhotoScreenState extends State<PassportPhotoScreen> {
  File? _input;
  File? _output;
  String _preset = '35x45 mm';
  final _presets = {
    '35x45 mm': [413, 531], // 300dpi approx
    '2x2 inch': [600, 600],
    '300x300 px': [300, 300],
    '200x230 px': [200, 230],
  };
  bool _processing = false;

  Future<void> _pick() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (x != null) setState(() => _input = File(x.path));
  }

  Future<void> _make() async {
    if (_input == null) return;
    setState(() => _processing = true);
    try {
      final wh = _presets[_preset]!;
      final out = await ImageService.resizeToKB(
        inputFile: _input!,
        targetKB: 100,
        targetWidth: wh[0],
        targetHeight: wh[1],
      );
      final saved = await StorageService.saveToMyDocuments(out);
      setState(() => _output = saved);
    } finally {
      setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Passport Photo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Passport presets - not a government approved claim. Just pixel presets.',
              style: TextStyle(fontSize: 11, color: AppColors.mutedText),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pick,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _input == null
                    ? const Icon(Icons.add_a_photo, size: 40)
                    : Image.file(_input!, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButton<String>(
              value: _preset,
              isExpanded: true,
              items: _presets.keys
                  .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                  .toList(),
              onChanged: (v) => setState(() => _preset = v!),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _processing ? null : _make,
              child: _processing
                  ? const CircularProgressIndicator()
                  : const Text('Make Passport Photo'),
            ),
            if (_output != null) Image.file(_output!, height: 200),
          ],
        ),
      ),
    );
  }
}
