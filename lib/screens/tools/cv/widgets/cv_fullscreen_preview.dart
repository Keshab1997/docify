import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../../models/cv_template_info.dart';
import '../../../../services/share_bytes.dart';
import '../../../../widgets/tool_ui.dart';
import '../cv_form_state.dart';
import 'cv_template_thumbnail.dart';

/// A design shown edge to edge, rendered from whatever is currently in the
/// form, with the other designs one tap away along the bottom.
///
/// Pops with the id of the design the user accepted, or null when they back
/// out without choosing.
class CvFullScreenPreviewPage extends StatefulWidget {
  final CvFormState form;

  /// Design to open on. Defaults to the one selected in the form.
  final int? templateId;

  const CvFullScreenPreviewPage({
    super.key,
    required this.form,
    this.templateId,
  });

  @override
  State<CvFullScreenPreviewPage> createState() =>
      _CvFullScreenPreviewPageState();
}

class _CvFullScreenPreviewPageState extends State<CvFullScreenPreviewPage> {
  late int _id = widget.templateId ?? widget.form.template;
  bool _busy = false;

  CvTemplateInfo get _active =>
      kCvTemplates[_id.clamp(0, kCvTemplates.length - 1)];

  Future<void> _share() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await widget.form.buildPdf(template: _id);
      await ShareBytes.share(
        bytes: bytes,
        name: 'CV_${widget.form.fileNameStem}.pdf',
        mime: 'application/pdf',
      );
    } catch (e) {
      if (!mounted) return;
      showJobSnack(context, 'Could not create CV: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = _active;
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1220),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              active.name,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            Text(
              '${active.badge} · full screen preview',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Share PDF',
            onPressed: _busy ? null : _share,
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.ios_share_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PdfPreview(
              key: ValueKey(_id),
              build: (format) => widget.form.buildPdf(template: _id),
              canChangePageFormat: false,
              canChangeOrientation: false,
              allowPrinting: false,
              allowSharing: false,
              maxPageWidth: 900,
              pdfFileName: 'CV_${widget.form.fileNameStem}.pdf',
              loadingWidget: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: active.accentColor),
                    const SizedBox(height: 12),
                    Text(
                      'Rendering ${active.name}…',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _DesignRail(
            selected: _id,
            onSelected: (id) => setState(() => _id = id),
          ),
          _AcceptBar(
            active: active,
            canAccept: _id != widget.form.template,
            onAccept: () => Navigator.of(context).pop(_id),
          ),
        ],
      ),
    );
  }
}

/// Strip of all designs so the user can flip through them without leaving the
/// full screen view.
class _DesignRail extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelected;

  const _DesignRail({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      color: const Color(0xFF111C31),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        itemCount: kCvTemplates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final t = kCvTemplates[i];
          final isSelected = t.id == selected;
          return GestureDetector(
            onTap: () => onSelected(t.id),
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 42,
                  height: 54,
                  child:
                      CvTemplateThumbnail(template: t, isSelected: isSelected),
                ),
                const SizedBox(height: 3),
                SizedBox(
                  width: 52,
                  child: Text(
                    t.name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.grey.shade400,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Bottom action bar: keeps the design, or confirms the choice.
class _AcceptBar extends StatelessWidget {
  final CvTemplateInfo active;
  final bool canAccept;
  final VoidCallback onAccept;

  const _AcceptBar({
    required this.active,
    required this.canAccept,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      color: const Color(0xFF111C31),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  side: BorderSide(color: Colors.grey.shade700),
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Back',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: active.accentColor,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: Icon(
                  canAccept
                      ? Icons.check_circle_rounded
                      : Icons.check_circle_outline_rounded,
                  size: 18,
                ),
                label: Text(
                  canAccept ? 'Use this design' : 'Selected',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onPressed: canAccept ? onAccept : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
