/// Evidence type enumeration
enum EvidenceType {
  image,
  video,
  audio;

  /// Get file prefix for this evidence type
  String get filePrefix {
    switch (this) {
      case EvidenceType.image:
        return 'IMG';
      case EvidenceType.video:
        return 'VID';
      case EvidenceType.audio:
        return 'AUD';
    }
  }

  /// Create from string value
  static EvidenceType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'IMG':
      case 'IMAGE':
        return EvidenceType.image;
      case 'VID':
      case 'VIDEO':
        return EvidenceType.video;
      case 'AUD':
      case 'AUDIO':
        return EvidenceType.audio;
      default:
        throw ArgumentError('Invalid evidence type: $value');
    }
  }

  /// Convert to string for database storage
  String toDbString() {
    return filePrefix;
  }
}

/// Helper class to distinguish between "not provided" and "explicitly null" in copyWith
class _Undefined {
  const _Undefined();
}

/// Evidence entity representing captured media
///
/// Immutable domain model for evidence (photos, videos, audios).
/// If studentId is null, the evidence is in the temporal folder awaiting manual review.
class Evidence {
  final int? id;
  final int? studentId;
  final int? courseId;
  final int subjectId;
  final EvidenceType type;
  final String filePath;
  final String? thumbnailPath;
  final int? fileSize;
  final int? duration;
  final DateTime captureDate;
  final bool isReviewed;
  final String? notes;
  final DateTime createdAt;

  const Evidence({
    required this.subjectId, required this.type, required this.filePath, required this.captureDate, required this.createdAt, this.id,
    this.studentId,
    this.courseId,
    this.thumbnailPath,
    this.fileSize,
    this.duration,
    this.isReviewed = true,
    this.notes,
  });

  /// Create a copy with updated fields
  ///
  /// To explicitly set a nullable field to null, use the special constant:
  /// - Use `const _Null()` for studentId to set it to null
  Evidence copyWith({
    int? id,
    Object? studentId = const _Undefined(),
    Object? courseId = const _Undefined(),
    int? subjectId,
    EvidenceType? type,
    String? filePath,
    String? thumbnailPath,
    int? fileSize,
    int? duration,
    DateTime? captureDate,
    bool? isReviewed,
    String? notes,
    DateTime? createdAt,
  }) {
    return Evidence(
      id: id ?? this.id,
      studentId: studentId is _Undefined ? this.studentId : studentId as int?,
      courseId: courseId is _Undefined ? this.courseId : courseId as int?,
      subjectId: subjectId ?? this.subjectId,
      type: type ?? this.type,
      filePath: filePath ?? this.filePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      fileSize: fileSize ?? this.fileSize,
      duration: duration ?? this.duration,
      captureDate: captureDate ?? this.captureDate,
      isReviewed: isReviewed ?? this.isReviewed,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Check if evidence needs manual review
  bool get needsReview => !isReviewed || studentId == null;

  /// Check if evidence is assigned to a student
  bool get isAssigned => studentId != null;

  /// Get file size in MB
  double? get fileSizeMB =>
      fileSize != null ? fileSize! / (1024 * 1024) : null;

  /// Get duration in minutes (for videos/audios)
  double? get durationMinutes =>
      duration != null ? duration! / 60.0 : null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Evidence &&
        other.id == id &&
        other.studentId == studentId &&
        other.courseId == courseId &&
        other.subjectId == subjectId &&
        other.type == type &&
        other.filePath == filePath &&
        other.thumbnailPath == thumbnailPath &&
        other.fileSize == fileSize &&
        other.duration == duration &&
        other.captureDate == captureDate &&
        other.isReviewed == isReviewed &&
        other.notes == notes &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        studentId.hashCode ^
        courseId.hashCode ^
        subjectId.hashCode ^
        type.hashCode ^
        filePath.hashCode ^
        thumbnailPath.hashCode ^
        fileSize.hashCode ^
        duration.hashCode ^
        captureDate.hashCode ^
        isReviewed.hashCode ^
        notes.hashCode ^
        createdAt.hashCode;
  }

  @override
  String toString() {
    return 'Evidence(id: $id, studentId: $studentId, courseId: $courseId, subjectId: $subjectId, type: $type, filePath: $filePath, captureDate: $captureDate, isReviewed: $isReviewed, createdAt: $createdAt)';
  }
}
