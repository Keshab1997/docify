import 'package:flutter/material.dart';

import '../models/saved_doc.dart';
import '../screens/tools/compress_pdf_screen.dart';
import '../screens/tools/crop_image_screen.dart';
import '../screens/tools/image_to_pdf_screen.dart';
import '../screens/tools/merge_pdf_screen.dart';
import '../screens/tools/pdf_to_images_screen.dart';
import '../screens/tools/photo_resize_screen.dart';
import '../services/doc_store.dart';
import '../services/pick_bytes.dart';

enum DocTool {
  compress('Compress PDF', Icons.compress_rounded),
  merge('Merge PDFs', Icons.merge_type_rounded),
  pdfImages('PDF to Images', Icons.collections_rounded),
  resize('Resize image', Icons.photo_size_select_large_rounded),
  crop('Crop image', Icons.crop_rounded),
  imagePdf('Image to PDF', Icons.picture_as_pdf_rounded);

  const DocTool(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Reuses the existing screens and output flows; source documents are never
/// modified by a shortcut, and the picker is no longer a required extra step.
class DocToolShortcuts {
  DocToolShortcuts._();

  static List<DocTool> available(List<SavedDoc> docs) {
    if (docs.isEmpty) {
      return [];
    }
    if (docs.every((doc) => doc.isPdf)) {
      return docs.length == 1
          ? [DocTool.compress, DocTool.pdfImages]
          : [DocTool.merge];
    }
    if (docs.every((doc) => doc.isImage)) {
      return docs.length == 1
          ? [DocTool.resize, DocTool.crop, DocTool.imagePdf]
          : [DocTool.imagePdf];
    }
    return [];
  }

  static Future<Widget> page(DocTool tool, List<SavedDoc> docs) async {
    if (!available(docs).contains(tool)) {
      throw ArgumentError('Select compatible documents');
    }
    if (docs.fold<int>(0, (size, doc) => size + doc.size) > 100 * 1024 * 1024) {
      throw StateError(
          'Choose fewer or smaller documents (100 MB per action).');
    }
    final files = <NamedBytes>[];
    for (final doc in docs) {
      files.add(NamedBytes(doc.name, await DocStore.read(doc)));
    }
    return switch (tool) {
      DocTool.compress => CompressPdfScreen(initialFile: files.single),
      DocTool.merge => MergePdfScreen(initialFiles: files),
      DocTool.pdfImages => PdfToImagesScreen(initialFile: files.single),
      DocTool.resize => PhotoResizeScreen(initialBytes: files.single.bytes),
      DocTool.crop => CropImageScreen(initialBytes: files.single.bytes),
      DocTool.imagePdf => ImageToPdfScreen(
          initialImages: files.map((file) => file.bytes).toList()),
    };
  }
}
