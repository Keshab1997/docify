import 'package:flutter/material.dart';

import '../models/doc_meta.dart';
import '../models/saved_doc.dart';
import '../services/doc_thumbnails.dart';
import '../theme/app_theme.dart';

class DocFileCard extends StatelessWidget {
  const DocFileCard({super.key, required this.doc, required this.meta,
    required this.folder, required this.onOpen, required this.onSelect,
    required this.onStar, required this.menu, this.grid = false,
    this.selected = false, this.selecting = false, this.trash = false});

  final SavedDoc doc;
  final DocMeta meta;
  final String folder;
  final VoidCallback onOpen;
  final VoidCallback onSelect;
  final VoidCallback onStar;
  final Widget menu;
  final bool grid;
  final bool selected;
  final bool selecting;
  final bool trash;

  @override
  Widget build(BuildContext context) {
    return Semantics(selected: selected, button: true,
      label: '${doc.name}, ${fileSizeLabel(doc.size)}, $folder',
      child: Material(
        color: selected ? AppColors.lightBlue : AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.card),
          side: BorderSide(color: selected ? AppColors.primaryButton : AppColors.chipBorder)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: selecting ? onSelect : onOpen,
          onLongPress: onSelect,
          child: Padding(
            padding: const EdgeInsets.all(Space.md),
            child: FutureBuilder<DocVisual>(
              future: DocThumbnails.load(doc),
              builder: (_, snapshot) {
                final visual = snapshot.data ?? const DocVisual();
                final preview = _preview(visual);
                final info = _info(visual);
                if (grid) {
                  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [_selection(), const Spacer(), if (!selecting) _star(), menu]),
                    SizedBox(height: 92, width: double.infinity, child: preview),
                    const SizedBox(height: Space.sm),
                    _name(), const SizedBox(height: 4), info,
                    const SizedBox(height: 4), DocBackupBadge(meta: meta, trash: trash),
                  ]);
                }
                return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (selecting) _selection(),
                  SizedBox(width: 56, height: 64, child: preview),
                  const SizedBox(width: Space.md),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _name(), const SizedBox(height: 4), info,
                    const SizedBox(height: 4), DocBackupBadge(meta: meta, trash: trash),
                  ])),
                  Column(children: [_star(), menu]),
                ]);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _selection() => selecting ? SizedBox(width: 40, height: 40,
    child: Checkbox(value: selected, onChanged: (_) => onSelect(),
      semanticLabel: 'Select ${doc.name}')) : const SizedBox.shrink();

  Widget _star() => trash ? const SizedBox.shrink() : SizedBox(width: 48, height: 48,
    child: IconButton(tooltip: meta.starred ? 'Remove star' : 'Star document',
      onPressed: onStar, iconSize: 21,
      icon: Icon(meta.starred ? Icons.star_rounded : Icons.star_outline_rounded,
        color: meta.starred ? AppColors.folderInk : AppColors.mutedText)));

  Widget _name() => Tooltip(message: doc.name, child: Text(doc.name,
    maxLines: 2, overflow: TextOverflow.ellipsis,
    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)));

  Widget _info(DocVisual visual) {
    final type = doc.isPdf ? 'PDF' : doc.name.split('.').last.toUpperCase();
    final dimensions = visual.width != null ? '${visual.width} × ${visual.height} px' : null;
    final count = visual.pages != null ? '${visual.pages} page${visual.pages == 1 ? '' : 's'}' : null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text([type, fileSizeLabel(doc.size), if (count != null) count,
        if (dimensions != null) dimensions].join(' · '),
        maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.caption),
      Text('$folder · ${dateLabel(doc.modified)}', maxLines: 1,
        overflow: TextOverflow.ellipsis, style: AppText.caption),
      if (meta.tags.isNotEmpty) Text(meta.tags.map((tag) => '#$tag').join(' '),
        maxLines: 1, overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11, color: AppColors.titleBlue)),
    ]);
  }

  Widget _preview(DocVisual visual) => Container(
    decoration: BoxDecoration(color: doc.isPdf ? AppColors.pdfTint : AppColors.photoResizeCard,
      borderRadius: BorderRadius.circular(Radii.sm)),
    clipBehavior: Clip.antiAlias,
    child: visual.thumbnail != null ? Image.memory(visual.thumbnail!,
      fit: BoxFit.contain, errorBuilder: (_, __, ___) => _icon()) : _icon(),
  );

  Widget _icon() => Icon(doc.isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
    color: doc.isPdf ? AppColors.pdfBadge : AppColors.primaryButton, size: 30);
}

class DocBackupBadge extends StatelessWidget {
  const DocBackupBadge({super.key, required this.meta, this.trash = false});
  final DocMeta meta;
  final bool trash;

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = trash ? ('In Trash · kept for 30 days', Icons.delete_outline_rounded, AppColors.mutedText) :
      switch (meta.backupState) {
        DocBackupState.deviceOnly => ('Only on device', Icons.phone_android_rounded, AppColors.mutedText),
        DocBackupState.pending => ('Backup pending', Icons.cloud_upload_outlined, AppColors.titleBlue),
        DocBackupState.backedUp => ('Backed up in Drive', Icons.cloud_done_outlined, AppColors.successChip),
        DocBackupState.failed => ('Backup failed · retry available', Icons.cloud_off_outlined, AppColors.danger),
      };
    return Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 13, color: color),
      const SizedBox(width: 4), Flexible(child: Text(label, maxLines: 1,
        overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: color)))]);
  }
}
