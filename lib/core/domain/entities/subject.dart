/// Subject entity representing a school subject
///
/// Immutable domain model for subjects (e.g., "Matemáticas", "Lengua").
/// Default subjects are created automatically when the database is initialized.
class Subject {
  final int? id;
  final String name;
  final String? color;
  final String? icon;
  final bool isDefault;
  final DateTime createdAt;

  const Subject({
    required this.name, required this.createdAt, this.id,
    this.color,
    this.icon,
    this.isDefault = false,
  });

  /// Create a copy with updated fields
  Subject copyWith({
    int? id,
    String? name,
    String? color,
    String? icon,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Subject &&
        other.id == id &&
        other.name == name &&
        other.color == color &&
        other.icon == icon &&
        other.isDefault == isDefault &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        color.hashCode ^
        icon.hashCode ^
        isDefault.hashCode ^
        createdAt.hashCode;
  }

  @override
  String toString() {
    return 'Subject(id: $id, name: $name, color: $color, icon: $icon, isDefault: $isDefault, createdAt: $createdAt)';
  }
}
