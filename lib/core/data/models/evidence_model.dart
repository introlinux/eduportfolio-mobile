import '../../domain/entities/evidence.dart';

/// Evidence model for data layer
///
/// Extends Evidence entity with database serialization.
class EvidenceModel extends Evidence {
  const EvidenceModel({
    super.id,
    super.studentId,
    required super.subjectId,
    required super.type,
    required super.filePath,
    super.thumbnailPath,
    super.fileSize,
    super.duration,
    required super.captureDate,
    super.isReviewed,
    super.notes,
    required super.createdAt,
  });

  /// Create model from entity
  factory EvidenceModel.fromEntity(Evidence entity) {
    return EvidenceModel(
      id: entity.id,
      studentId: entity.studentId,
      subjectId: entity.subjectId,
      type: entity.type,
      filePath: entity.filePath,
      thumbnailPath: entity.thumbnailPath,
      fileSize: entity.fileSize,
      duration: entity.duration,
      captureDate: entity.captureDate,
      isReviewed: entity.isReviewed,
      notes: entity.notes,
      createdAt: entity.createdAt,
    );
  }

  /// Create model from database map
  factory EvidenceModel.fromMap(Map<String, dynamic> map) {
    return EvidenceModel(
      id: map['id'] as int?,
      studentId: map['student_id'] as int?,
      subjectId: map['subject_id'] as int,
      type: EvidenceType.fromString(map['type'] as String),
      filePath: map['file_path'] as String,
      thumbnailPath: map['thumbnail_path'] as String?,
      fileSize: map['file_size'] as int?,
      duration: map['duration'] as int?,
      captureDate: DateTime.parse(map['capture_date'] as String),
      isReviewed: (map['is_reviewed'] as int) == 1,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Convert model to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (studentId != null) 'student_id': studentId,
      'subject_id': subjectId,
      'type': type.toDbString(),
      'file_path': filePath,
      if (thumbnailPath != null) 'thumbnail_path': thumbnailPath,
      if (fileSize != null) 'file_size': fileSize,
      if (duration != null) 'duration': duration,
      'capture_date': captureDate.toIso8601String(),
      'is_reviewed': isReviewed ? 1 : 0,
      if (notes != null) 'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Convert model to entity
  Evidence toEntity() {
    return Evidence(
      id: id,
      studentId: studentId,
      subjectId: subjectId,
      type: type,
      filePath: filePath,
      thumbnailPath: thumbnailPath,
      fileSize: fileSize,
      duration: duration,
      captureDate: captureDate,
      isReviewed: isReviewed,
      notes: notes,
      createdAt: createdAt,
    );
  }

  @override
  String toString() {
    return 'EvidenceModel(id: $id, studentId: $studentId, subjectId: $subjectId, type: $type, filePath: $filePath, captureDate: $captureDate, isReviewed: $isReviewed, createdAt: $createdAt)';
  }
}
