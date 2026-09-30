import 'package:flutter/material.dart';

import '../services/doc_folders.dart';
import '../theme/app_theme.dart';
import 'doc_folder_widgets.dart';
import 'pressable.dart';

/// Where the files of an upload come from.
enum UploadSource { files, gallery, camera }

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

/// The user's answer in [DocFolderSheet].
class DocFiling {
  const DocFiling(this.folder, {this.name = ''});

  final DocFolder folder;

  /// The new name without extension, for a single file; empty keeps the
  /// file's own name.
  final String name;
}

/// Asks which folder of My documents files go in.
Future<DocFiling?> showDocFolderSheet(
  BuildContext context, {
  required String title,
  required List<DocFolder> folders,
  DocFolder? initial,
  String? name,
  String action = 'Save',
}) {
  return showModalBottomSheet<DocFiling>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.sheet)),
    ),
    builder: (_) => DocFolderSheet(
      title: title,
      folders: folders,
      initial: initial,
      name: name,
      action: action,
    ),
  );
}

/// Picks a folder, and for a single upload also a name: files from a phone
/// are often called things like "IMG-20250101-WA0003", which says nothing.
class DocFolderSheet extends StatefulWidget {
  const DocFolderSheet({
    super.key,
    required this.title,
    required this.folders,
    this.initial,
    this.name,
    this.action = 'Save',
  });

  final String title;
  final List<DocFolder> folders;

  /// Selected at the start, e.g. the folder the user is looking at. Without
  /// one, the button waits until a folder is picked, so nothing lands in a
  /// folder by accident.
  final DocFolder? initial;

  /// The name to offer for editing, without extension; null hides the
  /// field, as when several files are saved at once.
  final String? name;

  /// The button: Save for an upload, Move for a file already here.
  final String action;

  @override
  State<DocFolderSheet> createState() => _DocFolderSheetState();
}

class _DocFolderSheetState extends State<DocFolderSheet> {
  late List<DocFolder> _folders = widget.folders;
  late DocFolder? _folder = widget.initial;
  late final TextEditingController _name =
      TextEditingController(text: widget.name);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save(DocFolder folder) {
    Navigator.pop(context, DocFiling(folder, name: _name.text.trim()));
  }

  /// Makes a folder without leaving the sheet, e.g. "WBSSC 2026" for the
  /// forms of one exam, and picks it.
  Future<void> _newFolder() async {
    final name = await showFolderNameDialog(context, folders: _folders);
    if (name == null) return;
    final folder = await DocFolders.create(name);
    if (!mounted) return;
    setState(() {
      _folders = [..._folders, folder];
      _folder = folder;
    });
  }

  @override
  Widget build(BuildContext context) {
    final picked = _folder;
    return SafeArea(
      child: Padding(
        // Keeps the button above the keyboard while the name is typed.
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
                  for (final folder in _folders)
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Radii.card),
                      ),
                      selected: folder == picked,
                      selectedTileColor: folder.tint,
                      leading: CircleAvatar(
                        backgroundColor: folder.tint,
                        child: Icon(folder.icon, color: folder.ink),
                      ),
                      title: Text(
                        folder.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: folder.builtIn == null
                          ? null
                          : Text(folder.builtIn!.examples),
                      trailing: folder == picked
                          ? Icon(Icons.check_circle_rounded, color: folder.ink)
                          : null,
                      onTap: () => setState(() => _folder = folder),
                    ),
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Radii.card),
                    ),
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.lightBlue,
                      child: Icon(
                        Icons.create_new_folder_outlined,
                        color: AppColors.primaryButton,
                      ),
                    ),
                    title: const Text(
                      'New folder',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryButton,
                      ),
                    ),
                    onTap: _newFolder,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: picked == null ? null : () => _save(picked),
              child: Text(widget.action),
            ),
          ],
        ),
      ),
    );
  }
}
