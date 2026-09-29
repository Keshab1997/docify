import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:docify/services/pdf_merge.dart';
import 'package:docify/services/pdf_service.dart';

Uint8List _jpeg() {
  final image = img.Image(width: 40, height: 50);
  img.fill(image, color: img.ColorRgb8(10, 80, 160));
  return Uint8List.fromList(img.encodeJpg(image, quality: 80));
}

Uint8List _onePagePdf() {
  final buf = BytesBuilder();
  void w(String t) => buf.add(latin1.encode(t));
  w('%PDF-1.4\n');
  final offsets = <int, int>{};
  void obj(int id, String body) {
    offsets[id] = buf.length;
    w('$id 0 obj\n$body\nendobj\n');
  }

  obj(1, '<< /Type /Catalog /Pages 2 0 R >>');
  obj(2, '<< /Type /Pages /Count 1 /Kids [ 3 0 R ] /MediaBox [0 0 200 200] >>');
  obj(3, '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 200 200] >>');
  final xref = buf.length;
  w('xref\n0 4\n');
  w('0000000000 65535 f \n');
  for (var i = 1; i < 4; i++) {
    w('${offsets[i]!.toString().padLeft(10, '0')} 00000 n \n');
  }
  w('trailer\n<< /Size 4 /Root 1 0 R >>\nstartxref\n$xref\n%%EOF\n');
  return Uint8List.fromList(buf.takeBytes());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('classic merge concatenates pages', () {
    final merged = mergeClassicPdfs([_onePagePdf(), _onePagePdf()]);
    expect(latin1.decode(merged.sublist(0, 4)), '%PDF');
    expect(latin1.decode(merged), contains('/Count 2'));
  });

  test('imagesToPdf writes a PDF header', () async {
    final pdf = await PdfService.imagesToPdf([_jpeg()]);
    expect(latin1.decode(pdf.sublist(0, 4)), '%PDF');
  });
}
