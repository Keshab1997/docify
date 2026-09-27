import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crop_your_image/crop_your_image.dart';
import '../../services/storage_service.dart';
import 'dart:typed_data';

class CropImageScreen extends StatefulWidget {
  const CropImageScreen({super.key});

  @override
  State<CropImageScreen> createState() => _CropImageScreenState();
}

class _CropImageScreenState extends State<CropImageScreen> {
  File? _input;
  Uint8List? _imageBytes;
  final _cropController = CropController();
  File? _output;

  Future<void> _pick() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (x != null) {
      final file = File(x.path);
      final bytes = await file.readAsBytes();
      setState(() { _input = file; _imageBytes = bytes; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crop Image')),
      body: Column(
        children: [
          Expanded(
            child: _imageBytes == null
                ? Center(child: ElevatedButton(onPressed: _pick, child: const Text('Pick Image')))
                : Crop(image: _imageBytes!, controller: _cropController, onCropped: (cropped) async {
                    final dir = await StorageService.getAppDocsDir();
                    final path = '${dir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg';
                    final file = File(path)..writeAsBytesSync(cropped);
                    final saved = await StorageService.saveToMyDocuments(file);
                    setState(() => _output = saved);
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cropped saved')));
                  }),
          ),
          if (_imageBytes != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ElevatedButton(onPressed: _pick, child: const Text('Pick Another')),
                  const SizedBox(width: 12),
                  ElevatedButton(onPressed: () => _cropController.crop(), child: const Text('Crop & Save')),
                ],
              ),
            ),
          if (_output != null) Image.file(_output!, height: 120),
        ],
      ),
    );
  }
}
