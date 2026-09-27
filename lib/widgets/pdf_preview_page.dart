import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../services/share_bytes.dart';

class PdfPreviewPage extends StatelessWidget {
  const PdfPreviewPage({
    super.key,
    required this.bytes,
    required this.name,
  });

  final Uint8List bytes;
  final String name;

  static Future<void> open(
    BuildContext context, {
    required Uint8List bytes,
    required String name,
  }) {
    return Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => PdfPreviewPage(bytes: bytes, name: name),
      ),
    );
  }

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
              mime: 'application/pdf',
            ),
          ),
        ],
      ),
      body: PdfPreview(
        build: (_) async => bytes,
        canChangePageFormat: false,
        canChangeOrientation: false,
        allowPrinting: false,
      ),
    );
  }
}
