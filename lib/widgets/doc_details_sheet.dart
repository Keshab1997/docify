import 'package:flutter/material.dart';

import '../models/doc_meta.dart';
import '../models/saved_doc.dart';
import '../services/doc_ocr.dart';
import '../services/doc_thumbnails.dart';
import '../theme/app_theme.dart';
import 'doc_file_card.dart';

enum DocDetailAction { tags, recognise, clearText, retryBackup }

Future<DocDetailAction?> showDocDetails(BuildContext context, {
  required SavedDoc doc, required DocMeta meta, required String folder,
  Widget Function(Widget)? guard,
}) => showModalBottomSheet<DocDetailAction>(context: context, isScrollControlled: true,
  showDragHandle: true, builder: (_) {
    final sheet = _Details(doc: doc, meta: meta, folder: folder);
    return guard?.call(sheet) ?? sheet;
  });

class _Details extends StatelessWidget {
  const _Details({required this.doc, required this.meta, required this.folder});
  final SavedDoc doc;
  final DocMeta meta;
  final String folder;

  @override
  Widget build(BuildContext context) => SafeArea(child: ConstrainedBox(
    constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .85),
    child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        const Text('Document details', style: AppText.title), const SizedBox(height: 12),
        SelectableText(doc.name, style: AppText.body), const SizedBox(height: 8),
        Text('$folder · ${fileSizeLabel(doc.size)}'), Text('Modified: ${dateLabel(doc.modified)}'),
        FutureBuilder<DocVisual>(future: DocThumbnails.load(doc), builder: (_, snapshot) {
          final visual = snapshot.data;
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (visual?.width != null) Text('${visual!.width} × ${visual.height} pixels'),
            if (visual?.pages != null) Text('${visual!.pages} PDF pages'),
            if (visual?.unavailable == true) const Text('Preview unavailable; the saved original is kept.'),
          ]);
        }),
        const SizedBox(height: 12), DocBackupBadge(meta: meta, trash: meta.inTrash),
        if (meta.backupAt != null) Text('Last backed up: ${dateLabel(DateTime.fromMillisecondsSinceEpoch(meta.backupAt!))}', style: AppText.caption),
        if (!meta.inTrash) ...[
          const SizedBox(height: 16), Text(meta.tags.isEmpty ? 'No tags' : meta.tags.map((tag) => '#$tag').join(' ')),
          TextButton.icon(onPressed: () => Navigator.pop(context, DocDetailAction.tags),
            icon: const Icon(Icons.sell_outlined), label: const Text('Edit tags')),
          const Divider(), const Text('On-device text search', style: AppText.label),
          const SizedBox(height: 6),
          const Text('Optional OCR recognises printed Latin/English text, up to 20 PDF pages. It runs locally; the text index is not included in Drive backup.', style: AppText.caption),
          if (meta.ocrText != null) Text('${meta.ocrText!.length} characters indexed · ${meta.ocrPages ?? 1} page(s)', style: AppText.caption),
          TextButton.icon(onPressed: DocOcr.available ? () => Navigator.pop(context, DocDetailAction.recognise) : null,
            icon: const Icon(Icons.document_scanner_outlined),
            label: Text(DocOcr.available ? 'Recognise text for search' : 'OCR is available in the Android app')),
          if (meta.ocrText != null) TextButton(onPressed: () => Navigator.pop(context, DocDetailAction.clearText), child: const Text('Remove local text index')),
          if (meta.backupState == DocBackupState.failed || meta.backupState == DocBackupState.pending)
            TextButton.icon(onPressed: () => Navigator.pop(context, DocDetailAction.retryBackup),
              icon: const Icon(Icons.cloud_upload_outlined), label: const Text('Retry this file backup')),
        ],
        if (meta.inTrash && meta.trashedAt != null) Text('Moved to Trash: ${dateLabel(DateTime.fromMillisecondsSinceEpoch(meta.trashedAt!))}. Permanently removed after 30 days when you next open Documents.', style: AppText.caption),
      ]))));
}
