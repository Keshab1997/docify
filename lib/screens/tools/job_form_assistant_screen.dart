import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/image_service.dart';
import '../../services/pdf_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';

import 'package:share_plus/share_plus.dart';

class JobFormAssistantScreen extends StatefulWidget {
  const JobFormAssistantScreen({super.key});

  @override
  State<JobFormAssistantScreen> createState() => _JobFormAssistantScreenState();
}

class _JobFormAssistantScreenState extends State<JobFormAssistantScreen> {
  File? _photo;
  File? _photoResized;
  File? _sig;
  File? _sigResized;
  File? _pdf;
  bool _processing = false;

  Future<void> _pickPhoto() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (x != null) setState(() => _photo = File(x.path));
  }

  Future<void> _pickSig() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (x != null) setState(() => _sig = File(x.path));
  }

  Future<void> _process() async {
    if (_photo == null || _sig == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick photo and signature first')),
      );
      return;
    }
    setState(() => _processing = true);
    try {
      final pResized = await ImageService.resizeToKB(
        inputFile: _photo!,
        targetKB: 100,
      );
      final sResized = await ImageService.resizeToKB(
        inputFile: _sig!,
        targetKB: 50,
      );
      final savedP = await StorageService.saveToMyDocuments(pResized);
      final savedS = await StorageService.saveToMyDocuments(sResized);
      setState(() {
        _photoResized = savedP;
        _sigResized = savedS;
      });
      // Create PDF combining
      final pdf = await PdfService.imagesToPdf([
        savedP,
        savedS,
      ], fileName: 'JobForm_${DateTime.now().millisecondsSinceEpoch}.pdf');
      setState(() => _pdf = pdf);
    } finally {
      setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Job Form Assistant')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.jobFormStart, AppColors.jobFormEnd],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Get photo, signature and documents ready with correct size and format.',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Photo 100KB, Signature 50KB, PDF Ready checklist for one application. No upload, all on-device.',
                    style: TextStyle(fontSize: 11, color: AppColors.mutedText),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _stepCard(
              '1. Photo',
              '100KB target',
              _photo,
              _photoResized,
              _pickPhoto,
            ),
            const SizedBox(height: 12),
            _stepCard(
              '2. Signature',
              '50KB target',
              _sig,
              _sigResized,
              _pickSig,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _processing ? null : _process,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryButton,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _processing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Prepare All',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ),
            if (_pdf != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.successChip,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_pdf!.path.split('/').last)),
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: () => SharePlus.instance
                          .share(ShareParams(files: [XFile(_pdf!.path)])),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stepCard(
    String title,
    String target,
    File? input,
    File? output,
    VoidCallback pick,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              Chip(
                label: Text(target, style: const TextStyle(fontSize: 10)),
                backgroundColor: AppColors.photoResizeCard,
              ),
              const Spacer(),
              Icon(
                output != null ? Icons.check_circle : Icons.circle_outlined,
                color: output != null ? AppColors.successChip : Colors.grey,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              GestureDetector(
                onTap: pick,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: input == null
                      ? const Icon(Icons.add_a_photo)
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(input, fit: BoxFit.cover),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              if (output != null)
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(output, fit: BoxFit.cover),
                  ),
                ),
              const Spacer(),
              ElevatedButton(onPressed: pick, child: const Text('Pick')),
            ],
          ),
        ],
      ),
    );
  }
}
