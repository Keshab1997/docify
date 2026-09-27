import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class ResizeRequest {
  const ResizeRequest(this.bytes, this.targetKB, this.width, this.height);

  final Uint8List bytes;
  final int targetKB;
  final int? width;
  final int? height;
}

/// Pure image work, so the UI animation can keep running on another isolate.
Uint8List resizeJpegToKb(ResizeRequest request) {
  final maybe = img.decodeImage(request.bytes);
  if (maybe == null) throw Exception('Invalid image');
  var decoded = maybe;

  if (request.width != null && request.height != null) {
    decoded = img.copyResize(
      decoded,
      width: request.width,
      height: request.height,
    );
  } else if (request.width != null) {
    decoded = img.copyResize(decoded, width: request.width);
  } else if (request.height != null) {
    decoded = img.copyResize(decoded, height: request.height);
  }

  var low = 10;
  var high = 95;
  Uint8List? bestBytes;
  final targetBytes = request.targetKB * 1024;

  for (var i = 0; i < 10; i++) {
    final mid = (low + high) ~/ 2;
    final jpg = Uint8List.fromList(img.encodeJpg(decoded, quality: mid));
    if (jpg.length <= targetBytes) {
      bestBytes = jpg;
      low = mid + 1;
      if ((targetBytes - jpg.length).abs() < 1024) break;
    } else {
      high = mid - 1;
    }
  }

  bestBytes ??= Uint8List.fromList(img.encodeJpg(decoded, quality: low));

  if (bestBytes.length > targetBytes) {
    var attempts = 0;
    while (bestBytes!.length > targetBytes && attempts < 5) {
      decoded = img.copyResize(decoded, width: (decoded.width * 0.9).toInt());
      bestBytes = Uint8List.fromList(img.encodeJpg(decoded, quality: 60));
      attempts++;
    }
  }

  return bestBytes;
}

class ImageBytes {
  static Future<Uint8List> resizeToKb({
    required Uint8List bytes,
    required int targetKB,
    int? targetWidth,
    int? targetHeight,
  }) {
    return compute(
      resizeJpegToKb,
      ResizeRequest(bytes, targetKB, targetWidth, targetHeight),
    );
  }
}
