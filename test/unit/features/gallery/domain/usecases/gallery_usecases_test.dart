import 'dart:io';

import 'package:eduportfolio/core/domain/entities/evidence.dart';
import 'package:eduportfolio/core/domain/repositories/evidence_repository.dart';
import 'package:eduportfolio/features/gallery/domain/usecases/delete_evidence_usecase.dart';
import 'package:eduportfolio/features/gallery/domain/usecases/get_all_evidences_usecase.dart';
import 'package:eduportfolio/features/gallery/domain/usecases/get_evidence_by_id_usecase.dart';
import 'package:eduportfolio/features/gallery/domain/usecases/get_evidences_by_subject_usecase.dart';
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
}
