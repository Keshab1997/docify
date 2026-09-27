import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/pdf_service.dart';
import '../../theme/app_theme.dart';
import 'package:share_plus/share_plus.dart';

class MergePdfScreen extends StatefulWidget {
  const MergePdfScreen({super.key});

  @override
  State<MergePdfScreen> createState() => _MergePdfScreenState();
}

class _MergePdfScreenState extends State<MergePdfScreen> {
  List<File> _pdfs = [];
  File? _merged;
  bool _processing = false;

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true, type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null) {
      setState(() => _pdfs = result.paths.map((p) => File(p!)).toList());
    }
  }

  Future<void> _merge() async {
    if (_pdfs.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pick at least 2 PDFs')));
      return;
    }
    setState(() => _processing = true);
    try {
      final out = await PdfService.mergePdfs(_pdfs);
      setState(() => _merged = out);
    } finally {
      setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Merge PDF')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.mergePdfCard, borderRadius: BorderRadius.circular(12)), child: const Text('Combine multiple PDFs into one. On-device.', style: TextStyle(fontSize: 12))),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _pick, child: const Text('Pick PDFs')),
            const SizedBox(height: 12),
            Expanded(child: ListView.builder(itemCount: _pdfs.length, itemBuilder: (_, i) => ListTile(leading: const Icon(Icons.picture_as_pdf), title: Text(_pdfs[i].path.split('/').last)))),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _processing ? null : _merge, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryButton), child: _processing ? const CircularProgressIndicator(color: Colors.white) : const Text('Merge', style: TextStyle(color: Colors.white)))),
            if (_merged != null) ListTile(leading: const Icon(Icons.picture_as_pdf, color: AppColors.pdfBadge), title: Text(_merged!.path.split('/').last), trailing: IconButton(icon: const Icon(Icons.share), onPressed: () => Share.shareXFiles([XFile(_merged!.path)]))),
          ],
        ),
      ),
    );
  }
}
