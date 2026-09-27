import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class ResizeRequest {
  const ResizeRequest(
    this.bytes,
    this.targetKB,
    this.width,
    this.height, {
    this.minKB,
  });

  final Uint8List bytes;
  final int targetKB;
  final int? minKB;
  final int? width;
  final int? height;
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

Uint8List resizeJpegToKb(ResizeRequest request) {
  final decoded = _decodeSized(request.bytes, request.width, request.height);
  return _encodeToKb(decoded, request.targetKB, minKB: request.minKB);
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
      decoded = _replaceBackground(decoded, job.c ?? 0xFFFFFFFF, job.a ?? 38);
      return Uint8List.fromList(img.encodeJpg(decoded, quality: 92));
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

Uint8List _encodeToKb(img.Image decoded, int targetKB, {int? minKB}) {
  var work = decoded;
  var low = 10;
  var high = 95;
  Uint8List? bestBytes;
  final targetBytes = targetKB * 1024;
  final minBytes = (minKB ?? 0) * 1024;

  for (var i = 0; i < 10; i++) {
    final mid = (low + high) ~/ 2;
    final jpg = Uint8List.fromList(img.encodeJpg(work, quality: mid));
    if (jpg.length <= targetBytes) {
      bestBytes = jpg;
      low = mid + 1;
      if ((targetBytes - jpg.length).abs() < 1024) break;
    } else {
      high = mid - 1;
    }
  }

  var out =
      bestBytes ??
      Uint8List.fromList(img.encodeJpg(work, quality: low.clamp(10, 95)));

  var attempts = 0;
  while (out.length > targetBytes && attempts < 6) {
    work = img.copyResize(
      work,
      width: (work.width * 0.88).toInt().clamp(40, work.width),
    );
    out = Uint8List.fromList(img.encodeJpg(work, quality: 55));
    attempts++;
  }

  if (minBytes > 0 && out.length < minBytes) {
    for (final q in [85, 90, 95]) {
      final jpg = Uint8List.fromList(img.encodeJpg(decoded, quality: q));
      if (jpg.length <= targetBytes && jpg.length >= minBytes) {
        return jpg;
      }
      if (jpg.length <= targetBytes && jpg.length > out.length) {
        out = jpg;
      }
    }
  }

  return out;
}

img.Image _replaceBackground(img.Image src, int color, int tolerance) {
  if (src.width < 8 || src.height < 8) return src;
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
    final d =
        (ch(p, 'r') - ar).abs() +
        (ch(p, 'g') - ag).abs() +
        (ch(p, 'b') - ab).abs();
    if (d > spread) spread = d;
  }
  if (spread > 90) return src;

  final nr = (color >> 16) & 0xFF;
  final ng = (color >> 8) & 0xFF;
  final nb = color & 0xFF;
  final out = src.clone();
  final tol = tolerance.toDouble();
  for (var y = 0; y < out.height; y++) {
    for (var x = 0; x < out.width; x++) {
      final p = out.getPixel(x, y);
      final d = (p.r - ar).abs() + (p.g - ag).abs() + (p.b - ab).abs();
      if (d < tol * 3) {
        out.setPixelRgb(x, y, nr, ng, nb);
      }
    }
  }
  return out;
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
  static Future<Uint8List> resizeToKb({
    required Uint8List bytes,
    required int targetKB,
    int? minKB,
    int? targetWidth,
    int? targetHeight,
  }) {
    return compute(
      resizeJpegToKb,
      ResizeRequest(bytes, targetKB, targetWidth, targetHeight, minKB: minKB),
    );
  }

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
  }) async => (await compute(
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
  }) async => (await compute(
    runImgJob,
    ImgJob('background', bytes, a: tolerance, c: color),
  )) as Uint8List;

  static Future<Uint8List> extractSignature({
    required Uint8List bytes,
    int threshold = 168,
    bool transparent = false,
    int? width,
    int? height,
  }) async => (await compute(
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
