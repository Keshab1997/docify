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
    final files = await StorageService.listMyDocuments();
    if (!mounted) return;
    setState(() {
      _files = files;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My documents')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _files.isEmpty
              ? _empty()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                    itemCount: _files.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final f = _files[i];
                      final isPdf = f.path.toLowerCase().endsWith('.pdf');
                      final name = f.path.split('/').last;
                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isPdf
                                  ? const Color(0xFFFFF1F2)
                                  : AppColors.photoResizeCard,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              isPdf
                                  ? Icons.picture_as_pdf_rounded
                                  : Icons.image_rounded,
                              color: isPdf
                                  ? AppColors.pdfBadge
                                  : AppColors.primaryButton,
                            ),
                          ),
                          title: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            '${(File(f.path).lengthSync() / 1024).toStringAsFixed(1)} KB',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.mutedText,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.share_rounded,
                              color: AppColors.mutedText,
                            ),
                            onPressed: () => SharePlus.instance
                                .share(ShareParams(files: [XFile(f.path)])),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/deco_folder.png',
              width: 120,
              height: 96,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            const Text(
              'Nothing saved yet',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 6),
            const Text(
              'Photos, signatures and PDFs you create will show up here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.mutedText, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
