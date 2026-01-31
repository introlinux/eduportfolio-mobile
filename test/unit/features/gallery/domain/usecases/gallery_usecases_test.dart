import 'dart:io';

import 'package:eduportfolio/core/domain/entities/evidence.dart';
import 'package:eduportfolio/core/domain/repositories/evidence_repository.dart';
import 'package:eduportfolio/features/gallery/domain/usecases/assign_evidences_to_student_usecase.dart';
import 'package:eduportfolio/features/gallery/domain/usecases/delete_evidence_usecase.dart';
import 'package:eduportfolio/features/gallery/domain/usecases/delete_evidences_usecase.dart';
import 'package:eduportfolio/features/gallery/domain/usecases/get_all_evidences_usecase.dart';
import 'package:eduportfolio/features/gallery/domain/usecases/get_evidence_by_id_usecase.dart';
import 'package:eduportfolio/features/gallery/domain/usecases/get_evidences_by_subject_usecase.dart';
import 'package:eduportfolio/features/gallery/domain/usecases/update_evidences_subject_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'gallery_usecases_test.mocks.dart';

@GenerateMocks([EvidenceRepository])
void main() {
  late MockEvidenceRepository mockRepository;

  setUp(() {
    mockRepository = MockEvidenceRepository();
  });

  group('GetAllEvidencesUseCase', () {
    late GetAllEvidencesUseCase useCase;

    setUp(() {
      useCase = GetAllEvidencesUseCase(mockRepository);
    });

    test('should get all evidences ordered by capture date desc', () async {
      // Arrange
      final now = DateTime.now();
      final evidence1 = Evidence(
        id: 1,
        subjectId: 1,
        type: EvidenceType.image,
        filePath: '/path/1.jpg',
        captureDate: now.subtract(const Duration(hours: 2)),
        createdAt: now.subtract(const Duration(hours: 2)),
        isReviewed: false,
      );
      final evidence2 = Evidence(
        id: 2,
        subjectId: 2,
        type: EvidenceType.image,
        filePath: '/path/2.jpg',
        captureDate: now.subtract(const Duration(hours: 1)),
        createdAt: now.subtract(const Duration(hours: 1)),
        isReviewed: false,
      );
      final evidence3 = Evidence(
        id: 3,
        subjectId: 1,
        type: EvidenceType.image,
        filePath: '/path/3.jpg',
        captureDate: now,
        createdAt: now,
        isReviewed: false,
      );

      when(mockRepository.getAllEvidences())
          .thenAnswer((_) async => [evidence1, evidence2, evidence3]);

      // Act
      final result = await useCase();

      // Assert
      expect(result.length, 3);
      // Should be ordered newest first
      expect(result[0].id, 3);
      expect(result[1].id, 2);
      expect(result[2].id, 1);
      verify(mockRepository.getAllEvidences()).called(1);
    });

    test('should return empty list when no evidences', () async {
      // Arrange
      when(mockRepository.getAllEvidences()).thenAnswer((_) async => []);

      // Act
      final result = await useCase();

      // Assert
      expect(result, isEmpty);
    });
  });

  group('GetEvidencesBySubjectUseCase', () {
    late GetEvidencesBySubjectUseCase useCase;

    setUp(() {
      useCase = GetEvidencesBySubjectUseCase(mockRepository);
    });

    test('should get evidences for specific subject ordered by date desc',
        () async {
      // Arrange
      const subjectId = 1;
      final now = DateTime.now();
      final evidence1 = Evidence(
        id: 1,
        subjectId: subjectId,
        type: EvidenceType.image,
        filePath: '/path/1.jpg',
        captureDate: now.subtract(const Duration(hours: 1)),
        createdAt: now.subtract(const Duration(hours: 1)),
        isReviewed: false,
      );
      final evidence2 = Evidence(
        id: 2,
        subjectId: subjectId,
        type: EvidenceType.image,
        filePath: '/path/2.jpg',
        captureDate: now,
        createdAt: now,
        isReviewed: false,
      );

      when(mockRepository.getEvidencesBySubject(subjectId))
          .thenAnswer((_) async => [evidence1, evidence2]);

      // Act
      final result = await useCase(subjectId);

      // Assert
      expect(result.length, 2);
      // Should be ordered newest first
      expect(result[0].id, 2);
      expect(result[1].id, 1);
      verify(mockRepository.getEvidencesBySubject(subjectId)).called(1);
    });
  });

  group('GetEvidenceByIdUseCase', () {
    late GetEvidenceByIdUseCase useCase;

    setUp(() {
      useCase = GetEvidenceByIdUseCase(mockRepository);
    });

    test('should get evidence by ID', () async {
      // Arrange
      const evidenceId = 1;
      final evidence = Evidence(
        id: evidenceId,
        subjectId: 1,
        type: EvidenceType.image,
        filePath: '/path/1.jpg',
        captureDate: DateTime.now(),
        createdAt: DateTime.now(),
        isReviewed: false,
      );

      when(mockRepository.getEvidenceById(evidenceId))
          .thenAnswer((_) async => evidence);

      // Act
      final result = await useCase(evidenceId);

      // Assert
      expect(result, evidence);
      verify(mockRepository.getEvidenceById(evidenceId)).called(1);
    });

    test('should return null when evidence not found', () async {
      // Arrange
      const evidenceId = 999;

      when(mockRepository.getEvidenceById(evidenceId))
          .thenAnswer((_) async => null);

      // Act
      final result = await useCase(evidenceId);

      // Assert
      expect(result, isNull);
    });
  });

  group('DeleteEvidenceUseCase', () {
    late DeleteEvidenceUseCase useCase;
    late Directory tempDir;

    setUp(() async {
      useCase = DeleteEvidenceUseCase(mockRepository);
      // Create temp directory for test files
      tempDir = await Directory.systemTemp.createTemp('evidence_test_');
    });

    tearDown(() async {
      // Clean up temp directory
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('should delete evidence file and database record', () async {
      // Arrange
      const evidenceId = 1;
      final testFile = File('${tempDir.path}/test_evidence.jpg');
      await testFile.writeAsBytes([1, 2, 3, 4]);

      final evidence = Evidence(
        id: evidenceId,
        subjectId: 1,
        type: EvidenceType.image,
        filePath: testFile.path,
        captureDate: DateTime.now(),
        createdAt: DateTime.now(),
        isReviewed: false,
      );

      when(mockRepository.getEvidenceById(evidenceId))
          .thenAnswer((_) async => evidence);
      when(mockRepository.deleteEvidence(evidenceId))
          .thenAnswer((_) async => Future<void>.value());

      // Verify file exists before deletion
      expect(await testFile.exists(), isTrue);

      // Act
      await useCase(evidenceId);

      // Assert
      // File should be deleted
      expect(await testFile.exists(), isFalse);
      // Repository methods should be called
      verify(mockRepository.getEvidenceById(evidenceId)).called(1);
      verify(mockRepository.deleteEvidence(evidenceId)).called(1);
    });

    test('should delete thumbnail if it exists', () async {
      // Arrange
      const evidenceId = 1;
      final testFile = File('${tempDir.path}/test_evidence.jpg');
      final thumbnailFile = File('${tempDir.path}/test_thumbnail.jpg');
      await testFile.writeAsBytes([1, 2, 3, 4]);
      await thumbnailFile.writeAsBytes([5, 6, 7, 8]);

      final evidence = Evidence(
        id: evidenceId,
        subjectId: 1,
        type: EvidenceType.image,
        filePath: testFile.path,
        thumbnailPath: thumbnailFile.path,
        captureDate: DateTime.now(),
        createdAt: DateTime.now(),
        isReviewed: false,
      );

      when(mockRepository.getEvidenceById(evidenceId))
          .thenAnswer((_) async => evidence);
      when(mockRepository.deleteEvidence(evidenceId))
          .thenAnswer((_) async => Future<void>.value());

      // Verify files exist before deletion
      expect(await testFile.exists(), isTrue);
      expect(await thumbnailFile.exists(), isTrue);

      // Act
      await useCase(evidenceId);

      // Assert
      // Both files should be deleted
      expect(await testFile.exists(), isFalse);
      expect(await thumbnailFile.exists(), isFalse);
    });

    test('should throw exception when evidence not found', () async {
      // Arrange
      const evidenceId = 999;

      when(mockRepository.getEvidenceById(evidenceId))
          .thenAnswer((_) async => null);

      // Act & Assert
      expect(
        () => useCase(evidenceId),
        throwsA(isA<Exception>()),
      );
    });

    test('should handle missing file gracefully', () async {
      // Arrange
      const evidenceId = 1;
      final nonExistentPath = '${tempDir.path}/nonexistent.jpg';

      final evidence = Evidence(
        id: evidenceId,
        subjectId: 1,
        type: EvidenceType.image,
        filePath: nonExistentPath,
        captureDate: DateTime.now(),
        createdAt: DateTime.now(),
        isReviewed: false,
      );

      when(mockRepository.getEvidenceById(evidenceId))
          .thenAnswer((_) async => evidence);
      when(mockRepository.deleteEvidence(evidenceId))
          .thenAnswer((_) async => Future<void>.value());

      // Act - should not throw
      await useCase(evidenceId);

      // Assert
      verify(mockRepository.deleteEvidence(evidenceId)).called(1);
    });
  });

  group('UpdateEvidencesSubjectUseCase', () {
    late UpdateEvidencesSubjectUseCase useCase;

    setUp(() {
      useCase = UpdateEvidencesSubjectUseCase(mockRepository);
    });

    test('should update subject for all evidences and return count', () async {
      // Arrange
      final now = DateTime.now();
      const newSubjectId = 5;
      final evidenceIds = [1, 2, 3];

      final evidence1 = Evidence(
        id: 1,
        subjectId: 1,
        type: EvidenceType.image,
        filePath: '/path/1.jpg',
        captureDate: now,
        createdAt: now,
      );

      final evidence2 = Evidence(
        id: 2,
        subjectId: 2,
        type: EvidenceType.image,
        filePath: '/path/2.jpg',
        captureDate: now,
        createdAt: now,
      );

      final evidence3 = Evidence(
        id: 3,
        subjectId: 1,
        type: EvidenceType.image,
        filePath: '/path/3.jpg',
        captureDate: now,
        createdAt: now,
      );

      when(mockRepository.getEvidenceById(1))
          .thenAnswer((_) async => evidence1);
      when(mockRepository.getEvidenceById(2))
          .thenAnswer((_) async => evidence2);
      when(mockRepository.getEvidenceById(3))
          .thenAnswer((_) async => evidence3);

      when(mockRepository.updateEvidence(any))
          .thenAnswer((_) async => Future.value());

      // Act
      final successCount = await useCase(evidenceIds, newSubjectId);

      // Assert
      expect(successCount, 3);
      verify(mockRepository.getEvidenceById(1)).called(1);
      verify(mockRepository.getEvidenceById(2)).called(1);
      verify(mockRepository.getEvidenceById(3)).called(1);
      verify(mockRepository.updateEvidence(any)).called(3);
    });

    test('should skip missing evidences and return partial count', () async {
      // Arrange
      final now = DateTime.now();
      const newSubjectId = 5;
      final evidenceIds = [1, 999, 3]; // 999 doesn't exist

      final evidence1 = Evidence(
        id: 1,
        subjectId: 1,
        type: EvidenceType.image,
        filePath: '/path/1.jpg',
        captureDate: now,
        createdAt: now,
      );

      final evidence3 = Evidence(
        id: 3,
        subjectId: 1,
        type: EvidenceType.image,
        filePath: '/path/3.jpg',
        captureDate: now,
        createdAt: now,
      );

      when(mockRepository.getEvidenceById(1))
          .thenAnswer((_) async => evidence1);
      when(mockRepository.getEvidenceById(999))
          .thenAnswer((_) async => null); // Missing
      when(mockRepository.getEvidenceById(3))
          .thenAnswer((_) async => evidence3);

      when(mockRepository.updateEvidence(any))
          .thenAnswer((_) async => Future.value());

      // Act
      final successCount = await useCase(evidenceIds, newSubjectId);

      // Assert
      expect(successCount, 2); // Only 1 and 3 updated
      verify(mockRepository.updateEvidence(any)).called(2);
    });

    test('should continue on error and return partial count', () async {
      // Arrange
      final now = DateTime.now();
      const newSubjectId = 5;
      final evidenceIds = [1, 2, 3];

      final evidence1 = Evidence(
        id: 1,
        subjectId: 1,
        type: EvidenceType.image,
        filePath: '/path/1.jpg',
        captureDate: now,
        createdAt: now,
      );

      final evidence3 = Evidence(
        id: 3,
        subjectId: 1,
        type: EvidenceType.image,
        filePath: '/path/3.jpg',
        captureDate: now,
        createdAt: now,
      );

      when(mockRepository.getEvidenceById(1))
          .thenAnswer((_) async => evidence1);
      when(mockRepository.getEvidenceById(2))
          .thenThrow(Exception('Error')); // Error on 2
      when(mockRepository.getEvidenceById(3))
          .thenAnswer((_) async => evidence3);

      when(mockRepository.updateEvidence(any))
          .thenAnswer((_) async => Future.value());

      // Act - should not throw
      final successCount = await useCase(evidenceIds, newSubjectId);

      // Assert
      expect(successCount, 2); // Only 1 and 3 updated
    });
  });

  group('AssignEvidencesToStudentUseCase', () {
    late AssignEvidencesToStudentUseCase useCase;

    setUp(() {
      useCase = AssignEvidencesToStudentUseCase(mockRepository);
    });

    test('should assign all evidences to student and return count', () async {
      // Arrange
      const studentId = 10;
      final evidenceIds = [1, 2, 3];

      when(mockRepository.assignEvidenceToStudent(any, any))
          .thenAnswer((_) async => Future.value());

      // Act
      final successCount = await useCase(evidenceIds, studentId);

      // Assert
      expect(successCount, 3);
      verify(mockRepository.assignEvidenceToStudent(1, studentId)).called(1);
      verify(mockRepository.assignEvidenceToStudent(2, studentId)).called(1);
      verify(mockRepository.assignEvidenceToStudent(3, studentId)).called(1);
    });

    test('should continue on error and return partial count', () async {
      // Arrange
      const studentId = 10;
      final evidenceIds = [1, 2, 3];

      when(mockRepository.assignEvidenceToStudent(1, studentId))
          .thenAnswer((_) async => Future.value());
      when(mockRepository.assignEvidenceToStudent(2, studentId))
          .thenThrow(Exception('Error')); // Error on 2
      when(mockRepository.assignEvidenceToStudent(3, studentId))
          .thenAnswer((_) async => Future.value());

      // Act - should not throw
      final successCount = await useCase(evidenceIds, studentId);

      // Assert
      expect(successCount, 2); // Only 1 and 3 assigned
      verify(mockRepository.assignEvidenceToStudent(1, studentId)).called(1);
      verify(mockRepository.assignEvidenceToStudent(2, studentId)).called(1);
      verify(mockRepository.assignEvidenceToStudent(3, studentId)).called(1);
    });

    test('should return 0 for empty list', () async {
      // Arrange
      const studentId = 10;
      final evidenceIds = <int>[];

      // Act
      final successCount = await useCase(evidenceIds, studentId);

      // Assert
      expect(successCount, 0);
      verifyNever(mockRepository.assignEvidenceToStudent(any, any));
    });
  });

  group('DeleteEvidencesUseCase', () {
    late DeleteEvidencesUseCase useCase;

    setUp(() {
      useCase = DeleteEvidencesUseCase(mockRepository);
    });

    test('should delete all evidences and return count', () async {
      // Arrange
      final evidenceIds = [1, 2, 3];

      when(mockRepository.deleteEvidence(any))
          .thenAnswer((_) async => Future.value());

      // Act
      final successCount = await useCase(evidenceIds);

      // Assert
      expect(successCount, 3);
      verify(mockRepository.deleteEvidence(1)).called(1);
      verify(mockRepository.deleteEvidence(2)).called(1);
      verify(mockRepository.deleteEvidence(3)).called(1);
    });

    test('should continue on error and return partial count', () async {
      // Arrange
      final evidenceIds = [1, 2, 3];

      when(mockRepository.deleteEvidence(1))
          .thenAnswer((_) async => Future.value());
      when(mockRepository.deleteEvidence(2))
          .thenThrow(Exception('Error')); // Error on 2
      when(mockRepository.deleteEvidence(3))
          .thenAnswer((_) async => Future.value());

      // Act - should not throw
      final successCount = await useCase(evidenceIds);

      // Assert
      expect(successCount, 2); // Only 1 and 3 deleted
      verify(mockRepository.deleteEvidence(1)).called(1);
      verify(mockRepository.deleteEvidence(2)).called(1);
      verify(mockRepository.deleteEvidence(3)).called(1);
    });

    test('should return 0 for empty list', () async {
      // Arrange
      final evidenceIds = <int>[];

      // Act
      final successCount = await useCase(evidenceIds);

      // Assert
      expect(successCount, 0);
      verifyNever(mockRepository.deleteEvidence(any));
    });

    test('should handle large batch of evidences', () async {
      // Arrange
      final evidenceIds = List.generate(20, (i) => i + 1);

      when(mockRepository.deleteEvidence(any))
          .thenAnswer((_) async => Future.value());

      // Act
      final successCount = await useCase(evidenceIds);

      // Assert
      expect(successCount, 20);
      for (int i = 1; i <= 20; i++) {
        verify(mockRepository.deleteEvidence(i)).called(1);
      }
    });
  });
}
