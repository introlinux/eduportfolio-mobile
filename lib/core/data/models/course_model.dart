import '../../domain/entities/course.dart';

/// Course model for data layer
///
/// Extends Course entity with database serialization.
class CourseModel extends Course {
  const CourseModel({
    super.id,
    required super.name,
    required super.startDate,
    super.endDate,
    super.isActive,
    required super.createdAt,
  });

  /// Create model from entity
  factory CourseModel.fromEntity(Course entity) {
    return CourseModel(
      id: entity.id,
      name: entity.name,
      startDate: entity.startDate,
      endDate: entity.endDate,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
    );
  }

  /// Create model from database map
  factory CourseModel.fromMap(Map<String, dynamic> map) {
    return CourseModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: map['end_date'] != null
          ? DateTime.parse(map['end_date'] as String)
          : null,
      isActive: (map['is_active'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Convert model to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'start_date': startDate.toIso8601String(),
      if (endDate != null) 'end_date': endDate!.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Convert model to entity
  Course toEntity() {
    return Course(
      id: id,
      name: name,
      startDate: startDate,
      endDate: endDate,
      isActive: isActive,
      createdAt: createdAt,
    );
  }

  @override
  String toString() {
    return 'CourseModel(id: $id, name: $name, startDate: $startDate, endDate: $endDate, isActive: $isActive, createdAt: $createdAt)';
  }
}
