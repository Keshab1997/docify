import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

class ShareFile {
  const ShareFile(
      {required this.bytes, required this.name, required this.mime});
  final Uint8List bytes;
  final String name;
  final String mime;
}

class ShareBytes {
  static Future<void> share({
    required Uint8List bytes,
    required String name,
    required String mime,
  }) =>
      shareMany([ShareFile(bytes: bytes, name: name, mime: mime)]);

  static Future<void> shareMany(List<ShareFile> files) {
    if (files.isEmpty) return Future.value();
    return SharePlus.instance.share(ShareParams(
      files: [
        for (final file in files)
          XFile.fromData(file.bytes, name: file.name, mimeType: file.mime)
      ],
      fileNameOverrides: [for (final file in files) file.name],
    ));
  }
}
