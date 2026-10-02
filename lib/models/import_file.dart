import 'dart:typed_data';

/// A picked file read only when its import turn starts. Native imports no longer
/// keep the whole batch in RAM; failed sources can be retried in this session.
class ImportFile {
  const ImportFile({required this.name, required this.read, this.size});

  final String name;
  final int? size;
  final Future<Uint8List> Function() read;
}
