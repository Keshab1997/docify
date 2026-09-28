import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../models/cv_template_info.dart';
import '../../models/saved_doc.dart';
import '../../services/save_out.dart';
import '../../services/share_bytes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/tool_ui.dart';
import 'cv/cv_form_state.dart';
import 'cv/sections/cv_declaration_section.dart';
import 'cv/sections/cv_education_section.dart';
import 'cv/sections/cv_experience_section.dart';
import 'cv/sections/cv_objective_section.dart';
import 'cv/sections/cv_personal_section.dart';
import 'cv/sections/cv_skills_section.dart';
import 'cv/widgets/cv_design_tab.dart';
import 'cv/widgets/cv_fullscreen_preview.dart';
import 'cv/widgets/cv_progress_header.dart';
import 'cv/widgets/cv_section_tab_bar.dart';
import 'cv/widgets/cv_segmented_tab.dart';
import 'cv/widgets/cv_sticky_action_bar.dart';
import 'cv/cv_section_meta.dart';

/// CV Builder Studio.
///
/// The form is split into one tab per section (see `cv/sections/`) and a final
/// Design tab; tapping a design opens [CvFullScreenPreviewPage] so a template
/// can be judged at full size before it is chosen. All editing state lives in
/// [CvFormState], which is what keeps the tabs from losing typed input.
class CvBuilderScreen extends StatefulWidget {
  const CvBuilderScreen({super.key});

  @override
  State<CvBuilderScreen> createState() => _CvBuilderScreenState();
}

class _CvBuilderScreenState extends State<CvBuilderScreen> {
  final CvFormState _form = CvFormState();

  /// 0 = Edit CV, 1 = Preview.
  int _mode = 0;

  /// Index into the section tabs; [_designTab] is the last one.
  int _section = 0;

  /// One page per form section plus the design grid.
  static final int _designTab = kCvSections.length;

  /// Guards against the tab bar and the page stack drifting apart.
  void _selectTab(int i) {
    if (i < 0 || i > _designTab) return;
    setState(() => _section = i);
  }

  Key _previewKey = UniqueKey();

  Uint8List? _cv;
  String? _cvName;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    await _form.load();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  /// Rebuilds after a field changed so the completeness header stays live.
  void _touch() {
    if (mounted) setState(() {});
  }

  CvTemplateInfo get _activeTemplate =>
      kCvTemplates[_form.template.clamp(0, kCvTemplates.length - 1)];

  List<CvTabItem> get _tabItems => [
        for (var i = 0; i < kCvSections.length; i++)
          CvTabItem(
            label: kCvSections[i].label,
            icon: kCvSections[i].icon,
            done: _form.isSectionDone(i),
          ),
        const CvTabItem(label: 'Design', icon: Icons.palette_rounded),
      ];

  Future<void> _createPdf() async {
    try {
      await _form.persist();
      final bytes = await _form.buildPdf();
      final name =
          'CV_${_form.fileNameStem}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      await SaveOut.pdf(bytes, name);
      if (!mounted) return;
      setState(() {
        _cv = bytes;
        _cvName = name;
      });
      showJobSnack(
          context, '✅ CV saved successfully · ${kbLabel(bytes.length)}');
    } catch (e) {
      if (!mounted) return;
      showJobSnack(context, 'Could not create CV: $e');
    }
  }

  /// Opens the full screen preview, optionally on a specific design, and keeps
  /// the design the user accepted there.
  Future<void> _openFullScreen({int? templateId}) async {
    await _form.persist();
    if (!mounted) return;
    final navigator = Navigator.of(context);
    final chosen = await navigator.push<int>(
      MaterialPageRoute(
        builder: (_) =>
            CvFullScreenPreviewPage(form: _form, templateId: templateId),
      ),
    );
    if (chosen == null || !mounted) return;
    setState(() {
      _form.template = chosen;
      _previewKey = UniqueKey();
    });
    await _form.persist();
  }

  void _selectDesign(int id) {
    setState(() {
      _form.template = id;
      _previewKey = UniqueKey();
    });
    _form.persist();
  }

  void _loadSample() {
    setState(() {
      _form.loadSample();
      _previewKey = UniqueKey();
    });
    _form.persist();
    showJobSnack(context, '✨ Sample CV data loaded!');
  }

  void _clearAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all fields?'),
        content: const Text(
          'Are you sure you want to clear all entered CV information? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _form.clear();
                _cv = null;
                _cvName = null;
                _previewKey = UniqueKey();
              });
              _form.persist();
              showJobSnack(context, 'Form cleared');
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = _activeTemplate;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CV Builder Studio',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            Text(
              'Professional • ATS ready • ${kCvTemplates.length} designs',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        toolbarHeight: 62,
        actions: [
          IconButton(
            tooltip: 'Load Sample',
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.lightBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.auto_fix_high_rounded,
                color: AppColors.titleBlue,
                size: 18,
              ),
            ),
            onPressed: _loadSample,
          ),
          const SizedBox(width: 2),
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Icon(Icons.more_horiz_rounded, size: 18),
            ),
            onSelected: (val) {
              if (val == 'sample') _loadSample();
              if (val == 'clear') _clearAll();
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(
                value: 'sample',
                child: Row(
                  children: [
                    Icon(Icons.auto_fix_high_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Fill Sample Data'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: Colors.red,
                    ),
                    SizedBox(width: 8),
                    Text('Clear All Fields',
                        style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          CvSegmentedTab(
            index: _mode,
            onChanged: (i) {
              if (i == 1) {
                _form.persist();
                setState(() {
                  _mode = 1;
                  _previewKey = UniqueKey();
                });
              } else {
                setState(() => _mode = 0);
              }
            },
          ),
          if (_mode == 0) ...[
            CvProgressHeader(
              completeness: _form.completeness,
              onLoadSample: _loadSample,
            ),
            CvSectionTabBar(
              items: _tabItems,
              index: _section,
              onSelected: _selectTab,
            ),
            const SizedBox(height: 6),
            Expanded(child: _buildSectionPages()),
            if (_cv != null) _buildSavedBanner(),
            CvStickyActionBar(
              active: active,
              onFullScreen: () => _openFullScreen(),
              onCreatePdf: _createPdf,
            ),
          ] else
            Expanded(child: _buildInstantPreview(active)),
        ],
      ),
    );
  }

  Widget _buildSectionPages() {
    return IndexedStack(
      index: _section,
      children: [
        CvPersonalSection(form: _form, onChanged: _touch),
        CvObjectiveSection(form: _form, onChanged: _touch),
        CvEducationSection(form: _form, onChanged: _touch),
        CvExperienceSection(form: _form, onChanged: _touch),
        CvSkillsSection(form: _form, onChanged: _touch),
        CvDeclarationSection(form: _form, onChanged: _touch),
        CvDesignTab(
          selectedId: _form.template,
          onSelect: _selectDesign,
          onPreview: (t) => _openFullScreen(templateId: t.id),
        ),
      ],
    );
  }

  /// Shown after a PDF has been written, so it can be shared without leaving
  /// the builder.
  Widget _buildSavedBanner() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.picture_as_pdf_rounded,
                color: AppColors.pdfBadge,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _cvName ?? 'cv.pdf',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Ready to share • ${kbLabel(_cv!.length)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Share',
              style: IconButton.styleFrom(
                backgroundColor: AppColors.titleBlue,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.share_rounded, size: 18),
              onPressed: () => ShareBytes.share(
                bytes: _cv!,
                name: _cvName ?? 'cv.pdf',
                mime: 'application/pdf',
              ),
            ),
            IconButton(
              tooltip: 'Dismiss',
              icon: const Icon(Icons.close_rounded, size: 18),
              onPressed: () => setState(() {
                _cv = null;
                _cvName = null;
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstantPreview(CvTemplateInfo active) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: active.primaryColor.withValues(alpha: 0.06),
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Icon(active.icon, size: 16, color: active.accentColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Preview — ${active.name}',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: active.primaryColor,
                      ),
                    ),
                    Text(
                      active.subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Full screen',
                icon: const Icon(Icons.fullscreen_rounded, size: 20),
                onPressed: () => _openFullScreen(),
              ),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Refresh', style: TextStyle(fontSize: 11)),
                onPressed: () {
                  _form.persist();
                  setState(() => _previewKey = UniqueKey());
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            color: Colors.grey.shade100,
            child: PdfPreview(
              key: _previewKey,
              build: (format) => _form.buildPdf(),
              canChangePageFormat: false,
              canChangeOrientation: false,
              allowPrinting: true,
              allowSharing: true,
              maxPageWidth: 560,
              pdfFileName: 'CV_${_form.fileNameStem}.pdf',
              loadingWidget: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: active.accentColor),
                    const SizedBox(height: 12),
                    Text(
                      'Rendering ${active.name}…',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('Edit CV'),
                  onPressed: () => setState(() => _mode = 0),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: active.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    icon: const Icon(Icons.save_alt_rounded, size: 18),
                    label: const Text('Save to Device'),
                    onPressed: _createPdf,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
