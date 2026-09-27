import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'tools/photo_resize_screen.dart';
import 'tools/signature_screen.dart';
import 'tools/image_to_pdf_screen.dart';
import 'tools/merge_pdf_screen.dart';
import 'tools/job_form_assistant_screen.dart';
import 'tools/passport_photo_screen.dart';
import 'tools/crop_image_screen.dart';
import 'tools/jpg_png_screen.dart';
import 'tools/document_scan_screen.dart';
import 'tools/cv_builder_screen.dart';

class HomeScreen extends StatefulWidget {
  /// Switch the bottom tab. 0 home, 1 tools, 2 documents, 3 profile.
  final ValueChanged<int>? onOpenTab;

  const HomeScreen({super.key, this.onOpenTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeTool {
  final String title;
  final String subtitle;
  final String keywords;
  final IconData icon;
  final Color color;
  final Widget? screen;

  const _HomeTool({
    required this.title,
    required this.subtitle,
    required this.keywords,
    required this.icon,
    required this.color,
    this.screen,
  });
}

class _HomeScreenState extends State<HomeScreen> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  String _query = '';

  static const _tools = <_HomeTool>[
    _HomeTool(title: 'Photo Resize', subtitle: 'Set size & KB', keywords: 'resize photo compress kb image', icon: Icons.photo_size_select_large_rounded, color: Color(0xFF2563EB), screen: PhotoResizeScreen()),
    _HomeTool(title: 'Create Signature', subtitle: 'Clean & resize', keywords: 'signature sign draw', icon: Icons.draw_rounded, color: Color(0xFFE11D48), screen: SignatureScreen()),
    _HomeTool(title: 'Image → PDF', subtitle: 'Multiple images', keywords: 'image pdf convert', icon: Icons.image_rounded, color: Color(0xFF16A34A), screen: ImageToPdfScreen()),
    _HomeTool(title: 'Merge PDF', subtitle: 'Combine files', keywords: 'merge pdf combine', icon: Icons.merge_rounded, color: Color(0xFF7C3AED), screen: MergePdfScreen()),
    _HomeTool(title: 'Passport Photo', subtitle: '35x45, 2x2 inch', keywords: 'passport photo size', icon: Icons.person_rounded, color: Color(0xFF7C3AED), screen: PassportPhotoScreen()),
    _HomeTool(title: 'Crop Image', subtitle: 'Custom crop', keywords: 'crop image cut', icon: Icons.crop_rounded, color: Color(0xFFDB2777), screen: CropImageScreen()),
    _HomeTool(title: 'JPG ↔ PNG', subtitle: 'Convert format', keywords: 'jpg png convert', icon: Icons.swap_horiz_rounded, color: Color(0xFFEA580C), screen: JpgPngScreen()),
    _HomeTool(title: 'Document Scan', subtitle: 'Camera capture', keywords: 'scan camera document', icon: Icons.document_scanner_rounded, color: Color(0xFF16A34A), screen: DocumentScanScreen()),
    _HomeTool(title: 'CV Builder', subtitle: 'Simple local PDF', keywords: 'cv resume builder', icon: Icons.article_rounded, color: Color(0xFF059669), screen: CvBuilderScreen()),
    _HomeTool(title: 'Job Form Assistant', subtitle: 'Photo, signature, PDF', keywords: 'job form assistant checklist', icon: Icons.assignment_turned_in_rounded, color: Color(0xFF2563EB), screen: JobFormAssistantScreen()),
  ];

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _open(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _soon(String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$name is coming in the next update.')),
    );
  }

  List<_HomeTool> get _matches {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return _tools.where((t) => '${t.title} ${t.subtitle} ${t.keywords}'.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final matches = _matches;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(),
            const SizedBox(height: 16),
            _hero(),
            const SizedBox(height: 14),
            _searchBar(),
            const SizedBox(height: 18),
            if (_query.trim().isNotEmpty) ...[
              _sectionTitle(Icons.search_rounded, 'Search results', null),
              const SizedBox(height: 8),
              if (matches.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No matching tool. Try “resize”, “PDF”, or “CV”.', style: TextStyle(color: AppColors.mutedText, fontSize: 13)),
                )
              else
                ...matches.map(_resultTile),
            ] else ...[
              _sectionTitle(Icons.bolt_rounded, 'Quick Actions', () => widget.onOpenTab?.call(1), iconColor: const Color(0xFFF59E0B)),
              const SizedBox(height: 10),
              _quickActions(),
              const SizedBox(height: 16),
              _jobBanner(),
              const SizedBox(height: 18),
              _sectionTitle(Icons.grid_view_rounded, 'Tools by Category', () => widget.onOpenTab?.call(1)),
              const SizedBox(height: 10),
              _categories(),
              const SizedBox(height: 18),
              _sectionTitle(Icons.local_fire_department_rounded, 'Popular Tools', () => widget.onOpenTab?.call(1), iconColor: const Color(0xFFF97316)),
              const SizedBox(height: 10),
              _popular(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.asset('assets/images/app_logo.png', width: 46, height: 46, fit: BoxFit.cover),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('JobDoc', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, height: 1.05, color: AppColors.bodyText)),
              Text('Photo, PDF & CV', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, height: 1.15, color: AppColors.titleBlue)),
              SizedBox(height: 2),
              Text('All your document needs in one place', style: TextStyle(fontSize: 11, color: AppColors.mutedText)),
            ],
          ),
        ),
        _roundIcon(Icons.search_rounded, () => _searchFocus.requestFocus()),
        _roundIcon(Icons.notifications_none_rounded, () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No new alerts.')));
        }),
      ],
    );
  }

  Widget _roundIcon(IconData icon, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      icon: Icon(icon, color: AppColors.bodyText, size: 24),
    );
  }

  Widget _hero() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF7FBFF), Color(0xFFE7F0FE), Color(0xFFDCE9FD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              right: -8,
              top: 4,
              bottom: 4,
              width: 168,
              child: Image.asset('assets/images/hero_docs.png', fit: BoxFit.contain, alignment: Alignment.centerRight),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 150, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Get Your', style: TextStyle(fontSize: 20, height: 1.15, fontWeight: FontWeight.w800, color: AppColors.bodyText)),
                  const Text('Job Application', style: TextStyle(fontSize: 20, height: 1.15, fontWeight: FontWeight.w800, color: AppColors.titleBlue)),
                  const Text('Documents Ready', style: TextStyle(fontSize: 20, height: 1.15, fontWeight: FontWeight.w800, color: AppColors.bodyText)),
                  const SizedBox(height: 8),
                  const Text(
                    'Resize photos, create PDFs, make CV and keep your documents safe.',
                    style: TextStyle(fontSize: 12, height: 1.35, color: AppColors.mutedText),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => _open(const JobFormAssistantScreen()),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryButton,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Get Started', style: TextStyle(fontWeight: FontWeight.w700)),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward_rounded, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: TextField(
        controller: _search,
        focusNode: _searchFocus,
        onChanged: (v) => setState(() => _query = v),
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Search tools (e.g. resize photo, merge PDF, create CV...)',
          hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.mutedText),
          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.mutedText),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    _search.clear();
                    setState(() => _query = '');
                  },
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String title, VoidCallback? onSeeAll, {Color? iconColor}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor ?? AppColors.bodyText),
        const SizedBox(width: 6),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.bodyText)),
        const Spacer(),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(foregroundColor: AppColors.titleBlue, visualDensity: VisualDensity.compact),
            child: const Text('See All →', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
      ],
    );
  }

  Widget _quickActions() {
    final cards = [
      _QuickSpec('Photo Resize', 'Set size & KB', AppColors.photoResizeCard, const PhotoResizeScreen(), icon: Icons.image_outlined, iconBg: const Color(0xFF2563EB)),
      _QuickSpec('Create\nSignature', 'Clean & resize', AppColors.signatureCard, const SignatureScreen(), script: true),
      _QuickSpec('Image → PDF', 'Multiple images', AppColors.imageToPdfCard, const ImageToPdfScreen(), icon: Icons.add_photo_alternate_outlined, iconBg: const Color(0xFF16A34A)),
      _QuickSpec('Merge PDF', 'Combine files', AppColors.mergePdfCard, const MergePdfScreen(), icon: Icons.layers_rounded, iconBg: const Color(0xFF7C3AED)),
    ];
    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: _quickCard(cards[i])),
        ],
      ],
    );
  }

  Widget _quickCard(_QuickSpec spec) {
    return Material(
      color: spec.bg,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _open(spec.screen),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
          child: Column(
            children: [
              if (spec.script)
                Text('Jan', style: GoogleFonts.greatVibes(fontSize: 34, height: 0.9, color: const Color(0xFFE11D48)))
              else
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(color: spec.iconBg, borderRadius: BorderRadius.circular(12)),
                  child: Icon(spec.icon, color: Colors.white, size: 22),
                ),
              const SizedBox(height: 8),
              Text(spec.title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, height: 1.15, color: AppColors.bodyText)),
              const SizedBox(height: 2),
              Text(spec.subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: AppColors.mutedText)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _jobBanner() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _open(const JobFormAssistantScreen()),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.jobFormStart, AppColors.jobFormEnd]),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 10, 10),
            child: Row(
              children: [
                SizedBox(
                  width: 108,
                  height: 118,
                  child: Image.asset('assets/images/job_assistant.png', fit: BoxFit.contain, alignment: Alignment.bottomCenter),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Job Form Assistant', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.bodyText)),
                      const SizedBox(height: 4),
                      const Text(
                        'Get photo, signature and documents ready with correct size and format.',
                        style: TextStyle(fontSize: 11, height: 1.3, color: AppColors.mutedText),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: const [
                          _MiniChip('Photo 100KB', AppColors.successChip),
                          _MiniChip('Signature 50KB', Color(0xFF7C3AED)),
                          _MiniChip('PDF Ready', AppColors.primaryButton),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.bodyText),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _categories() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _categoryCard('Photo Tools', 'Resize, compress, crop, convert', Icons.photo_camera_rounded, const Color(0xFF2563EB), AppColors.photoResizeCard, 'assets/images/deco_photo.png', () => widget.onOpenTab?.call(1))),
        const SizedBox(width: 8),
        Expanded(child: _categoryCard('PDF Tools', 'Convert, merge, split, extract', Icons.description_rounded, const Color(0xFFEF4444), AppColors.signatureCard, 'assets/images/deco_pdf.png', () => widget.onOpenTab?.call(1))),
        const SizedBox(width: 8),
        Expanded(child: _categoryCard('CV Builder', 'Create professional resume', Icons.article_rounded, const Color(0xFF16A34A), AppColors.imageToPdfCard, 'assets/images/deco_cv.png', () => _open(const CvBuilderScreen()))),
        const SizedBox(width: 8),
        Expanded(child: _categoryCard('My Documents', 'Save and manage your files', Icons.folder_rounded, const Color(0xFF7C3AED), AppColors.mergePdfCard, 'assets/images/deco_folder.png', () => widget.onOpenTab?.call(2))),
      ],
    );
  }

  Widget _categoryCard(String title, String subtitle, IconData icon, Color iconColor, Color bg, String deco, VoidCallback onTap) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: SizedBox(
          height: 148,
          child: Stack(
            children: [
              Positioned(
                right: -6,
                bottom: -8,
                width: 72,
                height: 56,
                child: Opacity(opacity: 0.9, child: Image.asset(deco, fit: BoxFit.contain)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(color: iconColor, borderRadius: BorderRadius.circular(10)),
                      child: Icon(icon, color: Colors.white, size: 18),
                    ),
                    const Spacer(),
                    Text(title, maxLines: 2, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, height: 1.15, color: AppColors.bodyText)),
                    const SizedBox(height: 2),
                    Text(subtitle, maxLines: 3, style: const TextStyle(fontSize: 9.5, height: 1.2, color: AppColors.mutedText)),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.arrow_forward_rounded, size: 13, color: AppColors.mutedText),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _popular() {
    final items = <_Pop>[
      _Pop(Icons.person_rounded, 'Passport\nPhoto', const Color(0xFF7C3AED), const PassportPhotoScreen()),
      _Pop(Icons.crop_rounded, 'Crop\nImage', const Color(0xFFDB2777), const CropImageScreen()),
      _Pop(Icons.swap_horiz_rounded, 'JPG ↔\nPNG', const Color(0xFFEA580C), const JpgPngScreen()),
      _Pop(Icons.image_rounded, 'PDF →\nImages', const Color(0xFF2563EB), null),
      _Pop(Icons.document_scanner_rounded, 'Document\nScan', const Color(0xFF16A34A), const DocumentScanScreen()),
      _Pop(Icons.compress_rounded, 'Compress\nPDF', const Color(0xFFEF4444), null),
    ];
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(child: _popularTile(items[i])),
        ],
      ],
    );
  }

  Widget _popularTile(_Pop item) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => item.screen == null ? _soon(item.label.replaceAll('\n', ' ')) : _open(item.screen!),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: item.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(item.icon, color: item.color, size: 20),
              ),
              const SizedBox(height: 6),
              Text(item.label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9.5, height: 1.15, fontWeight: FontWeight.w700, color: AppColors.bodyText)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultTile(_HomeTool tool) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: tool.color.withValues(alpha: 0.12), child: Icon(tool.icon, color: tool.color, size: 20)),
        title: Text(tool.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        subtitle: Text(tool.subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_rounded, size: 18),
        onTap: () => tool.screen == null ? null : _open(tool.screen!),
      ),
    );
  }
}

class _QuickSpec {
  final String title;
  final String subtitle;
  final Color bg;
  final Widget screen;
  final IconData? icon;
  final Color? iconBg;
  final bool script;
  const _QuickSpec(this.title, this.subtitle, this.bg, this.screen, {this.icon, this.iconBg, this.script = false});
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniChip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 12, color: color),
          const SizedBox(width: 3),
          Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.bodyText)),
        ],
      ),
    );
  }
}

class _Pop {
  final IconData icon;
  final String label;
  final Color color;
  final Widget? screen;
  const _Pop(this.icon, this.label, this.color, this.screen);
}
