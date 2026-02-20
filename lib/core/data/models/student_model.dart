import 'dart:typed_data';

import 'package:eduportfolio/core/domain/entities/student.dart';

/// Student model for data layer
///
/// Extends Student entity with database serialization.
class StudentModel extends Student {
  const StudentModel({
    required super.courseId,
    required super.name,
    super.enrollmentDate,
    super.isActive = true,
    required super.createdAt,
    required super.updatedAt,
    super.id,
    super.faceEmbeddings,
  });

  /// Create model from entity
  factory StudentModel.fromEntity(Student entity) {
    return StudentModel(
      id: entity.id,
      courseId: entity.courseId,
      name: entity.name,
      faceEmbeddings: entity.faceEmbeddings,
      enrollmentDate: entity.enrollmentDate,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Create model from database map
  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(
      id: map['id'] as int?,
      courseId: map['course_id'] as int,
      name: map['name'] as String,
      faceEmbeddings: map['face_embeddings'] as Uint8List?,
      enrollmentDate: map['enrollment_date'] != null
          ? DateTime.parse(map['enrollment_date'] as String)
          : null,
      isActive: (map['is_active'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Convert model to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'course_id': courseId,
      'name': name,
      if (faceEmbeddings != null) 'face_embeddings': faceEmbeddings,
      if (enrollmentDate != null)
        'enrollment_date': enrollmentDate!.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Convert model to entity
  Student toEntity() {
    return Student(
      id: id,
      courseId: courseId,
      name: name,
      faceEmbeddings: faceEmbeddings,
      enrollmentDate: enrollmentDate,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  String toString() {
    return 'StudentModel(id: $id, courseId: $courseId, name: $name, hasFaceData: $hasFaceData, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
