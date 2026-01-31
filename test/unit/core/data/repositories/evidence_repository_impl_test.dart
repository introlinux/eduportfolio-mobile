import 'package:eduportfolio/core/data/datasources/evidence_local_datasource.dart';
import 'package:eduportfolio/core/data/models/evidence_model.dart';
import 'package:eduportfolio/core/data/repositories/evidence_repository_impl.dart';
import 'package:eduportfolio/core/domain/entities/evidence.dart';
import 'package:eduportfolio/core/errors/exceptions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'evidence_repository_impl_test.mocks.dart';

@GenerateMocks([EvidenceLocalDataSource])
void main() {
  late MockEvidenceLocalDataSource mockDataSource;
  late EvidenceRepositoryImpl repository;

  setUp(() {
    mockDataSource = MockEvidenceLocalDataSource();
    repository = EvidenceRepositoryImpl(mockDataSource);
  });

  final now = DateTime(2024, 1, 15, 10, 30);

  group('getAllEvidences', () {
    test('should return list of entities from datasource', () async {
      // Arrange
      final models = [
        EvidenceModel(
          id: 1,
          studentId: 1,
          subjectId: 1,
          type: EvidenceType.image,
          filePath: '/path/1.jpg',
          captureDate: now,
          createdAt: now,
        ),
        EvidenceModel(
          id: 2,
          studentId: 2,
          subjectId: 2,
          type: EvidenceType.video,
          filePath: '/path/2.mp4',
          captureDate: now,
          createdAt: now,
        ),
      ];

      when(mockDataSource.getAllEvidences()).thenAnswer((_) async => models);

      // Act
      final result = await repository.getAllEvidences();

      // Assert
      expect(result, isA<List<Evidence>>());
      expect(result.length, 2);
      expect(result[0].id, 1);
      expect(result[1].id, 2);
      verify(mockDataSource.getAllEvidences()).called(1);
    });

    test('should throw DatabaseException on datasource error', () async {
      // Arrange
      when(mockDataSource.getAllEvidences()).thenThrow(Exception('DB error'));

      // Act & Assert
      expect(
        () => repository.getAllEvidences(),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  group('getEvidencesByStudent', () {
    test('should return filtered evidences by student', () async {
      // Arrange
      final models = [
        EvidenceModel(
          id: 1,
          studentId: 1,
          subjectId: 1,
          type: EvidenceType.image,
          filePath: '/path/1.jpg',
          captureDate: now,
          createdAt: now,
        ),
      ];

      when(mockDataSource.getEvidencesByStudent(1))
          .thenAnswer((_) async => models);

      // Act
      final result = await repository.getEvidencesByStudent(1);

      // Assert
      expect(result.length, 1);
      expect(result[0].studentId, 1);
      verify(mockDataSource.getEvidencesByStudent(1)).called(1);
    });

    test('should throw DatabaseException on error', () async {
      // Arrange
      when(mockDataSource.getEvidencesByStudent(1))
          .thenThrow(Exception('Error'));

      // Act & Assert
      expect(
        () => repository.getEvidencesByStudent(1),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  group('getEvidencesBySubject', () {
    test('should return filtered evidences by subject', () async {
      // Arrange
      final models = [
        EvidenceModel(
          id: 1,
          studentId: 1,
          subjectId: 2,
          type: EvidenceType.image,
          filePath: '/path/1.jpg',
          captureDate: now,
          createdAt: now,
        ),
      ];

      when(mockDataSource.getEvidencesBySubject(2))
          .thenAnswer((_) async => models);

      // Act
      final result = await repository.getEvidencesBySubject(2);

      // Assert
      expect(result.length, 1);
      expect(result[0].subjectId, 2);
      verify(mockDataSource.getEvidencesBySubject(2)).called(1);
    });
  });

  group('getEvidencesByStudentAndSubject', () {
    test('should return evidences filtered by student and subject', () async {
      // Arrange
      final models = [
        EvidenceModel(
          id: 1,
          studentId: 1,
          subjectId: 2,
          type: EvidenceType.image,
          filePath: '/path/1.jpg',
          captureDate: now,
          createdAt: now,
        ),
      ];

      when(mockDataSource.getEvidencesByStudentAndSubject(1, 2))
          .thenAnswer((_) async => models);

      // Act
      final result = await repository.getEvidencesByStudentAndSubject(1, 2);

      // Assert
      expect(result.length, 1);
      expect(result[0].studentId, 1);
      expect(result[0].subjectId, 2);
      verify(mockDataSource.getEvidencesByStudentAndSubject(1, 2)).called(1);
    });
  });

  group('getEvidencesByType', () {
    test('should return evidences filtered by type', () async {
      // Arrange
      final models = [
        EvidenceModel(
          id: 1,
          studentId: 1,
          subjectId: 1,
          type: EvidenceType.video,
          filePath: '/path/1.mp4',
          captureDate: now,
          createdAt: now,
        ),
      ];

      when(mockDataSource.getEvidencesByType(EvidenceType.video))
          .thenAnswer((_) async => models);

      // Act
      final result = await repository.getEvidencesByType(EvidenceType.video);

      // Assert
      expect(result.length, 1);
      expect(result[0].type, EvidenceType.video);
      verify(mockDataSource.getEvidencesByType(EvidenceType.video)).called(1);
    });
  });

  group('getEvidencesNeedingReview', () {
    test('should return unreviewed evidences', () async {
      // Arrange
      final models = [
        EvidenceModel(
          id: 1,
          studentId: 1,
          subjectId: 1,
          type: EvidenceType.image,
          filePath: '/path/1.jpg',
          isReviewed: false,
          captureDate: now,
          createdAt: now,
        ),
      ];

      when(mockDataSource.getEvidencesNeedingReview())
          .thenAnswer((_) async => models);

      // Act
      final result = await repository.getEvidencesNeedingReview();

      // Assert
      expect(result.length, 1);
      expect(result[0].isReviewed, false);
      verify(mockDataSource.getEvidencesNeedingReview()).called(1);
    });
  });

  group('getUnassignedEvidences', () {
    test('should return evidences without student assignment', () async {
      // Arrange
      final models = [
        EvidenceModel(
          id: 1,
          studentId: null,
          subjectId: 1,
          type: EvidenceType.image,
          filePath: '/path/1.jpg',
          captureDate: now,
          createdAt: now,
        ),
      ];

      when(mockDataSource.getUnassignedEvidences())
          .thenAnswer((_) async => models);

      // Act
      final result = await repository.getUnassignedEvidences();

      // Assert
      expect(result.length, 1);
      expect(result[0].studentId, isNull);
      verify(mockDataSource.getUnassignedEvidences()).called(1);
    });
  });

  group('getEvidencesByDateRange', () {
    test('should return evidences within date range', () async {
      // Arrange
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 31);
      final models = [
        EvidenceModel(
          id: 1,
          studentId: 1,
          subjectId: 1,
          type: EvidenceType.image,
          filePath: '/path/1.jpg',
          captureDate: DateTime(2024, 1, 15),
          createdAt: now,
        ),
      ];

      when(mockDataSource.getEvidencesByDateRange(startDate, endDate))
          .thenAnswer((_) async => models);

      // Act
      final result = await repository.getEvidencesByDateRange(startDate, endDate);

      // Assert
      expect(result.length, 1);
      verify(mockDataSource.getEvidencesByDateRange(startDate, endDate)).called(1);
    });
  });

  group('getEvidenceById', () {
    test('should return single evidence when found', () async {
      // Arrange
      final model = EvidenceModel(
        id: 1,
        studentId: 1,
        subjectId: 1,
        type: EvidenceType.image,
        filePath: '/path/1.jpg',
        captureDate: now,
        createdAt: now,
      );

      when(mockDataSource.getEvidenceById(1)).thenAnswer((_) async => model);

      // Act
      final result = await repository.getEvidenceById(1);

      // Assert
      expect(result, isNotNull);
      expect(result?.id, 1);
      verify(mockDataSource.getEvidenceById(1)).called(1);
    });

    test('should return null when not found', () async {
      // Arrange
      when(mockDataSource.getEvidenceById(999)).thenAnswer((_) async => null);

      // Act
      final result = await repository.getEvidenceById(999);

      // Assert
      expect(result, isNull);
    });

    test('should throw DatabaseException on error', () async {
      // Arrange
      when(mockDataSource.getEvidenceById(1)).thenThrow(Exception('Error'));

      // Act & Assert
      expect(
        () => repository.getEvidenceById(1),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  group('createEvidence', () {
    test('should convert entity to model and insert', () async {
      // Arrange
      final entity = Evidence(
        studentId: 1,
        subjectId: 1,
        type: EvidenceType.image,
        filePath: '/path/1.jpg',
        captureDate: now,
        createdAt: now,
      );

      when(mockDataSource.insertEvidence(any)).thenAnswer((_) async => 42);

      // Act
      final id = await repository.createEvidence(entity);

      // Assert
      expect(id, 42);
      final captured = verify(mockDataSource.insertEvidence(captureAny))
          .captured
          .single as EvidenceModel;
      expect(captured.studentId, 1);
      expect(captured.subjectId, 1);
      expect(captured.type, EvidenceType.image);
    });

    test('should throw DatabaseException on error', () async {
      // Arrange
      final entity = Evidence(
        studentId: 1,
        subjectId: 1,
        type: EvidenceType.image,
        filePath: '/path/1.jpg',
        captureDate: now,
        createdAt: now,
      );

      when(mockDataSource.insertEvidence(any)).thenThrow(Exception('Error'));

      // Act & Assert
      expect(
        () => repository.createEvidence(entity),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  group('updateEvidence', () {
    test('should convert entity to model and update', () async {
      // Arrange
      final entity = Evidence(
        id: 1,
        studentId: 1,
        subjectId: 1,
        type: EvidenceType.image,
        filePath: '/path/1.jpg',
        isReviewed: true,
        captureDate: now,
        createdAt: now,
      );

      when(mockDataSource.updateEvidence(any)).thenAnswer((_) async => 1);

      // Act
      await repository.updateEvidence(entity);

      // Assert
      final captured = verify(mockDataSource.updateEvidence(captureAny))
          .captured
          .single as EvidenceModel;
      expect(captured.id, 1);
      expect(captured.isReviewed, true);
    });

    test('should throw InvalidDataException when ID is null', () async {
      // Arrange
      final entity = Evidence(
        studentId: 1,
        subjectId: 1,
        type: EvidenceType.image,
        filePath: '/path/1.jpg',
        captureDate: now,
        createdAt: now,
      );

      // Act & Assert
      expect(
        () => repository.updateEvidence(entity),
        throwsA(isA<InvalidDataException>()),
      );
      verifyNever(mockDataSource.updateEvidence(any));
    });

    test('should throw DatabaseException on datasource error', () async {
      // Arrange
      final entity = Evidence(
        id: 1,
        studentId: 1,
        subjectId: 1,
        type: EvidenceType.image,
        filePath: '/path/1.jpg',
        captureDate: now,
        createdAt: now,
      );

      when(mockDataSource.updateEvidence(any)).thenThrow(Exception('Error'));

      // Act & Assert
      expect(
        () => repository.updateEvidence(entity),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  group('deleteEvidence', () {
    test('should call datasource delete', () async {
      // Arrange
      when(mockDataSource.deleteEvidence(1)).thenAnswer((_) async => 1);

      // Act
      await repository.deleteEvidence(1);

      // Assert
      verify(mockDataSource.deleteEvidence(1)).called(1);
    });

    test('should throw DatabaseException on error', () async {
      // Arrange
      when(mockDataSource.deleteEvidence(1)).thenThrow(Exception('Error'));

      // Act & Assert
      expect(
        () => repository.deleteEvidence(1),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  group('assignEvidenceToStudent', () {
    test('should call datasource assign method', () async {
      // Arrange
      when(mockDataSource.assignEvidenceToStudent(1, 2))
          .thenAnswer((_) async => 1);

      // Act
      await repository.assignEvidenceToStudent(1, 2);

      // Assert
      verify(mockDataSource.assignEvidenceToStudent(1, 2)).called(1);
    });

    test('should throw DatabaseException on error', () async {
      // Arrange
      when(mockDataSource.assignEvidenceToStudent(1, 2))
          .thenThrow(Exception('Error'));

      // Act & Assert
      expect(
        () => repository.assignEvidenceToStudent(1, 2),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  group('countEvidences', () {
    test('should return count from datasource', () async {
      // Arrange
      when(mockDataSource.countEvidences()).thenAnswer((_) async => 42);

      // Act
      final count = await repository.countEvidences();

      // Assert
      expect(count, 42);
      verify(mockDataSource.countEvidences()).called(1);
    });

    test('should throw DatabaseException on error', () async {
      // Arrange
      when(mockDataSource.countEvidences()).thenThrow(Exception('Error'));

      // Act & Assert
      expect(
        () => repository.countEvidences(),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  group('countEvidencesByStudent', () {
    test('should return count for specific student', () async {
      // Arrange
      when(mockDataSource.countEvidencesByStudent(1))
          .thenAnswer((_) async => 15);

      // Act
      final count = await repository.countEvidencesByStudent(1);

      // Assert
      expect(count, 15);
      verify(mockDataSource.countEvidencesByStudent(1)).called(1);
    });
  });

  group('countEvidencesNeedingReview', () {
    test('should return count of unreviewed evidences', () async {
      // Arrange
      when(mockDataSource.countEvidencesNeedingReview())
          .thenAnswer((_) async => 7);

      // Act
      final count = await repository.countEvidencesNeedingReview();

      // Assert
      expect(count, 7);
      verify(mockDataSource.countEvidencesNeedingReview()).called(1);
    });
  });

  group('getTotalStorageSize', () {
    test('should return total storage size in bytes', () async {
      // Arrange
      when(mockDataSource.getTotalStorageSize())
          .thenAnswer((_) async => 1024000);

      // Act
      final size = await repository.getTotalStorageSize();

      // Assert
      expect(size, 1024000);
      verify(mockDataSource.getTotalStorageSize()).called(1);
    });

    test('should throw DatabaseException on error', () async {
      // Arrange
      when(mockDataSource.getTotalStorageSize()).thenThrow(Exception('Error'));

      // Act & Assert
      expect(
        () => repository.getTotalStorageSize(),
        throwsA(isA<DatabaseException>()),
      );
    });
  });
}
