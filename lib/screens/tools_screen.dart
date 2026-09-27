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
    final tools = [
      {'title': 'Photo Resize', 'sub': 'Set size & KB', 'icon': Icons.photo_size_select_large, 'color': AppColors.photoResizeCard, 'screen': const PhotoResizeScreen()},
      {'title': 'Passport Photo', 'sub': '35x45, 2x2 inch', 'icon': Icons.person, 'color': AppColors.mergePdfCard, 'screen': const PassportPhotoScreen()},
      {'title': 'Create Signature', 'sub': 'Draw & clean', 'icon': Icons.draw, 'color': AppColors.signatureCard, 'screen': const SignatureScreen()},
      {'title': 'Crop Image', 'sub': 'Custom crop', 'icon': Icons.crop, 'color': AppColors.imageToPdfCard, 'screen': const CropImageScreen()},
      {'title': 'JPG ↔ PNG', 'sub': 'Convert format', 'icon': Icons.swap_horiz, 'color': AppColors.photoResizeCard, 'screen': const JpgPngScreen()},
      {'title': 'Image → PDF', 'sub': 'Multiple images', 'icon': Icons.image, 'color': AppColors.imageToPdfCard, 'screen': const ImageToPdfScreen()},
      {'title': 'Merge PDF', 'sub': 'Combine files', 'icon': Icons.merge, 'color': AppColors.mergePdfCard, 'screen': const MergePdfScreen()},
      {'title': 'Document Scan', 'sub': 'Camera + crop', 'icon': Icons.document_scanner, 'color': AppColors.signatureCard, 'screen': const DocumentScanScreen()},
      {'title': 'CV Builder', 'sub': 'Simple local PDF', 'icon': Icons.article, 'color': AppColors.photoResizeCard, 'screen': const CvBuilderScreen()},
      {'title': 'Job Form Assistant', 'sub': 'Checklist', 'icon': Icons.assignment, 'color': AppColors.jobFormStart, 'screen': const JobFormAssistantScreen()},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('All Tools', style: TextStyle(fontWeight: FontWeight.w700))),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.1, crossAxisSpacing: 12, mainAxisSpacing: 12),
        itemCount: tools.length,
        itemBuilder: (ctx, i) {
          final t = tools[i];
          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => t['screen'] as Widget)),
            child: Container(
              decoration: BoxDecoration(color: t['color'] as Color, borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: Icon(t['icon'] as IconData, color: AppColors.primaryButton)),
                  const Spacer(),
                  Text(t['title'] as String, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(t['sub'] as String, style: const TextStyle(fontSize: 11, color: AppColors.mutedText)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
