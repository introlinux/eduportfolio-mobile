/// Course entity representing a school year
///
/// Immutable domain model for courses (e.g., "Curso 2024-25").
/// Only one course can be active at a time.
class Course {
  final int? id;
  final String name;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final DateTime createdAt;

  const Course({
    this.id,
    required this.name,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    required this.createdAt,
  });

  /// Create a copy with updated fields
  Course copyWith({
    int? id,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Course(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Course &&
        other.id == id &&
        other.name == name &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.isActive == isActive &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        startDate.hashCode ^
        endDate.hashCode ^
        isActive.hashCode ^
        createdAt.hashCode;
  }

  @override
  String toString() {
    return 'Course(id: $id, name: $name, startDate: $startDate, endDate: $endDate, isActive: $isActive, createdAt: $createdAt)';
  }
}
