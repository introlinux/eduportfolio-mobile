import '../../domain/entities/subject.dart';

/// Subject model for data layer
///
/// Extends Subject entity with database serialization.
class SubjectModel extends Subject {
  const SubjectModel({
    super.id,
    required super.name,
    super.color,
    super.icon,
    super.isDefault,
    required super.createdAt,
  });

  /// Create model from entity
  factory SubjectModel.fromEntity(Subject entity) {
    return SubjectModel(
      id: entity.id,
      name: entity.name,
      color: entity.color,
      icon: entity.icon,
      isDefault: entity.isDefault,
      createdAt: entity.createdAt,
    );
  }

  /// Create model from database map
  factory SubjectModel.fromMap(Map<String, dynamic> map) {
    return SubjectModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      color: map['color'] as String?,
      icon: map['icon'] as String?,
      isDefault: (map['is_default'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Convert model to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      if (color != null) 'color': color,
      if (icon != null) 'icon': icon,
      'is_default': isDefault ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Convert model to entity
  Subject toEntity() {
    return Subject(
      id: id,
      name: name,
      color: color,
      icon: icon,
      isDefault: isDefault,
      createdAt: createdAt,
    );
  }

  @override
  String toString() {
    return 'SubjectModel(id: $id, name: $name, color: $color, icon: $icon, isDefault: $isDefault, createdAt: $createdAt)';
  }
}
