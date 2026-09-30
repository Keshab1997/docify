import 'package:flutter/material.dart';

import '../app_info.dart';
import '../theme/app_theme.dart';
import '../tools/tool_registry.dart';
import '../widgets/animated_reveal.dart';
import '../widgets/pressable.dart';

/// How Home asks the shell to switch tabs: a tab index, plus an optional
/// tool group when a category card deep-links into a filtered Tools grid.
typedef OpenTab = void Function(int index, {ToolGroup? group});

class HomeScreen extends StatefulWidget {
  final OpenTab? onOpenTab;

  const HomeScreen({super.key, this.onOpenTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  String _query = '';
  List<ToolSpec> _recent = const [];

  /// The four shortcuts under Quick Actions.
  static const _quickIds = [
    'photo-resize',
    'create-signature',
    'image-to-pdf',
    'merge-pdf',
  ];

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _loadRecent() async {
    final items = await ToolRegistry.recent(limit: 6);
    if (!mounted) return;
    setState(() => _recent = items);
  }

  Future<void> _open(ToolSpec tool) async {
    await tool.open(context);
    if (!mounted) return;
    await _loadRecent();
  }

  ToolSpec _tool(String id) {
    final t = ToolRegistry.byId(id);
    if (t == null) {
      throw StateError('ToolRegistry is missing "$id"');
    }
    return t;
  }

  List<ToolSpec> get _matches => ToolRegistry.search(_query);

  @override
  Widget build(BuildContext context) {
    final matches = _matches;
    final strip = _recent.isNotEmpty
        ? _recent
        : ToolRegistry.byIds(ToolRegistry.popularIds);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Space.lg, 10, Space.lg, Space.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(),
            const SizedBox(height: Space.lg),
            _hero(),
            const SizedBox(height: 14),
            _searchBar(),
            const SizedBox(height: Space.xl),
            if (_query.trim().isNotEmpty) ...[
              _section('Search', null),
              const SizedBox(height: Space.sm),
              if (matches.isEmpty)
                const Text(
                  'No matching tool. Try resize, PDF, or CV.',
                  style: TextStyle(color: AppColors.mutedText, fontSize: 13),
                )
              else
                ...matches.map(_resultTile),
            ] else ...[
              _section(
                'Quick Actions',
                () => widget.onOpenTab?.call(1),
                icon: Icons.bolt_rounded,
                iconColor: const Color(0xFFF59E0B),
              ),
              const SizedBox(height: Space.md),
              _quickGrid(),
              const SizedBox(height: Space.lg),
              _jobBanner(),
              const SizedBox(height: 22),
              _section(
                'Tools by Category',
                () => widget.onOpenTab?.call(1),
                icon: Icons.grid_view_rounded,
              ),
              const SizedBox(height: Space.md),
              _categoryGrid(),
              const SizedBox(height: 22),
              _section(
                _recent.isEmpty ? 'Popular Tools' : 'Recently used',
                () => widget.onOpenTab?.call(1),
                icon: _recent.isEmpty
                    ? Icons.local_fire_department_rounded
                    : Icons.history_rounded,
                iconColor: _recent.isEmpty
                    ? const Color(0xFFF97316)
                    : AppColors.primaryButton,
              ),
              const SizedBox(height: Space.md),
              _toolStrip(strip),
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
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.field),
            boxShadow: Soft.card,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Radii.field),
            child: Image.asset(
              'assets/images/app_logo.png',
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: Space.md),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                kAppShortName,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 21,
                  height: 1.05,
                  color: AppColors.bodyText,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                kAppDescriptor,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  height: 1.2,
                  color: AppColors.titleBlue,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'All your document needs in one place',
                style: TextStyle(fontSize: 11.5, color: AppColors.mutedText),
              ),
            ],
          ),
        ),
        // Full 48dp target - no compact density, so TalkBack and thumbs
        // get the same button the guideline asks for.
        IconButton(
          onPressed: () => _searchFocus.requestFocus(),
          tooltip: 'Search',
          icon: const Icon(
            Icons.search_rounded,
            color: AppColors.bodyText,
            size: 24,
          ),
        ),
      ],
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
        borderRadius: BorderRadius.circular(Radii.shell),
        boxShadow: Soft.card,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.shell),
        child: Stack(
          children: [
            Positioned(
              right: -6,
              top: 8,
              bottom: 0,
              width: 168,
              child: Image.asset(
                'assets/images/hero_docs.png',
                fit: BoxFit.contain,
                alignment: Alignment.bottomRight,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 148, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Get Your',
                    style: TextStyle(
                      fontSize: 19,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Text(
                    'Job Application',
                    style: TextStyle(
                      fontSize: 19,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.titleBlue,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Text(
                    'Documents Ready',
                    style: TextStyle(
                      fontSize: 19,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: Space.sm),
                  const Text(
                    'Resize photos, create PDFs, make a CV and keep files on your phone.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: AppColors.mutedText,
                    ),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => _open(_tool('job-form-assistant')),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Radii.shell),
        boxShadow: Soft.card,
      ),
      child: TextField(
        controller: _search,
        focusNode: _searchFocus,
        onChanged: (v) => setState(() => _query = v),
        style: const TextStyle(fontSize: 13.5),
        decoration: InputDecoration(
          hintText: 'Search tools, like resize photo or CV',
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 20,
            color: AppColors.mutedText,
          ),
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

  Widget _section(
    String title,
    VoidCallback? onSeeAll, {
    IconData? icon,
    Color? iconColor,
  }) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: iconColor ?? AppColors.bodyText),
          const SizedBox(width: 6),
        ],
        Text(title, style: AppText.title),
        const Spacer(),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.titleBlue,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: Space.sm),
            ),
            child: const Text(
              'See all',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
      ],
    );
  }

  Widget _quickGrid() {
    final cards = [for (final id in _quickIds) _tool(id)];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: Space.md,
      crossAxisSpacing: Space.md,
      childAspectRatio: 1.55,
      children: [
        for (var i = 0; i < cards.length; i++)
          AnimatedReveal(index: i, child: _quickCard(cards[i])),
      ],
    );
  }

  Widget _quickCard(ToolSpec tool) {
    // The signature card keeps its hand-drawn mark instead of a glyph;
    // everything else shows the registry icon on the group ink.
    final body = Material(
      color: tool.tint,
      borderRadius: BorderRadius.circular(Radii.nav),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.nav),
        onTap: () => _open(tool),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.lg, Space.lg, Space.lg, 14),
          child: Row(
            children: [
              if (tool.id == 'create-signature')
                const SizedBox(width: 46, height: 46, child: _SignatureMark())
              else
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: tool.color,
                    borderRadius: BorderRadius.circular(Radii.chip),
                  ),
                  child: Icon(tool.icon, color: Colors.white, size: 24),
                ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      tool.title,
                      maxLines: 2,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tool.subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.mutedText,
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
    return Pressable(
      child: Semantics(
        button: true,
        label: '${tool.title}. ${tool.subtitle}',
        onTap: () => _open(tool),
        child: ExcludeSemantics(child: body),
      ),
    );
  }

  Widget _jobBanner() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(Radii.sheet),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.sheet),
        onTap: () => _open(_tool('job-form-assistant')),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF7F2), Color(0xFFFFF0F6)],
            ),
            borderRadius: BorderRadius.circular(Radii.sheet),
            boxShadow: Soft.card,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 8, Space.md, 8),
            child: Row(
              children: [
                SizedBox(
                  width: 112,
                  height: 128,
                  child: Image.asset(
                    'assets/images/job_assistant.png',
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomCenter,
                  ),
                ),
                const SizedBox(width: Space.xs),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Job Form Assistant',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(height: Space.xs),
                      Text(
                        'Photo, signature and PDF, sized for one application. Stays on this phone.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: AppColors.mutedText,
                        ),
                      ),
                      SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _MiniChip('Photo 100KB', AppColors.successChip),
                          _MiniChip('Sign 50KB', AppColors.assistantInk),
                          _MiniChip('PDF ready', AppColors.primaryButton),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
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
      mainAxisSpacing: Space.md,
      crossAxisSpacing: Space.md,
      childAspectRatio: 1.35,
      children: [
        // Photo and PDF land on the Tools grid pre-filtered to their group.
        _category(
          'Photo Tools',
          'Resize, crop, convert',
          Icons.photo_camera_rounded,
          ToolGroup.photo.color,
          ToolGroup.photo.tint,
          'assets/images/deco_photo.png',
          () => widget.onOpenTab?.call(1, group: ToolGroup.photo),
        ),
        _category(
          'PDF Tools',
          'Convert and merge',
          Icons.description_rounded,
          ToolGroup.pdf.color,
          ToolGroup.pdf.tint,
          'assets/images/deco_pdf.png',
          () => widget.onOpenTab?.call(1, group: ToolGroup.pdf),
        ),
        _category(
          'CV Builder',
          'A simple local resume',
          Icons.article_rounded,
          ToolGroup.cv.color,
          ToolGroup.cv.tint,
          'assets/images/deco_cv.png',
          () => _open(_tool('cv-builder')),
        ),
        _category(
          'My Documents',
          'Files saved in the app',
          Icons.folder_rounded,
          ToolGroup.assistant.color,
          ToolGroup.assistant.tint,
          'assets/images/deco_folder.png',
          () => widget.onOpenTab?.call(2),
        ),
      ],
    );
  }

  Widget _category(
    String title,
    String subtitle,
    IconData icon,
    Color iconColor,
    Color bg,
    String deco,
    VoidCallback onTap,
  ) {
    final body = Material(
      color: bg,
      borderRadius: BorderRadius.circular(Radii.nav),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.nav),
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
              padding: const EdgeInsets.all(Space.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: iconColor,
                          borderRadius: BorderRadius.circular(Radii.sm + 3),
                        ),
                        child: Icon(icon, color: Colors.white, size: 18),
                      ),
                      const Spacer(),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: AppColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return Pressable(
      child: Semantics(
        button: true,
        label: '$title. $subtitle',
        onTap: onTap,
        child: ExcludeSemantics(child: body),
      ),
    );
  }

  Widget _toolStrip(List<ToolSpec> items) {
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
              borderRadius: BorderRadius.circular(Radii.card),
              child: InkWell(
                borderRadius: BorderRadius.circular(Radii.card),
                onTap: () => _open(item),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.sm,
                    vertical: 12,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(Radii.field),
                        ),
                        child: Icon(item.icon, color: item.color, size: 22),
                      ),
                      const Spacer(),
                      Text(
                        item.short,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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

  Widget _resultTile(ToolSpec tool) {
    final body = Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Radii.field),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.field),
          ),
          onTap: () => _open(tool),
          leading: CircleAvatar(
            backgroundColor: tool.color.withValues(alpha: 0.12),
            child: Icon(tool.icon, color: tool.color, size: 20),
          ),
          title: Text(
            tool.title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          subtitle: Text(
            tool.subtitle,
            style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
          ),
          trailing: const Icon(Icons.arrow_forward_rounded, size: 18),
        ),
      ),
    );
    return Pressable(child: body);
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniChip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 12, color: color),
          const SizedBox(width: Space.xs),
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
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
      ..color = AppColors.signatureInk
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(size.width * 0.08, size.height * 0.62)
      ..cubicTo(
        size.width * 0.22,
        size.height * 0.15,
        size.width * 0.18,
        size.height * 0.9,
        size.width * 0.42,
        size.height * 0.48,
      )
      ..cubicTo(
        size.width * 0.55,
        size.height * 0.22,
        size.width * 0.5,
        size.height * 0.78,
        size.width * 0.92,
        size.height * 0.4,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
