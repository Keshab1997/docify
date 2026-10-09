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

/// A crisp folder illustration painted with vectors: a darker back panel
/// with a tab on the top-left, and a lighter front flap across the lower
/// two-thirds. Solid colours and clean rounded corners keep the icon
/// readable at tile size — no blur, no glyph stacked on the shape; the
/// card's own shadow lifts it off the background.
///
/// Non-folder icons (All files, Starred, Trash, or anything that isn't
/// literally a folder) fall back to a simple rounded-square chip with
/// the same colour language — so summaries stay clean and real folders
/// actually look like folders.
class _FolderClaw extends StatelessWidget {
  const _FolderClaw(
      {required this.icon, required this.tint, required this.ink});

  final IconData icon;
  final Color tint;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    final isFolder = icon == Icons.folder_rounded ||
        icon == Icons.folder_outlined ||
        icon == Icons.create_new_folder_outlined;

    if (!isFolder) {
      return _ChipIcon(icon: icon, tint: tint, ink: ink);
    }

    // The folder's own ink carries the colour: a deeper back + tab and a
    // lighter front flap — the classic two-tone folder, kept crisp.
    final back = Color.lerp(ink, Colors.black, 0.12)!;
    final front = Color.lerp(ink, Colors.white, 0.32)!;

    return SizedBox(
      width: 58,
      height: 48,
      child: CustomPaint(painter: _FolderPainter(back: back, front: front)),
    );
  }
}

class _ChipIcon extends StatelessWidget {
  const _ChipIcon({required this.icon, required this.tint, required this.ink});

  final IconData icon;
  final Color tint;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    final base = Color.alphaBlend(ink.withValues(alpha: 0.22), tint);
    final highlight = Color.lerp(base, Colors.white, 0.45)!;
    final shadow = Color.lerp(base, Colors.black, 0.45)!;
    return Container(
      width: 52,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [highlight, base, shadow],
          stops: const [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: shadow.withValues(alpha: 0.30),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }
}

/// Paints the two-tone folder: back panel and tab in [back], front flap in
/// [front] with a hairline fold under its top edge. Colour is solid or
/// gently graded *inside* the silhouette — edges stay sharp so the icon
/// still reads at tile size.
class _FolderPainter extends CustomPainter {
  _FolderPainter({required this.back, required this.front});

  final Color back;
  final Color front;

  @override
  void paint(Canvas canvas, Size size) {
    const sideInset = 2.0;
    const bottomInset = 4.0;
    const tabLeft = 6.0;
    const tabRight = 27.0;
    const tabTop = 4.0;
    const bodyTop = 11.0;
    const flapTop = 17.0;

    const left = sideInset;
    final right = size.width - sideInset;
    final bodyBottom = size.height - bottomInset;

    // Back panel: the folder body behind everything.
    final backPaint = Paint()..color = back;
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTRB(left, bodyTop, right, bodyBottom),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(7),
        bottomLeft: const Radius.circular(8),
        bottomRight: const Radius.circular(8),
      ),
      backPaint,
    );

    // Tab on the top-left, same colour as the back so the two read as one
    // silhouette with a step where the tab meets the body.
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        const Rect.fromLTRB(tabLeft, tabTop, tabRight, bodyTop),
        topLeft: const Radius.circular(5),
        topRight: const Radius.circular(5),
      ),
      backPaint,
    );

    // Front flap across the lower two-thirds — the folder opening. A gentle
    // vertical gradient gives depth without softening the edges.
    final flapPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [front, Color.lerp(front, Colors.black, 0.10)!],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTRB(left, flapTop, right, bodyBottom),
        topLeft: const Radius.circular(5),
        topRight: const Radius.circular(5),
        bottomLeft: const Radius.circular(8),
        bottomRight: const Radius.circular(8),
      ),
      flapPaint,
    );

    // Hairline fold under the flap's top edge — depth without blur.
    canvas.drawRect(
      Rect.fromLTRB(left + 2, flapTop, right - 2, flapTop + 1.2),
      Paint()..color = back.withValues(alpha: 0.35),
    );
  }

  @override
  bool shouldRepaint(covariant _FolderPainter old) =>
      old.back != back || old.front != front;
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
