import 'saved_doc.dart';

enum KitSlot {
  photo('Photo'),
  signature('Signature'),
  idProof('ID proof'),
  certificate('Certificate'),
  form('Application form');

  const KitSlot(this.label);
  final String label;
  bool accepts(SavedDoc doc) => this == photo || this == signature
      ? doc.isImage
      : doc.isImage || doc.isPdf;
}

class ApplicationKit {
  const ApplicationKit(
      {required this.id,
      required this.name,
      this.examId = 'custom',
      this.files = const {},
      this.requiredSlots = const {
        KitSlot.photo,
        KitSlot.signature,
        KitSlot.idProof,
        KitSlot.certificate
      }});

  final String id;
  final String name;
  final String examId;
  final Map<KitSlot, String> files;
  final Set<KitSlot> requiredSlots;

  List<KitSlot> missing(Iterable<SavedDoc> available) {
    final ids = {for (final doc in available) doc.id};
    return [
      for (final slot in requiredSlots)
        if (files[slot] == null || !ids.contains(files[slot])) slot
    ];
  }

  ApplicationKit copyWith(
          {String? name,
          String? examId,
          Map<KitSlot, String>? files,
          Set<KitSlot>? requiredSlots}) =>
      ApplicationKit(
          id: id,
          name: name ?? this.name,
          examId: examId ?? this.examId,
          files: files ?? this.files,
          requiredSlots: requiredSlots ?? this.requiredSlots);

  Map<String, Object> toJson() => {
        'id': id,
        'name': name,
        'examId': examId,
        'files': {
          for (final entry in files.entries) entry.key.name: entry.value
        },
        'required': requiredSlots.map((slot) => slot.name).toList()
      };

  factory ApplicationKit.fromJson(Map<String, dynamic> data) {
    final files = data['files'] as Map<String, dynamic>? ?? {};
    final required = (data['required'] as List<dynamic>? ??
            ['photo', 'signature', 'idProof', 'certificate'])
        .whereType<String>()
        .toSet();
    return ApplicationKit(
        id: data['id'] as String,
        name: data['name'] as String,
        examId: data['examId'] as String? ?? 'custom',
        files: {
          for (final slot in KitSlot.values)
            if (files[slot.name] is String) slot: files[slot.name] as String
        },
        requiredSlots: {
          for (final slot in KitSlot.values)
            if (required.contains(slot.name)) slot
        });
  }
}
