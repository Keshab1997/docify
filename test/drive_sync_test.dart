import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:docify/models/saved_doc.dart';
import 'package:docify/services/doc_folders.dart';
import 'package:docify/services/doc_deletions.dart';
import 'package:docify/services/drive/drive_api.dart';
import 'package:docify/services/drive/drive_sync.dart';
import 'package:docify/services/drive/folder_backup.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One file in the pretend Drive folder.
class _DriveFile {
  _DriveFile(this.id, this.name, this.bytes);

  final String id;
  final String name;
  List<int> bytes;

  Map<String, Object> get json => {
        'id': id,
        'name': name,
        'size': '${bytes.length}',
        'md5Checksum': md5.convert(bytes).toString(),
      };
}

/// The Docify folder on a pretend Google Drive, answering the same REST
/// calls DriveApi makes.
class _FakeDrive {
  final files = <String, _DriveFile>{};
  var updates = 0;
  var _ids = 0;

  DriveApi get api => DriveApi('token', client: MockClient(_answer));

  Iterable<String> get names => files.values.map((f) => f.name);

  FolderBackup get backup {
    const name = FolderBackup.fileName;
    final file = files.values.singleWhere((f) => f.name == name);
    return FolderBackup.parse(file.bytes);
  }

  Future<http.Response> _answer(http.Request request) async {
    final id = request.url.pathSegments.last;
    final query = request.url.queryParameters;
    switch (request.method) {
      case 'GET' when '${query['q']}'.contains('mimeType'):
        return _json({
          'files': [
            {'id': 'docify', 'name': 'Docify'},
          ],
        });
      case 'GET' when query['alt'] == 'media':
        return http.Response.bytes(files[id]!.bytes, 200);
      case 'GET':
        return _json({
          'files': [for (final f in files.values) f.json],
        });
      case 'POST':
        // Multipart: the JSON metadata, then the content.
        final body = latin1.decode(request.bodyBytes);
        final parts = body.split('--docify-sync-boundary');
        final meta = jsonDecode(_content(parts[1])) as Map<String, dynamic>;
        final file = _DriveFile(
          'd${_ids++}',
          meta['name'] as String,
          latin1.encode(_content(parts[2])),
        );
        files[file.id] = file;
        return _json({'id': file.id});
      case 'PATCH':
        files[id]!.bytes = request.bodyBytes;
        updates++;
        return _json({'id': id});
    }
    return http.Response('Unexpected ${request.method}', 400);
  }

  static String _content(String part) {
    final start = part.indexOf('\r\n\r\n') + 4;
    return part.substring(start, part.length - 2);
  }

  static http.Response _json(Object data) {
    return http.Response(
      jsonEncode(data),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
}

/// A phone's documents, kept in memory.
class _Phone extends LocalDocs {
  final files = <String, Uint8List>{};

  void add(String name, String content) {
    files[name] = Uint8List.fromList(utf8.encode(content));
  }

  SavedDoc doc(String name) {
    return SavedDoc(
      id: name,
      name: name,
      mime: mimeFromName(name),
      size: files[name]!.length,
      modified: DateTime(2026),
    );
  }

  @override
  Future<List<SavedDoc>> list() async => [for (final n in files.keys) doc(n)];

  @override
  Future<Uint8List> read(SavedDoc doc) async => files[doc.id]!;

  @override
  Future<SavedDoc> save({
    required Uint8List bytes,
    required String name,
    String? mime,
  }) async {
    files[name] = bytes;
    return doc(name);
  }
}

Future<SyncOutcome> _sync(_FakeDrive drive) async {
  final plan = await DriveSync.plan(drive.api);
  return DriveSync.run(drive.api, plan, onProgress: (_, __, ___) {});
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a new phone puts restored files back in their folders', () async {
    final drive = _FakeDrive();

    // The old phone: a folder of the user's with a file in it, a file in
    // ID Proof, and a photo never put anywhere.
    DriveSync.docs = _Phone()
      ..add('admit.pdf', 'admit card')
      ..add('aadhaar.pdf', 'aadhaar')
      ..add('photo.jpg', 'photo');
    final wbssc = await DocFolders.create('WBSSC 2026');
    await DocFolders.create('Railway Form');
    await DocFolders.file(['admit.pdf'], wbssc);
    await DocFolders.file(['aadhaar.pdf'], BuiltInFolder.idProof.folder);
    await _sync(drive);
    expect(drive.names, hasLength(4));
    expect(drive.backup.folders, hasLength(2));

    // The new phone starts with nothing.
    SharedPreferences.setMockInitialValues({});
    final phone = _Phone();
    DriveSync.docs = phone;
    final plan = await DriveSync.plan(drive.api);
    final names = [for (final f in plan.downloads) f.name];
    expect(names, unorderedEquals(['admit.pdf', 'aadhaar.pdf', 'photo.jpg']));
    expect(plan.folders.create, hasLength(2));

    final outcome = await DriveSync.run(
      drive.api,
      plan,
      onProgress: (_, __, ___) {},
    );
    expect(outcome.folders, 2);
    expect(outcome.changed, isTrue);

    final library = await DocFolders.load();
    final folders = [for (final f in library.custom) f.name];
    expect(folders, ['Railway Form', 'WBSSC 2026']);
    String folderOf(String name) => library.folderOf(phone.doc(name)).name;
    expect(folderOf('admit.pdf'), 'WBSSC 2026');
    expect(folderOf('aadhaar.pdf'), 'ID Proof');
    expect(folderOf('photo.jpg'), 'Photo & Signature');

    // The backup never came down as a document, and it was already right.
    expect(phone.files.keys, isNot(contains(FolderBackup.fileName)));
    expect(drive.updates, 0);
    expect((await DriveSync.plan(drive.api)).isEmpty, isTrue);
  });

  test('moving a file updates the backup instead of adding one', () async {
    final drive = _FakeDrive();
    DriveSync.docs = _Phone()..add('admit.pdf', 'admit card');
    final wbssc = await DocFolders.create('WBSSC 2026');
    await DocFolders.file(['admit.pdf'], wbssc);
    await _sync(drive);

    await DocFolders.file(['admit.pdf'], BuiltInFolder.jobForms.folder);
    final plan = await DriveSync.plan(drive.api);
    expect(plan.total, 0);
    expect(plan.isEmpty, isFalse);
    await DriveSync.run(drive.api, plan, onProgress: (_, __, ___) {});

    expect(drive.updates, 1);
    expect(drive.names, hasLength(2));
    expect(drive.backup.files.values, ['jobForms']);
  });

  test('a folder deleted on this phone stays deleted', () async {
    final drive = _FakeDrive();
    DriveSync.docs = _Phone()..add('admit.pdf', 'admit card');
    final wbssc = await DocFolders.create('WBSSC 2026');
    await DocFolders.file(['admit.pdf'], wbssc);
    await _sync(drive);

    await DocFolders.remove(wbssc.id);
    await _sync(drive);
    expect((await DocFolders.load()).custom, isEmpty);
    expect(drive.backup.folders, isEmpty);
    expect(drive.backup.files.values, ['others']);
  });
  test('a local deletion is not downloaded again, including a stale plan', () async {
    final drive = _FakeDrive();
    final old = _Phone()..add('id.pdf', 'private id');
    DriveSync.docs = old;
    await _sync(drive);
    final digest = DriveSync.md5Hex(old.files['id.pdf']!);
    final fresh = _Phone();
    DriveSync.docs = fresh;
    final stale = await DriveSync.plan(drive.api);
    expect(stale.downloads, hasLength(1));
    await DocDeletions.record(name: 'id.pdf', digest: digest);
    final outcome = await DriveSync.run(drive.api, stale, onProgress: (_, __, ___) {});
    expect(outcome.downloaded, 0);
    expect(fresh.files, isEmpty);
    expect((await DriveSync.plan(drive.api)).downloads, isEmpty);
    expect(drive.names, contains('id.pdf'));
  });

}
