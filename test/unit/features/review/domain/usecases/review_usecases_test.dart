import 'package:eduportfolio/core/domain/entities/evidence.dart';
import 'package:eduportfolio/core/domain/repositories/evidence_repository.dart';
import 'package:eduportfolio/features/review/domain/usecases/assign_evidence_to_student_usecase.dart';
import 'package:eduportfolio/features/review/domain/usecases/assign_multiple_evidences_usecase.dart';
import 'package:eduportfolio/features/review/domain/usecases/delete_evidence_usecase.dart';
import 'package:eduportfolio/features/review/domain/usecases/delete_multiple_evidences_usecase.dart';
import 'package:eduportfolio/features/review/domain/usecases/get_unassigned_evidences_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'review_usecases_test.mocks.dart';

@GenerateMocks([EvidenceRepository])
void main() {
  late MockEvidenceRepository mockRepository;

  setUp(() {
    mockRepository = MockEvidenceRepository();
  });

  group('GetUnassignedEvidencesUseCase', () {
    late GetUnassignedEvidencesUseCase useCase;

    setUp(() {
      useCase = GetUnassignedEvidencesUseCase(mockRepository);
    });

    test('should return all unassigned evidences ordered by capture date DESC',
        () async {
      // Arrange
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final twoDaysAgo = now.subtract(const Duration(days: 2));

      final evidence1 = Evidence(
        id: 1,
        studentId: null, // Unassigned
        subjectId: 1,
        type: EvidenceType.image,
        filePath: '/path/evidence1.jpg',
        captureDate: twoDaysAgo,
        createdAt: twoDaysAgo,
      );

      final evidence2 = Evidence(
        id: 2,
        studentId: null, // Unassigned
        subjectId: 1,
        type: EvidenceType.image,
        filePath: '/path/evidence2.jpg',
        captureDate: yesterday,
        createdAt: yesterday,
      );

      final evidence3 = Evidence(
        id: 3,
        studentId: null, // Unassigned
        subjectId: 1,
        type: EvidenceType.image,
        filePath: '/path/evidence3.jpg',
        captureDate: now,
        createdAt: now,
      );

      final evidence4 = Evidence(
        id: 4,
        studentId: 1, // Assigned - should be filtered out
        subjectId: 1,
        type: EvidenceType.image,
        filePath: '/path/evidence4.jpg',
        captureDate: now,
        createdAt: now,
      );

      when(mockRepository.getAllEvidences()).thenAnswer(
        (_) async => [evidence1, evidence2, evidence3, evidence4],
      );

      // Act
      final result = await useCase();

      // Assert
      expect(result.length, 3); // Only unassigned evidences
      expect(result[0].id, 3); // Most recent first
      expect(result[1].id, 2);
      expect(result[2].id, 1);
      verify(mockRepository.getAllEvidences()).called(1);
    });

    test('should filter by subject when subjectId is provided', () async {
      // Arrange
      final now = DateTime.now();

      final evidence1 = Evidence(
        id: 1,
        studentId: null,
        subjectId: 1, // Math
        type: EvidenceType.image,
        filePath: '/path/math.jpg',
        captureDate: now,
        createdAt: now,
      );

      final evidence2 = Evidence(
        id: 2,
        studentId: null,
        subjectId: 2, // Language - should be filtered out
        type: EvidenceType.image,
        filePath: '/path/language.jpg',
        captureDate: now,
        createdAt: now,
      );

      final evidence3 = Evidence(
        id: 3,
        studentId: null,
        subjectId: 1, // Math
        type: EvidenceType.image,
        filePath: '/path/math2.jpg',
        captureDate: now,
        createdAt: now,
      );

      when(mockRepository.getAllEvidences()).thenAnswer(
        (_) async => [evidence1, evidence2, evidence3],
      );

      // Act
      final result = await useCase(subjectId: 1);

      // Assert
      expect(result.length, 2); // Only Math evidences
      expect(result[0].subjectId, 1);
      expect(result[1].subjectId, 1);
      verify(mockRepository.getAllEvidences()).called(1);
    });

    test('should return empty list when no unassigned evidences exist',
        () async {
      // Arrange
      final now = DateTime.now();

      final evidence1 = Evidence(
        id: 1,
        studentId: 1, // All evidences are assigned
        subjectId: 1,
        type: EvidenceType.image,
        filePath: '/path/evidence1.jpg',
        captureDate: now,
        createdAt: now,
      );

      when(mockRepository.getAllEvidences()).thenAnswer(
        (_) async => [evidence1],
      );

      // Act
      final result = await useCase();

      // Assert
      expect(result, isEmpty);
    });

    test('should return empty list when getAllEvidences returns empty',
        () async {
      // Arrange
      when(mockRepository.getAllEvidences()).thenAnswer((_) async => []);

      // Act
      final result = await useCase();

      // Assert
      expect(result, isEmpty);
    });
  });

  group('AssignEvidenceToStudentUseCase', () {
    late AssignEvidenceToStudentUseCase useCase;

    setUp(() {
      useCase = AssignEvidenceToStudentUseCase(mockRepository);
    });

    test('should assign evidence to student and mark as reviewed', () async {
      // Arrange
      const evidenceId = 1;
      const studentId = 10;

      final originalEvidence = Evidence(
        id: evidenceId,
        studentId: null, // Unassigned
        subjectId: 1,
        type: EvidenceType.image,
        filePath: '/path/evidence.jpg',
        captureDate: DateTime.now(),
        isReviewed: false,
        createdAt: DateTime.now(),
      );

      when(mockRepository.getEvidenceById(evidenceId))
          .thenAnswer((_) async => originalEvidence);

      when(mockRepository.updateEvidence(any))
          .thenAnswer((_) async => Future.value());

      // Act
      await useCase(evidenceId: evidenceId, studentId: studentId);

      // Assert
      verify(mockRepository.getEvidenceById(evidenceId)).called(1);

      // Verify the update was called with correct values
      final captured = verify(mockRepository.updateEvidence(captureAny))
          .captured
          .single as Evidence;

      expect(captured.id, evidenceId);
      expect(captured.studentId, studentId);
      expect(captured.isReviewed, isTrue); // CRITICAL: Must be marked as reviewed
    });

    test('should throw exception when evidence not found', () async {
      // Arrange
      const evidenceId = 999;
      const studentId = 10;

      when(mockRepository.getEvidenceById(evidenceId))
          .thenAnswer((_) async => null);

      // Act & Assert
      expect(
        () => useCase(evidenceId: evidenceId, studentId: studentId),
        throwsException,
      );

      verify(mockRepository.getEvidenceById(evidenceId)).called(1);
      verifyNever(mockRepository.updateEvidence(any));
    });

    test('should preserve other evidence fields when updating', () async {
      // Arrange
      const evidenceId = 1;
      const studentId = 10;

      final originalEvidence = Evidence(
        id: evidenceId,
        studentId: null,
        subjectId: 2,
        type: EvidenceType.video,
        filePath: '/path/video.mp4',
        thumbnailPath: '/path/thumb.jpg',
        fileSize: 1024000,
        duration: 120,
        captureDate: DateTime(2024, 1, 15),
        isReviewed: false,
        notes: 'Test notes',
        createdAt: DateTime(2024, 1, 15),
      );

      when(mockRepository.getEvidenceById(evidenceId))
          .thenAnswer((_) async => originalEvidence);

      when(mockRepository.updateEvidence(any))
          .thenAnswer((_) async => Future.value());

      // Act
      await useCase(evidenceId: evidenceId, studentId: studentId);

      // Assert
      final captured = verify(mockRepository.updateEvidence(captureAny))
          .captured
          .single as Evidence;

      // Verify all fields are preserved except studentId and isReviewed
      expect(captured.id, evidenceId);
      expect(captured.studentId, studentId); // Updated
      expect(captured.isReviewed, isTrue); // Updated
      expect(captured.subjectId, 2); // Preserved
      expect(captured.type, EvidenceType.video); // Preserved
      expect(captured.filePath, '/path/video.mp4'); // Preserved
      expect(captured.thumbnailPath, '/path/thumb.jpg'); // Preserved
      expect(captured.fileSize, 1024000); // Preserved
      expect(captured.duration, 120); // Preserved
      expect(captured.notes, 'Test notes'); // Preserved
    });
  });

  group('AssignMultipleEvidencesUseCase', () {
    late AssignMultipleEvidencesUseCase useCase;

    setUp(() {
      useCase = AssignMultipleEvidencesUseCase(mockRepository);
    });

    test('should assign all evidences to student and mark as reviewed',
        () async {
      // Arrange
      const studentId = 10;
      final evidenceIds = [1, 2, 3];

      final evidence1 = Evidence(
        id: 1,
        studentId: null,
        subjectId: 1,
        type: EvidenceType.image,
        filePath: '/path/1.jpg',
        captureDate: DateTime.now(),
        createdAt: DateTime.now(),
      );

      final evidence2 = Evidence(
        id: 2,
        studentId: null,
        subjectId: 1,
        type: EvidenceType.image,
        filePath: '/path/2.jpg',
        captureDate: DateTime.now(),
        createdAt: DateTime.now(),
      );

      final evidence3 = Evidence(
        id: 3,
        studentId: null,
        subjectId: 1,
        type: EvidenceType.image,
        filePath: '/path/3.jpg',
        captureDate: DateTime.now(),
        createdAt: DateTime.now(),
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
      await useCase(evidenceIds: evidenceIds, studentId: studentId);

      // Assert
      verify(mockRepository.getEvidenceById(1)).called(1);
      verify(mockRepository.getEvidenceById(2)).called(1);
      verify(mockRepository.getEvidenceById(3)).called(1);
      verify(mockRepository.updateEvidence(any)).called(3);
    });

    test('should skip missing evidences and continue with others', () async {
      // Arrange
      const studentId = 10;
      final evidenceIds = [1, 999, 3]; // 999 doesn't exist

      final evidence1 = Evidence(
        id: 1,
        studentId: null,
        subjectId: 1,
        type: EvidenceType.image,
        filePath: '/path/1.jpg',
        captureDate: DateTime.now(),
        createdAt: DateTime.now(),
      );

      final evidence3 = Evidence(
        id: 3,
        studentId: null,
        subjectId: 1,
        type: EvidenceType.image,
        filePath: '/path/3.jpg',
        captureDate: DateTime.now(),
        createdAt: DateTime.now(),
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
      await useCase(evidenceIds: evidenceIds, studentId: studentId);

      // Assert
      verify(mockRepository.getEvidenceById(1)).called(1);
      verify(mockRepository.getEvidenceById(999)).called(1);
      verify(mockRepository.getEvidenceById(3)).called(1);
      verify(mockRepository.updateEvidence(any))
          .called(2); // Only 2 updates (1 and 3)
    });

    test('should return early when evidenceIds list is empty', () async {
      // Arrange
      const studentId = 10;
      final evidenceIds = <int>[];

      // Act
      await useCase(evidenceIds: evidenceIds, studentId: studentId);

      // Assert
      verifyNever(mockRepository.getEvidenceById(any));
      verifyNever(mockRepository.updateEvidence(any));
    });

    test('should continue on error and process remaining evidences', () async {
      // Arrange
      const studentId = 10;
      final evidenceIds = [1, 2, 3];

      final evidence1 = Evidence(
        id: 1,
        studentId: null,
        subjectId: 1,
        type: EvidenceType.image,
        filePath: '/path/1.jpg',
        captureDate: DateTime.now(),
        createdAt: DateTime.now(),
      );

      final evidence3 = Evidence(
        id: 3,
        studentId: null,
        subjectId: 1,
        type: EvidenceType.image,
        filePath: '/path/3.jpg',
        captureDate: DateTime.now(),
        createdAt: DateTime.now(),
      );

      when(mockRepository.getEvidenceById(1))
          .thenAnswer((_) async => evidence1);
      when(mockRepository.getEvidenceById(2))
          .thenThrow(Exception('Database error')); // Error on 2
      when(mockRepository.getEvidenceById(3))
          .thenAnswer((_) async => evidence3);

      when(mockRepository.updateEvidence(any))
          .thenAnswer((_) async => Future.value());

      // Act - should not throw
      await useCase(evidenceIds: evidenceIds, studentId: studentId);

      // Assert - should have processed 1 and 3
      verify(mockRepository.getEvidenceById(1)).called(1);
      verify(mockRepository.getEvidenceById(2)).called(1);
      verify(mockRepository.getEvidenceById(3)).called(1);
      verify(mockRepository.updateEvidence(any))
          .called(2); // Only 1 and 3 updated
    });
  });

  group('DeleteEvidenceUseCase', () {
    late DeleteEvidenceUseCase useCase;

    setUp(() {
      useCase = DeleteEvidenceUseCase(mockRepository);
    });

    test('should delete evidence from repository', () async {
      // Arrange
      const evidenceId = 1;

      final evidence = Evidence(
        id: evidenceId,
        studentId: 1,
        subjectId: 1,
        type: EvidenceType.image,
        filePath: '/test/path/image.jpg', // Non-existent file is ok for test
        captureDate: DateTime.now(),
        createdAt: DateTime.now(),
      );

      when(mockRepository.getEvidenceById(evidenceId))
          .thenAnswer((_) async => evidence);
      when(mockRepository.deleteEvidence(evidenceId))
          .thenAnswer((_) async => Future.value());

      // Act
      await useCase(evidenceId);

      // Assert
      verify(mockRepository.getEvidenceById(evidenceId)).called(1);
      verify(mockRepository.deleteEvidence(evidenceId)).called(1);
    });

    test('should throw exception when evidence not found', () async {
      // Arrange
      const evidenceId = 999;

      when(mockRepository.getEvidenceById(evidenceId))
          .thenAnswer((_) async => null);

      // Act & Assert
      expect(
        () => useCase(evidenceId),
        throwsException,
      );

      verify(mockRepository.getEvidenceById(evidenceId)).called(1);
      verifyNever(mockRepository.deleteEvidence(any));
    });

    test('should delete evidence even if file deletion fails', () async {
      // Arrange
      const evidenceId = 1;

      final evidence = Evidence(
        id: evidenceId,
        studentId: 1,
        subjectId: 1,
        type: EvidenceType.image,
        filePath: '/non/existent/path.jpg',
        captureDate: DateTime.now(),
        createdAt: DateTime.now(),
      );

      when(mockRepository.getEvidenceById(evidenceId))
          .thenAnswer((_) async => evidence);
      when(mockRepository.deleteEvidence(evidenceId))
          .thenAnswer((_) async => Future.value());

      // Act - should not throw even if file doesn't exist
      await useCase(evidenceId);

      // Assert - database deletion should still happen
      verify(mockRepository.deleteEvidence(evidenceId)).called(1);
    });
  });

  group('DeleteMultipleEvidencesUseCase', () {
    late DeleteMultipleEvidencesUseCase useCase;

    setUp(() {
      useCase = DeleteMultipleEvidencesUseCase(mockRepository);
    });

    test('should delete all evidences and return count', () async {
      // Arrange
      final evidenceIds = [1, 2, 3];

      final evidence1 = Evidence(
        id: 1,
        studentId: 1,
        subjectId: 1,
        type: EvidenceType.image,
        filePath: '/test/1.jpg',
        captureDate: DateTime.now(),
        createdAt: DateTime.now(),
      );

      final evidence2 = Evidence(
        id: 2,
        studentId: 1,
        subjectId: 1,
        type: EvidenceType.image,
        filePath: '/test/2.jpg',
        captureDate: DateTime.now(),
        createdAt: DateTime.now(),
      );

      final evidence3 = Evidence(
        id: 3,
        studentId: 1,
        subjectId: 1,
        type: EvidenceType.image,
        filePath: '/test/3.jpg',
        captureDate: DateTime.now(),
        createdAt: DateTime.now(),
      );

      when(mockRepository.getEvidenceById(1))
          .thenAnswer((_) async => evidence1);
      when(mockRepository.getEvidenceById(2))
          .thenAnswer((_) async => evidence2);
      when(mockRepository.getEvidenceById(3))
          .thenAnswer((_) async => evidence3);

      when(mockRepository.deleteEvidence(any))
          .thenAnswer((_) async => Future.value());

      // Act
      final deletedCount = await useCase(evidenceIds);

      // Assert
      expect(deletedCount, 3);
      verify(mockRepository.deleteEvidence(1)).called(1);
      verify(mockRepository.deleteEvidence(2)).called(1);
      verify(mockRepository.deleteEvidence(3)).called(1);
    });

    test('should skip missing evidences and return correct count', () async {
      // Arrange
      final evidenceIds = [1, 999, 3]; // 999 doesn't exist

      final evidence1 = Evidence(
        id: 1,
        studentId: 1,
        subjectId: 1,
        type: EvidenceType.image,
        filePath: '/test/1.jpg',
        captureDate: DateTime.now(),
        createdAt: DateTime.now(),
      );

      final evidence3 = Evidence(
        id: 3,
        studentId: 1,
        subjectId: 1,
        type: EvidenceType.image,
        filePath: '/test/3.jpg',
        captureDate: DateTime.now(),
        createdAt: DateTime.now(),
      );

      when(mockRepository.getEvidenceById(1))
          .thenAnswer((_) async => evidence1);
      when(mockRepository.getEvidenceById(999))
          .thenAnswer((_) async => null); // Missing
      when(mockRepository.getEvidenceById(3))
          .thenAnswer((_) async => evidence3);

      when(mockRepository.deleteEvidence(any))
          .thenAnswer((_) async => Future.value());

      // Act
      final deletedCount = await useCase(evidenceIds);

      // Assert
      expect(deletedCount, 2); // Only 1 and 3 deleted
      verify(mockRepository.deleteEvidence(1)).called(1);
      verifyNever(mockRepository.deleteEvidence(999));
      verify(mockRepository.deleteEvidence(3)).called(1);
    });

    test('should return 0 when evidenceIds list is empty', () async {
      // Arrange
      final evidenceIds = <int>[];

      // Act
      final deletedCount = await useCase(evidenceIds);

      // Assert
      expect(deletedCount, 0);
      verifyNever(mockRepository.getEvidenceById(any));
      verifyNever(mockRepository.deleteEvidence(any));
    });

    test('should continue on error and return partial count', () async {
      // Arrange
      final evidenceIds = [1, 2, 3];

      final evidence1 = Evidence(
        id: 1,
        studentId: 1,
        subjectId: 1,
        type: EvidenceType.image,
        filePath: '/test/1.jpg',
        captureDate: DateTime.now(),
        createdAt: DateTime.now(),
      );

      final evidence3 = Evidence(
        id: 3,
        studentId: 1,
        subjectId: 1,
        type: EvidenceType.image,
        filePath: '/test/3.jpg',
        captureDate: DateTime.now(),
        createdAt: DateTime.now(),
      );

      when(mockRepository.getEvidenceById(1))
          .thenAnswer((_) async => evidence1);
      when(mockRepository.getEvidenceById(2))
          .thenThrow(Exception('Error')); // Error on 2
      when(mockRepository.getEvidenceById(3))
          .thenAnswer((_) async => evidence3);

      when(mockRepository.deleteEvidence(any))
          .thenAnswer((_) async => Future.value());

      // Act - should not throw
      final deletedCount = await useCase(evidenceIds);

      // Assert
      expect(deletedCount, 2); // Only 1 and 3 deleted
      verify(mockRepository.deleteEvidence(1)).called(1);
      verifyNever(mockRepository.deleteEvidence(2)); // Never reached delete
      verify(mockRepository.deleteEvidence(3)).called(1);
    });
  });
}
