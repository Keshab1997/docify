import 'package:flutter/material.dart';

import '../models/saved_doc.dart';
import '../theme/app_theme.dart';

Future<String?> showDocRenameDialog(
  BuildContext context, {
  required SavedDoc doc,
  required List<SavedDoc> files,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _RenameDialog(doc: doc, names: files.map((f) => f.name).toList()),
  );
}

class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.doc, required this.names});

  final SavedDoc doc;
  final List<String> names;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final _name = TextEditingController(text: nameStem(widget.doc.name));
  bool _edited = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String? get _error => documentNameError(
    widget.doc.name, _name.text, widget.names, except: widget.doc.id,
  );

  void _save() {
    if (_error != null) return;
    Navigator.pop(context, renameKeepingExtension(widget.doc.name, _name.text));
  }

  @override
  Widget build(BuildContext context) {
    final stem = nameStem(widget.doc.name);
    final extension = widget.doc.name.substring(stem.length);
    final error = _error;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.sheet)),
      title: const Text('Rename document'),
      content: TextField(
        controller: _name,
        autofocus: true,
        decoration: InputDecoration(
          labelText: 'File name',
          suffixText: extension,
          helperText: 'The file format stays unchanged.',
          errorText: _edited ? error : null,
        ),
        onChanged: (_) => setState(() => _edited = true),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: error == null ? _save : null, child: const Text('Save')),
      ],
    );
  }
}
