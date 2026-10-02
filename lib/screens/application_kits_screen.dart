import 'package:flutter/material.dart';

import '../models/application_kit.dart';
import '../models/exam_preset.dart';
import '../models/saved_doc.dart';
import '../services/doc_kits.dart';
import '../services/doc_store.dart';
import '../services/share_bytes.dart';
import '../theme/app_theme.dart';
import '../widgets/kit_editor_dialog.dart';
import '../widgets/pdf_preview_page.dart';
import '../widgets/saved_doc_picker.dart';
import 'tools/job_form_assistant_screen.dart';

class ApplicationKitsScreen extends StatefulWidget {
  const ApplicationKitsScreen({super.key, this.guard});
  final Widget Function(Widget)? guard;
  @override
  State<ApplicationKitsScreen> createState() => _ApplicationKitsScreenState();
}

class _ApplicationKitsScreenState extends State<ApplicationKitsScreen> {
  List<ApplicationKit> _kits = [];
  List<SavedDoc> _files = [];
  bool _loading = true;
  bool _error = false;
  bool _busy = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final kits = await DocKits.load();
      final files = await DocStore.list();
      if (mounted) { setState(() { _kits = kits; _files = files; _loading = false; _error = false; }); }
    } catch (_) {
      if (mounted) { setState(() { _loading = false; _error = true; }); }
    }
  }

  Future<void> _edit([ApplicationKit? kit]) async {
    if (_busy) { return; }
    final draft = await showKitEditor(context, kits: _kits, kit: kit, guard: widget.guard);
    if (draft == null || !mounted) { return; }
    setState(() => _busy = true);
    try {
      if (kit == null) {
        await DocKits.create(draft.name, examId: draft.examId, requiredSlots: draft.requiredSlots);
      } else {
        await DocKits.save(kit.copyWith(name: draft.name, examId: draft.examId, requiredSlots: draft.requiredSlots));
      }
      await _load();
    } catch (_) { _say('Could not save the kit. Check its name and try again.'); }
    finally { if (mounted) { setState(() => _busy = false); } }
  }

  Future<void> _remove(ApplicationKit kit) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Delete kit?'), content: Text('${kit.name}\n\nAttached documents stay on this device.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete kit'))]));
    if (ok != true || !mounted || _busy) { return; }
    setState(() => _busy = true);
    try { await DocKits.remove(kit.id); await _load(); }
    catch (_) { _say('Could not delete the kit. Please try again.'); }
    finally { if (mounted) { setState(() => _busy = false); } }
  }

  void _say(String text) { if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text))); } }

  Future<void> _open(ApplicationKit kit) async {
    final page = _KitPage(id: kit.id, guard: widget.guard);
    await Navigator.push<void>(context, MaterialPageRoute(builder: (_) => widget.guard?.call(page) ?? page));
    await _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Application kits')),
    floatingActionButton: FloatingActionButton.extended(onPressed: _busy ? null : () => _edit(),
      icon: const Icon(Icons.add_rounded), label: const Text('New kit')),
    body: _loading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(
      onRefresh: _load, child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        physics: const AlwaysScrollableScrollPhysics(), children: [
          const Text('Keep the documents for one application together. Kits stay on this device and do not copy or upload files.', style: AppText.body),
          const SizedBox(height: 16),
          if (_error) TextButton(onPressed: _load, child: const Text('Could not load kits · Try again')),
          if (_kits.isEmpty && !_error) const Padding(padding: EdgeInsets.symmetric(vertical: 40),
            child: Text('Create a kit such as SSC 2026, attach saved documents, then see what is missing.', textAlign: TextAlign.center)),
          for (final kit in _kits) Padding(padding: const EdgeInsets.only(bottom: 12), child: Card(
            child: ListTile(isThreeLine: true,
              leading: const CircleAvatar(child: Icon(Icons.fact_check_outlined)),
              title: Text(kit.name, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text('${ExamPreset.byId(kit.examId).name} · ${kit.missing(_files).isEmpty ? 'Checklist complete' : '${kit.missing(_files).length} required attachment(s) missing'}\n${kit.files.length} attached · local only'),
              onTap: _busy ? null : () => _open(kit),
              trailing: PopupMenuButton<String>(onSelected: (value) {
                if (value == 'edit') { _edit(kit); } else { _remove(kit); }
              }, itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('Edit checklist')),
                PopupMenuItem(value: 'delete', child: Text('Delete kit'))]),
            ),
          )),
        ])),
  );
}

class _KitPage extends StatefulWidget {
  const _KitPage({required this.id, this.guard});
  final String id;
  final Widget Function(Widget)? guard;
  @override
  State<_KitPage> createState() => _KitPageState();
}

class _KitPageState extends State<_KitPage> {
  ApplicationKit? _kit;
  List<SavedDoc> _files = [];
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final kits = await DocKits.load();
      final files = await DocStore.list();
      if (!mounted) { return; }
      setState(() { _kit = kits.where((kit) => kit.id == widget.id).firstOrNull; _files = files; _loading = false; });
    } catch (_) { if (mounted) { setState(() => _loading = false); _say('Could not load this kit. Try again.'); } }
  }

  SavedDoc? _attachment(KitSlot slot) => _files.where((doc) => doc.id == _kit?.files[slot]).firstOrNull;
  void _say(String text) { if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text))); } }

  Future<void> _work(Future<void> Function() action) async {
    if (_busy) { return; }
    setState(() => _busy = true);
    try { await action(); await _load(); }
    catch (_) { _say('Could not finish. Your existing documents are kept.'); }
    finally { if (mounted) { setState(() => _busy = false); } }
  }

  Future<void> _attach(KitSlot slot) async {
    if (_kit == null || _busy) { return; }
    final doc = await showSavedDocPicker(context,
      files: _files.where(slot.accepts).toList(), title: 'Attach ${slot.label.toLowerCase()}', guard: widget.guard);
    if (doc != null && mounted) { await _work(() => DocKits.attach(widget.id, slot, doc.id)); }
  }

  Future<void> _open(SavedDoc doc) async {
    await _work(() async {
      final bytes = await DocStore.read(doc);
      if (!mounted) { return; }
      if (doc.isPdf) {
        await PdfPreviewPage.open(context, bytes: bytes, name: doc.name, guard: widget.guard);
      } else {
        final page = Scaffold(appBar: AppBar(title: Text(doc.name, overflow: TextOverflow.ellipsis)),
          body: InteractiveViewer(child: Center(child: Image.memory(bytes,
            errorBuilder: (_, __, ___) => const Text('Could not display this image.')))));
        await Navigator.push<void>(context, MaterialPageRoute(builder: (_) => widget.guard?.call(page) ?? page));
      }
    });
  }

  Future<void> _share() async {
    final kit = _kit;
    if (kit == null || _busy) { return; }
    final ids = kit.files.values.toSet();
    final files = _files.where((doc) => ids.contains(doc.id)).toList();
    if (files.isEmpty) { _say('Attach at least one document first.'); return; }
    if (kit.missing(_files).isNotEmpty) {
      final yes = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
        title: const Text('Share an incomplete kit?'),
        content: Text('${kit.missing(_files).length} required attachment(s) are missing. Share the ${files.length} available file(s)?'),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Share available'))]));
      if (yes != true || !mounted) { return; }
    }
    if (files.fold<int>(0, (total, doc) => total + doc.size) > 100 * 1024 * 1024) {
      _say('Share fewer files at a time (100 MB per share).'); return;
    }
    await _work(() async {
      final shared = <ShareFile>[];
      for (final doc in files) { shared.add(ShareFile(bytes: await DocStore.read(doc), name: doc.name, mime: doc.mime)); }
      await ShareBytes.shareMany(shared);
    });
  }

  Future<void> _prepare() async {
    final photo = _attachment(KitSlot.photo);
    final signature = _attachment(KitSlot.signature);
    if (photo == null || signature == null || !photo.isImage || !signature.isImage) {
      _say('Attach a photo and signature image first.'); return;
    }
    await _work(() async {
      final photoBytes = await DocStore.read(photo);
      final signatureBytes = await DocStore.read(signature);
      if (!mounted) { return; }
      final page = JobFormAssistantScreen(initialExam: ExamPreset.byId(_kit!.examId),
        initialPhoto: photoBytes, initialSignature: signatureBytes);
      await Navigator.push<void>(context, MaterialPageRoute(builder: (_) => widget.guard?.call(page) ?? page));
    });
  }

  @override
  Widget build(BuildContext context) {
    final kit = _kit;
    return Scaffold(appBar: AppBar(title: Text(kit?.name ?? 'Application kit', overflow: TextOverflow.ellipsis)),
      body: _loading ? const Center(child: CircularProgressIndicator()) : kit == null
        ? Center(child: TextButton(onPressed: _load, child: const Text('Kit unavailable · Try again')))
        : RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(), children: [
            Text('${ExamPreset.byId(kit.examId).name} · ${kit.missing(_files).isEmpty ? 'Checklist complete' : '${kit.missing(_files).length} required attachment(s) missing'}', style: AppText.title),
            const SizedBox(height: 8),
            const Text('Check the official notification for formats and limits. A complete checklist does not mean a portal will accept every file.', style: AppText.caption),
            const SizedBox(height: 16),
            for (final slot in KitSlot.values) _slot(slot, kit),
            if (_busy) const LinearProgressIndicator(),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: _busy ? null : _prepare,
              icon: const Icon(Icons.auto_fix_high_rounded), label: const Text('Prepare photo and signature')),
            const SizedBox(height: 8),
            OutlinedButton.icon(onPressed: _busy ? null : _share,
              icon: const Icon(Icons.share_rounded), label: const Text('Share kit files')),
            const SizedBox(height: 16),
            const Text('Prepared copies are saved in My Documents. Replace the attachments here when you want the kit to use them.', style: AppText.caption),
          ])));
  }

  Widget _slot(KitSlot slot, ApplicationKit kit) {
    final doc = _attachment(slot);
    final missingReference = kit.files[slot] != null && doc == null;
    return Card(child: ListTile(
      leading: Icon(doc == null ? Icons.add_circle_outline_rounded : Icons.check_circle_outline_rounded,
        color: doc == null ? AppColors.mutedText : AppColors.successChip),
      title: Text('${slot.label} · ${kit.requiredSlots.contains(slot) ? 'Required' : 'Optional'}'),
      subtitle: Text(doc?.name ?? (missingReference ? 'File is missing or in Trash · choose a replacement' : 'Choose a saved document'), maxLines: 2, overflow: TextOverflow.ellipsis),
      onTap: _busy ? null : () => doc == null ? _attach(slot) : _open(doc),
      trailing: PopupMenuButton<String>(enabled: !_busy,
        onSelected: (value) { if (value == 'attach') { _attach(slot); } else { _work(() => DocKits.attach(widget.id, slot, null)); } },
        itemBuilder: (_) => [PopupMenuItem(value: 'attach', child: Text(doc == null ? 'Attach file' : 'Replace attachment')),
          if (kit.files[slot] != null) const PopupMenuItem(value: 'remove', child: Text('Remove attachment'))]),
    ));
  }
}
