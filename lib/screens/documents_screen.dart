import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  List<FileSystemEntity> _files = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final files = await StorageService.listMyDocuments();
    setState(() { _files = files; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Documents', style: TextStyle(fontWeight: FontWeight.w700))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _files.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open_rounded, size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      const Text('Files you create will appear here.', style: TextStyle(color: AppColors.mutedText)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _files.length,
                    itemBuilder: (ctx, i) {
                      final f = _files[i];
                      final isPdf = f.path.toLowerCase().endsWith('.pdf');
                      return Card(
                        child: ListTile(
                          leading: Icon(isPdf ? Icons.picture_as_pdf : Icons.image, color: isPdf ? AppColors.pdfBadge : AppColors.primaryButton),
                          title: Text(f.path.split('/').last, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: Text('${(File(f.path).lengthSync() / 1024).toStringAsFixed(1)} KB', style: const TextStyle(fontSize: 11)),
                          trailing: IconButton(
                            icon: const Icon(Icons.share_rounded),
                            onPressed: () => Share.shareXFiles([XFile(f.path)]),
                          ),
                          onTap: () {
                            // Preview could be added
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
