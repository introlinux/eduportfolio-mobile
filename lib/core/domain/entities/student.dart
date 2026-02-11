import 'dart:typed_data';

/// Student entity representing a student in the system
///
/// Immutable domain model for students.
/// Face embeddings are stored encrypted in the database.
class Student {
  final int? id;
  final int courseId;
  final String name;
  final Uint8List? faceEmbeddings;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Student({
    required this.courseId,
    required this.name,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.id,
    this.faceEmbeddings,
  });

  /// Create a copy with updated fields
  Student copyWith({
    int? id,
    int? courseId,
    String? name,
    Uint8List? faceEmbeddings,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Student(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      name: name ?? this.name,
      faceEmbeddings: faceEmbeddings ?? this.faceEmbeddings,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if student has face recognition data
  bool get hasFaceData => faceEmbeddings != null && faceEmbeddings!.isNotEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Student &&
        other.id == id &&
        other.courseId == courseId &&
        other.name == name &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        courseId.hashCode ^
        name.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }

  @override
  String toString() {
    return 'Student(id: $id, courseId: $courseId, name: $name, hasFaceData: $hasFaceData, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
