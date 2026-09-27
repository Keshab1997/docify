import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:jobdoc/services/pdf_merge.dart';
import 'package:jobdoc/services/pdf_service.dart';

Uint8List _jpeg() {
  final image = img.Image(width: 40, height: 50);
  img.fill(image, color: img.ColorRgb8(10, 80, 160));
  return Uint8List.fromList(img.encodeJpg(image, quality: 80));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('classic merge concatenates pages', () async {
    final a = await PdfService.imagesToPdf([_jpeg()]);
    final b = await PdfService.imagesToPdf([_jpeg(), _jpeg()]);
    final merged = mergeClassicPdfs([a, b]);
    expect(latin1.decode(merged.sublist(0, 4)), '%PDF');
    expect(merged.length, greaterThan(a.length));
    expect(latin1.decode(merged), contains('/Count 3'));
  });

  test('imagesToPdf writes a PDF header', () async {
    final pdf = await PdfService.imagesToPdf([_jpeg()]);
    expect(latin1.decode(pdf.sublist(0, 4)), '%PDF');
  });
}
