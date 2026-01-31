import 'package:eduportfolio/core/domain/entities/evidence.dart';
import 'package:eduportfolio/core/domain/entities/student.dart';
import 'package:eduportfolio/core/domain/repositories/evidence_repository.dart';
import 'package:eduportfolio/core/domain/repositories/student_repository.dart';
import 'package:eduportfolio/features/settings/domain/usecases/delete_all_evidences_usecase.dart';
import 'package:eduportfolio/features/settings/domain/usecases/delete_all_students_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'settings_usecases_test.mocks.dart';

@GenerateMocks([EvidenceRepository, StudentRepository])
void main() {
  late MockEvidenceRepository mockEvidenceRepository;
  late MockStudentRepository mockStudentRepository;

  setUp(() {
    mockEvidenceRepository = MockEvidenceRepository();
    mockStudentRepository = MockStudentRepository();
  });

  group('DeleteAllEvidencesUseCase', () {
    late DeleteAllEvidencesUseCase useCase;

    setUp(() {
      useCase = DeleteAllEvidencesUseCase(mockEvidenceRepository);
    });

    test('should delete all evidences and return count', () async {
      // Arrange
      final now = DateTime.now();
      final evidences = [
        Evidence(
          id: 1,
          studentId: 1,
          subjectId: 1,
          type: EvidenceType.image,
          filePath: '/test/evidence1.jpg',
          captureDate: now,
          createdAt: now,
        ),
        Evidence(
          id: 2,
          studentId: 1,
          subjectId: 1,
          type: EvidenceType.image,
          filePath: '/test/evidence2.jpg',
          captureDate: now,
          createdAt: now,
        ),
        Evidence(
          id: 3,
          studentId: 2,
          subjectId: 2,
          type: EvidenceType.video,
          filePath: '/test/evidence3.mp4',
          thumbnailPath: '/test/thumb3.jpg',
          captureDate: now,
          createdAt: now,
        ),
      ];

      when(mockEvidenceRepository.getAllEvidences())
          .thenAnswer((_) async => evidences);

      when(mockEvidenceRepository.deleteEvidence(any))
          .thenAnswer((_) async => Future.value());

      // Act
      final deletedCount = await useCase();

      // Assert
      expect(deletedCount, 3);
      verify(mockEvidenceRepository.getAllEvidences()).called(1);
      verify(mockEvidenceRepository.deleteEvidence(1)).called(1);
      verify(mockEvidenceRepository.deleteEvidence(2)).called(1);
      verify(mockEvidenceRepository.deleteEvidence(3)).called(1);
    });

    test('should return 0 when no evidences exist', () async {
      // Arrange
      when(mockEvidenceRepository.getAllEvidences())
          .thenAnswer((_) async => []);

      // Act
      final deletedCount = await useCase();

      // Assert
      expect(deletedCount, 0);
      verify(mockEvidenceRepository.getAllEvidences()).called(1);
      verifyNever(mockEvidenceRepository.deleteEvidence(any));
    });

    test('should continue on error and return partial count', () async {
      // Arrange
      final now = DateTime.now();
      final evidences = [
        Evidence(
          id: 1,
          studentId: 1,
          subjectId: 1,
          type: EvidenceType.image,
          filePath: '/test/evidence1.jpg',
          captureDate: now,
          createdAt: now,
        ),
        Evidence(
          id: 2,
          studentId: 1,
          subjectId: 1,
          type: EvidenceType.image,
          filePath: '/test/evidence2.jpg',
          captureDate: now,
          createdAt: now,
        ),
        Evidence(
          id: 3,
          studentId: 2,
          subjectId: 2,
          type: EvidenceType.image,
          filePath: '/test/evidence3.jpg',
          captureDate: now,
          createdAt: now,
        ),
      ];

      when(mockEvidenceRepository.getAllEvidences())
          .thenAnswer((_) async => evidences);

      // Evidence 2 will fail
      when(mockEvidenceRepository.deleteEvidence(1))
          .thenAnswer((_) async => Future.value());
      when(mockEvidenceRepository.deleteEvidence(2))
          .thenThrow(Exception('Delete failed'));
      when(mockEvidenceRepository.deleteEvidence(3))
          .thenAnswer((_) async => Future.value());

      // Act - should not throw
      final deletedCount = await useCase();

      // Assert - only 1 and 3 were deleted
      expect(deletedCount, 2);
      verify(mockEvidenceRepository.deleteEvidence(1)).called(1);
      verify(mockEvidenceRepository.deleteEvidence(2)).called(1);
      verify(mockEvidenceRepository.deleteEvidence(3)).called(1);
    });

    test('should handle evidences with thumbnails', () async {
      // Arrange
      final now = DateTime.now();
      final evidence = Evidence(
        id: 1,
        studentId: 1,
        subjectId: 1,
        type: EvidenceType.video,
        filePath: '/test/video.mp4',
        thumbnailPath: '/test/thumb.jpg',
        captureDate: now,
        createdAt: now,
      );

      when(mockEvidenceRepository.getAllEvidences())
          .thenAnswer((_) async => [evidence]);

      when(mockEvidenceRepository.deleteEvidence(1))
          .thenAnswer((_) async => Future.value());

      // Act
      final deletedCount = await useCase();

      // Assert
      expect(deletedCount, 1);
      verify(mockEvidenceRepository.deleteEvidence(1)).called(1);
    });

    test('should handle large number of evidences', () async {
      // Arrange
      final now = DateTime.now();
      final evidences = List.generate(
        100,
        (i) => Evidence(
          id: i + 1,
          studentId: 1,
          subjectId: 1,
          type: EvidenceType.image,
          filePath: '/test/evidence${i + 1}.jpg',
          captureDate: now,
          createdAt: now,
        ),
      );

      when(mockEvidenceRepository.getAllEvidences())
          .thenAnswer((_) async => evidences);

      when(mockEvidenceRepository.deleteEvidence(any))
          .thenAnswer((_) async => Future.value());

      // Act
      final deletedCount = await useCase();

      // Assert
      expect(deletedCount, 100);
      verify(mockEvidenceRepository.getAllEvidences()).called(1);
      // Verify all evidences were deleted
      for (int i = 1; i <= 100; i++) {
        verify(mockEvidenceRepository.deleteEvidence(i)).called(1);
      }
    });
  });

  group('DeleteAllStudentsUseCase', () {
    late DeleteAllStudentsUseCase useCase;

    setUp(() {
      useCase = DeleteAllStudentsUseCase(mockStudentRepository);
    });

    test('should delete all students and return count', () async {
      // Arrange
      final now = DateTime.now();
      final students = [
        Student(
          id: 1,
          courseId: 1,
          name: 'Student 1',
          createdAt: now,
          updatedAt: now,
        ),
        Student(
          id: 2,
          courseId: 1,
          name: 'Student 2',
          createdAt: now,
          updatedAt: now,
        ),
        Student(
          id: 3,
          courseId: 2,
          name: 'Student 3',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      when(mockStudentRepository.getAllStudents())
          .thenAnswer((_) async => students);

      when(mockStudentRepository.deleteStudent(any))
          .thenAnswer((_) async => Future.value());

      // Act
      final deletedCount = await useCase();

      // Assert
      expect(deletedCount, 3);
      verify(mockStudentRepository.getAllStudents()).called(1);
      verify(mockStudentRepository.deleteStudent(1)).called(1);
      verify(mockStudentRepository.deleteStudent(2)).called(1);
      verify(mockStudentRepository.deleteStudent(3)).called(1);
    });

    test('should return 0 when no students exist', () async {
      // Arrange
      when(mockStudentRepository.getAllStudents())
          .thenAnswer((_) async => []);

      // Act
      final deletedCount = await useCase();

      // Assert
      expect(deletedCount, 0);
      verify(mockStudentRepository.getAllStudents()).called(1);
      verifyNever(mockStudentRepository.deleteStudent(any));
    });

    test('should continue on error and return partial count', () async {
      // Arrange
      final now = DateTime.now();
      final students = [
        Student(
          id: 1,
          courseId: 1,
          name: 'Student 1',
          createdAt: now,
          updatedAt: now,
        ),
        Student(
          id: 2,
          courseId: 1,
          name: 'Student 2',
          createdAt: now,
          updatedAt: now,
        ),
        Student(
          id: 3,
          courseId: 2,
          name: 'Student 3',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      when(mockStudentRepository.getAllStudents())
          .thenAnswer((_) async => students);

      // Student 2 will fail
      when(mockStudentRepository.deleteStudent(1))
          .thenAnswer((_) async => Future.value());
      when(mockStudentRepository.deleteStudent(2))
          .thenThrow(Exception('Delete failed'));
      when(mockStudentRepository.deleteStudent(3))
          .thenAnswer((_) async => Future.value());

      // Act - should not throw
      final deletedCount = await useCase();

      // Assert - only 1 and 3 were deleted
      expect(deletedCount, 2);
      verify(mockStudentRepository.deleteStudent(1)).called(1);
      verify(mockStudentRepository.deleteStudent(2)).called(1);
      verify(mockStudentRepository.deleteStudent(3)).called(1);
    });

    test('should delete students with face embeddings', () async {
      // Arrange
      final now = DateTime.now();
      final student = Student(
        id: 1,
        courseId: 1,
        name: 'Student with Face',
        faceEmbeddings: null, // Face embeddings are stored as Uint8List in model
        createdAt: now,
        updatedAt: now,
      );

      when(mockStudentRepository.getAllStudents())
          .thenAnswer((_) async => [student]);

      when(mockStudentRepository.deleteStudent(1))
          .thenAnswer((_) async => Future.value());

      // Act
      final deletedCount = await useCase();

      // Assert
      expect(deletedCount, 1);
      verify(mockStudentRepository.deleteStudent(1)).called(1);
    });

    test('should handle large number of students', () async {
      // Arrange
      final now = DateTime.now();
      final students = List.generate(
        50,
        (i) => Student(
          id: i + 1,
          courseId: 1,
          name: 'Student ${i + 1}',
          createdAt: now,
          updatedAt: now,
        ),
      );

      when(mockStudentRepository.getAllStudents())
          .thenAnswer((_) async => students);

      when(mockStudentRepository.deleteStudent(any))
          .thenAnswer((_) async => Future.value());

      // Act
      final deletedCount = await useCase();

      // Assert
      expect(deletedCount, 50);
      verify(mockStudentRepository.getAllStudents()).called(1);
      // Verify all students were deleted
      for (int i = 1; i <= 50; i++) {
        verify(mockStudentRepository.deleteStudent(i)).called(1);
      }
    });
  });
}
