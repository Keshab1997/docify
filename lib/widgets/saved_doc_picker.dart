import 'package:flutter/material.dart';

import '../models/saved_doc.dart';
import '../theme/app_theme.dart';

Future<SavedDoc?> showSavedDocPicker(
  BuildContext context, {
  required List<SavedDoc> files,
  required String title,
  Widget Function(Widget)? guard,
}) =>
    showModalBottomSheet<SavedDoc>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) {
          final picker = _SavedDocPicker(files: files, title: title);
          return guard?.call(picker) ?? picker;
        });

class _SavedDocPicker extends StatefulWidget {
  const _SavedDocPicker({required this.files, required this.title});
  final List<SavedDoc> files;
  final String title;
  @override
  State<_SavedDocPicker> createState() => _SavedDocPickerState();
}

class _SavedDocPickerState extends State<_SavedDocPicker> {
  final _search = TextEditingController();
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final files = widget.files
        .where((doc) =>
            doc.name.toLowerCase().contains(_search.text.trim().toLowerCase()))
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return SafeArea(
        child: SizedBox(
            height: MediaQuery.sizeOf(context).height * .75,
            child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(children: [
                  Text(widget.title, style: AppText.title),
                  const SizedBox(height: 12),
                  TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                          hintText: 'Search saved documents',
                          prefixIcon: Icon(Icons.search_rounded))),
                  const SizedBox(height: 8),
                  Expanded(
                      child: files.isEmpty
                          ? const Center(
                              child: Text(
                                  'No matching saved files. Add documents from the Documents tab first.'))
                          : ListView.builder(
                              itemCount: files.length,
                              itemBuilder: (_, i) {
                                final doc = files[i];
                                return ListTile(
                                    leading: Icon(doc.isPdf
                                        ? Icons.picture_as_pdf_rounded
                                        : Icons.image_rounded),
                                    title: Text(doc.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis),
                                    subtitle: Text(fileSizeLabel(doc.size)),
                                    onTap: () => Navigator.pop(context, doc));
                              })),
                ]))));
  }
}
