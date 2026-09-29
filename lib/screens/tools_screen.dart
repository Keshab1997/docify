import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/animated_reveal.dart';
import '../widgets/pressable.dart';
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
import 'tools/compress_pdf_screen.dart';
import 'tools/pdf_to_images_screen.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const tools = <_Tool>[
      _Tool(
        'Photo Resize',
        'Set size and KB',
        'assets/images/tools/photo_resize.png',
        AppColors.photoResizeCard,
        PhotoResizeScreen(),
      ),
      _Tool(
        'Passport Photo',
        '35x45 and 2x2 inch',
        'assets/images/tools/passport_photo.png',
        AppColors.mergePdfCard,
        PassportPhotoScreen(),
      ),
      _Tool(
        'Create Signature',
        'Draw and resize',
        'assets/images/tools/signature.png',
        AppColors.signatureCard,
        SignatureScreen(),
      ),
      _Tool(
        'Crop Image',
        'Trim the edges',
        'assets/images/tools/crop.png',
        AppColors.imageToPdfCard,
        CropImageScreen(),
      ),
      _Tool(
        'JPG to PNG',
        'Change the format',
        'assets/images/tools/jpg_png.png',
        AppColors.photoResizeCard,
        JpgPngScreen(),
      ),
      _Tool(
        'Image to PDF',
        'Several pictures',
        'assets/images/tools/image_to_pdf.png',
        AppColors.imageToPdfCard,
        ImageToPdfScreen(),
      ),
      _Tool(
        'Merge PDF',
        'Combine files',
        'assets/images/tools/merge_pdf.png',
        AppColors.mergePdfCard,
        MergePdfScreen(),
      ),
      _Tool(
        'Document Scan',
        'Camera capture',
        'assets/images/tools/scan.png',
        AppColors.signatureCard,
        DocumentScanScreen(),
      ),
      _Tool(
        'CV Builder',
        'A simple local PDF',
        'assets/images/tools/cv.png',
        AppColors.imageToPdfCard,
        CvBuilderScreen(),
      ),
      _Tool(
        'Job Form Assistant',
        'One application checklist',
        'assets/images/tools/job_form.png',
        AppColors.jobFormStart,
        JobFormAssistantScreen(),
      ),
      _Tool(
        'Compress PDF',
        'Smaller file size',
        'assets/images/tools/compress_pdf.png',
        AppColors.signatureCard,
        CompressPdfScreen(),
      ),
      _Tool(
        'PDF to Images',
        'Each page as a photo',
        'assets/images/tools/pdf_to_images.png',
        AppColors.photoResizeCard,
        PdfToImagesScreen(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('All tools')),
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.78,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        itemCount: tools.length,
        itemBuilder: (context, i) {
          final t = tools[i];
          void open() => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => t.screen),
              );
          // Reveal the grid in a short stagger, tick on press, and expose one
          // clean node to TalkBack instead of the four texts inside the card.
          return AnimatedReveal(
            index: i,
            child: Pressable(
              child: Semantics(
                button: true,
                label: '${t.title}. ${t.subtitle}',
                onTap: open,
                child:
                    ExcludeSemantics(child: _ToolCard(tool: t, onOpen: open)),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({required this.tool, required this.onOpen});

  final _Tool tool;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.sheet),
        boxShadow: Soft.card,
      ),
      child: Material(
        color: tool.bg,
        borderRadius: BorderRadius.circular(Radii.sheet),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.sheet),
          onTap: onOpen,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, tool.bg],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Center(
                      child: Image.asset(
                        tool.art,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tool.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                      height: 1.15,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    tool.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.25,
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tool {
  final String title;
  final String subtitle;
  final String art;
  final Color bg;
  final Widget screen;
  const _Tool(
    this.title,
    this.subtitle,
    this.art,
    this.bg,
    this.screen,
  );
}
