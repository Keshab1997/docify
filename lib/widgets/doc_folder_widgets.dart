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

/// One tile of the My documents grid: a 3D gradient folder "claw"
/// illustration, a name and a detail line. Cards keep the per-folder
/// colour so each category is still recognised at a glance, but now
/// sit on layered shadows and carry a small top highlight — the same
/// visual language as the Upload FAB.
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

  /// Darkens a colour for the shadow side of the folder gradient.
  static Color _shade(Color c, double factor) =>
      Color.lerp(c, Colors.black, 1 - factor)!;

  @override
  Widget build(BuildContext context) {
    // The card's very-faint background wash picks up the folder tint so the
    // grid feels grouped by colour without overwhelming the text.
    final cardWash =
        Color.alphaBlend(tint.withValues(alpha: 0.10), Colors.white);
    final shadow = _shade(ink, 0.55);
    return Pressable(
      scale: 0.97,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(Space.md, Space.md, 4, Space.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [cardWash, Colors.white],
          ),
          borderRadius: BorderRadius.circular(Radii.card),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.9),
            width: 1,
          ),
          boxShadow: [
            // Ambient glow in the folder's own colour.
            BoxShadow(
              color: ink.withValues(alpha: 0.10),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
            // Tight dark drop shadow for the "lifted" 3D feel.
            BoxShadow(
              color: shadow.withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _FolderClaw(icon: icon, tint: tint, ink: ink),
                const Spacer(),
                if (menu != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: menu!,
                  ),
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
                  fontWeight: FontWeight.w800,
                  color: AppColors.bodyText,
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

/// The 3D "claw" illustration: a rounded square whose gradient goes from
/// the light top-left to the dark bottom-right, with a stylised folder
/// tab cut at the top and the category icon centred in white.
class _FolderClaw extends StatelessWidget {
  const _FolderClaw(
      {required this.icon, required this.tint, required this.ink});

  final IconData icon;
  final Color tint;
  final Color ink;

  static Color _shade(Color c, double factor) =>
      Color.lerp(c, Colors.black, 1 - factor)!;

  static Color _light(Color c, double amount) =>
      Color.lerp(c, Colors.white, amount)!;

  @override
  Widget build(BuildContext context) {
    final lightTint = _light(tint, 0.55);
    final midTint = tint;
    final darkTint = _shade(ink, 0.75);
    // Only actual folder-shaped icons get the tab ear; the summary cards
    // (All files / Starred / Trash) keep a clean rounded claw.
    final hasTab = icon == Icons.folder_rounded ||
        icon == Icons.folder_outlined ||
        icon == Icons.create_new_folder_outlined;
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [lightTint, midTint, darkTint],
          stops: const [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.circular(Radii.chip),
        boxShadow: [
          // Dark drop under the claw.
          BoxShadow(
            color: darkTint.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
          // Top rim highlight catching light.
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.55),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.antiAlias,
        children: [
          if (hasTab) ...[
            // Folder tab (the little "ear").
            Positioned(
              top: -4,
              left: 8,
              child: Container(
                width: 22,
                height: 14,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [lightTint, midTint],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
              ),
            ),
            // Inner shadow line under the tab, to sell the fold.
            Positioned(
              top: 9,
              left: 6,
              right: 14,
              child: Container(
                height: 1.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      darkTint.withValues(alpha: 0.0),
                      darkTint.withValues(alpha: 0.35),
                      darkTint.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
          Center(
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }
}

/// The last tile of the grid, for making a folder — styled as a dashed
/// 3D claw slot so it reads as "drop a new folder here" instead of a
/// plain outlined box.
class NewFolderCard extends StatelessWidget {
  const NewFolderCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.97,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(Space.md),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(Radii.card),
          border: Border.all(
            color: AppColors.primaryButton.withValues(alpha: 0.35),
            width: 1.5,
            style: BorderStyle.solid,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryButton.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // The + sits inside a hollow 3D claw that echoes the real ones.
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    AppColors.lightBlue,
                  ],
                ),
                borderRadius: BorderRadius.circular(Radii.chip),
                border: Border.all(
                  color: const Color(0x882563EB),
                  width: 1.5,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x332563EB),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                size: 26,
                color: AppColors.primaryButton,
              ),
            ),
            const SizedBox(height: Space.sm),
            const Text(
              'New folder',
              style: TextStyle(
                fontWeight: FontWeight.w800,
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
