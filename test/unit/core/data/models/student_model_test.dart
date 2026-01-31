import 'dart:typed_data';

import 'package:eduportfolio/core/data/models/student_model.dart';
import 'package:eduportfolio/core/domain/entities/student.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StudentModel', () {
    final now = DateTime(2024, 1, 15, 10, 30);
    final updated = DateTime(2024, 1, 15, 11, 0);

    group('fromMap', () {
      test('should create model from map with all fields', () {
        // Arrange
        final embeddings = Uint8List.fromList([1, 2, 3, 4, 5]);
        final map = {
          'id': 1,
          'course_id': 2,
          'name': 'Juan Pérez',
          'face_embeddings': embeddings,
          'created_at': now.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        };

        // Act
        final model = StudentModel.fromMap(map);

        // Assert
        expect(model.id, 1);
        expect(model.courseId, 2);
        expect(model.name, 'Juan Pérez');
        expect(model.faceEmbeddings, embeddings);
        expect(model.createdAt, now);
        expect(model.updatedAt, updated);
        expect(model.hasFaceData, isTrue);
      });

      test('should create model from map with NULL face embeddings', () {
        // Arrange
        final map = {
          'id': 1,
          'course_id': 2,
          'name': 'Juan Pérez',
          'face_embeddings': null,
          'created_at': now.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        };

        // Act
        final model = StudentModel.fromMap(map);

        // Assert
        expect(model.id, 1);
        expect(model.courseId, 2);
        expect(model.name, 'Juan Pérez');
        expect(model.faceEmbeddings, isNull);
        expect(model.hasFaceData, isFalse);
      });

      test('should create model from map with empty face embeddings', () {
        // Arrange
        final embeddings = Uint8List(0);
        final map = {
          'id': 1,
          'course_id': 2,
          'name': 'Juan Pérez',
          'face_embeddings': embeddings,
          'created_at': now.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        };

        // Act
        final model = StudentModel.fromMap(map);

        // Assert
        expect(model.faceEmbeddings, isNotNull);
        expect(model.faceEmbeddings!.isEmpty, isTrue);
        expect(model.hasFaceData, isFalse); // Empty embeddings → no face data
      });

      test('should create model from map without ID (new student)', () {
        // Arrange
        final map = {
          'course_id': 2,
          'name': 'Juan Pérez',
          'created_at': now.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        };

        // Act
        final model = StudentModel.fromMap(map);

        // Assert
        expect(model.id, isNull);
        expect(model.courseId, 2);
        expect(model.name, 'Juan Pérez');
      });

      test('should handle special characters in name', () {
        // Arrange
        final map = {
          'id': 1,
          'course_id': 2,
          'name': 'María José García-López',
          'created_at': now.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        };

        // Act
        final model = StudentModel.fromMap(map);

        // Assert
        expect(model.name, 'María José García-López');
      });
    });

    group('toMap', () {
      test('should convert model to map with all fields', () {
        // Arrange
        final embeddings = Uint8List.fromList([1, 2, 3, 4, 5]);
        final model = StudentModel(
          id: 1,
          courseId: 2,
          name: 'Juan Pérez',
          faceEmbeddings: embeddings,
          createdAt: now,
          updatedAt: updated,
        );

        // Act
        final map = model.toMap();

        // Assert
        expect(map['id'], 1);
        expect(map['course_id'], 2);
        expect(map['name'], 'Juan Pérez');
        expect(map['face_embeddings'], embeddings);
        expect(map['created_at'], now.toIso8601String());
        expect(map['updated_at'], updated.toIso8601String());
      });

      test('should convert model to map with NULL face embeddings', () {
        // Arrange
        final model = StudentModel(
          id: 1,
          courseId: 2,
          name: 'Juan Pérez',
          faceEmbeddings: null,
          createdAt: now,
          updatedAt: updated,
        );

        // Act
        final map = model.toMap();

        // Assert
        expect(map.containsKey('face_embeddings'), isFalse);
        expect(map['id'], 1);
        expect(map['course_id'], 2);
      });

      test('should convert model to map without ID (new student)', () {
        // Arrange
        final model = StudentModel(
          courseId: 2,
          name: 'Juan Pérez',
          createdAt: now,
          updatedAt: updated,
        );

        // Act
        final map = model.toMap();

        // Assert
        expect(map.containsKey('id'), isFalse);
        expect(map['course_id'], 2);
        expect(map['name'], 'Juan Pérez');
      });

      test('should include empty face embeddings in map', () {
        // Arrange
        final embeddings = Uint8List(0);
        final model = StudentModel(
          id: 1,
          courseId: 2,
          name: 'Juan Pérez',
          faceEmbeddings: embeddings,
          createdAt: now,
          updatedAt: updated,
        );

        // Act
        final map = model.toMap();

        // Assert
        expect(map.containsKey('face_embeddings'), isTrue);
        expect(map['face_embeddings'], embeddings);
      });
    });

    group('toEntity', () {
      test('should convert model to entity with all fields', () {
        // Arrange
        final embeddings = Uint8List.fromList([1, 2, 3, 4, 5]);
        final model = StudentModel(
          id: 1,
          courseId: 2,
          name: 'Juan Pérez',
          faceEmbeddings: embeddings,
          createdAt: now,
          updatedAt: updated,
        );

        // Act
        final entity = model.toEntity();

        // Assert
        expect(entity, isA<Student>());
        expect(entity.id, 1);
        expect(entity.courseId, 2);
        expect(entity.name, 'Juan Pérez');
        expect(entity.faceEmbeddings, embeddings);
        expect(entity.createdAt, now);
        expect(entity.updatedAt, updated);
        expect(entity.hasFaceData, isTrue);
      });

      test('should convert model to entity without face data', () {
        // Arrange
        final model = StudentModel(
          id: 1,
          courseId: 2,
          name: 'Juan Pérez',
          faceEmbeddings: null,
          createdAt: now,
          updatedAt: updated,
        );

        // Act
        final entity = model.toEntity();

        // Assert
        expect(entity, isA<Student>());
        expect(entity.faceEmbeddings, isNull);
        expect(entity.hasFaceData, isFalse);
      });

      test('should preserve all data in model → entity conversion', () {
        // Arrange
        final embeddings = Uint8List.fromList(List.generate(128, (i) => i % 256));
        final model = StudentModel(
          id: 999,
          courseId: 5,
          name: 'Test Student',
          faceEmbeddings: embeddings,
          createdAt: now,
          updatedAt: updated,
        );

        // Act
        final entity = model.toEntity();

        // Assert
        expect(entity.id, model.id);
        expect(entity.courseId, model.courseId);
        expect(entity.name, model.name);
        expect(entity.faceEmbeddings, model.faceEmbeddings);
        expect(entity.createdAt, model.createdAt);
        expect(entity.updatedAt, model.updatedAt);
      });
    });

    group('fromEntity', () {
      test('should create model from entity with all fields', () {
        // Arrange
        final embeddings = Uint8List.fromList([1, 2, 3, 4, 5]);
        final entity = Student(
          id: 1,
          courseId: 2,
          name: 'Juan Pérez',
          faceEmbeddings: embeddings,
          createdAt: now,
          updatedAt: updated,
        );

        // Act
        final model = StudentModel.fromEntity(entity);

        // Assert
        expect(model, isA<StudentModel>());
        expect(model.id, 1);
        expect(model.courseId, 2);
        expect(model.name, 'Juan Pérez');
        expect(model.faceEmbeddings, embeddings);
        expect(model.createdAt, now);
        expect(model.updatedAt, updated);
      });

      test('should create model from entity without face data', () {
        // Arrange
        final entity = Student(
          id: 1,
          courseId: 2,
          name: 'Juan Pérez',
          faceEmbeddings: null,
          createdAt: now,
          updatedAt: updated,
        );

        // Act
        final model = StudentModel.fromEntity(entity);

        // Assert
        expect(model, isA<StudentModel>());
        expect(model.faceEmbeddings, isNull);
        expect(model.hasFaceData, isFalse);
      });

      test('should preserve all data in entity → model conversion', () {
        // Arrange
        final embeddings = Uint8List.fromList(List.generate(512, (i) => i % 256));
        final entity = Student(
          id: 777,
          courseId: 3,
          name: 'Another Student',
          faceEmbeddings: embeddings,
          createdAt: now,
          updatedAt: updated,
        );

        // Act
        final model = StudentModel.fromEntity(entity);

        // Assert
        expect(model.id, entity.id);
        expect(model.courseId, entity.courseId);
        expect(model.name, entity.name);
        expect(model.faceEmbeddings, entity.faceEmbeddings);
        expect(model.createdAt, entity.createdAt);
        expect(model.updatedAt, entity.updatedAt);
      });
    });

    group('round-trip conversions', () {
      test('should maintain data integrity in map → model → map', () {
        // Arrange
        final embeddings = Uint8List.fromList([10, 20, 30, 40, 50]);
        final originalMap = {
          'id': 1,
          'course_id': 2,
          'name': 'Test Student',
          'face_embeddings': embeddings,
          'created_at': now.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        };

        // Act
        final model = StudentModel.fromMap(originalMap);
        final resultMap = model.toMap();

        // Assert
        expect(resultMap['id'], originalMap['id']);
        expect(resultMap['course_id'], originalMap['course_id']);
        expect(resultMap['name'], originalMap['name']);
        expect(resultMap['face_embeddings'], originalMap['face_embeddings']);
        expect(resultMap['created_at'], originalMap['created_at']);
        expect(resultMap['updated_at'], originalMap['updated_at']);
      });

      test('should maintain data integrity in entity → model → entity', () {
        // Arrange
        final embeddings = Uint8List.fromList([5, 10, 15, 20, 25]);
        final originalEntity = Student(
          id: 1,
          courseId: 2,
          name: 'Test Student',
          faceEmbeddings: embeddings,
          createdAt: now,
          updatedAt: updated,
        );

        // Act
        final model = StudentModel.fromEntity(originalEntity);
        final resultEntity = model.toEntity();

        // Assert
        expect(resultEntity.id, originalEntity.id);
        expect(resultEntity.courseId, originalEntity.courseId);
        expect(resultEntity.name, originalEntity.name);
        expect(resultEntity.faceEmbeddings, originalEntity.faceEmbeddings);
        expect(resultEntity.createdAt, originalEntity.createdAt);
        expect(resultEntity.updatedAt, originalEntity.updatedAt);
        expect(resultEntity.hasFaceData, originalEntity.hasFaceData);
      });
    });

    group('hasFaceData flag', () {
      test('should return true when embeddings exist and are not empty', () {
        // Arrange
        final embeddings = Uint8List.fromList([1, 2, 3]);
        final model = StudentModel(
          id: 1,
          courseId: 2,
          name: 'Juan Pérez',
          faceEmbeddings: embeddings,
          createdAt: now,
          updatedAt: updated,
        );

        // Assert
        expect(model.hasFaceData, isTrue);
      });

      test('should return false when embeddings are NULL', () {
        // Arrange
        final model = StudentModel(
          id: 1,
          courseId: 2,
          name: 'Juan Pérez',
          faceEmbeddings: null,
          createdAt: now,
          updatedAt: updated,
        );

        // Assert
        expect(model.hasFaceData, isFalse);
      });

      test('should return false when embeddings are empty', () {
        // Arrange
        final model = StudentModel(
          id: 1,
          courseId: 2,
          name: 'Juan Pérez',
          faceEmbeddings: Uint8List(0),
          createdAt: now,
          updatedAt: updated,
        );

        // Assert
        expect(model.hasFaceData, isFalse);
      });
    });

    group('toString', () {
      test('should return string representation with face data', () {
        // Arrange
        final embeddings = Uint8List.fromList([1, 2, 3]);
        final model = StudentModel(
          id: 1,
          courseId: 2,
          name: 'Juan Pérez',
          faceEmbeddings: embeddings,
          createdAt: now,
          updatedAt: updated,
        );

        // Act
        final result = model.toString();

        // Assert
        expect(result, contains('StudentModel'));
        expect(result, contains('id: 1'));
        expect(result, contains('courseId: 2'));
        expect(result, contains('name: Juan Pérez'));
        expect(result, contains('hasFaceData: true'));
        expect(result, contains('createdAt: $now'));
        expect(result, contains('updatedAt: $updated'));
      });

      test('should return string representation without face data', () {
        // Arrange
        final model = StudentModel(
          id: 1,
          courseId: 2,
          name: 'Juan Pérez',
          createdAt: now,
          updatedAt: updated,
        );

        // Act
        final result = model.toString();

        // Assert
        expect(result, contains('hasFaceData: false'));
      });
    });
  });
}
