enum DocBackupState { deviceOnly, pending, backedUp, failed }

/// Additive, local-only metadata. Document bytes and existing names are untouched.
class DocMeta {
  const DocMeta({
    this.starred = false,
    this.tags = const [],
    this.openedAt,
    this.trashedAt,
    this.digest,
    this.backupDigest,
    this.backupError,
    this.backupAt,
    this.backupPending = false,
    this.width,
    this.height,
    this.pages,
    this.ocrText,
    this.ocrPages,
  });

  final bool starred;
  final List<String> tags;
  final int? openedAt;
  final int? trashedAt;
  final String? digest;
  final String? backupDigest;
  final String? backupError;
  final int? backupAt;
  final bool backupPending;
  final int? width;
  final int? height;
  final int? pages;
  final String? ocrText;
  final int? ocrPages;

  bool get inTrash => trashedAt != null;

  DocBackupState get backupState {
    if (backupError != null) return DocBackupState.failed;
    if (backupPending) return DocBackupState.pending;
    if (digest != null && digest == backupDigest) {
      return DocBackupState.backedUp;
    }
    return backupDigest == null
        ? DocBackupState.deviceOnly
        : DocBackupState.pending;
  }

  DocMeta copyWith({
    bool? starred,
    List<String>? tags,
    int? openedAt,
    int? trashedAt,
    bool restore = false,
    String? digest,
    String? backupDigest,
    String? backupError,
    bool clearBackupError = false,
    int? backupAt,
    bool? backupPending,
    int? width,
    int? height,
    int? pages,
    String? ocrText,
    int? ocrPages,
    bool clearOcr = false,
  }) =>
      DocMeta(
        starred: starred ?? this.starred,
        tags: tags ?? this.tags,
        openedAt: openedAt ?? this.openedAt,
        trashedAt: restore ? null : trashedAt ?? this.trashedAt,
        digest: digest ?? this.digest,
        backupDigest: backupDigest ?? this.backupDigest,
        backupError: clearBackupError ? null : backupError ?? this.backupError,
        backupAt: backupAt ?? this.backupAt,
        backupPending: backupPending ?? this.backupPending,
        width: width ?? this.width,
        height: height ?? this.height,
        pages: pages ?? this.pages,
        ocrText: clearOcr ? null : ocrText ?? this.ocrText,
        ocrPages: clearOcr ? null : ocrPages ?? this.ocrPages,
      );

  Map<String, Object?> toJson() => {
        'starred': starred,
        'tags': tags,
        if (openedAt != null) 'openedAt': openedAt,
        if (trashedAt != null) 'trashedAt': trashedAt,
        if (digest != null) 'digest': digest,
        if (backupDigest != null) 'backupDigest': backupDigest,
        if (backupError != null) 'backupError': backupError,
        if (backupAt != null) 'backupAt': backupAt,
        'backupPending': backupPending,
        if (width != null) 'width': width,
        if (height != null) 'height': height,
        if (pages != null) 'pages': pages,
        if (ocrText != null) 'ocrText': ocrText,
        if (ocrPages != null) 'ocrPages': ocrPages,
      };

  factory DocMeta.fromJson(Map<String, dynamic> json) => DocMeta(
        starred: json['starred'] == true,
        tags: [...(json['tags'] as List<dynamic>? ?? []).whereType<String>()],
        openedAt: json['openedAt'] as int?,
        trashedAt: json['trashedAt'] as int?,
        digest: json['digest'] as String?,
        backupDigest: json['backupDigest'] as String?,
        backupError: json['backupError'] as String?,
        backupAt: json['backupAt'] as int?,
        backupPending: json['backupPending'] == true,
        width: json['width'] as int?,
        height: json['height'] as int?,
        pages: json['pages'] as int?,
        ocrText: json['ocrText'] as String?,
        ocrPages: json['ocrPages'] as int?,
      );
}
