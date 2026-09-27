import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

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

  static Future<List<NamedBytes>> pdfs({bool multiple = true}) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: multiple,
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
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
