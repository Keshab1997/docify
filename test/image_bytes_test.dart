import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:jobdoc/services/image_bytes.dart';

Uint8List _jpeg({int w = 120, int h = 160}) {
  final image = img.Image(width: w, height: h);
  img.fill(image, color: img.ColorRgb8(180, 90, 40));
  return Uint8List.fromList(img.encodeJpg(image, quality: 95));
}

Uint8List _transparentPng() {
  final image = img.Image(width: 240, height: 120, numChannels: 4);
  for (var x = 20; x < 220; x++) {
    image.setPixelRgba(x, 60, 0, 0, 0, 255);
  }
  return Uint8List.fromList(img.encodePng(image));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('resizeToKb stays under the max', () async {
    final out = await ImageBytes.resizeToKb(
      bytes: _jpeg(),
      targetKB: 15,
      targetWidth: 60,
      targetHeight: 80,
    );
    expect(out.length, lessThanOrEqualTo(15 * 1024));
    final info = await ImageBytes.info(out);
    expect(info[0], 60);
    expect(info[1], 80);
  });

  test('convert to png and back', () async {
    final png = await ImageBytes.toPng(_jpeg());
    expect(png[0], 0x89);
    final jpg = await ImageBytes.toJpg(png, quality: 80);
    expect(jpg[0], 0xFF);
  });

  test('a PNG target keeps PNG bytes, so transparency survives', () async {
    final out = await ImageBytes.resizeToKb(
      bytes: _transparentPng(),
      targetKB: 8,
      png: true,
    );
    expect(ImageBytes.detectFormat(out), 'png');
    expect(out.length, lessThanOrEqualTo(8 * 1024));
  });

  test('the KB maximum is honoured even when the minimum cannot be met',
      () async {
    final out = await ImageBytes.resizeToKb(
      bytes: _jpeg(),
      targetKB: 6,
      minKB: 40,
    );
    expect(out.length, lessThanOrEqualTo(6 * 1024));
    expect(ImageBytes.detectFormat(out), 'jpg');
  });

  test('requested pixel dimensions survive a resize', () async {
    final out = await ImageBytes.resizeToKb(
      bytes: _jpeg(w: 400, h: 400),
      targetKB: 200,
      minKB: 100,
      targetWidth: 413,
      targetHeight: 531,
    );
    final info = await ImageBytes.info(out);
    expect(info[0], 413);
    expect(info[1], 531);
  });

  test('detectImageFormat reads the real container', () {
    expect(ImageBytes.detectFormat(_jpeg()), 'jpg');
    expect(ImageBytes.detectFormat(_transparentPng()), 'png');
    expect(
      ImageBytes.detectFormat(Uint8List.fromList([1, 2, 3])),
      'unknown',
    );
  });

  test('a non-uniform background is reported instead of faked', () async {
    // Four corners of different colours: nothing can be replaced here.
    final busy = img.Image(width: 60, height: 60);
    img.fill(busy, color: img.ColorRgb8(255, 255, 255));
    img.fillRect(
      busy,
      x1: 0,
      y1: 0,
      x2: 10,
      y2: 10,
      color: img.ColorRgb8(0, 0, 0),
    );
    img.fillRect(
      busy,
      x1: 45,
      y1: 45,
      x2: 59,
      y2: 59,
      color: img.ColorRgb8(200, 30, 30),
    );
    final result = await ImageBytes.replaceBackgroundDetailed(
      bytes: Uint8List.fromList(img.encodeJpg(busy, quality: 90)),
      color: 0xFFB3D4F7,
    );
    expect(result.changed, isFalse);
  });
}
