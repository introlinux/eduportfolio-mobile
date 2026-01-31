import 'package:eduportfolio/core/data/datasources/subject_local_datasource.dart';
import 'package:eduportfolio/core/data/models/subject_model.dart';
import 'package:eduportfolio/core/data/repositories/subject_repository_impl.dart';
import 'package:eduportfolio/core/domain/entities/subject.dart';
import 'package:eduportfolio/core/errors/exceptions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'subject_repository_impl_test.mocks.dart';

@GenerateMocks([SubjectLocalDataSource])
void main() {
  late MockSubjectLocalDataSource mockDataSource;
  late SubjectRepositoryImpl repository;

  setUp(() {
    mockDataSource = MockSubjectLocalDataSource();
    repository = SubjectRepositoryImpl(mockDataSource);
  });

  final now = DateTime(2024, 1, 15, 10, 30);

  group('getAllSubjects', () {
    test('should return list of entities from datasource', () async {
      // Arrange
      final models = [
        SubjectModel(
          id: 1,
          name: 'Matemáticas',
          color: 'FF2196F3',
          icon: 'calculate',
          isDefault: true,
          createdAt: now,
        ),
        SubjectModel(
          id: 2,
          name: 'Lengua',
          color: 'FFF44336',
          icon: 'menu_book',
          isDefault: false,
          createdAt: now,
        ),
      ];

      when(mockDataSource.getAllSubjects()).thenAnswer((_) async => models);

      // Act
      final result = await repository.getAllSubjects();

      // Assert
      expect(result, isA<List<Subject>>());
      expect(result.length, 2);
      expect(result[0].name, 'Matemáticas');
      expect(result[1].name, 'Lengua');
      verify(mockDataSource.getAllSubjects()).called(1);
    });

    test('should throw DatabaseException on datasource error', () async {
      // Arrange
      when(mockDataSource.getAllSubjects()).thenThrow(Exception('DB error'));

      // Act & Assert
      expect(
        () => repository.getAllSubjects(),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  group('getDefaultSubjects', () {
    test('should return only default subjects', () async {
      // Arrange
      final models = [
        SubjectModel(
          id: 1,
          name: 'Matemáticas',
          color: 'FF2196F3',
          icon: 'calculate',
          isDefault: true,
          createdAt: now,
        ),
      ];

      when(mockDataSource.getDefaultSubjects())
          .thenAnswer((_) async => models);

      // Act
      final result = await repository.getDefaultSubjects();

      // Assert
      expect(result.length, 1);
      expect(result[0].isDefault, isTrue);
      verify(mockDataSource.getDefaultSubjects()).called(1);
    });

    test('should throw DatabaseException on error', () async {
      // Arrange
      when(mockDataSource.getDefaultSubjects()).thenThrow(Exception('Error'));

      // Act & Assert
      expect(
        () => repository.getDefaultSubjects(),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  group('getSubjectById', () {
    test('should return single subject when found', () async {
      // Arrange
      final model = SubjectModel(
        id: 1,
        name: 'Matemáticas',
        color: 'FF2196F3',
        icon: 'calculate',
        isDefault: true,
        createdAt: now,
      );

      when(mockDataSource.getSubjectById(1)).thenAnswer((_) async => model);

      // Act
      final result = await repository.getSubjectById(1);

      // Assert
      expect(result, isNotNull);
      expect(result?.id, 1);
      expect(result?.name, 'Matemáticas');
      verify(mockDataSource.getSubjectById(1)).called(1);
    });

    test('should return null when not found', () async {
      // Arrange
      when(mockDataSource.getSubjectById(999)).thenAnswer((_) async => null);

      // Act
      final result = await repository.getSubjectById(999);

      // Assert
      expect(result, isNull);
    });

    test('should throw DatabaseException on error', () async {
      // Arrange
      when(mockDataSource.getSubjectById(1)).thenThrow(Exception('Error'));

      // Act & Assert
      expect(
        () => repository.getSubjectById(1),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  group('getSubjectByName', () {
    test('should return subject when found by name', () async {
      // Arrange
      final model = SubjectModel(
        id: 1,
        name: 'Matemáticas',
        color: 'FF2196F3',
        icon: 'calculate',
        isDefault: true,
        createdAt: now,
      );

      when(mockDataSource.getSubjectByName('Matemáticas'))
          .thenAnswer((_) async => model);

      // Act
      final result = await repository.getSubjectByName('Matemáticas');

      // Assert
      expect(result, isNotNull);
      expect(result?.name, 'Matemáticas');
      verify(mockDataSource.getSubjectByName('Matemáticas')).called(1);
    });

    test('should return null when not found', () async {
      // Arrange
      when(mockDataSource.getSubjectByName('NonExistent'))
          .thenAnswer((_) async => null);

      // Act
      final result = await repository.getSubjectByName('NonExistent');

      // Assert
      expect(result, isNull);
    });

    test('should throw DatabaseException on error', () async {
      // Arrange
      when(mockDataSource.getSubjectByName('Test'))
          .thenThrow(Exception('Error'));

      // Act & Assert
      expect(
        () => repository.getSubjectByName('Test'),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  group('createSubject', () {
    test('should convert entity to model and insert', () async {
      // Arrange
      final entity = Subject(
        name: 'Nueva Asignatura',
        color: 'FF9C27B0',
        icon: 'school',
        isDefault: false,
        createdAt: now,
      );

      when(mockDataSource.insertSubject(any)).thenAnswer((_) async => 42);

      // Act
      final id = await repository.createSubject(entity);

      // Assert
      expect(id, 42);
      final captured = verify(mockDataSource.insertSubject(captureAny))
          .captured
          .single as SubjectModel;
      expect(captured.name, 'Nueva Asignatura');
      expect(captured.color, 'FF9C27B0');
      expect(captured.isDefault, false);
    });

    test('should throw DatabaseException on error', () async {
      // Arrange
      final entity = Subject(
        name: 'Test',
        color: 'FF000000',
        icon: 'school',
        isDefault: false,
        createdAt: now,
      );

      when(mockDataSource.insertSubject(any)).thenThrow(Exception('Error'));

      // Act & Assert
      expect(
        () => repository.createSubject(entity),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  group('updateSubject', () {
    test('should convert entity to model and update', () async {
      // Arrange
      final entity = Subject(
        id: 1,
        name: 'Matemáticas Actualizadas',
        color: 'FF2196F3',
        icon: 'calculate',
        isDefault: true,
        createdAt: now,
      );

      when(mockDataSource.updateSubject(any)).thenAnswer((_) async => 1);

      // Act
      await repository.updateSubject(entity);

      // Assert
      final captured = verify(mockDataSource.updateSubject(captureAny))
          .captured
          .single as SubjectModel;
      expect(captured.id, 1);
      expect(captured.name, 'Matemáticas Actualizadas');
    });

    test('should throw InvalidDataException when ID is null', () async {
      // Arrange
      final entity = Subject(
        name: 'Test',
        color: 'FF000000',
        icon: 'school',
        isDefault: false,
        createdAt: now,
      );

      // Act & Assert
      expect(
        () => repository.updateSubject(entity),
        throwsA(isA<InvalidDataException>()),
      );
      verifyNever(mockDataSource.updateSubject(any));
    });

    test('should throw DatabaseException on datasource error', () async {
      // Arrange
      final entity = Subject(
        id: 1,
        name: 'Test',
        color: 'FF000000',
        icon: 'school',
        isDefault: false,
        createdAt: now,
      );

      when(mockDataSource.updateSubject(any)).thenThrow(Exception('Error'));

      // Act & Assert
      expect(
        () => repository.updateSubject(entity),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  group('deleteSubject', () {
    test('should call datasource delete', () async {
      // Arrange
      when(mockDataSource.deleteSubject(1)).thenAnswer((_) async => 1);

      // Act
      await repository.deleteSubject(1);

      // Assert
      verify(mockDataSource.deleteSubject(1)).called(1);
    });

    test('should throw DatabaseException on error', () async {
      // Arrange
      when(mockDataSource.deleteSubject(1)).thenThrow(Exception('Error'));

      // Act & Assert
      expect(
        () => repository.deleteSubject(1),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  group('countSubjects', () {
    test('should return count from datasource', () async {
      // Arrange
      when(mockDataSource.countSubjects()).thenAnswer((_) async => 12);

      // Act
      final count = await repository.countSubjects();

      // Assert
      expect(count, 12);
      verify(mockDataSource.countSubjects()).called(1);
    });

    test('should throw DatabaseException on error', () async {
      // Arrange
      when(mockDataSource.countSubjects()).thenThrow(Exception('Error'));

      // Act & Assert
      expect(
        () => repository.countSubjects(),
        throwsA(isA<DatabaseException>()),
      );
    });
  });
}
