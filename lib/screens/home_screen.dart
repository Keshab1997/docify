import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/tool_card.dart';
import 'tools/photo_resize_screen.dart';
import 'tools/signature_screen.dart';
import 'tools/image_to_pdf_screen.dart';
import 'tools/merge_pdf_screen.dart';
import 'tools/job_form_assistant_screen.dart';
import 'tools_screen.dart';
import 'tools/passport_photo_screen.dart';
import 'tools/crop_image_screen.dart';
import 'tools/jpg_png_screen.dart';
import 'tools/document_scan_screen.dart';
import 'tools/cv_builder_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryButton,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.description_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('JobDoc', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.bodyText)),
                      Text('Photo, PDF & CV', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.titleBlue)),
                      Text('All your document needs in one place', style: TextStyle(fontSize: 11, color: AppColors.mutedText)),
                    ],
                  ),
                ),
                IconButton(onPressed: () {}, icon: const Icon(Icons.search_rounded)),
                Stack(
                  children: [
                    IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded)),
                    Positioned(
                      right: 8, top: 8,
                      child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Hero Card
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE8F0FE), Color(0xFFF0F7FF)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Get Your', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                        const Text('Job Application', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.titleBlue)),
                        const Text('Documents Ready', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        const Text('Resize photos, create PDFs, make CV and keep your documents safe.',
                          style: TextStyle(fontSize: 12, color: AppColors.mutedText)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JobFormAssistantScreen())),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryButton,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [Text('Get Started'), SizedBox(width: 6), Icon(Icons.arrow_forward, size: 16)],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(child: Icon(Icons.picture_as_pdf_rounded, size: 60, color: AppColors.pdfBadge)),
                        ),
                        const Positioned(top: 0, right: 0, child: Icon(Icons.star, color: Colors.amber, size: 16)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Search pill - no mic per spec
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Search tools (e.g. resize photo, merge PDF, create CV...)',
                  hintStyle: TextStyle(fontSize: 13, color: AppColors.mutedText),
                  border: InputBorder.none,
                  icon: Icon(Icons.search, size: 20),
                ),
              ),
            ),
            const SizedBox(height: 18),
            // Quick Actions
            Row(
              children: [
                const Icon(Icons.bolt, color: Colors.orange, size: 20),
                const SizedBox(width: 6),
                const Text('Quick Actions', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const Spacer(),
                TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ToolsScreen())), child: const Text('See All →', style: TextStyle(fontSize: 12))),
              ],
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                ToolCard(
                  title: 'Photo Resize',
                  subtitle: 'Set size & KB',
                  icon: Icons.photo_size_select_large_rounded,
                  bgColor: AppColors.photoResizeCard,
                  iconColor: AppColors.primaryButton,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PhotoResizeScreen())),
                ),
                ToolCard(
                  title: 'Create Signature',
                  subtitle: 'Clean & resize',
                  icon: Icons.draw_rounded,
                  bgColor: AppColors.signatureCard,
                  iconColor: Colors.pink,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignatureScreen())),
                ),
                ToolCard(
                  title: 'Image → PDF',
                  subtitle: 'Multiple images',
                  icon: Icons.image_rounded,
                  bgColor: AppColors.imageToPdfCard,
                  iconColor: Colors.green,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ImageToPdfScreen())),
                ),
                ToolCard(
                  title: 'Merge PDF',
                  subtitle: 'Combine files',
                  icon: Icons.merge_rounded,
                  bgColor: AppColors.mergePdfCard,
                  iconColor: Colors.deepPurple,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MergePdfScreen())),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Job Form Assistant Banner
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JobFormAssistantScreen())),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.jobFormStart, AppColors.jobFormEnd]),
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.person_pin_rounded, size: 36, color: AppColors.primaryButton),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Job Form Assistant', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                          SizedBox(height: 4),
                          Text('Get photo, signature and documents ready with correct size and format.', style: TextStyle(fontSize: 11, color: AppColors.mutedText)),
                          SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            children: [
                              Chip(label: Text('Photo 100KB', style: TextStyle(fontSize: 10)), backgroundColor: Colors.white, avatar: Icon(Icons.check_circle, size: 14, color: AppColors.successChip)),
                              Chip(label: Text('Signature 50KB', style: TextStyle(fontSize: 10)), backgroundColor: Colors.white, avatar: Icon(Icons.check_circle, size: 14, color: Colors.purple)),
                              Chip(label: Text('PDF Ready', style: TextStyle(fontSize: 10)), backgroundColor: Colors.white, avatar: Icon(Icons.check_circle, size: 14, color: AppColors.primaryButton)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            // Tools by Category
            Row(
              children: [
                const Icon(Icons.grid_view_rounded, size: 20),
                const SizedBox(width: 6),
                const Text('Tools by Category', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const Spacer(),
                TextButton(onPressed: () {}, child: const Text('See All →', style: TextStyle(fontSize: 12))),
              ],
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                CategoryCard(title: 'Photo Tools', subtitle: 'Resize, compress, crop, convert', icon: Icons.camera_alt_rounded, bgColor: AppColors.photoResizeCard, onTap: () {}),
                CategoryCard(title: 'PDF Tools', subtitle: 'Convert, merge, split, extract', icon: Icons.picture_as_pdf_rounded, bgColor: AppColors.signatureCard, onTap: () {}),
                CategoryCard(title: 'CV Builder', subtitle: 'Create professional resume', icon: Icons.article_rounded, bgColor: AppColors.imageToPdfCard, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CvBuilderScreen()))),
                CategoryCard(title: 'My Documents', subtitle: 'Save and manage your files', icon: Icons.folder_rounded, bgColor: AppColors.mergePdfCard, onTap: () {}),
              ],
            ),
            const SizedBox(height: 18),
            // Popular Tools
            Row(
              children: [
                const Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
                const SizedBox(width: 6),
                const Text('Popular Tools', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const Spacer(),
                TextButton(onPressed: () {}, child: const Text('See All →', style: TextStyle(fontSize: 12))),
              ],
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 0.9,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                _popularTool(Icons.person_rounded, 'Passport Photo', Colors.purple, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PassportPhotoScreen()))),
                _popularTool(Icons.crop_rounded, 'Crop Image', Colors.pink, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CropImageScreen()))),
                _popularTool(Icons.swap_horiz_rounded, 'JPG ↔ PNG', Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JpgPngScreen()))),
                _popularTool(Icons.image_rounded, 'PDF → Images', Colors.blue, () {}),
                _popularTool(Icons.document_scanner_rounded, 'Document Scan', Colors.green, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DocumentScanScreen()))),
                _popularTool(Icons.compress_rounded, 'Compress PDF', Colors.red, () {}),
              ],
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _popularTool(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
