import 'package:eduportfolio/core/data/datasources/course_local_datasource.dart';
import 'package:eduportfolio/core/data/datasources/evidence_local_datasource.dart';
import 'package:eduportfolio/core/data/models/course_model.dart';
import 'package:eduportfolio/core/data/repositories/course_repository_impl.dart';
import 'package:eduportfolio/core/domain/entities/course.dart';
import 'package:eduportfolio/core/errors/exceptions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'course_repository_impl_test.mocks.dart';

@GenerateMocks([CourseLocalDataSource, EvidenceLocalDataSource])
void main() {
  late MockCourseLocalDataSource mockDataSource;
  late MockEvidenceLocalDataSource mockEvidenceDataSource;
  late CourseRepositoryImpl repository;

  setUp(() {
    mockDataSource = MockCourseLocalDataSource();
    mockEvidenceDataSource = MockEvidenceLocalDataSource();
    repository = CourseRepositoryImpl(mockDataSource, mockEvidenceDataSource);
  });

  final startDate = DateTime(2024, 9, 1);
  final endDate = DateTime(2025, 6, 30);
  final createdAt = DateTime(2024, 1, 15, 10, 30);

  group('getAllCourses', () {
    test('should return list of entities from datasource', () async {
      // Arrange
      final models = [
        CourseModel(
          id: 1,
          name: 'Curso 2024-25',
          startDate: startDate,
          endDate: endDate,
          isActive: true,
          createdAt: createdAt,
        ),
        CourseModel(
          id: 2,
          name: 'Curso 2023-24',
          startDate: DateTime(2023, 9, 1),
          endDate: DateTime(2024, 6, 30),
          isActive: false,
          createdAt: createdAt,
        ),
      ];

      when(mockDataSource.getAllCourses()).thenAnswer((_) async => models);

      // Act
      final result = await repository.getAllCourses();

      // Assert
      expect(result, isA<List<Course>>());
      expect(result.length, 2);
      expect(result[0].name, 'Curso 2024-25');
      expect(result[0].isActive, isTrue);
      expect(result[1].isActive, isFalse);
      verify(mockDataSource.getAllCourses()).called(1);
    });

    test('should throw DatabaseException on datasource error', () async {
      // Arrange
      when(mockDataSource.getAllCourses()).thenThrow(Exception('DB error'));

      // Act & Assert
      expect(
        () => repository.getAllCourses(),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  group('getActiveCourse', () {
    test('should return active course when exists', () async {
      // Arrange
      final model = CourseModel(
        id: 1,
        name: 'Curso Activo 2024-25',
        startDate: startDate,
        isActive: true,
        createdAt: createdAt,
      );

      when(mockDataSource.getActiveCourse()).thenAnswer((_) async => model);

      // Act
      final result = await repository.getActiveCourse();

      // Assert
      expect(result, isNotNull);
      expect(result?.isActive, isTrue);
      expect(result?.name, 'Curso Activo 2024-25');
      verify(mockDataSource.getActiveCourse()).called(1);
    });

    test('should return null when no active course exists', () async {
      // Arrange
      when(mockDataSource.getActiveCourse()).thenAnswer((_) async => null);

      // Act
      final result = await repository.getActiveCourse();

      // Assert
      expect(result, isNull);
    });

    test('should throw DatabaseException on error', () async {
      // Arrange
      when(mockDataSource.getActiveCourse()).thenThrow(Exception('Error'));

      // Act & Assert
      expect(
        () => repository.getActiveCourse(),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  group('getCourseById', () {
    test('should return single course when found', () async {
      // Arrange
      final model = CourseModel(
        id: 1,
        name: 'Curso 2024-25',
        startDate: startDate,
        endDate: endDate,
        isActive: true,
        createdAt: createdAt,
      );

      when(mockDataSource.getCourseById(1)).thenAnswer((_) async => model);

      // Act
      final result = await repository.getCourseById(1);

      // Assert
      expect(result, isNotNull);
      expect(result?.id, 1);
      expect(result?.name, 'Curso 2024-25');
      verify(mockDataSource.getCourseById(1)).called(1);
    });

    test('should return null when not found', () async {
      // Arrange
      when(mockDataSource.getCourseById(999)).thenAnswer((_) async => null);

      // Act
      final result = await repository.getCourseById(999);

      // Assert
      expect(result, isNull);
    });

    test('should throw DatabaseException on error', () async {
      // Arrange
      when(mockDataSource.getCourseById(1)).thenThrow(Exception('Error'));

      // Act & Assert
      expect(
        () => repository.getCourseById(1),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  group('createCourse', () {
    test('should convert entity to model and insert', () async {
      // Arrange
      final entity = Course(
        name: 'Nuevo Curso 2025-26',
        startDate: DateTime(2025, 9, 1),
        isActive: true,
        createdAt: createdAt,
      );

      when(mockDataSource.insertCourse(any)).thenAnswer((_) async => 42);

      // Act
      final id = await repository.createCourse(entity);

      // Assert
      expect(id, 42);
      final captured = verify(mockDataSource.insertCourse(captureAny))
          .captured
          .single as CourseModel;
      expect(captured.name, 'Nuevo Curso 2025-26');
      expect(captured.isActive, isTrue);
    });

    test('should preserve all course fields when creating', () async {
      // Arrange
      final entity = Course(
        name: 'Curso Completo',
        startDate: startDate,
        endDate: endDate,
        isActive: true,
        createdAt: createdAt,
      );

      when(mockDataSource.insertCourse(any)).thenAnswer((_) async => 42);

      // Act
      await repository.createCourse(entity);

      // Assert
      final captured = verify(mockDataSource.insertCourse(captureAny))
          .captured
          .single as CourseModel;
      expect(captured.name, 'Curso Completo');
      expect(captured.startDate, startDate);
      expect(captured.endDate, endDate);
      expect(captured.isActive, true);
    });

    test('should throw DatabaseException on error', () async {
      // Arrange
      final entity = Course(
        name: 'Test',
        startDate: startDate,
        createdAt: createdAt,
      );

      when(mockDataSource.insertCourse(any)).thenThrow(Exception('Error'));

      // Act & Assert
      expect(
        () => repository.createCourse(entity),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  group('updateCourse', () {
    test('should convert entity to model and update', () async {
      // Arrange
      final entity = Course(
        id: 1,
        name: 'Curso Actualizado',
        startDate: startDate,
        endDate: endDate,
        isActive: true,
        createdAt: createdAt,
      );

      when(mockDataSource.updateCourse(any)).thenAnswer((_) async => 1);

      // Act
      await repository.updateCourse(entity);

      // Assert
      final captured = verify(mockDataSource.updateCourse(captureAny))
          .captured
          .single as CourseModel;
      expect(captured.id, 1);
      expect(captured.name, 'Curso Actualizado');
    });

    test('should update isActive status', () async {
      // Arrange
      final entity = Course(
        id: 1,
        name: 'Curso',
        startDate: startDate,
        isActive: false,
        createdAt: createdAt,
      );

      when(mockDataSource.updateCourse(any)).thenAnswer((_) async => 1);

      // Act
      await repository.updateCourse(entity);

      // Assert
      final captured = verify(mockDataSource.updateCourse(captureAny))
          .captured
          .single as CourseModel;
      expect(captured.isActive, false);
    });

    test('should throw InvalidDataException when ID is null', () async {
      // Arrange
      final entity = Course(
        name: 'Test',
        startDate: startDate,
        createdAt: createdAt,
      );

      // Act & Assert
      expect(
        () => repository.updateCourse(entity),
        throwsA(isA<InvalidDataException>()),
      );
      verifyNever(mockDataSource.updateCourse(any));
    });

    test('should throw DatabaseException on datasource error', () async {
      // Arrange
      final entity = Course(
        id: 1,
        name: 'Test',
        startDate: startDate,
        createdAt: createdAt,
      );

      when(mockDataSource.updateCourse(any)).thenThrow(Exception('Error'));

      // Act & Assert
      expect(
        () => repository.updateCourse(entity),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  group('deleteCourse', () {
    test('should call datasource delete', () async {
      // Arrange
      when(mockDataSource.deleteCourse(1)).thenAnswer((_) async => 1);

      // Act
      await repository.deleteCourse(1);

      // Assert
      verify(mockDataSource.deleteCourse(1)).called(1);
    });

    test('should throw DatabaseException on error', () async {
      // Arrange
      when(mockDataSource.deleteCourse(1)).thenThrow(Exception('Error'));

      // Act & Assert
      expect(
        () => repository.deleteCourse(1),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  group('archiveCourse', () {
    test('should call datasource archive with end date', () async {
      // Arrange
      final archiveDate = DateTime(2025, 6, 30);
      when(mockDataSource.archiveCourse(1, archiveDate))
          .thenAnswer((_) async => 1);

      // Act
      await repository.archiveCourse(1, archiveDate);

      // Assert
      verify(mockDataSource.archiveCourse(1, archiveDate)).called(1);
    });

    test('should throw DatabaseException on error', () async {
      // Arrange
      final archiveDate = DateTime(2025, 6, 30);
      when(mockDataSource.archiveCourse(1, archiveDate))
          .thenThrow(Exception('Error'));

      // Act & Assert
      expect(
        () => repository.archiveCourse(1, archiveDate),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  group('countCourses', () {
    test('should return count from datasource', () async {
      // Arrange
      when(mockDataSource.countCourses()).thenAnswer((_) async => 5);

      // Act
      final count = await repository.countCourses();

      // Assert
      expect(count, 5);
      verify(mockDataSource.countCourses()).called(1);
    });

    test('should throw DatabaseException on error', () async {
      // Arrange
      when(mockDataSource.countCourses()).thenThrow(Exception('Error'));

      // Act & Assert
      expect(
        () => repository.countCourses(),
        throwsA(isA<DatabaseException>()),
      );
    });
  });
}
