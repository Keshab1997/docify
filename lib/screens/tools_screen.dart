import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'tools/photo_resize_screen.dart';
import 'tools/passport_photo_screen.dart';
import 'tools/signature_screen.dart';
import 'tools/crop_image_screen.dart';
import 'tools/jpg_png_screen.dart';
import 'tools/image_to_pdf_screen.dart';
import 'tools/merge_pdf_screen.dart';
import 'tools/document_scan_screen.dart';
import 'tools/cv_builder_screen.dart';
import 'tools/job_form_assistant_screen.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const tools = <_Tool>[
      _Tool('Photo Resize', 'Set size and KB', Icons.photo_size_select_large_rounded, Color(0xFF2563EB), AppColors.photoResizeCard, PhotoResizeScreen()),
      _Tool('Passport Photo', '35x45 and 2x2 inch', Icons.person_rounded, Color(0xFF7C3AED), AppColors.mergePdfCard, PassportPhotoScreen()),
      _Tool('Create Signature', 'Draw and resize', Icons.draw_rounded, Color(0xFFE11D48), AppColors.signatureCard, SignatureScreen()),
      _Tool('Crop Image', 'Trim the edges', Icons.crop_rounded, Color(0xFFDB2777), AppColors.imageToPdfCard, CropImageScreen()),
      _Tool('JPG to PNG', 'Change the format', Icons.swap_horiz_rounded, Color(0xFFEA580C), AppColors.photoResizeCard, JpgPngScreen()),
      _Tool('Image to PDF', 'Several pictures', Icons.image_rounded, Color(0xFF16A34A), AppColors.imageToPdfCard, ImageToPdfScreen()),
      _Tool('Merge PDF', 'Combine files', Icons.merge_rounded, Color(0xFF7C3AED), AppColors.mergePdfCard, MergePdfScreen()),
      _Tool('Document Scan', 'Camera capture', Icons.document_scanner_rounded, Color(0xFF059669), AppColors.signatureCard, DocumentScanScreen()),
      _Tool('CV Builder', 'A simple local PDF', Icons.article_rounded, Color(0xFF16A34A), AppColors.imageToPdfCard, CvBuilderScreen()),
      _Tool('Job Form Assistant', 'One application checklist', Icons.assignment_turned_in_rounded, Color(0xFF2563EB), AppColors.jobFormStart, JobFormAssistantScreen()),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('All tools')),
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.28,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: tools.length,
        itemBuilder: (context, i) {
          final t = tools[i];
          return Material(
            color: t.bg,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => t.screen)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                      child: Icon(t.icon, color: t.color),
                    ),
                    const Spacer(),
                    Text(t.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, letterSpacing: -0.2)),
                    const SizedBox(height: 2),
                    Text(t.subtitle, style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Tool {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color bg;
  final Widget screen;
  const _Tool(this.title, this.subtitle, this.icon, this.color, this.bg, this.screen);
}
