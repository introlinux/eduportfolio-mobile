import 'dart:io';

import 'package:eduportfolio/core/domain/entities/evidence.dart';
import 'package:eduportfolio/core/domain/repositories/evidence_repository.dart';
import 'package:eduportfolio/features/capture/domain/usecases/save_evidence_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'save_evidence_usecase_test.mocks.dart';

// Mock path_provider
class FakePathProviderPlatform extends PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return Directory.systemTemp.path;
  }
}

@GenerateMocks([EvidenceRepository])
void main() {
  late SaveEvidenceUseCase useCase;
  late MockEvidenceRepository mockRepository;
  late File tempImageFile;

  setUpAll(() {
    // Register fake path provider
    PathProviderPlatform.instance = FakePathProviderPlatform();
  });

  setUp(() async {
    mockRepository = MockEvidenceRepository();
    useCase = SaveEvidenceUseCase(mockRepository);

    // Create a temporary image file for testing
    tempImageFile = File('${Directory.systemTemp.path}/test_image.jpg');
    await tempImageFile.writeAsBytes([1, 2, 3, 4]); // Dummy image data
  });

  tearDown(() async {
    // Clean up temporary files
    if (await tempImageFile.exists()) {
      await tempImageFile.delete();
    }

    // Clean up any copied files in evidences directory
    final evidencesDir = Directory('${Directory.systemTemp.path}/evidences');
    if (await evidencesDir.exists()) {
      await evidencesDir.delete(recursive: true);
    }
  });

  group('SaveEvidenceUseCase', () {
    test('should copy file to permanent storage and create evidence', () async {
      // Arrange
      const subjectId = 1;
      const expectedEvidenceId = 123;

      when(mockRepository.createEvidence(any))
          .thenAnswer((_) async => expectedEvidenceId);

      // Act
      final result = await useCase(
        tempImagePath: tempImageFile.path,
        subjectId: subjectId,
      );

      // Assert
      expect(result, expectedEvidenceId);

      // Verify repository was called with correct evidence
      final captured =
          verify(mockRepository.createEvidence(captureAny)).captured.single
              as Evidence;
      expect(captured.subjectId, subjectId);
      expect(captured.type, EvidenceType.image);
      expect(captured.filePath, contains('evidences'));
      expect(captured.filePath, endsWith('.jpg'));
      expect(captured.studentId, isNull);
      expect(captured.isReviewed, isFalse);

      // Verify file was copied to permanent storage
      final copiedFile = File(captured.filePath);
      expect(await copiedFile.exists(), isTrue);
    });

    test('should include studentId if provided', () async {
      // Arrange
      const subjectId = 1;
      const studentId = 42;
      const expectedEvidenceId = 123;

      when(mockRepository.createEvidence(any))
          .thenAnswer((_) async => expectedEvidenceId);

      // Act
      await useCase(
        tempImagePath: tempImageFile.path,
        subjectId: subjectId,
        studentId: studentId,
      );

      // Assert
      // Verify repository was called with studentId
      final captured =
          verify(mockRepository.createEvidence(captureAny)).captured.single
              as Evidence;
      expect(captured.studentId, studentId);
      expect(captured.subjectId, subjectId);
    });

    test('should generate unique filenames for multiple captures', () async {
      // Arrange
      const subjectId = 1;

      when(mockRepository.createEvidence(any)).thenAnswer((_) async => 1);

      // Act
      final result1 = await useCase(
        tempImagePath: tempImageFile.path,
        subjectId: subjectId,
      );
      // Small delay to ensure different timestamps
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final result2 = await useCase(
        tempImagePath: tempImageFile.path,
        subjectId: subjectId,
      );

      // Assert
      expect(result1, 1);
      expect(result2, 1);

      // Verify different filenames were used
      final calls =
          verify(mockRepository.createEvidence(captureAny)).captured;
      final evidence1 = calls[0] as Evidence;
      final evidence2 = calls[1] as Evidence;

      expect(evidence1.filePath, isNot(equals(evidence2.filePath)));
      expect(evidence1.filePath, contains('evidence_'));
      expect(evidence2.filePath, contains('evidence_'));
    });

    test('should create evidences directory if it does not exist', () async {
      // Arrange
      const subjectId = 1;
      final evidencesDir = Directory('${Directory.systemTemp.path}/evidences');

      // Ensure directory doesn't exist
      if (await evidencesDir.exists()) {
        await evidencesDir.delete(recursive: true);
      }

      when(mockRepository.createEvidence(any)).thenAnswer((_) async => 1);

      // Act
      await useCase(
        tempImagePath: tempImageFile.path,
        subjectId: subjectId,
      );

      // Assert
      expect(await evidencesDir.exists(), isTrue);
    });

    test('should set captureDate and createdAt to current time', () async {
      // Arrange
      const subjectId = 1;
      final beforeCall = DateTime.now();

      when(mockRepository.createEvidence(any)).thenAnswer((_) async => 1);

      // Act
      await useCase(
        tempImagePath: tempImageFile.path,
        subjectId: subjectId,
      );

      final afterCall = DateTime.now();

      // Assert
      final captured =
          verify(mockRepository.createEvidence(captureAny)).captured.single
              as Evidence;

      expect(captured.captureDate.isAfter(beforeCall.subtract(const Duration(seconds: 1))),
          isTrue);
      expect(captured.captureDate.isBefore(afterCall.add(const Duration(seconds: 1))),
          isTrue);
      expect(captured.createdAt.isAfter(beforeCall.subtract(const Duration(seconds: 1))),
          isTrue);
      expect(captured.createdAt.isBefore(afterCall.add(const Duration(seconds: 1))),
          isTrue);
    });
  });
}
