import 'package:flutter/material.dart';

import '../../../../models/cv_template_info.dart';

/// Fixed bottom bar of the edit view: preview and create-PDF.
class CvStickyActionBar extends StatelessWidget {
  final CvTemplateInfo active;

  /// Opens the template view: the selected design at full size, with the rail
  /// for switching to any of the others.
  final VoidCallback onFullScreen;

  final VoidCallback onCreatePdf;

  const CvStickyActionBar({
    super.key,
    required this.active,
    required this.onFullScreen,
    required this.onCreatePdf,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  side: BorderSide(color: Colors.grey.shade300),
                  foregroundColor: Colors.grey.shade800,
                ),
                icon: const Icon(Icons.grid_view_rounded, size: 18),
                label: const Text(
                  'Template',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                ),
                onPressed: onFullScreen,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: active.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                label: Text(
                  'Create PDF • ${active.name}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onPressed: onCreatePdf,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
