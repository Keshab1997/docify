class OcrResult {
  const OcrResult(
      {required this.text, required this.pages, this.truncated = false});
  final String text;
  final int pages;
  final bool truncated;
}
