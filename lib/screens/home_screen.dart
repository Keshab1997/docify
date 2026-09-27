import 'package:flutter/material.dart';
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
    _HomeTool(title: 'Create Signature', subtitle: 'Draw & resize', keywords: 'signature sign draw', icon: Icons.draw_rounded, color: Color(0xFFE11D48), screen: SignatureScreen()),
    _HomeTool(title: 'Image to PDF', subtitle: 'Multiple images', keywords: 'image pdf convert', icon: Icons.image_rounded, color: Color(0xFF16A34A), screen: ImageToPdfScreen()),
    _HomeTool(title: 'Merge PDF', subtitle: 'Combine files', keywords: 'merge pdf combine', icon: Icons.merge_rounded, color: Color(0xFF7C3AED), screen: MergePdfScreen()),
    _HomeTool(title: 'Passport Photo', subtitle: '35x45, 2x2 inch', keywords: 'passport photo size', icon: Icons.person_rounded, color: Color(0xFF7C3AED), screen: PassportPhotoScreen()),
    _HomeTool(title: 'Crop Image', subtitle: 'Custom crop', keywords: 'crop image cut', icon: Icons.crop_rounded, color: Color(0xFFDB2777), screen: CropImageScreen()),
    _HomeTool(title: 'JPG to PNG', subtitle: 'Convert format', keywords: 'jpg png convert', icon: Icons.swap_horiz_rounded, color: Color(0xFFEA580C), screen: JpgPngScreen()),
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

  void _open(Widget screen) => Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  void _soon(String name) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$name is coming in the next update.')));
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
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(),
            const SizedBox(height: 16),
            _hero(),
            const SizedBox(height: 14),
            _searchBar(),
            const SizedBox(height: 20),
            if (_query.trim().isNotEmpty) ...[
              _section('Search', null),
              const SizedBox(height: 10),
              if (matches.isEmpty)
                const Text('No matching tool. Try resize, PDF, or CV.', style: TextStyle(color: AppColors.mutedText, fontSize: 13))
              else
                ...matches.map(_resultTile),
            ] else ...[
              _section('Quick Actions', () => widget.onOpenTab?.call(1), icon: Icons.bolt_rounded, iconColor: const Color(0xFFF59E0B)),
              const SizedBox(height: 12),
              _quickGrid(),
              const SizedBox(height: 16),
              _jobBanner(),
              const SizedBox(height: 22),
              _section('Tools by Category', () => widget.onOpenTab?.call(1), icon: Icons.grid_view_rounded),
              const SizedBox(height: 12),
              _categoryGrid(),
              const SizedBox(height: 22),
              _section('Popular Tools', () => widget.onOpenTab?.call(1), icon: Icons.local_fire_department_rounded, iconColor: const Color(0xFFF97316)),
              const SizedBox(height: 12),
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
        Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), boxShadow: Soft.card),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset('assets/images/app_logo.png', width: 48, height: 48, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('JobDoc', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 21, height: 1.05, color: AppColors.bodyText, letterSpacing: -0.3)),
              Text('Photo, PDF & CV', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, height: 1.2, color: AppColors.titleBlue)),
              SizedBox(height: 2),
              Text('All your document needs in one place', style: TextStyle(fontSize: 11.5, color: AppColors.mutedText)),
            ],
          ),
        ),
        _iconBtn(Icons.search_rounded, () => _searchFocus.requestFocus()),
        _iconBtn(Icons.notifications_none_rounded, () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No new alerts.')));
        }),
      ],
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      icon: Icon(icon, color: AppColors.bodyText, size: 24),
    );
  }

  Widget _hero() {
    return Container(
      height: 196,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF8FBFF), Color(0xFFE8F1FE), Color(0xFFD7E6FD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: Soft.card,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned(
              right: -6,
              top: 8,
              bottom: 0,
              width: 168,
              child: Image.asset('assets/images/hero_docs.png', fit: BoxFit.contain, alignment: Alignment.bottomRight),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 148, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Get Your', style: TextStyle(fontSize: 19, height: 1.15, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                  const Text('Job Application', style: TextStyle(fontSize: 19, height: 1.15, fontWeight: FontWeight.w800, color: AppColors.titleBlue, letterSpacing: -0.3)),
                  const Text('Documents Ready', style: TextStyle(fontSize: 19, height: 1.15, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                  const SizedBox(height: 8),
                  const Text(
                    'Resize photos, create PDFs, make a CV and keep files on your phone.',
                    style: TextStyle(fontSize: 12, height: 1.35, color: AppColors.mutedText),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => _open(const JobFormAssistantScreen()),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Get Started'),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: Soft.card),
      child: TextField(
        controller: _search,
        focusNode: _searchFocus,
        onChanged: (v) => setState(() => _query = v),
        style: const TextStyle(fontSize: 13.5),
        decoration: InputDecoration(
          hintText: 'Search tools, like resize photo or CV',
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
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _section(String title, VoidCallback? onSeeAll, {IconData? icon, Color? iconColor}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: iconColor ?? AppColors.bodyText),
          const SizedBox(width: 6),
        ],
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, letterSpacing: -0.2)),
        const Spacer(),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(foregroundColor: AppColors.titleBlue, visualDensity: VisualDensity.compact, padding: const EdgeInsets.symmetric(horizontal: 8)),
            child: const Text('See all', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ),
      ],
    );
  }

  Widget _quickGrid() {
    const cards = [
      _Quick('Photo Resize', 'Set size and KB', AppColors.photoResizeCard, PhotoResizeScreen(), Icons.image_outlined, Color(0xFF2563EB)),
      _Quick('Create Signature', 'Draw and resize', AppColors.signatureCard, SignatureScreen(), Icons.draw_rounded, Color(0xFFE11D48), script: true),
      _Quick('Image to PDF', 'Several pictures', AppColors.imageToPdfCard, ImageToPdfScreen(), Icons.add_photo_alternate_outlined, Color(0xFF16A34A)),
      _Quick('Merge PDF', 'Combine files', AppColors.mergePdfCard, MergePdfScreen(), Icons.layers_rounded, Color(0xFF7C3AED)),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: [for (final c in cards) _quickCard(c)],
    );
  }

  Widget _quickCard(_Quick spec) {
    return Material(
      color: spec.bg,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _open(spec.screen),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Row(
            children: [
              if (spec.script)
                const SizedBox(width: 46, height: 46, child: _SignatureMark())
              else
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(color: spec.iconBg, borderRadius: BorderRadius.circular(14)),
                  child: Icon(spec.icon, color: Colors.white, size: 24),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(spec.title, maxLines: 2, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, height: 1.15)),
                    const SizedBox(height: 3),
                    Text(spec.subtitle, style: const TextStyle(fontSize: 11.5, color: AppColors.mutedText)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _jobBanner() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _open(const JobFormAssistantScreen()),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFFF7F2), Color(0xFFFFF0F6)]),
            borderRadius: BorderRadius.circular(24),
            boxShadow: Soft.card,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 8, 12, 8),
            child: Row(
              children: [
                SizedBox(
                  width: 112,
                  height: 128,
                  child: Image.asset('assets/images/job_assistant.png', fit: BoxFit.contain, alignment: Alignment.bottomCenter),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Job Form Assistant', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: -0.2)),
                      const SizedBox(height: 4),
                      const Text(
                        'Photo, signature and PDF, sized for one application. Stays on this phone.',
                        style: TextStyle(fontSize: 12, height: 1.35, color: AppColors.mutedText),
                      ),
                      const SizedBox(height: 10),
                      const Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _MiniChip('Photo 100KB', AppColors.successChip),
                          _MiniChip('Sign 50KB', Color(0xFF7C3AED)),
                          _MiniChip('PDF ready', AppColors.primaryButton),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_forward_rounded, size: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _categoryGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: [
        _category('Photo Tools', 'Resize, crop, convert', Icons.photo_camera_rounded, const Color(0xFF2563EB), AppColors.photoResizeCard, 'assets/images/deco_photo.png', () => widget.onOpenTab?.call(1)),
        _category('PDF Tools', 'Convert and merge', Icons.description_rounded, const Color(0xFFEF4444), AppColors.signatureCard, 'assets/images/deco_pdf.png', () => widget.onOpenTab?.call(1)),
        _category('CV Builder', 'A simple local resume', Icons.article_rounded, const Color(0xFF16A34A), AppColors.imageToPdfCard, 'assets/images/deco_cv.png', () => _open(const CvBuilderScreen())),
        _category('My Documents', 'Files saved in the app', Icons.folder_rounded, const Color(0xFF7C3AED), AppColors.mergePdfCard, 'assets/images/deco_folder.png', () => widget.onOpenTab?.call(2)),
      ],
    );
  }

  Widget _category(String title, String subtitle, IconData icon, Color iconColor, Color bg, String deco, VoidCallback onTap) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Stack(
          children: [
            Positioned(
              right: -4,
              bottom: -6,
              width: 78,
              height: 64,
              child: Image.asset(deco, fit: BoxFit.contain),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(color: iconColor, borderRadius: BorderRadius.circular(11)),
                        child: Icon(icon, color: Colors.white, size: 18),
                      ),
                      const Spacer(),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.mutedText),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: -0.2)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11.5, color: AppColors.mutedText)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _popular() {
    final items = <_Pop>[
      _Pop(Icons.person_rounded, 'Passport', const Color(0xFF7C3AED), const PassportPhotoScreen()),
      _Pop(Icons.crop_rounded, 'Crop', const Color(0xFFDB2777), const CropImageScreen()),
      _Pop(Icons.swap_horiz_rounded, 'JPG PNG', const Color(0xFFEA580C), const JpgPngScreen()),
      _Pop(Icons.image_rounded, 'PDF images', const Color(0xFF2563EB), null),
      _Pop(Icons.document_scanner_rounded, 'Scan', const Color(0xFF16A34A), const DocumentScanScreen()),
      _Pop(Icons.compress_rounded, 'Compress', const Color(0xFFEF4444), null),
    ];
    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final item = items[i];
          return SizedBox(
            width: 92,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => item.screen == null ? _soon(item.label) : _open(item.screen!),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: item.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                        child: Icon(item.icon, color: item.color, size: 22),
                      ),
                      const Spacer(),
                      Text(item.label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _resultTile(_HomeTool tool) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          leading: CircleAvatar(backgroundColor: tool.color.withValues(alpha: 0.12), child: Icon(tool.icon, color: tool.color, size: 20)),
          title: Text(tool.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          subtitle: Text(tool.subtitle, style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
          trailing: const Icon(Icons.arrow_forward_rounded, size: 18),
          onTap: tool.screen == null ? null : () => _open(tool.screen!),
        ),
      ),
    );
  }
}

class _Quick {
  final String title;
  final String subtitle;
  final Color bg;
  final Widget screen;
  final IconData icon;
  final Color iconBg;
  final bool script;
  const _Quick(this.title, this.subtitle, this.bg, this.screen, this.icon, this.iconBg, {this.script = false});
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniChip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
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

class _SignatureMark extends StatelessWidget {
  const _SignatureMark();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _SigPainter());
  }
}

class _SigPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE11D48)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(size.width * 0.08, size.height * 0.62)
      ..cubicTo(size.width * 0.22, size.height * 0.15, size.width * 0.18, size.height * 0.9, size.width * 0.42, size.height * 0.48)
      ..cubicTo(size.width * 0.55, size.height * 0.22, size.width * 0.5, size.height * 0.78, size.width * 0.92, size.height * 0.4);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
