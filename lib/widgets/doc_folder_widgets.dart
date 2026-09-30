import 'package:flutter/material.dart';

import '../services/doc_folders.dart';
import '../theme/app_theme.dart';
import 'pressable.dart';

/// How each folder looks, so a folder is recognised at a glance and not
/// only by its name. The user's own folders share the classic yellow.
extension DocFolderLook on DocFolder {
  IconData get icon => switch (builtIn) {
        BuiltInFolder.jobForms => Icons.work_outline_rounded,
        BuiltInFolder.certificates => Icons.school_outlined,
        BuiltInFolder.idProof => Icons.badge_outlined,
        BuiltInFolder.photoSign => Icons.portrait_outlined,
        BuiltInFolder.others => Icons.folder_outlined,
        null => Icons.folder_rounded,
      };

  Color get tint => switch (builtIn) {
        BuiltInFolder.jobForms => AppColors.mergePdfCard,
        BuiltInFolder.certificates => AppColors.imageToPdfCard,
        BuiltInFolder.idProof => AppColors.photoResizeCard,
        BuiltInFolder.photoSign => AppColors.signatureCard,
        BuiltInFolder.others => AppColors.background,
        null => AppColors.folderTint,
      };

  Color get ink => switch (builtIn) {
        BuiltInFolder.jobForms => AppColors.assistantInk,
        BuiltInFolder.certificates => AppColors.successChip,
        BuiltInFolder.idProof => AppColors.primaryButton,
        BuiltInFolder.photoSign => AppColors.signatureInk,
        BuiltInFolder.others => AppColors.mutedText,
        null => AppColors.folderInk,
      };
}

/// "3 files" under a folder's name.
String filesLabel(int count) {
  if (count == 0) return 'Empty';
  if (count == 1) return '1 file';
  return '$count files';
}

/// One tile of the My documents grid: an icon, a name and a detail line.
class DocFolderCard extends StatelessWidget {
  const DocFolderCard({
    super.key,
    required this.icon,
    required this.tint,
    required this.ink,
    required this.name,
    required this.detail,
    required this.onTap,
    this.menu,
  });

  final IconData icon;
  final Color tint;
  final Color ink;
  final String name;

  /// The line under the name, such as the number of files.
  final String detail;
  final VoidCallback onTap;

  /// Actions in the top corner, for the user's own folders.
  final Widget? menu;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.98,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(Space.md, Space.md, 4, Space.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(Radii.card),
          boxShadow: Soft.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: tint,
                  child: Icon(icon, color: ink),
                ),
                const Spacer(),
                if (menu != null) menu!,
              ],
            ),
            const SizedBox(height: Space.sm),
            Padding(
              padding: const EdgeInsets.only(right: Space.sm),
              child: Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(detail, style: AppText.caption),
          ],
        ),
      ),
    );
  }
}

/// The last tile of the grid, for making a folder.
class NewFolderCard extends StatelessWidget {
  const NewFolderCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.98,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(Space.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Radii.card),
          border: Border.all(color: AppColors.chipBorder, width: 1.5),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.create_new_folder_outlined,
              size: 32,
              color: AppColors.primaryButton,
            ),
            SizedBox(height: Space.sm),
            Text(
              'New folder',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.primaryButton,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Asks for a folder name: for a new folder, or a new name for [folder].
/// [folders] are the ones that exist, whose names can't be used twice.
/// Returns the trimmed name, or null when cancelled.
Future<String?> showFolderNameDialog(
  BuildContext context, {
  required List<DocFolder> folders,
  DocFolder? folder,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _FolderNameDialog(folders: folders, folder: folder),
  );
}

class _FolderNameDialog extends StatefulWidget {
  const _FolderNameDialog({required this.folders, this.folder});

  final List<DocFolder> folders;
  final DocFolder? folder;

  @override
  State<_FolderNameDialog> createState() => _FolderNameDialogState();
}

class _FolderNameDialogState extends State<_FolderNameDialog> {
  late final TextEditingController _name =
      TextEditingController(text: widget.folder?.name);

  /// Errors wait for the first edit, so the dialog doesn't open with one.
  bool _edited = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String? get _error {
    return folderNameError(
      _name.text,
      widget.folders,
      except: widget.folder?.id,
    );
  }

  void _submit() {
    if (_error != null) return;
    Navigator.pop(context, _name.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.sheet),
      ),
      title: Text(widget.folder == null ? 'New folder' : 'Rename folder'),
      content: TextField(
        controller: _name,
        autofocus: true,
        maxLength: DocFolders.maxName,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          hintText: 'e.g. WBSSC 2026',
          errorText: _edited ? error : null,
        ),
        onChanged: (_) => setState(() => _edited = true),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: error == null ? _submit : null,
          child: Text(widget.folder == null ? 'Create' : 'Save'),
        ),
      ],
    );
  }
}
