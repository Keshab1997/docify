import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'image_bytes.dart';

/// Core image processing - all on device, no upload
class ImageService {
  /// Resize to exact KB using binary search on JPEG quality
  static Future<File> resizeToKB({
    required File inputFile,
    required int targetKB,
    int? targetWidth,
    int? targetHeight,
  }) async {
    final bytes = await inputFile.readAsBytes();
    final bestBytes = await ImageBytes.resizeToKb(
      bytes: bytes,
      targetKB: targetKB,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
    );

    final dir = await getTemporaryDirectory();
    final outPath = p.join(
      dir.path,
      'resized_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    final outFile = File(outPath);
    await outFile.writeAsBytes(bestBytes);
    return outFile;
  }

  static Future<File> convertFormat(File input, String targetExt) async {
    final bytes = await input.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw Exception('Invalid image');
    final dir = await getTemporaryDirectory();
    final outPath = p.join(
      dir.path,
      'converted_${DateTime.now().millisecondsSinceEpoch}.$targetExt',
    );
    if (targetExt.toLowerCase() == 'png') {
      return File(outPath)..writeAsBytesSync(img.encodePng(decoded));
    } else {
      return File(outPath)
        ..writeAsBytesSync(img.encodeJpg(decoded, quality: 90));
    }
  }

  static Future<File> compressImage(File input, {int quality = 70}) async {
    final dir = await getTemporaryDirectory();
    final outPath = p.join(
      dir.path,
      'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    final result = await FlutterImageCompress.compressAndGetFile(
      input.absolute.path,
      outPath,
      quality: quality,
      format: CompressFormat.jpeg,
    );
    return File(result!.path);
  }
}
