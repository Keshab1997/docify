import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/tools/compress_pdf_screen.dart';
import '../screens/tools/crop_image_screen.dart';
import '../screens/tools/cv_builder_screen.dart';
import '../screens/tools/document_scan_screen.dart';
import '../screens/tools/image_to_pdf_screen.dart';
import '../screens/tools/job_form_assistant_screen.dart';
import '../screens/tools/jpg_png_screen.dart';
import '../screens/tools/merge_pdf_screen.dart';
import '../screens/tools/passport_photo_screen.dart';
import '../screens/tools/pdf_to_images_screen.dart';
import '../screens/tools/photo_resize_screen.dart';
import '../screens/tools/signature_screen.dart';
import '../theme/app_theme.dart';

/// The visual family a tool belongs to.
///
/// Every surface - Home, the Tools grid, search results, category cards -
/// paints a tool with its group's [color] and [tint], so the same tool can
/// never wear two different colours on two different screens.
enum ToolGroup { photo, signature, pdf, cv, assistant }

extension ToolGroupLook on ToolGroup {
  String get label => switch (this) {
        ToolGroup.photo => 'Photo',
        ToolGroup.signature => 'Signature',
        ToolGroup.pdf => 'PDF',
        ToolGroup.cv => 'CV',
        ToolGroup.assistant => 'Assistant',
      };

  /// Ink colour for icons, chips and accents.
  Color get color => switch (this) {
        ToolGroup.photo => AppColors.primaryButton,
        ToolGroup.signature => AppColors.signatureInk,
        ToolGroup.pdf => AppColors.pdfBadge,
        ToolGroup.cv => AppColors.successChip,
        ToolGroup.assistant => AppColors.assistantInk,
      };

  /// Pastel card background. The names of the older entries predate the
  /// grouping - the values are the same ones the app has always used.
  Color get tint => switch (this) {
        ToolGroup.photo => AppColors.photoResizeCard,
        ToolGroup.signature => AppColors.signatureCard,
        ToolGroup.pdf => AppColors.pdfTint,
        ToolGroup.cv => AppColors.imageToPdfCard,
        ToolGroup.assistant => AppColors.mergePdfCard,
      };
}

/// One tool, as the UI knows it: where it lives, what it looks like, how to
/// open it. Home, the Tools grid and search all read from [ToolRegistry.all]
/// instead of each keeping their own copy of this data.
class ToolSpec {
  const ToolSpec({
    required this.id,
    required this.title,
    required this.short,
    required this.subtitle,
    required this.keywords,
    required this.icon,
    required this.art,
    required this.group,
    required this.screen,
  });

  /// Stable id, also used as the key for "Recently used".
  final String id;
  final String title;
  final String subtitle;

  /// One-word label for the horizontal chips strip.
  final String short;
  final String keywords;
  final IconData icon;

  /// Asset path of the illustration on the Tools grid card.
  final String art;
  final ToolGroup group;
  final Widget screen;

  Color get color => group.color;
  Color get tint => group.tint;

  /// Opens the tool, recording the visit for Home's "Recently used" strip.
  ///
  /// Returns the push future so callers can refresh when the user comes back.
  Future<void> open(BuildContext context) {
    unawaited(ToolRegistry.markUsed(id));
    return Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}

/// The single source of truth for the twelve tools.
class ToolRegistry {
  const ToolRegistry._();

  /// Display order is the grouped order: Photo, Signature, PDF, CV,
  /// Assistant — the same sequence as the [ToolGroup] enum and the filter
  /// chips. Every unfiltered surface (the "All" grid, search results)
  /// shows this list as-is, so keep each group's tools in one block and
  /// add new tools inside their group, never at the end blindly.
  static const List<ToolSpec> all = [
    // ── Photo ─────────────────────────────────────────────────────────
    ToolSpec(
      id: 'photo-resize',
      title: 'Photo Resize',
      short: 'Resize',
      subtitle: 'Set size and KB',
      keywords: 'resize photo compress kb image',
      icon: Icons.photo_size_select_large_rounded,
      art: 'assets/images/tools/photo_resize.png',
      group: ToolGroup.photo,
      screen: PhotoResizeScreen(),
    ),
    ToolSpec(
      id: 'passport-photo',
      title: 'Passport Photo',
      short: 'Passport',
      subtitle: '35x45 and 2x2 inch',
      keywords: 'passport photo size',
      icon: Icons.person_rounded,
      art: 'assets/images/tools/passport_photo.png',
      group: ToolGroup.photo,
      screen: PassportPhotoScreen(),
    ),
    ToolSpec(
      id: 'crop-image',
      title: 'Crop Image',
      short: 'Crop',
      subtitle: 'Trim the edges',
      keywords: 'crop image cut',
      icon: Icons.crop_rounded,
      art: 'assets/images/tools/crop.png',
      group: ToolGroup.photo,
      screen: CropImageScreen(),
    ),
    ToolSpec(
      id: 'jpg-to-png',
      title: 'JPG to PNG',
      short: 'JPG PNG',
      subtitle: 'Change the format',
      keywords: 'jpg png convert',
      icon: Icons.swap_horiz_rounded,
      art: 'assets/images/tools/jpg_png.png',
      group: ToolGroup.photo,
      screen: JpgPngScreen(),
    ),
    // ── Signature ─────────────────────────────────────────────────────
    ToolSpec(
      id: 'create-signature',
      title: 'Create Signature',
      short: 'Sign',
      subtitle: 'Draw and resize',
      keywords: 'signature sign draw',
      icon: Icons.draw_rounded,
      art: 'assets/images/tools/signature.png',
      group: ToolGroup.signature,
      screen: SignatureScreen(),
    ),
    // ── PDF ───────────────────────────────────────────────────────────
    ToolSpec(
      id: 'image-to-pdf',
      title: 'Image to PDF',
      short: 'To PDF',
      subtitle: 'Several pictures',
      keywords: 'image pdf convert',
      icon: Icons.image_rounded,
      art: 'assets/images/tools/image_to_pdf.png',
      group: ToolGroup.pdf,
      screen: ImageToPdfScreen(),
    ),
    ToolSpec(
      id: 'merge-pdf',
      title: 'Merge PDF',
      short: 'Merge',
      subtitle: 'Combine files',
      keywords: 'merge pdf combine',
      icon: Icons.merge_rounded,
      art: 'assets/images/tools/merge_pdf.png',
      group: ToolGroup.pdf,
      screen: MergePdfScreen(),
    ),
    ToolSpec(
      id: 'document-scan',
      title: 'Document Scan',
      short: 'Scan',
      subtitle: 'Camera capture',
      keywords: 'scan camera document',
      icon: Icons.document_scanner_rounded,
      art: 'assets/images/tools/scan.png',
      group: ToolGroup.pdf,
      screen: DocumentScanScreen(),
    ),
    ToolSpec(
      id: 'compress-pdf',
      title: 'Compress PDF',
      short: 'Compress',
      subtitle: 'Smaller file size',
      keywords: 'compress pdf shrink',
      icon: Icons.compress_rounded,
      art: 'assets/images/tools/compress_pdf.png',
      group: ToolGroup.pdf,
      screen: CompressPdfScreen(),
    ),
    ToolSpec(
      id: 'pdf-to-images',
      title: 'PDF to Images',
      short: 'PDF images',
      subtitle: 'Each page as a photo',
      keywords: 'pdf images pages jpg',
      icon: Icons.collections_rounded,
      art: 'assets/images/tools/pdf_to_images.png',
      group: ToolGroup.pdf,
      screen: PdfToImagesScreen(),
    ),
    // ── CV ────────────────────────────────────────────────────────────
    ToolSpec(
      id: 'cv-builder',
      title: 'CV Builder',
      short: 'CV',
      subtitle: 'A simple local resume',
      keywords: 'cv resume builder',
      icon: Icons.article_rounded,
      art: 'assets/images/tools/cv.png',
      group: ToolGroup.cv,
      screen: CvBuilderScreen(),
    ),
    // ── Assistant ─────────────────────────────────────────────────────
    ToolSpec(
      id: 'job-form-assistant',
      title: 'Job Form Assistant',
      short: 'Job Form',
      subtitle: 'One application checklist',
      keywords: 'job form assistant checklist ssc ibps',
      icon: Icons.assignment_turned_in_rounded,
      art: 'assets/images/tools/job_form.png',
      group: ToolGroup.assistant,
      screen: JobFormAssistantScreen(),
    ),
  ];

  /// Home's strip order until the user has built up a history of their own.
  static const List<String> popularIds = [
    'passport-photo',
    'crop-image',
    'jpg-to-png',
    'pdf-to-images',
    'document-scan',
    'compress-pdf',
  ];

  static ToolSpec? byId(String id) {
    for (final t in all) {
      if (t.id == id) return t;
    }
    return null;
  }

  static List<ToolSpec> byIds(List<String> ids) {
    final out = <ToolSpec>[];
    for (final id in ids) {
      final t = byId(id);
      if (t != null) out.add(t);
    }
    return out;
  }

  static List<ToolSpec> inGroup(ToolGroup group) =>
      all.where((t) => t.group == group).toList();

  static List<ToolSpec> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const <ToolSpec>[];
    return all
        .where(
          (t) => '${t.title} ${t.subtitle} ${t.keywords}'
              .toLowerCase()
              .contains(q),
        )
        .toList();
  }

  static const _recentKey = 'recent_tool_ids';

  /// Records a visit so Home can offer "Recently used".
  ///
  /// Never throws: without a preferences backend (widget tests, locked
  /// storage) the app simply carries on without a history.
  static Future<void> markUsed(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList(_recentKey) ?? <String>[];
      ids.remove(id);
      ids.insert(0, id);
      if (ids.length > 12) ids.removeRange(12, ids.length);
      await prefs.setStringList(_recentKey, ids);
    } catch (_) {
      // Preferences unavailable - history is optional.
    }
  }

  /// Most recently used tools, newest first.
  static Future<List<ToolSpec>> recent({int limit = 6}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList(_recentKey) ?? const <String>[];
      final out = <ToolSpec>[];
      for (final id in ids) {
        final t = byId(id);
        if (t == null) continue;
        out.add(t);
        if (out.length >= limit) break;
      }
      return out;
    } catch (_) {
      return const <ToolSpec>[];
    }
  }
}
