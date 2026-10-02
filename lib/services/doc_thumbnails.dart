import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:printing/printing.dart';

import '../models/saved_doc.dart';
import 'doc_platform.dart';
import 'doc_store.dart';

class DocVisual {
  const DocVisual({this.thumbnail, this.width, this.height, this.pages, this.unavailable = false});
  final Uint8List? thumbnail;
  final int? width;
  final int? height;
  final int? pages;
  final bool unavailable;
}

DocVisual _imageVisual(Uint8List bytes) {
  final image = img.decodeImage(bytes);
  if (image == null) { return const DocVisual(unavailable: true); }
  final scale = math.min(1.0, math.min(240 / image.width, 240 / image.height));
  final thumb = img.copyResize(image,
    width: math.max(1, (image.width * scale).round()),
    height: math.max(1, (image.height * scale).round()));
  return DocVisual(thumbnail: img.encodeJpg(thumb, quality: 75),
    width: image.width, height: image.height);
}

/// Bounded, small thumbnails instead of retaining each full-resolution input.
class DocThumbnails {
  DocThumbnails._();
  static const capacity = 80;
  static final _cache = LinkedHashMap<String, Future<DocVisual>>();

  static Future<DocVisual> load(SavedDoc doc) {
    final key = '${doc.id}:${doc.modified.millisecondsSinceEpoch}:${doc.size}';
    final cached = _cache.remove(key);
    if (cached != null) { _cache[key] = cached; return cached; }
    final value = _create(doc);
    _cache[key] = value;
    while (_cache.length > capacity) { _cache.remove(_cache.keys.first); }
    return value;
  }

  static Future<DocVisual> _create(SavedDoc doc) async {
    if (doc.size > 30 * 1024 * 1024) { return const DocVisual(unavailable: true); }
    try {
      final bytes = await DocStore.read(doc);
      if (doc.isImage) return await compute(_imageVisual, bytes);
      if (doc.isPdf) {
        final count = await DocPlatform.pageCount(doc);
        final page = await Printing.raster(bytes, pages: const [0], dpi: 45).first;
        return DocVisual(thumbnail: await page.toPng(), pages: count);
      }
    } catch (_) {
      return const DocVisual(unavailable: true);
    }
    return const DocVisual();
  }
}
