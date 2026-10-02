import 'package:flutter/material.dart';

Future<List<String>?> showDocTagsDialog(BuildContext context, List<String> tags, {
  Widget Function(Widget)? guard,
}) => showDialog<List<String>>(context: context, builder: (_) {
  final dialog = _TagsDialog(tags: tags);
  return guard?.call(dialog) ?? dialog;
});

class _TagsDialog extends StatefulWidget {
  const _TagsDialog({required this.tags});
  final List<String> tags;
  @override
  State<_TagsDialog> createState() => _TagsDialogState();
}

class _TagsDialogState extends State<_TagsDialog> {
  late final _tags = TextEditingController(text: widget.tags.join(', '));
  @override
  void dispose() { _tags.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Document tags'),
    content: TextField(controller: _tags, autofocus: true, maxLength: 220,
      decoration: const InputDecoration(labelText: 'Comma-separated tags',
        hintText: 'ssc, id, certificate', helperText: 'Up to 8 tags, 24 characters each.')),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      FilledButton(onPressed: () => Navigator.pop(context, _tags.text.split(',')), child: const Text('Save'))],
  );
}
