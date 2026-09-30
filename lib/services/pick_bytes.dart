import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../models/saved_doc.dart';
import 'image_bytes.dart';
import 'read_path.dart';

class NamedBytes {
  const NamedBytes(this.name, this.bytes);
  final String name;
  final Uint8List bytes;
}

class PickBytes {
  static final _images = ImagePicker();

  static Future<Uint8List?> image(ImageSource source) async {
    final x = await _images.pickImage(source: source, imageQuality: 98);
    if (x == null) return null;
    return x.readAsBytes();
  }

  static Future<List<Uint8List>> images() async {
    final picked = await _images.pickMultiImage(imageQuality: 98);
    final out = <Uint8List>[];
    for (final x in picked) {
      out.add(await x.readAsBytes());
    }
    return out;
  }

  static Future<List<NamedBytes>> pdfs({bool multiple = true}) {
    return _files(const ['pdf'], multiple: multiple);
  }

  /// PDFs and photos saved on the phone, such as a downloaded application
  /// form or a scanned certificate, under their own names.
  static Future<List<NamedBytes>> documents() {
    return _files(const ['pdf', 'jpg', 'jpeg', 'png', 'webp']);
  }

  /// Photos of paper documents from the gallery or the camera. Their own
  /// names say nothing about the page, so each gets a dated Docify name with
  /// the extension of what it really is.
  static Future<List<NamedBytes>> photos(ImageSource source) async {
    final List<Uint8List> picked;
    if (source == ImageSource.camera) {
      final shot = await image(source);
      picked = [if (shot != null) shot];
    } else {
      picked = await images();
    }
    return [
      for (final bytes in picked)
        NamedBytes(
          uniqueDocifyName(detectImageFormat(bytes) == 'png' ? 'png' : 'jpg'),
          bytes,
        ),
    ];
  }

  static Future<List<NamedBytes>> _files(
    List<String> extensions, {
    bool multiple = true,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: multiple,
      type: FileType.custom,
      allowedExtensions: extensions,
      withData: true,
    );
    if (result == null) return const [];
    final list = <NamedBytes>[];
    for (final f in result.files) {
      var b = f.bytes;
      if (b == null || b.isEmpty) {
        b = await readFilePath(f.path);
      }
      if (b != null && b.isNotEmpty) {
        list.add(NamedBytes(f.name, b));
      }
    }
    return list;
  }
}
