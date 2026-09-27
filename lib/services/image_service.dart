import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

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
    img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) throw Exception('Invalid image');

    if (targetWidth != null && targetHeight != null) {
      decoded = img.copyResize(decoded, width: targetWidth, height: targetHeight);
    } else if (targetWidth != null) {
      decoded = img.copyResize(decoded, width: targetWidth);
    } else if (targetHeight != null) {
      decoded = img.copyResize(decoded, height: targetHeight);
    }

    // Binary search quality 10-95 to hit target KB
    int low = 10, high = 95, bestQuality = 70;
    Uint8List? bestBytes;
    final targetBytes = targetKB * 1024;

    for (int i = 0; i < 10; i++) {
      int mid = (low + high) ~/ 2;
      final jpg = Uint8List.fromList(img.encodeJpg(decoded, quality: mid));
      if (jpg.length <= targetBytes) {
        bestBytes = jpg;
        bestQuality = mid;
        low = mid + 1;
        if ((targetBytes - jpg.length).abs() < 1024) break; // close enough
      } else {
        high = mid - 1;
      }
    }

    bestBytes ??= Uint8List.fromList(img.encodeJpg(decoded, quality: low));

    // If still too large, downscale and retry
    if (bestBytes.length > targetBytes) {
      int attempts = 0;
      while (bestBytes!.length > targetBytes && attempts < 5) {
        decoded = img.copyResize(decoded!, width: (decoded.width * 0.9).toInt());
        bestBytes = Uint8List.fromList(img.encodeJpg(decoded, quality: 60));
        attempts++;
      }
    }

    final dir = await getTemporaryDirectory();
    final outPath = p.join(dir.path, 'resized_${DateTime.now().millisecondsSinceEpoch}.jpg');
    final outFile = File(outPath);
    await outFile.writeAsBytes(bestBytes);
    return outFile;
  }

  static Future<File> convertFormat(File input, String targetExt) async {
    final bytes = await input.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw Exception('Invalid image');
    final dir = await getTemporaryDirectory();
    final outPath = p.join(dir.path, 'converted_${DateTime.now().millisecondsSinceEpoch}.$targetExt');
    if (targetExt.toLowerCase() == 'png') {
      return File(outPath)..writeAsBytesSync(img.encodePng(decoded));
    } else {
      return File(outPath)..writeAsBytesSync(img.encodeJpg(decoded, quality: 90));
    }
  }

  static Future<File> compressImage(File input, {int quality = 70}) async {
    final dir = await getTemporaryDirectory();
    final outPath = p.join(dir.path, 'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');
    final result = await FlutterImageCompress.compressAndGetFile(
      input.absolute.path,
      outPath,
      quality: quality,
      format: CompressFormat.jpeg,
    );
    return File(result!.path);
  }
}
