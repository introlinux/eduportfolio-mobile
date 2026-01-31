import 'dart:typed_data';

import 'package:eduportfolio/core/data/datasources/student_local_datasource.dart';
import 'package:eduportfolio/core/data/models/student_model.dart';
import 'package:eduportfolio/core/data/repositories/student_repository_impl.dart';
import 'package:eduportfolio/core/domain/entities/student.dart';
import 'package:eduportfolio/core/errors/exceptions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'student_repository_impl_test.mocks.dart';

@GenerateMocks([StudentLocalDataSource])
void main() {
  late MockStudentLocalDataSource mockDataSource;
  late StudentRepositoryImpl repository;

  setUp(() {
    mockDataSource = MockStudentLocalDataSource();
    repository = StudentRepositoryImpl(mockDataSource);
  });

  final now = DateTime(2024, 1, 15, 10, 30);
  final embeddings = Uint8List.fromList([1, 2, 3, 4, 5]);

  group('getAllStudents', () {
    test('should return list of entities from datasource', () async {
      // Arrange
      final models = [
        StudentModel(
          id: 1,
          courseId: 1,
          name: 'Student 1',
          createdAt: now,
          updatedAt: now,
        ),
        StudentModel(
          id: 2,
          courseId: 1,
          name: 'Student 2',
          faceEmbeddings: embeddings,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      when(mockDataSource.getAllStudents()).thenAnswer((_) async => models);

      // Act
      final result = await repository.getAllStudents();

      // Assert
      expect(result, isA<List<Student>>());
      expect(result.length, 2);
      expect(result[0].id, 1);
      expect(result[1].hasFaceData, isTrue);
      verify(mockDataSource.getAllStudents()).called(1);
    });

    test('should throw DatabaseException on datasource error', () async {
      // Arrange
      when(mockDataSource.getAllStudents()).thenThrow(Exception('DB error'));

      // Act & Assert
      expect(
        () => repository.getAllStudents(),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  group('getStudentsByCourse', () {
    test('should return filtered students by course', () async {
      // Arrange
      final models = [
        StudentModel(
          id: 1,
          courseId: 2,
          name: 'Student in Course 2',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      when(mockDataSource.getStudentsByCourse(2))
          .thenAnswer((_) async => models);

      // Act
      final result = await repository.getStudentsByCourse(2);

      // Assert
      expect(result.length, 1);
      expect(result[0].courseId, 2);
      verify(mockDataSource.getStudentsByCourse(2)).called(1);
    });

    test('should throw DatabaseException on error', () async {
      // Arrange
      when(mockDataSource.getStudentsByCourse(1)).thenThrow(Exception('Error'));

      // Act & Assert
      expect(
        () => repository.getStudentsByCourse(1),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  group('getStudentsFromActiveCourse', () {
    test('should return students from active course', () async {
      // Arrange
      final models = [
        StudentModel(
          id: 1,
          courseId: 1,
          name: 'Active Course Student',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      when(mockDataSource.getStudentsFromActiveCourse())
          .thenAnswer((_) async => models);

      // Act
      final result = await repository.getStudentsFromActiveCourse();

      // Assert
      expect(result.length, 1);
      verify(mockDataSource.getStudentsFromActiveCourse()).called(1);
    });

    test('should throw DatabaseException on error', () async {
      // Arrange
      when(mockDataSource.getStudentsFromActiveCourse())
          .thenThrow(Exception('Error'));

      // Act & Assert
      expect(
        () => repository.getStudentsFromActiveCourse(),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  group('getStudentById', () {
    test('should return single student when found', () async {
      // Arrange
      final model = StudentModel(
        id: 1,
        courseId: 1,
        name: 'Test Student',
        createdAt: now,
        updatedAt: now,
      );

      when(mockDataSource.getStudentById(1)).thenAnswer((_) async => model);

      // Act
      final result = await repository.getStudentById(1);

      // Assert
      expect(result, isNotNull);
      expect(result?.id, 1);
      expect(result?.name, 'Test Student');
      verify(mockDataSource.getStudentById(1)).called(1);
    });

    test('should return null when not found', () async {
      // Arrange
      when(mockDataSource.getStudentById(999)).thenAnswer((_) async => null);

      // Act
      final result = await repository.getStudentById(999);

      // Assert
      expect(result, isNull);
    });

    test('should throw DatabaseException on error', () async {
      // Arrange
      when(mockDataSource.getStudentById(1)).thenThrow(Exception('Error'));

      // Act & Assert
      expect(
        () => repository.getStudentById(1),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  group('getStudentsWithFaceData', () {
    test('should return only students with face embeddings', () async {
      // Arrange
      final models = [
        StudentModel(
          id: 1,
          courseId: 1,
          name: 'Student with Face',
          faceEmbeddings: embeddings,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      when(mockDataSource.getStudentsWithFaceData())
          .thenAnswer((_) async => models);

      // Act
      final result = await repository.getStudentsWithFaceData();

      // Assert
      expect(result.length, 1);
      expect(result[0].hasFaceData, isTrue);
      verify(mockDataSource.getStudentsWithFaceData()).called(1);
    });

    test('should throw DatabaseException on error', () async {
      // Arrange
      when(mockDataSource.getStudentsWithFaceData())
          .thenThrow(Exception('Error'));

      // Act & Assert
      expect(
        () => repository.getStudentsWithFaceData(),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  group('getActiveStudentsWithFaceData', () {
    test('should return active students with face data', () async {
      // Arrange
      final models = [
        StudentModel(
          id: 1,
          courseId: 1,
          name: 'Active Student with Face',
          faceEmbeddings: embeddings,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      when(mockDataSource.getActiveStudentsWithFaceData())
          .thenAnswer((_) async => models);

      // Act
      final result = await repository.getActiveStudentsWithFaceData();

      // Assert
      expect(result.length, 1);
      expect(result[0].hasFaceData, isTrue);
      verify(mockDataSource.getActiveStudentsWithFaceData()).called(1);
    });

    test('should throw DatabaseException on error', () async {
      // Arrange
      when(mockDataSource.getActiveStudentsWithFaceData())
          .thenThrow(Exception('Error'));

      // Act & Assert
      expect(
        () => repository.getActiveStudentsWithFaceData(),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  group('createStudent', () {
    test('should convert entity to model and insert', () async {
      // Arrange
      final entity = Student(
        courseId: 1,
        name: 'New Student',
        createdAt: now,
        updatedAt: now,
      );

      when(mockDataSource.insertStudent(any)).thenAnswer((_) async => 42);

      // Act
      final id = await repository.createStudent(entity);

      // Assert
      expect(id, 42);
      final captured = verify(mockDataSource.insertStudent(captureAny))
          .captured
          .single as StudentModel;
      expect(captured.courseId, 1);
      expect(captured.name, 'New Student');
    });

    test('should preserve face embeddings when creating student', () async {
      // Arrange
      final entity = Student(
        courseId: 1,
        name: 'Student with Face',
        faceEmbeddings: embeddings,
        createdAt: now,
        updatedAt: now,
      );

      when(mockDataSource.insertStudent(any)).thenAnswer((_) async => 42);

      // Act
      await repository.createStudent(entity);

      // Assert
      final captured = verify(mockDataSource.insertStudent(captureAny))
          .captured
          .single as StudentModel;
      expect(captured.faceEmbeddings, embeddings);
      expect(captured.hasFaceData, isTrue);
    });

    test('should throw DatabaseException on error', () async {
      // Arrange
      final entity = Student(
        courseId: 1,
        name: 'Student',
        createdAt: now,
        updatedAt: now,
      );

      when(mockDataSource.insertStudent(any)).thenThrow(Exception('Error'));

      // Act & Assert
      expect(
        () => repository.createStudent(entity),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  group('updateStudent', () {
    test('should convert entity to model and update', () async {
      // Arrange
      final entity = Student(
        id: 1,
        courseId: 1,
        name: 'Updated Student',
        createdAt: now,
        updatedAt: now,
      );

      when(mockDataSource.updateStudent(any)).thenAnswer((_) async => 1);

      // Act
      await repository.updateStudent(entity);

      // Assert
      final captured = verify(mockDataSource.updateStudent(captureAny))
          .captured
          .single as StudentModel;
      expect(captured.id, 1);
      expect(captured.name, 'Updated Student');
    });

    test('should preserve face embeddings when updating student', () async {
      // Arrange
      final entity = Student(
        id: 1,
        courseId: 1,
        name: 'Student',
        faceEmbeddings: embeddings,
        createdAt: now,
        updatedAt: now,
      );

      when(mockDataSource.updateStudent(any)).thenAnswer((_) async => 1);

      // Act
      await repository.updateStudent(entity);

      // Assert
      final captured = verify(mockDataSource.updateStudent(captureAny))
          .captured
          .single as StudentModel;
      expect(captured.faceEmbeddings, embeddings);
    });

    test('should throw InvalidDataException when ID is null', () async {
      // Arrange
      final entity = Student(
        courseId: 1,
        name: 'Student',
        createdAt: now,
        updatedAt: now,
      );

      // Act & Assert
      expect(
        () => repository.updateStudent(entity),
        throwsA(isA<InvalidDataException>()),
      );
      verifyNever(mockDataSource.updateStudent(any));
    });

    test('should throw DatabaseException on datasource error', () async {
      // Arrange
      final entity = Student(
        id: 1,
        courseId: 1,
        name: 'Student',
        createdAt: now,
        updatedAt: now,
      );

      when(mockDataSource.updateStudent(any)).thenThrow(Exception('Error'));

      // Act & Assert
      expect(
        () => repository.updateStudent(entity),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  group('deleteStudent', () {
    test('should call datasource delete', () async {
      // Arrange
      when(mockDataSource.deleteStudent(1)).thenAnswer((_) async => 1);

      // Act
      await repository.deleteStudent(1);

      // Assert
      verify(mockDataSource.deleteStudent(1)).called(1);
    });

    test('should throw DatabaseException on error', () async {
      // Arrange
      when(mockDataSource.deleteStudent(1)).thenThrow(Exception('Error'));

      // Act & Assert
      expect(
        () => repository.deleteStudent(1),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  group('countStudents', () {
    test('should return count from datasource', () async {
      // Arrange
      when(mockDataSource.countStudents()).thenAnswer((_) async => 25);

      // Act
      final count = await repository.countStudents();

      // Assert
      expect(count, 25);
      verify(mockDataSource.countStudents()).called(1);
    });

    test('should throw DatabaseException on error', () async {
      // Arrange
      when(mockDataSource.countStudents()).thenThrow(Exception('Error'));

      // Act & Assert
      expect(
        () => repository.countStudents(),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  group('countStudentsByCourse', () {
    test('should return count for specific course', () async {
      // Arrange
      when(mockDataSource.countStudentsByCourse(2))
          .thenAnswer((_) async => 15);

      // Act
      final count = await repository.countStudentsByCourse(2);

      // Assert
      expect(count, 15);
      verify(mockDataSource.countStudentsByCourse(2)).called(1);
    });

    test('should throw DatabaseException on error', () async {
      // Arrange
      when(mockDataSource.countStudentsByCourse(2))
          .thenThrow(Exception('Error'));

      // Act & Assert
      expect(
        () => repository.countStudentsByCourse(2),
        throwsA(isA<DatabaseException>()),
      );
    });
  });
}
