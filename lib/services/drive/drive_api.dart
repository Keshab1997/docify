import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// One file (or folder) inside the user's Google Drive.
class DriveFile {
  const DriveFile({
    required this.id,
    required this.name,
    this.md5,
    this.size = 0,
  });

  final String id;
  final String name;
  final String? md5;
  final int size;

  factory DriveFile.fromJson(Map<String, dynamic> json) => DriveFile(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        md5: json['md5Checksum'] as String?,
        size: int.tryParse('${json['size'] ?? 0}') ?? 0,
      );
}

/// Drive REST error. [status] 401 means the token expired (web tokens last
/// about an hour) — the caller should re-authorize and retry.
class DriveException implements Exception {
  DriveException(this.status, this.message);

  final int status;
  final String message;

  bool get isUnauthorized => status == 401 || status == 403;

  @override
  String toString() => 'DriveException($status): $message';
}

/// Thin Google Drive v3 REST client (file scope) over package:http — plain
/// enough to work on every platform the app builds for, and small enough to
/// read in one sitting. Auth is just a bearer token; token lifecycle lives
/// in AppAuth.
class DriveApi {
  DriveApi(this.token, {http.Client? client})
      : _client = client ?? http.Client();

  final String token;
  final http.Client _client;

  static const String _api = 'https://www.googleapis.com/drive/v3';
  static const String _uploadApi = 'https://www.googleapis.com/upload/drive/v3';

  /// The single folder sync keeps everything in.
  static const String folderName = 'Docify';

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      };

  dynamic _decode(http.Response res) {
    dynamic data;
    try {
      data = jsonDecode(res.body);
    } catch (_) {
      data = null;
    }
    if (res.statusCode >= 400) {
      final err = data is Map ? data['error'] : null;
      final msg = err is Map
          ? '${err['message'] ?? res.body}'
          : (res.body.isEmpty ? 'HTTP ${res.statusCode}' : res.body);
      throw DriveException(res.statusCode, msg);
    }
    return data;
  }

  List<Map<String, dynamic>> _filesOf(dynamic data) {
    final files = data is Map ? data['files'] : null;
    if (files is! List) return const [];
    return [for (final f in files) f as Map<String, dynamic>];
  }

  /// Finds (or creates) the app's `Docify/` folder in My Drive and returns
  /// its file id. Listing `drive.file`-scoped files also finds this folder
  /// once it exists, so this never duplicates.
  Future<String> ensureFolder() async {
    const q = "mimeType='application/vnd.google-apps.folder' "
        "and name='$folderName' and trashed=false";
    final res = await _client.get(
      Uri.parse(
        '$_api/files?q=${Uri.encodeQueryComponent(q)}'
        '&fields=files(id,name)&spaces=drive',
      ),
      headers: _headers,
    );
    final existing = _filesOf(_decode(res));
    if (existing.isNotEmpty) return existing.first['id'] as String;

    final created = await _client.post(
      Uri.parse('$_api/files?fields=id'),
      headers: {
        ..._headers,
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'name': folderName,
        'mimeType': 'application/vnd.google-apps.folder',
      }),
    );
    final data = _decode(created) as Map<String, dynamic>;
    return data['id'] as String;
  }

  /// All non-trashed files directly under [folderId], with md5 + size.
  Future<List<DriveFile>> listFiles(String folderId) async {
    final q = "'$folderId' in parents and trashed=false";
    final res = await _client.get(
      Uri.parse(
        '$_api/files?q=${Uri.encodeQueryComponent(q)}'
        '&fields=files(id,name,size,md5Checksum)&pageSize=1000',
      ),
      headers: _headers,
    );
    return [for (final f in _filesOf(_decode(res))) DriveFile.fromJson(f)];
  }

  /// Uploads a small local file with a manual multipart/related body:
  /// package:http cannot set a per-part Content-Type, and Drive rejects
  /// metadata without one. Body is built by hand and posted once.
  Future<void> uploadFile({
    required String folderId,
    required String name,
    required Uint8List bytes,
    required String mime,
  }) async {
    const boundary = 'docify-sync-boundary';
    final body = Uint8List.fromList([
      ...utf8.encode(
        '--$boundary\r\n'
        'Content-Type: application/json; charset=UTF-8\r\n\r\n'
        '${jsonEncode({
              'name': name,
              'parents': [folderId]
            })}\r\n',
      ),
      ...utf8.encode('--$boundary\r\nContent-Type: $mime\r\n\r\n'),
      ...bytes,
      ...utf8.encode('\r\n--$boundary--'),
    ]);
    final res = await _client.post(
      Uri.parse('$_uploadApi/files?uploadType=multipart&fields=id,name'),
      headers: {
        ..._headers,
        'Content-Type': 'multipart/related; boundary=$boundary',
      },
      body: body,
    );
    _decode(res);
  }

  /// Downloads a file's bytes (`alt=media`). Non-Google files only, which
  /// is all this app puts in the folder.
  Future<Uint8List> download(String fileId) async {
    final res = await _client.get(
      Uri.parse('$_api/files/$fileId?alt=media'),
      headers: _headers,
    );
    _decode(res);
    return res.bodyBytes;
  }
}
