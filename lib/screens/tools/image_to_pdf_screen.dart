import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/pdf_service.dart';
import '../../theme/app_theme.dart';

import 'package:share_plus/share_plus.dart';

class ImageToPdfScreen extends StatefulWidget {
  const ImageToPdfScreen({super.key});

  @override
  State<ImageToPdfScreen> createState() => _ImageToPdfScreenState();
}

class _ImageToPdfScreenState extends State<ImageToPdfScreen> {
  List<File> _images = [];
  File? _pdf;
  bool _processing = false;

  Future<void> _pick() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() => _images = picked.map((e) => File(e.path)).toList());
    }
  }

  Future<void> _create() async {
    if (_images.isEmpty) return;
    setState(() => _processing = true);
    try {
      final pdf = await PdfService.imagesToPdf(_images);
      if (!mounted) return;
      setState(() => _pdf = pdf);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF created in My Documents')),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Image → PDF')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.imageToPdfCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Select multiple images and create a single PDF. All on-device.',
                style: TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _pick, child: const Text('Pick Images')),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _images.length,
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(_images[i], fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _processing ? null : _create,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryButton,
                ),
                child: _processing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Create PDF',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ),
            if (_pdf != null) ...[
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(
                  Icons.picture_as_pdf,
                  color: AppColors.pdfBadge,
                ),
                title: Text(_pdf!.path.split('/').last),
                trailing: IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () => SharePlus.instance
                      .share(ShareParams(files: [XFile(_pdf!.path)])),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
