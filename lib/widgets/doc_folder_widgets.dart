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

/// A proper folder illustration painted with vectors: a wide body, a
/// naturally-sized tab on the top-left, soft corners, a subtle gradient
/// and drop shadow. The category icon sits centred on the body in white.
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

    final base = Color.alphaBlend(ink.withValues(alpha: 0.18), tint);
    final highlight = Color.lerp(base, Colors.white, 0.45)!;
    final shadow = Color.lerp(base, Colors.black, 0.45)!;

    return SizedBox(
      width: 58,
      height: 48,
      child: CustomPaint(
        painter:
            _FolderPainter(base: base, highlight: highlight, shadow: shadow),
        child: Center(
          heightFactor: 1.0,
          child: Padding(
            // Push the icon down so it sits in the body, not on the tab.
            padding: const EdgeInsets.only(top: 8),
            child: Icon(icon,
                color: Colors.white.withValues(alpha: 0.92), size: 22),
          ),
        ),
      ),
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

/// Paints a folder silhouette: body rectangle + smaller tab on the top-left.
class _FolderPainter extends CustomPainter {
  _FolderPainter(
      {required this.base, required this.highlight, required this.shadow});

  final Color base;
  final Color highlight;
  final Color shadow;

  @override
  void paint(Canvas canvas, Size size) {
    const radius = 10.0;
    const tabH = 13.0;
    const tabW = 26.0;
    const tabLeftInset = 3.0;
    const bodyTop = tabH - 3.0; // tab slightly overlaps body for the fold

    // Drop shadow first, slightly offset.
    final shadowPaint = Paint()
      ..color = shadow.withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final shadowRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(1, 4, size.width - 2, size.height - 4),
      topLeft: const Radius.circular(radius),
      topRight: const Radius.circular(radius),
      bottomLeft: const Radius.circular(radius + 2),
      bottomRight: const Radius.circular(radius + 2),
    );
    canvas.drawRRect(shadowRect, shadowPaint);

    // Tab path (top-left).
    final tabPath = Path()
      ..moveTo(tabLeftInset + radius, bodyTop - tabH)
      ..lineTo(tabLeftInset + tabW - 8, bodyTop - tabH)
      ..quadraticBezierTo(tabLeftInset + tabW - 3, bodyTop - tabH,
          tabLeftInset + tabW, bodyTop - tabH + 6)
      ..lineTo(tabLeftInset + tabW + 2, bodyTop - 2)
      ..lineTo(tabLeftInset + 2, bodyTop - 2)
      ..quadraticBezierTo(
          tabLeftInset, bodyTop - 2, tabLeftInset, bodyTop + radius - 2)
      ..lineTo(tabLeftInset, bodyTop - tabH + radius)
      ..quadraticBezierTo(
          tabLeftInset, bodyTop - tabH, tabLeftInset + radius, bodyTop - tabH)
      ..close();

    final tabPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [highlight, base],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(tabPath, tabPaint);

    // Body rectangle, rounded corners.
    final bodyRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, bodyTop, size.width, size.height - bodyTop),
      topLeft: const Radius.circular(4),
      topRight: const Radius.circular(radius),
      bottomLeft: const Radius.circular(radius + 2),
      bottomRight: const Radius.circular(radius + 2),
    );
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          highlight,
          base,
          Color.lerp(base, shadow, 0.35)!,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRRect(bodyRect, bodyPaint);

    // Fold crease under the tab — a thin dark line to sell depth.
    final creasePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          shadow.withValues(alpha: 0.0),
          shadow.withValues(alpha: 0.28),
          shadow.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(
        const Rect.fromLTWH(tabLeftInset, bodyTop - 1, tabW + 6, 3),
      );
    canvas.drawRect(
      const Rect.fromLTWH(tabLeftInset - 1, bodyTop - 1, tabW + 8, 1.5),
      creasePaint,
    );

    // Top shine — a very faint white sweep along the top edge of the body.
    final shinePaint = Paint()..color = Colors.white.withValues(alpha: 0.18);
    final shineRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(1, bodyTop + 1, size.width - 2, 3),
      topLeft: const Radius.circular(4),
      topRight: Radius.circular(radius - 1),
    );
    canvas.drawRRect(shineRect, shinePaint);
  }

  @override
  bool shouldRepaint(covariant _FolderPainter old) =>
      old.base != base || old.highlight != highlight || old.shadow != shadow;
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
