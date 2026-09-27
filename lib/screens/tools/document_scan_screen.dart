import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/storage_service.dart';

class DocumentScanScreen extends StatefulWidget {
  const DocumentScanScreen({super.key});

  @override
  State<DocumentScanScreen> createState() => _DocumentScanScreenState();
}

class _DocumentScanScreenState extends State<DocumentScanScreen> {
  File? _image;

  Future<void> _capture() async {
    final x = await ImagePicker().pickImage(source: ImageSource.camera);
    if (x != null) {
      final file = File(x.path);
      final saved = await StorageService.saveToMyDocuments(file);
      setState(() => _image = saved);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Document Scan')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Camera capture and crop, on your phone. No server upload.', style: TextStyle(fontSize: 11)),
            const SizedBox(height: 16),
            Container(height: 300, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: _image == null ? const Center(child: Text('No scan yet')) : Image.file(_image!)),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _capture, child: const Text('Capture Document'))),
          ],
        ),
      ),
    );
  }
}
