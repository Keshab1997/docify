import 'package:flutter_test/flutter_test.dart';
import 'package:jobdoc/models/requirement_check.dart';

void main() {
  test('a file inside the KB window passes', () {
    final check = RequirementCheck.forFile(
      title: 'Photo',
      sizeBytes: 38 * 1024,
      spec: const FileSpec(minKb: 20, maxKb: 50),
      format: 'jpg',
    );
    expect(check.items.length, 1);
    expect(check.allPassed, isTrue);
    expect(check.summary, 'All checks passed');
  });

  test('a file under the minimum fails and names the window', () {
    final check = RequirementCheck.forFile(
      title: 'Signature',
      sizeBytes: 4 * 1024,
      spec: const FileSpec(minKb: 10, maxKb: 20),
      format: 'jpg',
    );
    expect(check.allPassed, isFalse);
    expect(check.failedCount, 1);
    expect(check.summary, contains('1 check'));
    expect(check.items.single.detail, contains('4.0 KB'));
    expect(check.items.single.detail, contains('KB'));
  });

  test('pixel size and format are only checked when the form asks', () {
    final check = RequirementCheck.forFile(
      title: 'Photo',
      sizeBytes: 30 * 1024,
      spec: const FileSpec(
        minKb: 20,
        maxKb: 50,
        width: 413,
        height: 531,
        format: 'jpg',
      ),
      width: 413,
      height: 531,
      format: 'jpg',
    );
    expect(check.items.length, 3);
    expect(check.allPassed, isTrue);
  });

  test('wrong pixels and wrong format are both reported', () {
    final check = RequirementCheck.forFile(
      title: 'Photo',
      sizeBytes: 30 * 1024,
      spec: const FileSpec(
        minKb: 20,
        maxKb: 50,
        width: 413,
        height: 531,
        format: 'jpg',
      ),
      width: 320,
      height: 240,
      format: 'png',
    );
    expect(check.allPassed, isFalse);
    expect(check.failedCount, 2);
  });

  test('unreadable dimensions fail loudly instead of passing', () {
    final check = RequirementCheck.forFile(
      title: 'Photo',
      sizeBytes: 30 * 1024,
      spec: const FileSpec(width: 413, height: 531),
    );
    expect(check.allPassed, isFalse);
    expect(check.items.single.detail, contains('could not be read'));
  });

  test('a maximum with no minimum still checks the cap', () {
    final over = RequirementCheck.forFile(
      title: 'Photo',
      sizeBytes: 80 * 1024,
      spec: const FileSpec(maxKb: 50),
    );
    expect(over.allPassed, isFalse);

    final under = RequirementCheck.forFile(
      title: 'Photo',
      sizeBytes: 10 * 1024,
      spec: const FileSpec(maxKb: 50),
    );
    expect(under.allPassed, isTrue);
  });
}
