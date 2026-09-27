import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/image_service.dart';
import '../../services/storage_service.dart';

class JpgPngScreen extends StatefulWidget {
  const JpgPngScreen({super.key});

  @override
  State<JpgPngScreen> createState() => _JpgPngScreenState();
}

class _JpgPngScreenState extends State<JpgPngScreen> {
  File? _input;
  File? _output;

  Future<void> _pick() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (x != null) setState(() => _input = File(x.path));
  }

  Future<void> _convert(String ext) async {
    if (_input == null) return;
    final out = await ImageService.convertFormat(_input!, ext);
    final saved = await StorageService.saveToMyDocuments(out);
    setState(() => _output = saved);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('JPG ↔ PNG')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(onTap: _pick, child: Container(height: 200, width: double.infinity, color: Colors.white, child: _input == null ? const Icon(Icons.add_photo_alternate, size: 40) : Image.file(_input!))),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: ElevatedButton(onPressed: () => _convert('jpg'), child: const Text('To JPG'))),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(onPressed: () => _convert('png'), child: const Text('To PNG'))),
              ],
            ),
            if (_output != null) ...[
              const SizedBox(height: 12),
              Image.file(_output!, height: 150),
              Text('Saved: ${_output!.path.split('/').last}'),
            ],
          ],
        ),
      ),
    );
  }
}
