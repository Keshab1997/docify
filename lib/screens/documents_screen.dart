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
import '../services/doc_store.dart';
import '../services/pick_bytes.dart';
import '../services/share_bytes.dart';
import '../theme/app_theme.dart';
import '../widgets/doc_folder_widgets.dart';
import '../widgets/doc_lock_gate.dart';
import '../widgets/doc_rename_dialog.dart';
import '../widgets/doc_upload_sheet.dart';
import '../widgets/empty_state.dart';
import '../widgets/pdf_preview_page.dart';
import '../widgets/sync_sheet.dart';

enum _Sort { newest, oldest, name, size }

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

  /// The search box and the type chips narrow every list view.
  final _search = TextEditingController();
  DocFilter _filter = DocFilter.all;

  /// One read per file, reused across rebuilds; cleared on reload.
  final _thumbs = <String, Future<Uint8List?>>{};

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
    _thumbs.clear();
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

  /// Special views name the folder, since their files come from everywhere.
  bool get _showsFolder =>
      _openId == _allFiles || _openId == _starred || _openId == _trashView;

  bool _isStarred(SavedDoc doc) =>
      (_index[doc.id] ?? const DocMeta()).starred;

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

  void _show(String? id) => setState(() => _openId = id);

  Future<void> _open(SavedDoc doc) async {
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
        content: Text(failed == 0
            ? 'Trash emptied'
            : 'Emptied Trash, but ${filesLabel(failed)} stayed. Try again.'),
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

  Future<Uint8List?> _thumbBytes(SavedDoc doc) =>
      _thumbs.putIfAbsent(doc.id, () async {
        try {
          return await DocStore.read(doc);
        } catch (_) {
          return null; // File vanished between list and read.
        }
      });

  @override
  Widget build(BuildContext context) {
    return DocLockGate(key: _gate, builder: (_, gate) => _page(gate));
  }

  Widget _page(DocLockGateState gate) {
    final open = _openId != null;
    return PopScope(
      // Back closes the open folder first, as in a file manager.
      canPop: !open || !widget.active,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _show(null);
      },
      child: Scaffold(
        appBar: open ? _folderBar() : _gridBar(gate),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _upload,
          icon: const Icon(Icons.upload_file_rounded),
          label: const Text('Upload'),
        ),
        body: _body(),
      ),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return _openId == null ? _grid() : _fileList();
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

  AppBar _folderBar() {
    final folder = _folder;
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
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        // Keeps the last row clear of the Upload button.
        padding: const EdgeInsets.fromLTRB(Space.lg, 4, Space.lg, 96),
        children: [
          for (var i = 0; i < cards.length; i += 2)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.md),
              // Both cards of a row take the taller one's height, which
              // follows the phone's font size instead of a fixed guess.
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

  Widget _fileList() {
    final shown = _shown;
    return Column(
      children: [
        _searchField(),
        _filterChips(),
        Expanded(child: shown.isEmpty ? _empty() : _fileScroll(shown)),
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
          hintText: 'Search name, folder or tag',
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
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        // Keeps the last file clear of the Upload button.
        padding: const EdgeInsets.fromLTRB(Space.lg, 4, Space.lg, 96),
        itemCount: shown.length,
        separatorBuilder: (_, __) => const SizedBox(height: Space.md),
        itemBuilder: (_, i) => _fileTile(shown[i]),
      ),
    );
  }

  Widget _fileTile(SavedDoc f) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.card),
        boxShadow: Soft.card,
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Radii.card),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.card),
          ),
          onTap: () => _open(f),
          leading: _leading(f),
          title: Text(
            f.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            [
              if (_showsFolder) _library.folderOf(f).name,
              dateLabel(f.modified),
              kbLabel(f.size),
            ].join('  ·  '),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.mutedText,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_openId != _trashView)
                IconButton(
                  tooltip: _isStarred(f) ? 'Remove star' : 'Star this document',
                  onPressed: () => _toggleStar(f),
                  icon: Icon(
                    _isStarred(f)
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: _isStarred(f)
                        ? AppColors.folderInk
                        : AppColors.mutedText,
                  ),
                ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  switch (v) {
                    case 'open':
                      _open(f);
                    case 'share':
                      _share(f);
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
                itemBuilder: (_) => _tileMenu(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Trash offers a way back; everywhere else offers a way in.
  List<PopupMenuEntry<String>> _tileMenu() {
    if (_openId == _trashView) {
      return const [
        PopupMenuItem(value: 'open', child: Text('Open')),
        PopupMenuItem(value: 'share', child: Text('Share')),
        PopupMenuItem(value: 'restore', child: Text('Restore')),
        PopupMenuItem(value: 'delete', child: Text('Delete forever')),
      ];
    }
    return const [
      PopupMenuItem(value: 'open', child: Text('Open')),
      PopupMenuItem(value: 'share', child: Text('Share')),
      PopupMenuItem(value: 'rename', child: Text('Rename')),
      PopupMenuItem(value: 'move', child: Text('Move to folder')),
      PopupMenuItem(value: 'trash', child: Text('Move to Trash')),
    ];
  }

  Widget _empty() {
    if (_queryActive) {
      final text = _search.text.trim();
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: 'No matches',
        message: text.isEmpty
            ? 'Nothing here matches this filter.'
            : 'Nothing matches "$text" here.',
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

  /// Photos show a real thumbnail; PDFs keep the red badge.
  Widget _leading(SavedDoc f) {
    final decoration = BoxDecoration(
      color: f.isPdf ? AppColors.pdfTint : AppColors.photoResizeCard,
      borderRadius: BorderRadius.circular(Radii.chip),
    );
    if (!f.isImage) {
      return Container(
        width: 44,
        height: 44,
        decoration: decoration,
        child: Icon(
          f.isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
          color: f.isPdf ? AppColors.pdfBadge : AppColors.primaryButton,
        ),
      );
    }
    return Container(
      width: 44,
      height: 44,
      decoration: decoration,
      clipBehavior: Clip.antiAlias,
      child: FutureBuilder<Uint8List?>(
        future: _thumbBytes(f),
        builder: (context, snap) {
          final bytes = snap.data;
          if (bytes == null) {
            return const Icon(
              Icons.image_rounded,
              color: AppColors.primaryButton,
            );
          }
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            cacheWidth: 160,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.image_rounded, color: AppColors.primaryButton),
          );
        },
      ),
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
