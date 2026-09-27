import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/pdf_service.dart';
import '../../theme/app_theme.dart';
import 'package:share_plus/share_plus.dart';

class CvBuilderScreen extends StatefulWidget {
  const CvBuilderScreen({super.key});

  @override
  State<CvBuilderScreen> createState() => _CvBuilderScreenState();
}

class _CvBuilderScreenState extends State<CvBuilderScreen> {
  final _name = TextEditingController(text: 'Keshab Sarkar');
  final _email = TextEditingController(text: 'keshab@example.com');
  final _phone = TextEditingController(text: '+91 9XXXXXXXXX');
  final _education = TextEditingController(text: 'BCA - University\n12th - WBCHSE');
  final _experience = TextEditingController(text: 'Flutter Developer - 2 years\nBuilt 5 apps');
  final _skills = TextEditingController(text: 'Flutter, Dart, Firebase, REST API');
  File? _cv;
  bool _processing = false;

  Future<void> _create() async {
    setState(() => _processing = true);
    try {
      final file = await PdfService.createSimpleCV(
        name: _name.text,
        email: _email.text,
        phone: _phone.text,
        education: _education.text,
        experience: _experience.text,
        skills: _skills.text,
      );
      setState(() => _cv = file);
    } finally {
      setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CV Builder')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.imageToPdfCard, borderRadius: BorderRadius.circular(12)), child: const Text('Simple local PDF, no account. Text stays on device.', style: TextStyle(fontSize: 12))),
            const SizedBox(height: 12),
            _field(_name, 'Full Name'),
            _field(_email, 'Email'),
            _field(_phone, 'Phone'),
            _field(_education, 'Education', maxLines: 3),
            _field(_experience, 'Experience', maxLines: 3),
            _field(_skills, 'Skills', maxLines: 2),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _processing ? null : _create, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryButton), child: _processing ? const CircularProgressIndicator(color: Colors.white) : const Text('Create CV PDF', style: TextStyle(color: Colors.white)))),
            if (_cv != null) ...[
              const SizedBox(height: 12),
              ListTile(leading: const Icon(Icons.picture_as_pdf, color: AppColors.pdfBadge), title: Text(_cv!.path.split('/').last), trailing: IconButton(icon: const Icon(Icons.share), onPressed: () => Share.shareXFiles([XFile(_cv!.path)]))),
            ],
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(controller: c, maxLines: maxLines, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder())),
    );
  }
}
