import 'dart:io';
import 'dart:typed_data';

import 'package:gal/gal.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'storage_service.dart';

class GallerySave {
  static Future<void> saveJpeg(Uint8List bytes, String name) async {
    final temp = await getTemporaryDirectory();
    final file = File(p.join(temp.path, name));
    await file.writeAsBytes(bytes, flush: true);
    await StorageService.saveToMyDocuments(file);

    final allowed = await Gal.requestAccess();
    if (!allowed) {
      throw Exception('Gallery permission was not granted');
    }
    await Gal.putImageBytes(bytes, name: name);
  }
}
