class SavedDoc {
  const SavedDoc({
    required this.id,
    required this.name,
    required this.mime,
    required this.size,
    required this.modified,
  });

  final String id;
  final String name;
  final String mime;
  final int size;
  final DateTime modified;

  bool get isPdf =>
      mime == 'application/pdf' || name.toLowerCase().endsWith('.pdf');
  bool get isImage => mime.startsWith('image/') || _imageExt.hasMatch(name);

  static final _imageExt = RegExp(
    r'\.(jpe?g|png|webp|gif|bmp)$',
    caseSensitive: false,
  );
}

String mimeFromName(String name) {
  final n = name.toLowerCase();
  if (n.endsWith('.png')) return 'image/png';
  if (n.endsWith('.webp')) return 'image/webp';
  if (n.endsWith('.pdf')) return 'application/pdf';
  if (n.endsWith('.gif')) return 'image/gif';
  if (n.endsWith('.jpg') || n.endsWith('.jpeg')) return 'image/jpeg';
  return 'application/octet-stream';
}

String kbLabel(int bytes) => '${(bytes / 1024).toStringAsFixed(1)} KB';

String uniqueJobDocName(String ext) {
  final t = DateTime.now();
  String two(int n) => n.toString().padLeft(2, '0');
  return 'JobDoc_${t.year}${two(t.month)}${two(t.day)}_${two(t.hour)}${two(t.minute)}${two(t.second)}.$ext';
}
