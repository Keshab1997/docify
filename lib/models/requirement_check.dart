import 'saved_doc.dart';

/// What a form asks for. A zero size or a null field is simply not checked.
class FileSpec {
  const FileSpec({
    this.minKb = 0,
    this.maxKb = 0,
    this.width,
    this.height,
    this.format,
  });

  final int minKb;
  final int maxKb;
  final int? width;
  final int? height;

  /// 'jpg' or 'png'. Null means the form takes either.
  final String? format;
}

/// One requirement and how the finished file did against it.
class FileCheck {
  const FileCheck(this.label, this.passed, this.detail);

  final String label;
  final bool passed;
  final String detail;
}

/// The pass/fail list JobDoc shows before a file is uploaded to a portal.
/// Pure data, so it is cheap to unit test.
class RequirementCheck {
  const RequirementCheck(this.title, this.items);

  final String title;
  final List<FileCheck> items;

  bool get allPassed => items.every((item) => item.passed);

  int get failedCount => items.where((item) => !item.passed).length;

  String get summary => allPassed
      ? 'All checks passed'
      : '$failedCount check${failedCount == 1 ? '' : 's'} need attention';

  /// Checks a finished file against [spec]. [width], [height] and [format] are
  /// read from the bytes; pass null when they could not be determined.
  static RequirementCheck forFile({
    required String title,
    required int sizeBytes,
    required FileSpec spec,
    int? width,
    int? height,
    String? format,
  }) {
    final items = <FileCheck>[];

    if (spec.width != null && spec.height != null) {
      final known = width != null && height != null;
      items.add(
        FileCheck(
          'Pixel size',
          known && width == spec.width && height == spec.height,
          known
              ? '$width×$height px (form wants ${spec.width}×${spec.height})'
              : 'could not be read — form wants ${spec.width}×${spec.height}',
        ),
      );
    }

    if (spec.maxKb > 0 || spec.minKb > 0) {
      final kb = sizeBytes / 1024;
      final above = spec.minKb == 0 || sizeBytes >= spec.minKb * 1024;
      final below = spec.maxKb == 0 || sizeBytes <= spec.maxKb * 1024;
      items.add(
        FileCheck(
          'File size',
          above && below,
          '${kbLabel(sizeBytes)} '
              '(${_kbRange(spec.minKb, spec.maxKb)})',
        ),
      );
    }

    if (spec.format != null) {
      final actual = format ?? 'unknown';
      items.add(
        FileCheck(
          'Format',
          actual == spec.format,
          '${_formatName(actual)} (form wants ${_formatName(spec.format!)})',
        ),
      );
    }

    return RequirementCheck(title, items);
  }
}

String _kbRange(int minKb, int maxKb) {
  if (minKb > 0 && maxKb > 0) return 'form wants $minKb–$maxKb KB';
  if (maxKb > 0) return 'form wants up to $maxKb KB';
  return 'form wants at least $minKb KB';
}

String _formatName(String format) {
  switch (format) {
    case 'jpg':
      return 'JPEG';
    case 'png':
      return 'PNG';
    default:
      return 'unknown';
  }
}
