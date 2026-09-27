import 'dart:convert';
import 'dart:typed_data';

/// Classic PDF 1.4 object-copy merger. Throws if the file uses object streams.
Uint8List mergeClassicPdfs(List<Uint8List> files) {
  if (files.length < 2) {
    throw ArgumentError('Need at least 2 PDFs');
  }

  final pageIds = <int>[];
  final out = <int, String>{};
  var nextId = 3;

  for (final file in files) {
    final parsed = _PdfFile.parse(file);
    final idMap = <int, int>{};
    for (final id in parsed.objects.keys) {
      final obj = parsed.objects[id]!;
      if (obj.isCatalog || obj.isPages) continue;
      idMap[id] = nextId++;
    }
    if (parsed.pageOrder.isEmpty) {
      throw Exception('No pages in a PDF');
    }
    for (final oldId in parsed.objects.keys) {
      if (!idMap.containsKey(oldId)) continue;
      final obj = parsed.objects[oldId]!;
      var dict = _remapRefs(obj.dictText, idMap);
      if (obj.isPage) {
        dict = dict.replaceAll(
          RegExp(r'/Parent\s+\d+\s+\d+\s+R'),
          '/Parent 2 0 R',
        );
        if (!RegExp(r'/MediaBox').hasMatch(dict) && parsed.mediaBox != null) {
          dict = dict.replaceFirst('<<', '<< /MediaBox ${parsed.mediaBox} ');
        }
      }
      if (obj.streamBytes != null) {
        dict = dict.replaceAll(
          RegExp(r'/Length\s+\d+(?:\s+\d+\s+R)?'),
          '/Length ${obj.streamBytes!.length}',
        );
      }
      out[idMap[oldId]!] = _compose(dict, obj.streamBytes);
    }
    for (final oldPage in parsed.pageOrder) {
      final nid = idMap[oldPage];
      if (nid != null) pageIds.add(nid);
    }
  }

  if (pageIds.isEmpty) throw Exception('Nothing to merge');

  final buf = BytesBuilder();
  void addStr(String t) => buf.add(latin1.encode(t));

  addStr('%PDF-1.4\n%\x80\x81\x82\x83\n');
  final offsets = <int, int>{};

  void writeObj(int id, String content) {
    offsets[id] = buf.length;
    addStr('$id 0 obj\n$content\nendobj\n');
  }

  writeObj(1, '<< /Type /Catalog /Pages 2 0 R >>');
  final kids = pageIds.map((id) => '$id 0 R').join(' ');
  writeObj(2, '<< /Type /Pages /Count ${pageIds.length} /Kids [ $kids ] >>');
  final ids = out.keys.toList()..sort();
  for (final id in ids) {
    writeObj(id, out[id]!);
  }

  final xrefAt = buf.length;
  addStr('xref\n0 $nextId\n');
  addStr('0000000000 65535 f \n');
  for (var i = 1; i < nextId; i++) {
    final off = offsets[i] ?? 0;
    addStr('${off.toString().padLeft(10, '0')} 00000 n \n');
  }
  addStr(
    'trailer\n<< /Size $nextId /Root 1 0 R >>\nstartxref\n$xrefAt\n%%EOF\n',
  );
  return Uint8List.fromList(buf.takeBytes());
}

class _Obj {
  _Obj(this.dictText, this.streamBytes);
  final String dictText;
  final Uint8List? streamBytes;

  bool get isCatalog => RegExp(r'/Type\s*/Catalog\b').hasMatch(dictText);
  bool get isPages => RegExp(r'/Type\s*/Pages\b').hasMatch(dictText);
  bool get isPage => RegExp(r'/Type\s*/Page\b').hasMatch(dictText) && !isPages;
  bool get isObjStm => RegExp(r'/Type\s*/ObjStm\b').hasMatch(dictText);
}

class _PdfFile {
  _PdfFile(this.objects, this.pageOrder, this.mediaBox);
  final Map<int, _Obj> objects;
  final List<int> pageOrder;
  final String? mediaBox;

  static _PdfFile parse(Uint8List data) {
    final s = latin1.decode(data);
    if (RegExp(r'/Type\s*/ObjStm\b').hasMatch(s)) {
      throw Exception('PDF uses object streams');
    }
    if (!s.contains('%PDF')) throw Exception('Not a PDF');

    final objects = <int, _Obj>{};
    final objRe = RegExp(r'(\d+)\s+(\d+)\s+obj');
    for (final m in objRe.allMatches(s)) {
      final id = int.parse(m.group(1)!);
      final start = m.end;
      final streamAt = s.indexOf('stream', start);
      final endObj = s.indexOf('endobj', start);
      if (endObj < 0) continue;

      if (streamAt >= 0 && streamAt < endObj) {
        var dict = s.substring(start, streamAt).trim();
        var i = streamAt + 6;
        if (i < s.length && s.codeUnitAt(i) == 13) i++;
        if (i < s.length && s.codeUnitAt(i) == 10) i++;
        final length = _directLength(dict);
        int streamEnd;
        if (length >= 0 && i + length <= s.length) {
          streamEnd = i + length;
        } else {
          streamEnd = s.indexOf('endstream', i);
          if (streamEnd < 0) continue;
        }
        final streamBytes = Uint8List.fromList(data.sublist(i, streamEnd));
        objects[id] = _Obj(dict.trim(), streamBytes);
      } else {
        objects[id] = _Obj(s.substring(start, endObj).trim(), null);
      }
    }

    final trailerAt = s.lastIndexOf('trailer');
    if (trailerAt < 0) throw Exception('PDF trailer missing');
    final rootM = RegExp(r'/Root\s+(\d+)\s+\d+\s+R')
        .firstMatch(s.substring(trailerAt));
    if (rootM == null) throw Exception('PDF root missing');
    final rootId = int.parse(rootM.group(1)!);
    final catalog = objects[rootId];
    if (catalog == null) throw Exception('Catalog missing');
    final pagesM = RegExp(r'/Pages\s+(\d+)\s+\d+\s+R')
        .firstMatch(catalog.dictText);
    if (pagesM == null) throw Exception('Pages tree missing');
    final pagesId = int.parse(pagesM.group(1)!);

    String? inheritedBox;
    final pages = objects[pagesId];
    if (pages != null) {
      inheritedBox = _mediaBox(pages.dictText);
    }

    final order = <int>[];
    void walk(int id, String? box) {
      final obj = objects[id];
      if (obj == null) return;
      final localBox = _mediaBox(obj.dictText) ?? box;
      if (obj.isPages) {
        for (final kid in _kids(obj.dictText)) {
          walk(kid, localBox);
        }
      } else if (obj.isPage) {
        if (!RegExp(r'/MediaBox').hasMatch(obj.dictText) && localBox != null) {
          objects[id] = _Obj(
            obj.dictText.replaceFirst('<<', '<< /MediaBox $localBox '),
            obj.streamBytes,
          );
        }
        order.add(id);
      }
    }

    walk(pagesId, inheritedBox);
    return _PdfFile(objects, order, inheritedBox);
  }
}

int _directLength(String dict) {
  if (RegExp(r'/Length\s+\d+\s+\d+\s+R').hasMatch(dict)) return -1;
  final m = RegExp(r'/Length\s+(\d+)').firstMatch(dict);
  return m == null ? -1 : int.parse(m.group(1)!);
}

String? _mediaBox(String dict) {
  final m = RegExp(r'/MediaBox\s*(\[[^\]]+\])').firstMatch(dict);
  return m?.group(1);
}

List<int> _kids(String dict) {
  final m = RegExp(r'/Kids\s*\[(.*?)\]', dotAll: true).firstMatch(dict);
  if (m == null) return const [];
  return [
    for (final k in RegExp(r'(\d+)\s+\d+\s+R').allMatches(m.group(1)!))
      int.parse(k.group(1)!),
  ];
}

String _remapRefs(String dict, Map<int, int> idMap) {
  return dict.replaceAllMapped(RegExp(r'(\d+)\s+(\d+)\s+R'), (m) {
    final mapped = idMap[int.parse(m.group(1)!)];
    if (mapped == null) return m.group(0)!;
    return '$mapped ${m.group(2)} R';
  });
}

String _compose(String dict, Uint8List? stream) {
  if (stream == null) return dict;
  final body = latin1.decode(stream);
  return '$dict\nstream\n$body\nendstream';
}
