import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:jobdoc/services/image_bytes.dart';

Uint8List _jpeg({int w = 120, int h = 160}) {
  final image = img.Image(width: w, height: h);
  img.fill(image, color: img.ColorRgb8(180, 90, 40));
  return Uint8List.fromList(img.encodeJpg(image, quality: 95));
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
}
