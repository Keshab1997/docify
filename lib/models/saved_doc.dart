import 'dart:convert';

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

const _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Human date for a file row: "Today 14:05", "Yesterday 09:30",
/// otherwise "12 Sep 2026".
String dateLabel(DateTime when) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(when.year, when.month, when.day);
  final clock = '${when.hour.toString().padLeft(2, '0')}'
      ':${when.minute.toString().padLeft(2, '0')}';
  if (day == today) return 'Today $clock';
  if (day == today.subtract(const Duration(days: 1))) return 'Yesterday $clock';
  return '${when.day} ${_monthNames[when.month - 1]} ${when.year}';
}

String uniqueDocifyName(String ext) {
  final t = DateTime.now();
  String two(int n) => n.toString().padLeft(2, '0');
  return 'Docify_${t.year}${two(t.month)}${two(t.day)}_${two(t.hour)}${two(t.minute)}${two(t.second)}.$ext';
}

/// [name] without its extension, for editing.
String nameStem(String name) {
  final dot = name.lastIndexOf('.');
  return dot <= 0 ? name : name.substring(0, dot);
}

/// [original] renamed to [stem] but keeping its extension, so the file
/// still opens as what it is. A blank [stem] keeps the original name, and a
/// slash cannot sneak in a folder.
String renameKeepingExtension(String original, String stem) {
  final clean = stem.trim().replaceAll(RegExp(r'[\\/]'), '-');
  if (clean.isEmpty) return original;
  final dot = original.lastIndexOf('.');
  if (dot <= 0) return clean;
  final ext = original.substring(dot);
  return clean.toLowerCase().endsWith(ext.toLowerCase()) ? clean : '$clean$ext';
}

/// Checks the editable name while keeping the original format. Case-insensitive
/// conflicts are rejected even on file systems that permit both spellings.
String? documentNameError(
  String original,
  String stem,
  Iterable<String> names, {
  String? except,
}) {
  final clean = stem.trim();
  if (clean.isEmpty) return 'Enter a file name';
  if (clean == '.' ||
      clean == '..' ||
      RegExp(r'[\\/\x00-\x1f]').hasMatch(clean)) {
    return 'Use a name without slashes or control characters';
  }
  final next = renameKeepingExtension(original, clean);
  if (utf8.encode(next).length > 240) return 'Use a shorter file name';
  for (final name in names) {
    if (name != except && name.toLowerCase() == next.toLowerCase()) {
      return 'A document named $next already exists';
    }
  }
  return null;
}

/// Human size for the library. Tool KB-limit labels intentionally stay in KB.
String fileSizeLabel(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return kbLabel(bytes);
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}
