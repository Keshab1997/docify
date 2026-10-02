import 'package:flutter/material.dart';

import '../models/application_kit.dart';
import '../models/exam_preset.dart';

class KitDraft {
  const KitDraft(this.name, this.examId, this.requiredSlots);
  final String name;
  final String examId;
  final Set<KitSlot> requiredSlots;
}

Future<KitDraft?> showKitEditor(
  BuildContext context, {
  required List<ApplicationKit> kits,
  ApplicationKit? kit,
  Widget Function(Widget)? guard,
}) =>
    showDialog<KitDraft>(
        context: context,
        builder: (_) {
          final dialog = _KitEditor(kits: kits, kit: kit);
          return guard?.call(dialog) ?? dialog;
        });

class _KitEditor extends StatefulWidget {
  const _KitEditor({required this.kits, this.kit});
  final List<ApplicationKit> kits;
  final ApplicationKit? kit;
  @override
  State<_KitEditor> createState() => _KitEditorState();
}

class _KitEditorState extends State<_KitEditor> {
  late final _name = TextEditingController(text: widget.kit?.name);
  late String _exam = ExamPreset.byId(widget.kit?.examId ?? 'custom').id;
  late final _required = {
    ...widget.kit?.requiredSlots ??
        const {
          KitSlot.photo,
          KitSlot.signature,
          KitSlot.idProof,
          KitSlot.certificate
        }
  };
  bool _edited = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String? get _error {
    final name = _name.text.trim();
    if (name.isEmpty) {
      return 'Enter a kit name';
    }
    if (name.length > 60) {
      return 'Use 60 characters or fewer';
    }
    if (widget.kits.any((kit) =>
        kit.id != widget.kit?.id &&
        kit.name.toLowerCase() == name.toLowerCase())) {
      return 'A kit with this name already exists';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.kit == null
            ? 'New application kit'
            : 'Edit application kit'),
        content: SizedBox(
            width: 360,
            child: SingleChildScrollView(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  TextField(
                      controller: _name,
                      autofocus: true,
                      maxLength: 60,
                      decoration: InputDecoration(
                          labelText: 'Kit name',
                          hintText: 'e.g. SSC 2026',
                          errorText: _edited ? _error : null),
                      onChanged: (_) => setState(() => _edited = true)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                      // ignore: deprecated_member_use
                      value: _exam,
                      isExpanded: true,
                      decoration: const InputDecoration(
                          labelText: 'Photo/signature preset'),
                      items: [
                        for (final exam in ExamPreset.all)
                          DropdownMenuItem(
                              value: exam.id, child: Text(exam.name))
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _exam = value);
                        }
                      }),
                  const SizedBox(height: 16),
                  const Text('Choose your required attachments'),
                  for (final slot in KitSlot.values)
                    CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(slot.label),
                        value: _required.contains(slot),
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (value) => setState(() {
                              if (value == true) {
                                _required.add(slot);
                              } else {
                                _required.remove(slot);
                              }
                            })),
                  const Text(
                      'This is your checklist, not an official form requirement. Check the current notification.',
                      style: TextStyle(fontSize: 12)),
                ]))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: _error == null
                  ? () => Navigator.pop(context,
                      KitDraft(_name.text.trim(), _exam, {..._required}))
                  : null,
              child: const Text('Save'))
        ],
      );
}
