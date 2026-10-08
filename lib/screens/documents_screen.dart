import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/doc_meta.dart';
import '../models/doc_query.dart';
import '../models/saved_doc.dart';
import '../services/doc_folders.dart';
import '../services/doc_index.dart';
import '../services/doc_actions.dart';
import '../services/doc_deletions.dart';
import '../services/doc_ocr.dart';
import '../services/doc_store.dart';
import '../services/pick_bytes.dart';
import '../services/share_bytes.dart';
import '../theme/app_theme.dart';
import '../widgets/doc_details_sheet.dart';
import '../widgets/doc_file_card.dart';
import '../widgets/doc_folder_widgets.dart';
import '../widgets/doc_lock_gate.dart';
import '../widgets/doc_rename_dialog.dart';
import '../widgets/pressable.dart';
import '../services/doc_thumbnails.dart';
import '../widgets/doc_tags_dialog.dart';
import '../widgets/doc_upload_sheet.dart';
import '../widgets/empty_state.dart';
import '../widgets/pdf_preview_page.dart';
import '../widgets/sync_sheet.dart';

enum _Sort { newest, oldest, name, size }

enum _ViewMode { list, grid }

/// What happens to the files of a folder being deleted.
enum _FolderFiles { move, delete }

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key, this.active = true, this.onBrowseTools});

  /// Whether this tab is the one on screen. The shell keeps every tab
  /// alive, so Back may only close a folder while the user can see it.
  final bool active;

  /// Empty-state button; wired to the Tools tab by the shell.
  final VoidCallback? onBrowseTools;

  @override
  State<DocumentsScreen> createState() => DocumentsScreenState();
}

class DocumentsScreenState extends State<DocumentsScreen> {
  /// [_openId] of the special views; folder ids never start with '#'.
  static const _allFiles = '#all';
  static const _starred = '#starred';
  static const _trashView = '#trash';

  List<SavedDoc> _files = [];
  List<SavedDoc> _trash = [];
  Map<String, DocMeta> _index = {};
  DocLibrary _library = const DocLibrary();
  bool _loading = true;

  /// The folder on screen, a special view, or null for the grid of folders.
  String? _openId;
  _Sort _sort = _Sort.newest;
  _ViewMode _viewMode = _ViewMode.list;

  /// The search box and the type chips narrow every list view.
  final _search = TextEditingController();
  DocFilter _filter = DocFilter.all;

  /// Multi-selection: long-press enters, any tap toggles; [null] when idle.
  Set<String> _selected = {};

  final _gate = GlobalKey<DocLockGateState>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Called by the shell whenever the Documents tab is opened.
  Future<void> reload() {
    _gate.currentState?.shown();
    return _load();
  }

  Future<void> _load() async {
    try {
      await DocActions.purgeExpired();
    } catch (_) {
      // A failed purge retries on the next visit; the list still loads.
    }
    final files = await DocStore.list();
    final library = await DocFolders.load();
    final index = await DocIndex.load();
    final trash = (await DocStore.list(includeTrash: true))
        .where((doc) => (index[doc.id] ?? const DocMeta()).inTrash)
        .toList();
    if (!mounted) return;
    // Leaving a folder cancels selection so the selection bar never shows on
    // a screen with nothing selected.
    _selected = {};
    setState(() {
      _files = files;
      _trash = trash;
      _library = library;
      _index = index;
      _loading = false;
    });
  }

  /// The open folder; null on the grid and in the special views.
  DocFolder? get _folder {
    final id = _openId;
    return id == null ? null : _library.byId(id);
  }

  /// The title of a special view; folders use their own name.
  String get _viewTitle => switch (_openId) {
        _starred => 'Starred',
        _trashView => 'Trash',
        _ => 'All files',
      };

  /// The grid and the special views name the folder, since their files
  /// come from everywhere.
  bool get _showsFolder => _folder == null;

  bool _isStarred(SavedDoc doc) => (_index[doc.id] ?? const DocMeta()).starred;

  bool get _queryActive =>
      _search.text.trim().isNotEmpty || _filter != DocFilter.all;

  /// The search box and type chips narrow the list; empty text with the All
  /// chip leaves the folder exactly as it is.
  List<SavedDoc> _applyQuery(List<SavedDoc> list) {
    if (!_queryActive) return list;
    final query = DocQuery(text: _search.text, filter: _filter);
    return list
        .where(
          (doc) => query.matches(
            doc,
            _index[doc.id] ?? const DocMeta(),
            _library.folderOf(doc).name,
          ),
        )
        .toList();
  }

  /// Trash shows what went in last, first.
  List<SavedDoc> _byTrashedAt() {
    final list = [..._trash];
    int trashedAt(SavedDoc doc) =>
        (_index[doc.id] ?? const DocMeta()).trashedAt ?? 0;
    list.sort((a, b) => trashedAt(b).compareTo(trashedAt(a)));
    return list;
  }

  List<SavedDoc> get _shown {
    final id = _openId;
    if (id == _trashView) return _applyQuery(_byTrashedAt());
    final list = id == _allFiles
        ? [..._files]
        : id == _starred
            ? _files.where(_isStarred).toList()
            : _files.where((f) => _library.folderOf(f).id == id).toList();
    switch (_sort) {
      case _Sort.newest:
        list.sort((a, b) => b.modified.compareTo(a.modified));
      case _Sort.oldest:
        list.sort((a, b) => a.modified.compareTo(b.modified));
      case _Sort.name:
        list.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
      case _Sort.size:
        list.sort((a, b) => b.size.compareTo(a.size));
    }
    return _applyQuery(list);
  }

  void _show(String? id) => setState(() {
        _openId = id;
        _selected = {};
        _search.clear();
        _filter = DocFilter.all;
      });

  bool get _selecting => _selected.isNotEmpty;

  List<SavedDoc> get _selectedDocs =>
      _files.where((f) => _selected.contains(f.id)).toList();

  void _startSelection(SavedDoc doc) => setState(() {
        _selected = {doc.id};
      });

  void _toggleSelection(SavedDoc doc) {
    setState(() {
      if (!_selected.add(doc.id)) _selected.remove(doc.id);
    });
  }

  void _clearSelection() => setState(() => _selected = {});

  Future<void> _selectAll(List<SavedDoc> shown) async {
    setState(() => _selected = shown.map((d) => d.id).toSet());
  }

  /// Bulk actions applied to the current selection.
  Future<void> _bulkTrash() async {
    final docs = _selectedDocs;
    if (docs.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.sheet),
        ),
        title: Text('Move ${filesLabel(docs.length)} to Trash?'),
        content: const Text(
            'They stay for 30 days, then go forever. Drive copies are kept.',
            style: AppText.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Move to Trash'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    var failed = 0;
    for (final doc in docs) {
      try {
        await DocActions.trash(doc);
      } catch (_) {
        failed++;
      }
    }
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(failed == 0
            ? 'Moved ${filesLabel(docs.length)} to Trash'
            : 'Moved most files, ${filesLabel(failed)} failed.'),
      ),
    );
  }

  Future<void> _bulkShare() async {
    final docs = _selectedDocs;
    if (docs.length == 1) return _share(docs.first);
    // Multi-file share falls back to sharing the first: the OS share sheet
    // does not always accept multiple, and ShareBytes only wraps one.
    if (docs.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Sharing the first selected file — share one at a time '
          'to pick specific files.'),
    ));
    await _share(docs.first);
  }

  Future<void> _bulkStar(bool starred) async {
    final docs = _selectedDocs;
    for (final doc in docs) {
      try {
        await DocIndex.starred(doc.id, starred);
      } catch (_) {}
    }
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(starred
          ? 'Starred ${filesLabel(docs.length)}'
          : 'Removed stars from ${filesLabel(docs.length)}')),
    );
  }

  Future<void> _bulkMove() async {
    final docs = _selectedDocs;
    if (docs.isEmpty) return;
    final filing = await showDocFolderSheet(
      context,
      title: 'Move ${filesLabel(docs.length)}',
      folders: _library.folders,
      initial: _folder,
      action: 'Move',
    );
    if (filing == null) {
      await _load();
      return;
    }
    await DocFolders.file(docs.map((d) => d.id), filing.folder);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Moved to ${filing.folder.name}')),
    );
  }

  /// Called by the shell on Back: closes selection first, then the open
  /// folder (or special view), as in a file manager. False when nothing is
  /// on screen to close, so the shell goes on to Home.
  bool closeOpenFolder() {
    final onScreen = widget.active && _gate.currentState?.showing == true;
    if (_selecting) {
      _clearSelection();
      return true;
    }
    if (_openId == null || !onScreen) return false;
    _show(null);
    return true;
  }

  Future<void> _open(SavedDoc doc) async {
    try {
      await DocIndex.opened(doc.id);
    } catch (_) {
      // Opening a file never fails because its timestamp didn't save.
    }
    final bytes = await DocStore.read(doc);
    if (!mounted) return;
    if (doc.isPdf) {
      await PdfPreviewPage.open(
        context,
        bytes: bytes,
        name: doc.name,
        guard: _gate.currentState?.guard,
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) {
          final page = _ImagePreviewPage(name: doc.name, bytes: bytes);
          return _gate.currentState?.guard(page) ?? page;
        },
      ),
    );
  }

  Future<void> _share(SavedDoc doc) async {
    final bytes = await DocStore.read(doc);
    await ShareBytes.share(bytes: bytes, name: doc.name, mime: doc.mime);
  }

  Future<void> _trashDoc(SavedDoc doc) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.sheet),
        ),
        title: const Text('Move to Trash?'),
        content: Text(
            '${doc.name}\n\nStays in Trash for 30 days, then goes forever. '
            'Your Drive copy is kept.',
            style: AppText.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Move to Trash'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await DocActions.trash(doc);
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not move to Trash. Try again.'),
      ));
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Moved ${doc.name} to Trash'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            await _restore(doc, silent: true);
          },
        ),
      ),
    );
  }

  Future<void> _restore(SavedDoc doc, {bool silent = false}) async {
    try {
      await DocActions.restore(doc);
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not restore. Try again.'),
      ));
      return;
    }
    if (silent || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Restored ${doc.name}')),
    );
  }

  Future<void> _deleteForever(SavedDoc doc) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.sheet),
        ),
        title: const Text('Delete forever?'),
        content: Text(
            '${doc.name}\n\nThis cannot be undone. Your Drive copy is kept.',
            style: AppText.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            // Red, because this is the one button here that destroys data.
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete forever'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await DocActions.permanentlyDelete(doc);
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not finish deleting. Refresh and try again.'),
      ));
    }
  }

  Future<void> _emptyTrash() async {
    if (_trash.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.sheet),
        ),
        title: const Text('Empty Trash?'),
        content: Text(
            'Delete ${filesLabel(_trash.length)} in Trash forever? This '
            'cannot be undone. Your Drive copies are kept.',
            style: AppText.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            // Red, because this is the one button here that destroys data.
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Empty Trash'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    var failed = 0;
    for (final doc in _trash) {
      try {
        await DocActions.permanentlyDelete(doc);
      } catch (_) {
        failed++;
      }
    }
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          failed == 0
              ? 'Trash emptied'
              : 'Emptied Trash, but ${filesLabel(failed)} stayed. Try again.',
        ),
      ),
    );
  }

  Future<void> _rename(SavedDoc doc) async {
    final next = await showDocRenameDialog(context, doc: doc, files: _files);
    if (next == null || next == doc.name) return;
    try {
      final renamed = await DocStore.rename(doc, next);
      await DocIndex.renamed(doc.id, renamed.id);
      await DocFolders.move(doc.id, renamed.id);
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
          'Could not rename. Check the name and try again; the original is kept.',
        )),
      );
    }
  }

  Future<void> _toggleStar(SavedDoc doc) async {
    final starred = !_isStarred(doc);
    try {
      await DocIndex.starred(doc.id, starred);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not update the star. Try again.'),
      ));
      return;
    }
    await _load();
  }

  Future<void> _details(SavedDoc doc) async {
    final action = await showDocDetails(
      context,
      doc: doc,
      meta: _index[doc.id] ?? const DocMeta(),
      folder: _library.folderOf(doc).name,
      guard: _gate.currentState?.guard,
    );
    if (action == null || !mounted) return;
    switch (action) {
      case DocDetailAction.tags:
        final tags = await showDocTagsDialog(
          context,
          (_index[doc.id] ?? const DocMeta()).tags,
          guard: _gate.currentState?.guard,
        );
        if (tags == null || !mounted) return;
        try {
          await DocIndex.tags(doc.id, tags);
          await _load();
        } catch (_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not save the tags. Try again.'),
          ));
        }
      case DocDetailAction.recognise:
        await _recognise(doc);
      case DocDetailAction.clearText:
        try {
          await DocIndex.update(doc.id, (m) => m.copyWith(clearOcr: true));
          await _load();
        } catch (_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not remove the text index. Try again.'),
          ));
        }
      case DocDetailAction.retryBackup:
        final changed = await showSyncSheet(context);
        if (changed && mounted) await _load();
    }
  }

  /// Runs on-device OCR behind a progress dialog, then makes the recognised
  /// words searchable.
  Future<void> _recognise(SavedDoc doc) async {
    final progress = ValueNotifier<String>('Starting…');
    if (!mounted) return;
    // Stays up until the recognition below pops it, one way or another.
    unawaited(showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: Space.lg),
              Expanded(
                child: ValueListenableBuilder<String>(
                  valueListenable: progress,
                  builder: (_, label, __) => Text(label),
                ),
              ),
            ],
          ),
        ),
      ),
    ));
    try {
      final result = await DocOcr.recognise(
        doc,
        onProgress: (_, label) => progress.value = label,
      );
      await DocIndex.recognised(doc.id, result.text, result.pages);
      if (!mounted) return;
      Navigator.of(context).pop();
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.text.trim().isEmpty
                ? 'No readable text found in ${doc.name}.'
                : 'Text recognised. Search can now find words inside it.',
          ),
        ),
      );
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_ocrError(e))),
      );
    } finally {
      progress.dispose();
    }
  }

  /// The OCR errors users can act on say so; the rest stay generic.
  String _ocrError(Object e) {
    if (e is FormatException) return e.message;
    if (e is UnsupportedError) {
      return e.message ?? 'Text recognition needs the Android app.';
    }
    return 'Could not recognise text. Try again.';
  }

  /// Adds files from the phone, the gallery or the camera to a folder, so
  /// application forms, certificates and ID proofs live here next to what
  /// the tools made.
  Future<void> _upload() async {
    final source = await showUploadSourceSheet(context);
    if (source == null) return;
    final picked = switch (source) {
      UploadSource.files => await PickBytes.documents(),
      UploadSource.gallery => await PickBytes.photos(ImageSource.gallery),
      UploadSource.camera => await PickBytes.photos(ImageSource.camera),
    };
    if (picked.isEmpty) return;
    if (!mounted) return;
    final single = picked.length == 1 ? picked.single : null;
    final filing = await showDocFolderSheet(
      context,
      title: single == null ? 'Save ${picked.length} files' : 'Save file',
      folders: _library.folders,
      initial: _folder,
      name: single == null ? null : nameStem(single.name),
    );
    if (filing == null) {
      // The sheet may have made a folder before it was closed.
      await _load();
      return;
    }
    final ids = <String>[];
    for (final file in picked) {
      final doc = await DocStore.save(
        bytes: file.bytes,
        name: single == null
            ? file.name
            : renameKeepingExtension(file.name, filing.name),
      );
      await DocDeletions.allow(
        name: doc.name,
        digest: await documentDigest(file.bytes),
      );
      ids.add(doc.id);
    }
    await DocFolders.file(ids, filing.folder);
    if (!mounted) return;
    // Show where the files went.
    _show(filing.folder.id);
    await _load();
    if (!mounted) return;
    final where = filing.folder.name;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ids.length == 1
              ? 'Saved to $where'
              : 'Saved ${ids.length} files to $where',
        ),
      ),
    );
  }

  Future<void> _move(SavedDoc doc) async {
    final filing = await showDocFolderSheet(
      context,
      title: 'Move to folder',
      folders: _library.folders,
      initial: _library.folderOf(doc),
      action: 'Move',
    );
    if (filing == null) {
      // The sheet may have made a folder before it was closed.
      await _load();
      return;
    }
    await DocFolders.file([doc.id], filing.folder);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Moved to ${filing.folder.name}')),
    );
  }

  Future<void> _newFolder() async {
    final name = await showFolderNameDialog(context, folders: _library.folders);
    if (name == null) return;
    final folder = await DocFolders.create(name);
    if (!mounted) return;
    // Open it, ready for its first upload.
    _show(folder.id);
    await _load();
  }

  Future<void> _renameFolder(DocFolder folder) async {
    final name = await showFolderNameDialog(
      context,
      folders: _library.folders,
      folder: folder,
    );
    if (name == null || name == folder.name) return;
    await DocFolders.rename(folder.id, name);
    await _load();
  }

  /// Deleting a folder never takes its files by surprise: they move to
  /// Others, or to Trash when the user picks the red button.
  Future<void> _deleteFolder(DocFolder folder) async {
    final inside = _files.where((f) => _library.folderOf(f) == folder).toList();
    var message = folder.name;
    if (inside.isNotEmpty) {
      message = '${folder.name} has ${filesLabel(inside.length)}. Move '
          'them to Others, or delete them too?';
    }
    final choice = await showDialog<_FolderFiles>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.sheet),
        ),
        title: const Text('Delete folder?'),
        content: Text(message, style: AppText.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          if (inside.isEmpty)
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, _FolderFiles.move),
              child: const Text('Delete'),
            ),
          if (inside.isNotEmpty) ...[
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              onPressed: () => Navigator.pop(ctx, _FolderFiles.delete),
              child: const Text('Delete files too'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, _FolderFiles.move),
              child: const Text('Move to Others'),
            ),
          ],
        ],
      ),
    );
    if (choice == null) return;
    if (choice == _FolderFiles.delete) {
      for (final doc in inside) {
        await DocActions.trash(doc);
      }
    }
    await DocFolders.remove(folder.id);
    if (!mounted) return;
    if (_openId == folder.id) _show(null);
    await _load();
    if (!mounted) return;
    var done = 'Deleted ${folder.name}';
    if (inside.isNotEmpty) {
      done = choice == _FolderFiles.delete
          ? '$done. Its files are in Trash now.'
          : '$done. Its files are in Others now.';
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(done)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DocLockGate(key: _gate, builder: (_, gate) => _page(gate));
  }

  Widget _page(DocLockGateState gate) {
    final open = _openId != null;
    return Scaffold(
      appBar: open ? _folderBar() : _gridBar(gate),
      floatingActionButton: _selecting
          ? null
          : FloatingActionButton.extended(
              onPressed: _upload,
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text('Upload'),
            ),
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return _openId == null ? _grid() : _fileList();
  }

  // ---------------------------------------------------------------------------
  // Home grid (no folder open): quick stats + recent strip + folders.
  // ---------------------------------------------------------------------------

  Widget _statsRow() {
    final totalBytes = _files.fold<int>(0, (s, f) => s + f.size);
    final pdfs = _files.where((f) => f.isPdf).length;
    final images = _files.where((f) => f.isImage).length;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: Row(
        children: [
          Expanded(child: _statCard(
            icon: Icons.folder_copy_outlined,
            value: filesLabel(_files.length),
            label: 'Total files',
            tint: AppColors.lightBlue,
            ink: AppColors.titleBlue,
          )),
          const SizedBox(width: Space.sm),
          Expanded(child: _statCard(
            icon: Icons.sd_storage_outlined,
            value: fileSizeLabel(totalBytes),
            label: 'On device',
            tint: AppColors.imageToPdfCard,
            ink: AppColors.successChip,
          )),
          const SizedBox(width: Space.sm),
          Expanded(child: _statCard(
            icon: Icons.picture_as_pdf_rounded,
            value: '$pdfs',
            label: 'PDFs',
            tint: AppColors.pdfTint,
            ink: AppColors.pdfBadge,
          )),
          const SizedBox(width: Space.sm),
          Expanded(child: _statCard(
            icon: Icons.image_outlined,
            value: '$images',
            label: 'Images',
            tint: AppColors.photoResizeCard,
            ink: AppColors.primaryButton,
          )),
        ],
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String value,
    required String label,
    required Color tint,
    required Color ink,
  }) {
    return Container(
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Radii.card),
        boxShadow: Soft.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: tint,
            child: Icon(icon, size: 18, color: ink),
          ),
          const SizedBox(height: Space.sm),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.bodyText,
            ),
          ),
          Text(label, style: AppText.caption),
        ],
      ),
    );
  }

  /// A horizontal thumbnail strip for recently opened files — faster to scan
  /// than a list, and a natural home for the real thumbnails we already make.
  Widget _recentStrip(List<SavedDoc> recent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: Space.sm),
          child: Row(
            children: [
              const Expanded(child: Text('Recent', style: AppText.title)),
              TextButton(
                onPressed: () => _show(_allFiles),
                child: const Text('See all'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 128,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: recent.length,
            separatorBuilder: (_, __) => const SizedBox(width: Space.md),
            itemBuilder: (_, i) => _recentThumb(recent[i]),
          ),
        ),
        const SizedBox(height: Space.lg),
      ],
    );
  }

  Widget _recentThumb(SavedDoc doc) {
    return Pressable(
      scale: 0.97,
      onTap: () => _open(doc),
      child: SizedBox(
        width: 110,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 88,
              width: 110,
              decoration: BoxDecoration(
                color: doc.isPdf ? AppColors.pdfTint : AppColors.photoResizeCard,
                borderRadius: BorderRadius.circular(Radii.chip),
                boxShadow: Soft.card,
              ),
              clipBehavior: Clip.antiAlias,
              child: _Thumb(doc: doc),
            ),
            const SizedBox(height: 6),
            Text(
              doc.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Quick jump chips on the home screen so users do not have to open a
  /// folder and then tap filter chips again.
  Widget _quickFilters() {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _quickChip(
              icon: Icons.star_outline_rounded,
              label: 'Starred',
              onTap: () => _show(_starred),
              tint: AppColors.folderTint,
              ink: AppColors.folderInk,
            ),
            _quickChip(
              icon: Icons.picture_as_pdf_rounded,
              label: 'All PDFs',
              onTap: () {
                _show(_allFiles);
                setState(() => _filter = DocFilter.pdf);
              },
              tint: AppColors.pdfTint,
              ink: AppColors.pdfBadge,
            ),
            _quickChip(
              icon: Icons.image_outlined,
              label: 'All images',
              onTap: () {
                _show(_allFiles);
                setState(() => _filter = DocFilter.images);
              },
              tint: AppColors.photoResizeCard,
              ink: AppColors.primaryButton,
            ),
            _quickChip(
              icon: Icons.delete_outline_rounded,
              label: 'Trash',
              onTap: () => _show(_trashView),
              tint: AppColors.mergePdfCard,
              ink: AppColors.assistantInk,
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color tint,
    required Color ink,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: Space.sm),
      child: Pressable(
        scale: 0.97,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.md,
            vertical: Space.sm,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(Radii.pill),
            border: Border.all(color: AppColors.chipBorder),
          ),
          child: Row(children: [
            Icon(icon, size: 18, color: ink),
            const SizedBox(width: 6),
            Text(label, style: AppText.label),
          ]),
        ),
      ),
    );
  }

  Widget _grid() {
    final counts = <String, int>{};
    for (final f in _files) {
      final id = _library.folderOf(f).id;
      counts[id] = (counts[id] ?? 0) + 1;
    }
    final cards = <Widget>[
      DocFolderCard(
        icon: Icons.apps_rounded,
        tint: AppColors.lightBlue,
        ink: AppColors.titleBlue,
        name: 'All files',
        detail: filesLabel(_files.length),
        onTap: () => _show(_allFiles),
      ),
      DocFolderCard(
        icon: Icons.star_rounded,
        tint: AppColors.folderTint,
        ink: AppColors.folderInk,
        name: 'Starred',
        detail: filesLabel(_files.where(_isStarred).length),
        onTap: () => _show(_starred),
      ),
      DocFolderCard(
        icon: Icons.delete_outline_rounded,
        tint: AppColors.pdfTint,
        ink: AppColors.pdfBadge,
        name: 'Trash',
        detail: filesLabel(_trash.length),
        onTap: () => _show(_trashView),
      ),
      for (final folder in _library.folders)
        DocFolderCard(
          icon: folder.icon,
          tint: folder.tint,
          ink: folder.ink,
          name: folder.name,
          detail: filesLabel(counts[folder.id] ?? 0),
          onTap: () => _show(folder.id),
          menu: folder.isCustom ? _folderMenu(folder) : null,
        ),
      NewFolderCard(onTap: _newFolder),
    ];
    final recent = recentDocuments(_files, _index, limit: 8);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(Space.lg, 4, Space.lg, 96),
        children: [
          if (_files.isNotEmpty) _statsRow(),
          _quickFilters(),
          if (recent.isNotEmpty) _recentStrip(recent),
          for (var i = 0; i < cards.length; i += 2)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.md),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: cards[i]),
                    const SizedBox(width: Space.md),
                    Expanded(
                      child: i + 1 < cards.length
                          ? cards[i + 1]
                          : const SizedBox(),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Folder / special view: search + filter chips + list or grid of files.
  // ---------------------------------------------------------------------------

  Widget _fileList() {
    final shown = _shown;
    return Column(
      children: [
        _searchField(),
        _filterChips(),
        _resultHeader(shown.length),
        Expanded(child: shown.isEmpty ? _empty() : _fileScroll(shown)),
      ],
    );
  }

  /// A small "N files · List/Grid" row that disappears when search/filter
  /// narrows things to zero so the empty state has the whole screen.
  Widget _resultHeader(int count) {
    if (_openId == _trashView) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.lg),
      child: Row(
        children: [
          Text(
            filesLabel(count),
            style: AppText.caption,
          ),
          const Spacer(),
          _viewToggle(),
        ],
      ),
    );
  }

  Widget _viewToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Radii.chip),
        border: Border.all(color: AppColors.chipBorder),
      ),
      child: Row(children: [
        _viewButton(
          icon: Icons.view_list_rounded,
          active: _viewMode == _ViewMode.list,
          onTap: () => setState(() => _viewMode = _ViewMode.list),
          tooltip: 'List view',
        ),
        _viewButton(
          icon: Icons.grid_view_rounded,
          active: _viewMode == _ViewMode.grid,
          onTap: () => setState(() => _viewMode = _ViewMode.grid),
          tooltip: 'Grid view',
        ),
      ]),
    );
  }

  Widget _viewButton({
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.chip),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: active ? AppColors.lightBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(Radii.chip),
          ),
          child: Icon(
            icon,
            size: 18,
            color: active ? AppColors.primaryButton : AppColors.mutedText,
          ),
        ),
      ),
    );
  }

  AppBar _gridBar(DocLockGateState gate) {
    final lockOn = gate.lockOn;
    return AppBar(
      title: const Text('My documents'),
      actions: [
        IconButton(
          tooltip: lockOn ? 'Turn off the lock' : 'Turn on the lock',
          icon: Icon(lockOn ? Icons.lock_rounded : Icons.lock_open_rounded),
          onPressed: gate.toggle,
        ),
        IconButton(
          tooltip: 'Sync with Drive',
          icon: const Icon(Icons.cloud_sync_rounded),
          onPressed: () async {
            final changed = await showSyncSheet(context);
            if (changed && mounted) await _load();
          },
        ),
      ],
    );
  }

  /// Selection replaces the folder bar with a close + count + bulk actions.
  AppBar _selectionBar(List<SavedDoc> shown) {
    final count = _selected.length;
    final allSelected = count == shown.length && shown.isNotEmpty;
    return AppBar(
      leading: IconButton(
        tooltip: 'Cancel selection',
        icon: const Icon(Icons.close_rounded),
        onPressed: _clearSelection,
      ),
      title: Text(
        filesLabel(count),
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      actions: [
        IconButton(
          tooltip: allSelected ? 'Clear selection' : 'Select all',
          icon: Icon(allSelected
              ? Icons.deselect_rounded
              : Icons.select_all_rounded),
          onPressed: () => allSelected
              ? _clearSelection()
              : _selectAll(shown),
        ),
        if (_openId != _trashView) ...[
          IconButton(
            tooltip: 'Star',
            icon: const Icon(Icons.star_rounded),
            onPressed: () => _bulkStar(true),
          ),
          IconButton(
            tooltip: 'Move to folder',
            icon: const Icon(Icons.drive_file_move_outlined),
            onPressed: _bulkMove,
          ),
        ],
        IconButton(
          tooltip: 'Share',
          icon: const Icon(Icons.share_rounded),
          onPressed: _bulkShare,
        ),
        IconButton(
          tooltip: _openId == _trashView ? 'Delete forever' : 'Move to Trash',
          icon: Icon(
            _openId == _trashView
                ? Icons.delete_forever_rounded
                : Icons.delete_outline_rounded,
            color: AppColors.danger,
          ),
          onPressed: _bulkTrash,
        ),
      ],
    );
  }

  AppBar _folderBar() {
    final folder = _folder;
    if (_selecting) return _selectionBar(_shown);
    return AppBar(
      leading: IconButton(
        tooltip: 'All folders',
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => _show(null),
      ),
      title: Text(
        folder?.name ?? _viewTitle,
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        if (_openId != _trashView)
          IconButton(
            tooltip: _viewMode == _ViewMode.list
                ? 'Switch to grid view'
                : 'Switch to list view',
            icon: Icon(_viewMode == _ViewMode.list
                ? Icons.grid_view_rounded
                : Icons.view_list_rounded),
            onPressed: () => setState(() {
              _viewMode = _viewMode == _ViewMode.list
                  ? _ViewMode.grid
                  : _ViewMode.list;
            }),
          ),
        if (_openId == _trashView)
          TextButton.icon(
            onPressed: _trash.isEmpty ? null : _emptyTrash,
            icon: const Icon(Icons.delete_forever_rounded),
            label: const Text('Empty'),
          )
        else
          PopupMenuButton<_Sort>(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sort',
            initialValue: _sort,
            onSelected: (s) => setState(() => _sort = s),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.card),
            ),
            itemBuilder: (_) => const [
              PopupMenuItem(value: _Sort.newest, child: Text('Newest first')),
              PopupMenuItem(value: _Sort.oldest, child: Text('Oldest first')),
              PopupMenuItem(value: _Sort.name, child: Text('Name A-Z')),
              PopupMenuItem(value: _Sort.size, child: Text('Largest first')),
            ],
          ),
        if (folder != null && folder.isCustom) _folderMenu(folder),
      ],
    );
  }

  /// Rename and delete, for the user's own folders only: the built-in ones
  /// are the fallback homes of every file.
  Widget _folderMenu(DocFolder folder) {
    return PopupMenuButton<String>(
      tooltip: 'Folder options',
      icon: const Icon(Icons.more_vert_rounded, color: AppColors.mutedText),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.card),
      ),
      onSelected: (v) {
        if (v == 'rename') _renameFolder(folder);
        if (v == 'delete') _deleteFolder(folder);
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'rename', child: Text('Rename folder')),
        PopupMenuItem(value: 'delete', child: Text('Delete folder')),
      ],
    );
  }

  Widget _searchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.lg, 4, Space.lg, 0),
      child: TextField(
        controller: _search,
        onChanged: (_) => setState(() {}),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search_rounded),
          hintText: _openId == _trashView
              ? 'Search Trash'
              : 'Search name, folder, tag or text inside documents',
          suffixIcon: _search.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () => setState(_search.clear),
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Radii.card),
          ),
        ),
      ),
    );
  }

  Widget _filterChips() {
    if (_openId == _trashView) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: Space.lg,
        vertical: Space.sm,
      ),
      child: Row(
        children: [
          for (final filter in DocFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: Space.sm),
              child: FilterChip(
                label: Text(_filterLabel(filter)),
                selected: _filter == filter,
                onSelected: (_) => setState(() => _filter = filter),
              ),
            ),
        ],
      ),
    );
  }

  String _filterLabel(DocFilter filter) => switch (filter) {
        DocFilter.all => 'All',
        DocFilter.pdf => 'PDFs',
        DocFilter.images => 'Images',
        DocFilter.starred => 'Starred',
      };

  Widget _fileScroll(List<SavedDoc> shown) {
    final grid = _viewMode == _ViewMode.grid && _openId != _trashView;
    if (grid) {
      return RefreshIndicator(
        onRefresh: _load,
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(Space.lg, 4, Space.lg, 96),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: Space.md,
            crossAxisSpacing: Space.md,
            childAspectRatio: 0.63,
          ),
          itemCount: shown.length,
          itemBuilder: (_, i) => _docCard(shown[i], grid: true),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(Space.lg, 4, Space.lg, 96),
        itemCount: shown.length,
        separatorBuilder: (_, __) => const SizedBox(height: Space.md),
        itemBuilder: (_, i) => _docCard(shown[i]),
      ),
    );
  }

  /// One card used in both list and grid views. Long-press starts multi-select;
  /// a tap while selecting toggles the tick; otherwise the file opens.
  Widget _docCard(SavedDoc f, {bool grid = false}) {
    final meta = _index[f.id] ?? const DocMeta();
    final folderName = _library.folderOf(f).name;
    final trash = _openId == _trashView;
    final selected = _selected.contains(f.id);
    return DocFileCard(
      doc: f,
      meta: meta,
      folder: _showsFolder ? folderName : '',
      selected: selected,
      selecting: _selecting,
      trash: trash,
      grid: grid,
      onOpen: () => _open(f),
      onSelect: () {
        if (!_selecting) {
          _startSelection(f);
        } else {
          _toggleSelection(f);
        }
      },
      onStar: () => _toggleStar(f),
      menu: _cardMenu(f, trash: trash),
    );
  }

  Widget _cardMenu(SavedDoc f, {required bool trash}) {
    return PopupMenuButton<String>(
      tooltip: 'More',
      onSelected: (v) {
        switch (v) {
          case 'open':
            _open(f);
          case 'share':
            _share(f);
          case 'details':
            _details(f);
          case 'restore':
            _restore(f);
          case 'rename':
            _rename(f);
          case 'move':
            _move(f);
          case 'trash':
            _trashDoc(f);
          case 'delete':
            _deleteForever(f);
        }
      },
      itemBuilder: (_) => trash
          ? const [
              PopupMenuItem(value: 'open', child: Text('Open')),
              PopupMenuItem(value: 'share', child: Text('Share')),
              PopupMenuItem(value: 'restore', child: Text('Restore')),
              PopupMenuItem(value: 'details', child: Text('Details')),
              PopupMenuItem(value: 'delete', child: Text('Delete forever')),
            ]
          : const [
              PopupMenuItem(value: 'open', child: Text('Open')),
              PopupMenuItem(value: 'share', child: Text('Share')),
              PopupMenuItem(value: 'details', child: Text('Details')),
              PopupMenuItem(value: 'rename', child: Text('Rename')),
              PopupMenuItem(value: 'move', child: Text('Move to folder')),
              PopupMenuItem(value: 'trash', child: Text('Move to Trash')),
            ],
    );
  }

  Widget _empty() {
    if (_queryActive) {
      final text = _search.text.trim();
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: 'No matches',
        message: text.isEmpty
            ? 'Nothing here matches this filter.'
            : "Nothing matches \"$text\" here. Try the Recognise text button in a file's details to search inside scanned pages.",
        ctaLabel: text.isEmpty ? 'Show all' : 'Clear search',
        onCta: () => setState(() {
          _search.clear();
          _filter = DocFilter.all;
        }),
      );
    }
    if (_openId == _trashView) {
      return const EmptyState(
        icon: Icons.delete_outline_rounded,
        title: 'Trash is empty',
        message: 'Deleted files stay here for 30 days, then go forever.',
      );
    }
    final folder = _folder;
    if (_openId == _starred) {
      return const EmptyState(
        icon: Icons.star_outline_rounded,
        title: 'No starred documents',
        message: 'Tap the star on a file to keep it here.',
      );
    }
    if (folder == null) {
      return EmptyState(
        image: 'assets/images/deco_folder.png',
        title: 'Nothing saved yet',
        message: 'Upload your job forms and documents, or make photos, '
            'signatures and PDFs with the tools.',
        ctaLabel: widget.onBrowseTools == null ? null : 'Browse tools',
        onCta: widget.onBrowseTools,
      );
    }
    final hint = folder.builtIn?.examples;
    return EmptyState(
      icon: folder.icon,
      title: 'Nothing in ${folder.name} yet',
      message: hint == null
          ? 'Tap Upload to add files to this folder.'
          : '$hint. Tap Upload to add them.',
    );
  }
}

/// A small thumbnail used in the Recent strip: centres a PDF icon or a
/// cached image preview. Shares the DocThumbnails cache so it stays cheap.
class _Thumb extends StatelessWidget {
  const _Thumb({required this.doc});
  final SavedDoc doc;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocVisual>(
      future: DocThumbnails.load(doc),
      builder: (_, snap) {
        final visual = snap.data;
        final bytes = visual?.thumbnail;
        if (bytes == null) {
          return Center(
            child: Icon(
              doc.isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
              color: doc.isPdf ? AppColors.pdfBadge : AppColors.primaryButton,
              size: 34,
            ),
          );
        }
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => Center(
            child: Icon(
              doc.isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
              color: doc.isPdf ? AppColors.pdfBadge : AppColors.primaryButton,
              size: 34,
            ),
          ),
        );
      },
    );
  }
}

class _ImagePreviewPage extends StatelessWidget {
  const _ImagePreviewPage({required this.name, required this.bytes});
  final String name;
  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(name, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () => ShareBytes.share(
              bytes: bytes,
              name: name,
              mime: mimeFromName(name),
            ),
          ),
        ],
      ),
      body: InteractiveViewer(child: Center(child: Image.memory(bytes))),
    );
  }
}
