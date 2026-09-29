import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Sniffs the real container format from the bytes so a file name or MIME type
/// can never disagree with what is actually inside.
String detectImageFormat(Uint8List bytes) {
  if (bytes.length >= 4 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47) {
    return 'png';
  }
  if (bytes.length >= 3 &&
      bytes[0] == 0xFF &&
      bytes[1] == 0xD8 &&
      bytes[2] == 0xFF) {
    return 'jpg';
  }
  return 'unknown';
}

class ResizeRequest {
  const ResizeRequest(
    this.bytes,
    this.targetKB,
    this.width,
    this.height, {
    this.minKB,
    this.png = false,
  });

  final Uint8List bytes;
  final int targetKB;
  final int? minKB;
  final int? width;
  final int? height;

  /// Encode as PNG (keeps transparency) instead of JPEG.
  final bool png;

  /// Growing the canvas can lift a file above a KB minimum, but a form's pixel
  /// size must never change behind the user's back - so only do it when no
  /// exact pixel dimensions were requested.
  bool get allowUpscale => width == null && height == null;
}

class ImgJob {
  const ImgJob(this.op, this.bytes, {this.a, this.b, this.c, this.flag});

  final String op;
  final Uint8List bytes;
  final int? a;
  final int? b;
  final int? c;
  final bool? flag;
}

/// Result of a background replacement: the bytes plus whether anything was
/// actually changed. `changed` is false when the photo background is not
/// uniform, which the old implementation used to hide.
class BackgroundResult {
  const BackgroundResult(this.bytes, this.changed);

  final Uint8List bytes;
  final bool changed;
}

Uint8List resizeImageToKb(ResizeRequest request) {
  final decoded = _decodeSized(request.bytes, request.width, request.height);
  if (request.png) {
    return _encodePngToKb(
      decoded,
      request.targetKB,
      minKB: request.minKB,
      allowUpscale: request.allowUpscale,
    );
  }
  return _encodeJpegToKb(
    decoded,
    request.targetKB,
    minKB: request.minKB,
    allowUpscale: request.allowUpscale,
  );
}

Object runImgJob(ImgJob job) {
  final decoded0 = img.decodeImage(job.bytes);
  if (decoded0 == null) throw Exception('Invalid image');
  var decoded = decoded0;

  switch (job.op) {
    case 'info':
      return <int>[decoded.width, decoded.height];
    case 'rotate90':
      decoded = img.copyRotate(decoded, angle: 90);
      return Uint8List.fromList(img.encodeJpg(decoded, quality: 92));
    case 'convertPng':
      return Uint8List.fromList(img.encodePng(decoded));
    case 'convertJpg':
      return Uint8List.fromList(img.encodeJpg(decoded, quality: job.a ?? 90));
    case 'enhance':
      decoded = img.grayscale(decoded);
      decoded = img.adjustColor(decoded, contrast: 1.4, brightness: 1.04);
      return Uint8List.fromList(img.encodeJpg(decoded, quality: 88));
    case 'trim':
      decoded = img.trim(decoded);
      return Uint8List.fromList(
        job.flag == true
            ? img.encodePng(decoded)
            : img.encodeJpg(decoded, quality: 92),
      );
    case 'letterbox':
      final w = job.a ?? decoded.width;
      final h = job.b ?? decoded.height;
      final color = img.ColorRgb8(
        ((job.c ?? 0xFFFFFFFF) >> 16) & 0xFF,
        ((job.c ?? 0xFFFFFFFF) >> 8) & 0xFF,
        (job.c ?? 0xFFFFFFFF) & 0xFF,
      );
      final canvas = img.Image(width: w, height: h);
      img.fill(canvas, color: color);
      final scale = (w / decoded.width < h / decoded.height)
          ? w / decoded.width
          : h / decoded.height;
      final nw = (decoded.width * scale).round().clamp(1, w);
      final nh = (decoded.height * scale).round().clamp(1, h);
      final resized = img.copyResize(
        decoded,
        width: nw,
        height: nh,
        interpolation: img.Interpolation.cubic,
      );
      img.compositeImage(
        canvas,
        resized,
        dstX: ((w - nw) / 2).round(),
        dstY: ((h - nh) / 2).round(),
      );
      return Uint8List.fromList(img.encodeJpg(canvas, quality: 92));
    case 'fitExact':
      decoded = img.copyResize(
        decoded,
        width: job.a ?? decoded.width,
        height: job.b ?? decoded.height,
        interpolation: img.Interpolation.cubic,
      );
      return Uint8List.fromList(img.encodeJpg(decoded, quality: 92));
    case 'background':
      final replaced = _replaceBackground(
        decoded,
        job.c ?? 0xFFFFFFFF,
        job.a ?? 38,
      );
      return Uint8List.fromList(img.encodeJpg(replaced.image, quality: 92));
    case 'backgroundDetail':
      final replaced = _replaceBackground(
        decoded,
        job.c ?? 0xFFFFFFFF,
        job.a ?? 38,
      );
      return BackgroundResult(
        Uint8List.fromList(img.encodeJpg(replaced.image, quality: 92)),
        replaced.changed,
      );
    case 'signature':
      return _extractSignature(
        decoded,
        threshold: job.a ?? 168,
        transparent: job.flag ?? false,
        width: job.b,
        height: job.c,
      );
    default:
      throw Exception('Unknown image op ${job.op}');
  }
}

img.Image _decodeSized(Uint8List bytes, int? width, int? height) {
  final maybe = img.decodeImage(bytes);
  if (maybe == null) throw Exception('Invalid image');
  var decoded = maybe;
  if (width != null && height != null) {
    decoded = img.copyResize(
      decoded,
      width: width,
      height: height,
      interpolation: img.Interpolation.cubic,
    );
  } else if (width != null) {
    decoded = img.copyResize(decoded, width: width);
  } else if (height != null) {
    decoded = img.copyResize(decoded, height: height);
  }
  return decoded;
}

/// The largest JPEG that fits [targetBytes], or a best-effort quality-10 encode
/// when even that is too big (the caller shrinks the canvas next).
Uint8List _bestJpegUnder(img.Image image, int targetBytes) {
  var low = 10;
  var high = 100;
  Uint8List? best;
  for (var i = 0; i < 10; i++) {
    final mid = (low + high) ~/ 2;
    final jpg = Uint8List.fromList(img.encodeJpg(image, quality: mid));
    if (jpg.length <= targetBytes) {
      best = jpg;
      low = mid + 1;
      if ((targetBytes - jpg.length).abs() < 1024) break;
    } else {
      high = mid - 1;
    }
    if (low > high) break;
  }
  return best ?? Uint8List.fromList(img.encodeJpg(image, quality: 10));
}

Uint8List _encodeJpegToKb(
  img.Image decoded,
  int targetKB, {
  int? minKB,
  bool allowUpscale = false,
}) {
  final targetBytes = targetKB * 1024;
  final minBytes = (minKB ?? 0) * 1024;
  var work = decoded;
  var out = _bestJpegUnder(work, targetBytes);

  // Below the minimum some forms ask for: more pixels carry more bytes, so
  // grow the canvas - but only when no exact pixel size was requested.
  var growth = 0;
  while (minBytes > 0 && out.length < minBytes && allowUpscale && growth < 4) {
    final w = (work.width * 1.3).round();
    final h = (work.height * 1.3).round();
    if (w > 3000 || h > 3000) break;
    work = img.copyResize(
      work,
      width: w,
      height: h,
      interpolation: img.Interpolation.cubic,
    );
    final grown = _bestJpegUnder(work, targetBytes);
    if (grown.length <= out.length) break;
    out = grown;
    growth++;
  }

  // Above the maximum: drop detail until it fits.
  var shrink = 0;
  while (out.length > targetBytes && shrink < 8) {
    final w = (work.width * 0.88).toInt().clamp(40, work.width);
    if (w >= work.width) break;
    work = img.copyResize(
      work,
      width: w,
      interpolation: img.Interpolation.cubic,
    );
    out = _bestJpegUnder(work, targetBytes);
    shrink++;
  }

  return out;
}

Uint8List _encodePngToKb(
  img.Image decoded,
  int targetKB, {
  int? minKB,
  bool allowUpscale = false,
}) {
  final targetBytes = targetKB * 1024;
  final minBytes = (minKB ?? 0) * 1024;
  var work = decoded;

  for (var round = 0; round < 5; round++) {
    // PNG has no quality knob, only compression: level 0 stores the most bytes
    // and level 9 the fewest, so the first level that fits is the best one.
    Uint8List? largestFitting;
    for (var level = 0; level <= 9; level++) {
      final candidate = Uint8List.fromList(img.encodePng(work, level: level));
      if (candidate.length <= targetBytes) {
        largestFitting = candidate;
        break;
      }
    }

    if (largestFitting != null) {
      if (minBytes == 0 || largestFitting.length >= minBytes) {
        return largestFitting;
      }
      if (!allowUpscale || work.width > 3000) return largestFitting;
      work = img.copyResize(
        work,
        width: (work.width * 1.3).round(),
        interpolation: img.Interpolation.cubic,
      );
      continue;
    }

    // Even the most compressed PNG is too big: shrink the canvas.
    final w = (work.width * 0.85).toInt().clamp(32, work.width);
    if (w >= work.width) break;
    work = img.copyResize(
      work,
      width: w,
      interpolation: img.Interpolation.cubic,
    );
  }

  return Uint8List.fromList(img.encodePng(work, level: 9));
}

({img.Image image, bool changed}) _replaceBackground(
  img.Image src,
  int color,
  int tolerance,
) {
  if (src.width < 8 || src.height < 8) return (image: src, changed: false);
  img.Pixel sample(int x, int y) => src.getPixel(x, y);
  final corners = [
    sample(2, 2),
    sample(src.width - 3, 2),
    sample(2, src.height - 3),
    sample(src.width - 3, src.height - 3),
  ];
  double ch(img.Pixel p, String c) => c == 'r'
      ? p.r.toDouble()
      : c == 'g'
          ? p.g.toDouble()
          : p.b.toDouble();
  final ar = corners.map((p) => ch(p, 'r')).reduce((a, b) => a + b) / 4;
  final ag = corners.map((p) => ch(p, 'g')).reduce((a, b) => a + b) / 4;
  final ab = corners.map((p) => ch(p, 'b')).reduce((a, b) => a + b) / 4;
  var spread = 0.0;
  for (final p in corners) {
    final d = (ch(p, 'r') - ar).abs() +
        (ch(p, 'g') - ag).abs() +
        (ch(p, 'b') - ab).abs();
    if (d > spread) spread = d;
  }
  // Corners disagree: this is not a plain studio background, so leave it alone
  // and let the screen tell the user instead of pretending it worked.
  if (spread > 90) return (image: src, changed: false);

  final nr = (color >> 16) & 0xFF;
  final ng = (color >> 8) & 0xFF;
  final nb = color & 0xFF;
  final out = src.clone();
  final tol = tolerance.toDouble();
  var changed = false;
  for (var y = 0; y < out.height; y++) {
    for (var x = 0; x < out.width; x++) {
      final p = out.getPixel(x, y);
      final d = (p.r - ar).abs() + (p.g - ag).abs() + (p.b - ab).abs();
      if (d < tol * 3) {
        out.setPixelRgb(x, y, nr, ng, nb);
        changed = true;
      }
    }
  }
  return (image: out, changed: changed);
}

Uint8List _extractSignature(
  img.Image src, {
  required int threshold,
  required bool transparent,
  int? width,
  int? height,
}) {
  var work = img.grayscale(src);
  final ink = img.Image(width: work.width, height: work.height, numChannels: 4);
  for (var y = 0; y < work.height; y++) {
    for (var x = 0; x < work.width; x++) {
      final lum = work.getPixel(x, y).r;
      if (lum < threshold) {
        ink.setPixelRgba(x, y, 0, 0, 0, 255);
      } else if (transparent) {
        ink.setPixelRgba(x, y, 255, 255, 255, 0);
      } else {
        ink.setPixelRgba(x, y, 255, 255, 255, 255);
      }
    }
  }
  var trimmed = img.trim(
    ink,
    mode: transparent ? img.TrimMode.transparent : img.TrimMode.topLeftColor,
  );
  if (width != null || height != null) {
    trimmed = img.copyResize(
      trimmed,
      width: width,
      height: height,
      interpolation: img.Interpolation.cubic,
    );
  }
  if (transparent) return Uint8List.fromList(img.encodePng(trimmed));
  return Uint8List.fromList(img.encodeJpg(trimmed, quality: 88));
}

class ImageBytes {
  /// Resizes to a KB window. [png] keeps transparency (and is the only format
  /// that can), everything else is JPEG.
  static Future<Uint8List> resizeToKb({
    required Uint8List bytes,
    required int targetKB,
    int? minKB,
    int? targetWidth,
    int? targetHeight,
    bool png = false,
  }) {
    return compute(
      resizeImageToKb,
      ResizeRequest(
        bytes,
        targetKB,
        targetWidth,
        targetHeight,
        minKB: minKB,
        png: png,
      ),
    );
  }

  /// Container format of [bytes]: 'png', 'jpg' or 'unknown'.
  static String detectFormat(Uint8List bytes) => detectImageFormat(bytes);

  static Future<List<int>> info(Uint8List bytes) async {
    final r = await compute(runImgJob, ImgJob('info', bytes));
    return (r as List).cast<int>();
  }

  static Future<Uint8List> rotate90(Uint8List bytes) async =>
      (await compute(runImgJob, ImgJob('rotate90', bytes))) as Uint8List;

  static Future<Uint8List> toPng(Uint8List bytes) async =>
      (await compute(runImgJob, ImgJob('convertPng', bytes))) as Uint8List;

  static Future<Uint8List> toJpg(Uint8List bytes, {int quality = 90}) async =>
      (await compute(runImgJob, ImgJob('convertJpg', bytes, a: quality)))
          as Uint8List;

  static Future<Uint8List> enhanceDocument(Uint8List bytes) async =>
      (await compute(runImgJob, ImgJob('enhance', bytes))) as Uint8List;

  static Future<Uint8List> trim(Uint8List bytes, {bool png = false}) async =>
      (await compute(runImgJob, ImgJob('trim', bytes, flag: png))) as Uint8List;

  static Future<Uint8List> letterbox({
    required Uint8List bytes,
    required int width,
    required int height,
    int bg = 0xFFFFFFFF,
  }) async =>
      (await compute(
        runImgJob,
        ImgJob('letterbox', bytes, a: width, b: height, c: bg),
      )) as Uint8List;

  static Future<Uint8List> fitExact({
    required Uint8List bytes,
    required int width,
    required int height,
  }) async =>
      (await compute(runImgJob, ImgJob('fitExact', bytes, a: width, b: height)))
          as Uint8List;

  static Future<Uint8List> replaceBackground({
    required Uint8List bytes,
    int color = 0xFFFFFFFF,
    int tolerance = 38,
  }) async =>
      (await compute(
        runImgJob,
        ImgJob('background', bytes, a: tolerance, c: color),
      )) as Uint8List;

  /// Like [replaceBackground], but reports whether anything actually changed -
  /// a busy photo background is left as it is and the caller must say so.
  static Future<BackgroundResult> replaceBackgroundDetailed({
    required Uint8List bytes,
    int color = 0xFFFFFFFF,
    int tolerance = 38,
  }) async =>
      (await compute(
        runImgJob,
        ImgJob('backgroundDetail', bytes, a: tolerance, c: color),
      )) as BackgroundResult;

  static Future<Uint8List> extractSignature({
    required Uint8List bytes,
    int threshold = 168,
    bool transparent = false,
    int? width,
    int? height,
  }) async =>
      (await compute(
        runImgJob,
        ImgJob(
          'signature',
          bytes,
          a: threshold,
          b: width,
          c: height,
          flag: transparent,
        ),
      )) as Uint8List;
}
