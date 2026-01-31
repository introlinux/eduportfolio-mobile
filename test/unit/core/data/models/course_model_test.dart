import 'package:eduportfolio/core/data/models/course_model.dart';
import 'package:eduportfolio/core/domain/entities/course.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CourseModel', () {
    final startDate = DateTime(2024, 9, 1);
    final endDate = DateTime(2025, 6, 30);
    final createdAt = DateTime(2024, 1, 15, 10, 30);

    group('fromMap', () {
      test('should create model from map with all fields', () {
        // Arrange
        final map = {
          'id': 1,
          'name': 'Curso 2024-25',
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
          'is_active': 1,
          'created_at': createdAt.toIso8601String(),
        };

        // Act
        final model = CourseModel.fromMap(map);

        // Assert
        expect(model.id, 1);
        expect(model.name, 'Curso 2024-25');
        expect(model.startDate, startDate);
        expect(model.endDate, endDate);
        expect(model.isActive, isTrue);
        expect(model.createdAt, createdAt);
      });

      test('should create model with is_active = 1 as true', () {
        // Arrange
        final map = {
          'id': 1,
          'name': 'Curso Activo',
          'start_date': startDate.toIso8601String(),
          'is_active': 1,
          'created_at': createdAt.toIso8601String(),
        };

        // Act
        final model = CourseModel.fromMap(map);

        // Assert
        expect(model.isActive, isTrue);
      });

      test('should create model with is_active = 0 as false', () {
        // Arrange
        final map = {
          'id': 1,
          'name': 'Curso Inactivo',
          'start_date': startDate.toIso8601String(),
          'is_active': 0,
          'created_at': createdAt.toIso8601String(),
        };

        // Act
        final model = CourseModel.fromMap(map);

        // Assert
        expect(model.isActive, isFalse);
      });

      test('should create model with NULL end_date', () {
        // Arrange
        final map = {
          'id': 1,
          'name': 'Curso Sin Fin',
          'start_date': startDate.toIso8601String(),
          'end_date': null,
          'is_active': 1,
          'created_at': createdAt.toIso8601String(),
        };

        // Act
        final model = CourseModel.fromMap(map);

        // Assert
        expect(model.endDate, isNull);
      });

      test('should create model from map without end_date field', () {
        // Arrange
        final map = {
          'id': 1,
          'name': 'Curso Actual',
          'start_date': startDate.toIso8601String(),
          'is_active': 1,
          'created_at': createdAt.toIso8601String(),
        };

        // Act
        final model = CourseModel.fromMap(map);

        // Assert
        expect(model.endDate, isNull);
      });

      test('should create model from map without ID (new course)', () {
        // Arrange
        final map = {
          'name': 'Nuevo Curso',
          'start_date': startDate.toIso8601String(),
          'is_active': 1,
          'created_at': createdAt.toIso8601String(),
        };

        // Act
        final model = CourseModel.fromMap(map);

        // Assert
        expect(model.id, isNull);
        expect(model.name, 'Nuevo Curso');
      });

      test('should handle special characters in name', () {
        // Arrange
        final map = {
          'id': 1,
          'name': 'Curso 2024-25 (6º Primaria)',
          'start_date': startDate.toIso8601String(),
          'is_active': 1,
          'created_at': createdAt.toIso8601String(),
        };

        // Act
        final model = CourseModel.fromMap(map);

        // Assert
        expect(model.name, 'Curso 2024-25 (6º Primaria)');
      });
    });

    group('toMap', () {
      test('should convert model to map with all fields', () {
        // Arrange
        final model = CourseModel(
          id: 1,
          name: 'Curso 2024-25',
          startDate: startDate,
          endDate: endDate,
          isActive: true,
          createdAt: createdAt,
        );

        // Act
        final map = model.toMap();

        // Assert
        expect(map['id'], 1);
        expect(map['name'], 'Curso 2024-25');
        expect(map['start_date'], startDate.toIso8601String());
        expect(map['end_date'], endDate.toIso8601String());
        expect(map['is_active'], 1);
        expect(map['created_at'], createdAt.toIso8601String());
      });

      test('should convert isActive true to 1', () {
        // Arrange
        final model = CourseModel(
          id: 1,
          name: 'Curso Activo',
          startDate: startDate,
          isActive: true,
          createdAt: createdAt,
        );

        // Act
        final map = model.toMap();

        // Assert
        expect(map['is_active'], 1);
      });

      test('should convert isActive false to 0', () {
        // Arrange
        final model = CourseModel(
          id: 1,
          name: 'Curso Inactivo',
          startDate: startDate,
          isActive: false,
          createdAt: createdAt,
        );

        // Act
        final map = model.toMap();

        // Assert
        expect(map['is_active'], 0);
      });

      test('should not include end_date when NULL', () {
        // Arrange
        final model = CourseModel(
          id: 1,
          name: 'Curso Sin Fin',
          startDate: startDate,
          endDate: null,
          createdAt: createdAt,
        );

        // Act
        final map = model.toMap();

        // Assert
        expect(map.containsKey('end_date'), isFalse);
      });

      test('should include end_date when present', () {
        // Arrange
        final model = CourseModel(
          id: 1,
          name: 'Curso Con Fin',
          startDate: startDate,
          endDate: endDate,
          createdAt: createdAt,
        );

        // Act
        final map = model.toMap();

        // Assert
        expect(map.containsKey('end_date'), isTrue);
        expect(map['end_date'], endDate.toIso8601String());
      });

      test('should not include ID when NULL (new course)', () {
        // Arrange
        final model = CourseModel(
          name: 'Nuevo Curso',
          startDate: startDate,
          createdAt: createdAt,
        );

        // Act
        final map = model.toMap();

        // Assert
        expect(map.containsKey('id'), isFalse);
        expect(map['name'], 'Nuevo Curso');
      });

      test('should include ID when present', () {
        // Arrange
        final model = CourseModel(
          id: 42,
          name: 'Curso Existente',
          startDate: startDate,
          createdAt: createdAt,
        );

        // Act
        final map = model.toMap();

        // Assert
        expect(map.containsKey('id'), isTrue);
        expect(map['id'], 42);
      });
    });

    group('toEntity', () {
      test('should convert model to entity with all fields', () {
        // Arrange
        final model = CourseModel(
          id: 1,
          name: 'Curso 2024-25',
          startDate: startDate,
          endDate: endDate,
          isActive: true,
          createdAt: createdAt,
        );

        // Act
        final entity = model.toEntity();

        // Assert
        expect(entity, isA<Course>());
        expect(entity.id, 1);
        expect(entity.name, 'Curso 2024-25');
        expect(entity.startDate, startDate);
        expect(entity.endDate, endDate);
        expect(entity.isActive, isTrue);
        expect(entity.createdAt, createdAt);
      });

      test('should convert model to entity with inactive course', () {
        // Arrange
        final model = CourseModel(
          id: 1,
          name: 'Curso Inactivo',
          startDate: startDate,
          isActive: false,
          createdAt: createdAt,
        );

        // Act
        final entity = model.toEntity();

        // Assert
        expect(entity, isA<Course>());
        expect(entity.isActive, isFalse);
      });

      test('should preserve all data in model → entity conversion', () {
        // Arrange
        final model = CourseModel(
          id: 999,
          name: 'Test Course',
          startDate: startDate,
          endDate: endDate,
          isActive: true,
          createdAt: createdAt,
        );

        // Act
        final entity = model.toEntity();

        // Assert
        expect(entity.id, model.id);
        expect(entity.name, model.name);
        expect(entity.startDate, model.startDate);
        expect(entity.endDate, model.endDate);
        expect(entity.isActive, model.isActive);
        expect(entity.createdAt, model.createdAt);
      });
    });

    group('fromEntity', () {
      test('should create model from entity with all fields', () {
        // Arrange
        final entity = Course(
          id: 1,
          name: 'Curso 2024-25',
          startDate: startDate,
          endDate: endDate,
          isActive: true,
          createdAt: createdAt,
        );

        // Act
        final model = CourseModel.fromEntity(entity);

        // Assert
        expect(model, isA<CourseModel>());
        expect(model.id, 1);
        expect(model.name, 'Curso 2024-25');
        expect(model.startDate, startDate);
        expect(model.endDate, endDate);
        expect(model.isActive, isTrue);
        expect(model.createdAt, createdAt);
      });

      test('should create model from entity with inactive course', () {
        // Arrange
        final entity = Course(
          id: 1,
          name: 'Curso Inactivo',
          startDate: startDate,
          isActive: false,
          createdAt: createdAt,
        );

        // Act
        final model = CourseModel.fromEntity(entity);

        // Assert
        expect(model, isA<CourseModel>());
        expect(model.isActive, isFalse);
      });

      test('should preserve all data in entity → model conversion', () {
        // Arrange
        final entity = Course(
          id: 777,
          name: 'Another Course',
          startDate: startDate,
          endDate: endDate,
          isActive: false,
          createdAt: createdAt,
        );

        // Act
        final model = CourseModel.fromEntity(entity);

        // Assert
        expect(model.id, entity.id);
        expect(model.name, entity.name);
        expect(model.startDate, entity.startDate);
        expect(model.endDate, entity.endDate);
        expect(model.isActive, entity.isActive);
        expect(model.createdAt, entity.createdAt);
      });
    });

    group('round-trip conversions', () {
      test('should maintain data integrity in map → model → map', () {
        // Arrange
        final originalMap = {
          'id': 1,
          'name': 'Curso Test',
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
          'is_active': 1,
          'created_at': createdAt.toIso8601String(),
        };

        // Act
        final model = CourseModel.fromMap(originalMap);
        final resultMap = model.toMap();

        // Assert
        expect(resultMap['id'], originalMap['id']);
        expect(resultMap['name'], originalMap['name']);
        expect(resultMap['start_date'], originalMap['start_date']);
        expect(resultMap['end_date'], originalMap['end_date']);
        expect(resultMap['is_active'], originalMap['is_active']);
        expect(resultMap['created_at'], originalMap['created_at']);
      });

      test('should maintain data integrity in entity → model → entity', () {
        // Arrange
        final originalEntity = Course(
          id: 1,
          name: 'Curso Test',
          startDate: startDate,
          endDate: endDate,
          isActive: true,
          createdAt: createdAt,
        );

        // Act
        final model = CourseModel.fromEntity(originalEntity);
        final resultEntity = model.toEntity();

        // Assert
        expect(resultEntity.id, originalEntity.id);
        expect(resultEntity.name, originalEntity.name);
        expect(resultEntity.startDate, originalEntity.startDate);
        expect(resultEntity.endDate, originalEntity.endDate);
        expect(resultEntity.isActive, originalEntity.isActive);
        expect(resultEntity.createdAt, originalEntity.createdAt);
      });

      test('should handle round-trip with NULL end_date', () {
        // Arrange
        final map = {
          'id': 1,
          'name': 'Curso Actual',
          'start_date': startDate.toIso8601String(),
          'is_active': 1,
          'created_at': createdAt.toIso8601String(),
        };

        // Act
        final model = CourseModel.fromMap(map);
        final resultMap = model.toMap();

        // Assert
        expect(resultMap.containsKey('end_date'), isFalse);
      });
    });

    group('toString', () {
      test('should return string representation with all fields', () {
        // Arrange
        final model = CourseModel(
          id: 1,
          name: 'Curso 2024-25',
          startDate: startDate,
          endDate: endDate,
          isActive: true,
          createdAt: createdAt,
        );

        // Act
        final result = model.toString();

        // Assert
        expect(result, contains('CourseModel'));
        expect(result, contains('id: 1'));
        expect(result, contains('name: Curso 2024-25'));
        expect(result, contains('startDate: $startDate'));
        expect(result, contains('endDate: $endDate'));
        expect(result, contains('isActive: true'));
        expect(result, contains('createdAt: $createdAt'));
      });

      test('should return string representation for inactive course', () {
        // Arrange
        final model = CourseModel(
          id: 1,
          name: 'Curso Inactivo',
          startDate: startDate,
          isActive: false,
          createdAt: createdAt,
        );

        // Act
        final result = model.toString();

        // Assert
        expect(result, contains('isActive: false'));
      });

      test('should return string representation with NULL end_date', () {
        // Arrange
        final model = CourseModel(
          id: 1,
          name: 'Curso Sin Fin',
          startDate: startDate,
          endDate: null,
          createdAt: createdAt,
        );

        // Act
        final result = model.toString();

        // Assert
        expect(result, contains('endDate: null'));
      });
    });
  });
}
