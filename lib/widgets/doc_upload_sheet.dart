import 'package:flutter/material.dart';

import '../services/doc_categories.dart';
import '../theme/app_theme.dart';
import 'pressable.dart';

/// Where the files of an upload come from.
enum UploadSource { files, gallery, camera }

/// How each shelf looks in the pickers, so a shelf is recognised at a
/// glance and not only by its name.
extension DocCategoryLook on DocCategory {
  IconData get icon => switch (this) {
        DocCategory.jobForms => Icons.work_outline_rounded,
        DocCategory.certificates => Icons.school_outlined,
        DocCategory.idProof => Icons.badge_outlined,
        DocCategory.photoSign => Icons.portrait_outlined,
        DocCategory.others => Icons.folder_outlined,
      };

  Color get tint => switch (this) {
        DocCategory.jobForms => AppColors.mergePdfCard,
        DocCategory.certificates => AppColors.imageToPdfCard,
        DocCategory.idProof => AppColors.photoResizeCard,
        DocCategory.photoSign => AppColors.signatureCard,
        DocCategory.others => AppColors.background,
      };

  Color get ink => switch (this) {
        DocCategory.jobForms => AppColors.assistantInk,
        DocCategory.certificates => AppColors.successChip,
        DocCategory.idProof => AppColors.primaryButton,
        DocCategory.photoSign => AppColors.signatureInk,
        DocCategory.others => AppColors.mutedText,
      };
}

/// Asks where to upload from. Files cover PDFs such as a downloaded
/// application form; the gallery and the camera cover paper documents.
Future<UploadSource?> showUploadSourceSheet(BuildContext context) {
  return showModalBottomSheet<UploadSource>(
    context: context,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.sheet)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Upload documents',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 12),
            _SourceTile(
              icon: Icons.folder_open_rounded,
              tint: AppColors.pdfTint,
              ink: AppColors.pdfBadge,
              title: 'Files',
              subtitle: 'PDFs and photos saved on your phone',
              onTap: () => Navigator.pop(ctx, UploadSource.files),
            ),
            _SourceTile(
              icon: Icons.photo_library_rounded,
              tint: AppColors.photoResizeCard,
              ink: AppColors.primaryButton,
              title: 'Gallery',
              subtitle: 'Photos of your documents',
              onTap: () => Navigator.pop(ctx, UploadSource.gallery),
            ),
            _SourceTile(
              icon: Icons.photo_camera_rounded,
              tint: AppColors.imageToPdfCard,
              ink: AppColors.successChip,
              title: 'Camera',
              subtitle: 'Take a photo of a paper document',
              onTap: () => Navigator.pop(ctx, UploadSource.camera),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon,
    required this.tint,
    required this.ink,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color tint;
  final Color ink;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.99,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: tint,
          child: Icon(icon, color: ink),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        onTap: onTap,
      ),
    );
  }
}

/// The user's answer in [DocCategorySheet].
class DocFiling {
  const DocFiling(this.category, {this.name = ''});

  final DocCategory category;

  /// The new name without extension, for a single file; empty keeps the
  /// file's own name.
  final String name;
}

/// Asks which shelf of My documents files go on.
Future<DocFiling?> showDocCategorySheet(
  BuildContext context, {
  required String title,
  DocCategory? initial,
  String? name,
}) {
  return showModalBottomSheet<DocFiling>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.sheet)),
    ),
    builder: (_) => DocCategorySheet(
      title: title,
      initial: initial,
      name: name,
    ),
  );
}

/// Picks a shelf, and for a single upload also a name: files from a phone
/// are often called things like "IMG-20250101-WA0003", which says nothing.
class DocCategorySheet extends StatefulWidget {
  const DocCategorySheet({
    super.key,
    required this.title,
    this.initial,
    this.name,
  });

  final String title;

  /// Selected at the start, e.g. the shelf the user is looking at. Without
  /// one, Save waits until a shelf is picked, so nothing lands on a shelf
  /// by accident.
  final DocCategory? initial;

  /// The name to offer for editing, without extension; null hides the
  /// field, as when several files are saved at once.
  final String? name;

  @override
  State<DocCategorySheet> createState() => _DocCategorySheetState();
}

class _DocCategorySheetState extends State<DocCategorySheet> {
  late DocCategory? _category = widget.initial;
  late final TextEditingController _name =
      TextEditingController(text: widget.name);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save(DocCategory category) {
    Navigator.pop(context, DocFiling(category, name: _name.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final category = _category;
    return SafeArea(
      child: Padding(
        // Keeps the Save button above the keyboard while the name is typed.
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 12),
            if (widget.name != null) ...[
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'File name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Radii.field),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final shelf in DocCategory.values)
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Radii.card),
                      ),
                      selected: shelf == category,
                      selectedTileColor: shelf.tint,
                      leading: CircleAvatar(
                        backgroundColor: shelf.tint,
                        child: Icon(shelf.icon, color: shelf.ink),
                      ),
                      title: Text(
                        shelf.label,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(shelf.examples),
                      trailing: shelf == category
                          ? Icon(Icons.check_circle_rounded, color: shelf.ink)
                          : null,
                      onTap: () => setState(() => _category = shelf),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: category == null ? null : () => _save(category),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
