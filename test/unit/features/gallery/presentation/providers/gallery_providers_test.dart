import 'package:eduportfolio/core/domain/entities/evidence.dart';
import 'package:eduportfolio/features/courses/presentation/providers/course_providers.dart';
import 'package:eduportfolio/features/gallery/domain/usecases/get_all_evidences_usecase.dart';
import 'package:eduportfolio/features/gallery/domain/usecases/get_evidence_by_id_usecase.dart';
import 'package:eduportfolio/features/gallery/presentation/providers/gallery_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'gallery_providers_test.mocks.dart';

@GenerateMocks([GetAllEvidencesUseCase, GetEvidenceByIdUseCase])
void main() {
  late MockGetAllEvidencesUseCase mockGetAllEvidencesUseCase;
  late MockGetEvidenceByIdUseCase mockGetEvidenceByIdUseCase;

  setUp(() {
    mockGetAllEvidencesUseCase = MockGetAllEvidencesUseCase();
    mockGetEvidenceByIdUseCase = MockGetEvidenceByIdUseCase();
  });

  // Helper to create test evidences
  List<Evidence> createTestEvidences() {
    final now = DateTime(2024, 1, 15);
    return [
      // Subject 1, Student 1, Reviewed
      Evidence(
        id: 1,
        subjectId: 1,
        studentId: 1,
        type: EvidenceType.image,
        filePath: '/test/1.jpg',
        isReviewed: true,
        captureDate: now.subtract(const Duration(days: 5)),
        createdAt: now,
      ),
      // Subject 1, Student 2, Pending
      Evidence(
        id: 2,
        subjectId: 1,
        studentId: 2,
        type: EvidenceType.image,
        filePath: '/test/2.jpg',
        isReviewed: false,
        captureDate: now.subtract(const Duration(days: 4)),
        createdAt: now,
      ),
      // Subject 2, Student 1, Reviewed
      Evidence(
        id: 3,
        subjectId: 2,
        studentId: 1,
        type: EvidenceType.image,
        filePath: '/test/3.jpg',
        isReviewed: true,
        captureDate: now.subtract(const Duration(days: 3)),
        createdAt: now,
      ),
      // Subject 2, Student 2, Pending
      Evidence(
        id: 4,
        subjectId: 2,
        studentId: 2,
        type: EvidenceType.image,
        filePath: '/test/4.jpg',
        isReviewed: false,
        captureDate: now.subtract(const Duration(days: 2)),
        createdAt: now,
      ),
      // Subject 1, No student (unassigned), Pending
      Evidence(
        id: 5,
        subjectId: 1,
        studentId: null,
        type: EvidenceType.image,
        filePath: '/test/5.jpg',
        isReviewed: false,
        captureDate: now.subtract(const Duration(days: 1)),
        createdAt: now,
      ),
      // Subject 2, No student (unassigned), Pending - Most recent
      Evidence(
        id: 6,
        subjectId: 2,
        studentId: null,
        type: EvidenceType.image,
        filePath: '/test/6.jpg',
        isReviewed: false,
        captureDate: now,
        createdAt: now,
      ),
    ];
  }

  group('State Providers', () {
    test('selectedSubjectFilterProvider should default to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final selectedSubject = container.read(selectedSubjectFilterProvider);
      expect(selectedSubject, isNull);
    });

    test('selectedSubjectFilterProvider should update value', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedSubjectFilterProvider.notifier).state = 1;
      final selectedSubject = container.read(selectedSubjectFilterProvider);
      expect(selectedSubject, 1);
    });

    test('selectedStudentFilterProvider should default to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final selectedStudent = container.read(selectedStudentFilterProvider);
      expect(selectedStudent, isNull);
    });

    test('selectedStudentFilterProvider should update value', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedStudentFilterProvider.notifier).state = 2;
      final selectedStudent = container.read(selectedStudentFilterProvider);
      expect(selectedStudent, 2);
    });

    test('reviewStatusFilterProvider should default to all', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final reviewStatus = container.read(reviewStatusFilterProvider);
      expect(reviewStatus, ReviewStatusFilter.all);
    });

    test('reviewStatusFilterProvider should update value', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(reviewStatusFilterProvider.notifier).state =
          ReviewStatusFilter.pending;
      final reviewStatus = container.read(reviewStatusFilterProvider);
      expect(reviewStatus, ReviewStatusFilter.pending);
    });
  });

  group('filteredEvidencesProvider - No filters', () {
    test('should return all evidences ordered by capture date DESC', () async {
      // Arrange
      final evidences = createTestEvidences();
      when(mockGetAllEvidencesUseCase.call())
          .thenAnswer((_) async => evidences);

      final container = ProviderContainer(
        overrides: [
          getAllEvidencesUseCaseProvider
              .overrideWithValue(mockGetAllEvidencesUseCase),
          // Mock activeCourseProvider to return null (no active course filter)
          activeCourseProvider.overrideWith((ref) => null),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final result = await container.read(filteredEvidencesProvider.future);

      // Assert
      expect(result.length, 6);
      // Should be ordered by captureDate DESC (most recent first)
      expect(result[0].id, 6); // Most recent
      expect(result[1].id, 5);
      expect(result[2].id, 4);
      expect(result[3].id, 3);
      expect(result[4].id, 2);
      expect(result[5].id, 1); // Oldest
    });

    test('should return empty list when no evidences', () async {
      // Arrange
      when(mockGetAllEvidencesUseCase.call()).thenAnswer((_) async => []);

      final container = ProviderContainer(
        overrides: [
          getAllEvidencesUseCaseProvider
              .overrideWithValue(mockGetAllEvidencesUseCase),
          // Mock activeCourseProvider to return null (no active course filter)
          activeCourseProvider.overrideWith((ref) => null),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final result = await container.read(filteredEvidencesProvider.future);

      // Assert
      expect(result, isEmpty);
    });
  });

  group('filteredEvidencesProvider - Subject filter', () {
    test('should filter by subject ID', () async {
      // Arrange
      final evidences = createTestEvidences();
      when(mockGetAllEvidencesUseCase.call())
          .thenAnswer((_) async => evidences);

      final container = ProviderContainer(
        overrides: [
          getAllEvidencesUseCaseProvider
              .overrideWithValue(mockGetAllEvidencesUseCase),
          selectedSubjectFilterProvider.overrideWith((ref) => 1),
          // Mock activeCourseProvider to return null
          activeCourseProvider.overrideWith((ref) => null),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final result = await container.read(filteredEvidencesProvider.future);

      // Assert
      expect(result.length, 3);
      expect(result.every((e) => e.subjectId == 1), isTrue);
      // Should still be ordered by captureDate DESC
      expect(result[0].id, 5);
      expect(result[1].id, 2);
      expect(result[2].id, 1);
    });

    test('should return empty when subject has no evidences', () async {
      // Arrange
      final evidences = createTestEvidences();
      when(mockGetAllEvidencesUseCase.call())
          .thenAnswer((_) async => evidences);

      final container = ProviderContainer(
        overrides: [
          getAllEvidencesUseCaseProvider
              .overrideWithValue(mockGetAllEvidencesUseCase),
          selectedSubjectFilterProvider.overrideWith((ref) => 999),
          // Mock activeCourseProvider to return null
          activeCourseProvider.overrideWith((ref) => null),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final result = await container.read(filteredEvidencesProvider.future);

      // Assert
      expect(result, isEmpty);
    });
  });

  group('filteredEvidencesProvider - Student filter', () {
    test('should filter by student ID', () async {
      // Arrange
      final evidences = createTestEvidences();
      when(mockGetAllEvidencesUseCase.call())
          .thenAnswer((_) async => evidences);

      final container = ProviderContainer(
        overrides: [
          getAllEvidencesUseCaseProvider
              .overrideWithValue(mockGetAllEvidencesUseCase),
          selectedStudentFilterProvider.overrideWith((ref) => 1),
          // Mock activeCourseProvider to return null
          activeCourseProvider.overrideWith((ref) => null),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final result = await container.read(filteredEvidencesProvider.future);

      // Assert
      expect(result.length, 2);
      expect(result.every((e) => e.studentId == 1), isTrue);
      expect(result[0].id, 3); // More recent
      expect(result[1].id, 1);
    });

    test('should include unassigned evidences when filtering by null student',
        () async {
      // Arrange
      final evidences = createTestEvidences();
      when(mockGetAllEvidencesUseCase.call())
          .thenAnswer((_) async => evidences);

      // Note: This test shows current behavior - if we want to filter
      // by "unassigned only", we'd need a special filter value

      final container = ProviderContainer(
        overrides: [
          getAllEvidencesUseCaseProvider
              .overrideWithValue(mockGetAllEvidencesUseCase),
          // null means "show all students"
          // Mock activeCourseProvider to return null
          activeCourseProvider.overrideWith((ref) => null),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final result = await container.read(filteredEvidencesProvider.future);

      // Assert
      expect(result.length, 6); // All evidences
    });
  });

  group('filteredEvidencesProvider - Review status filter', () {
    test('should filter by pending status', () async {
      // Arrange
      final evidences = createTestEvidences();
      when(mockGetAllEvidencesUseCase.call())
          .thenAnswer((_) async => evidences);

      final container = ProviderContainer(
        overrides: [
          getAllEvidencesUseCaseProvider
              .overrideWithValue(mockGetAllEvidencesUseCase),
          reviewStatusFilterProvider
              .overrideWith((ref) => ReviewStatusFilter.pending),
          // Mock activeCourseProvider to return null
          activeCourseProvider.overrideWith((ref) => null),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final result = await container.read(filteredEvidencesProvider.future);

      // Assert
      expect(result.length, 4);
      expect(result.every((e) => !e.isReviewed), isTrue);
      expect(result.map((e) => e.id).toSet(), {2, 4, 5, 6});
    });

    test('should filter by reviewed status', () async {
      // Arrange
      final evidences = createTestEvidences();
      when(mockGetAllEvidencesUseCase.call())
          .thenAnswer((_) async => evidences);

      final container = ProviderContainer(
        overrides: [
          getAllEvidencesUseCaseProvider
              .overrideWithValue(mockGetAllEvidencesUseCase),
          reviewStatusFilterProvider
              .overrideWith((ref) => ReviewStatusFilter.reviewed),
          // Mock activeCourseProvider to return null
          activeCourseProvider.overrideWith((ref) => null),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final result = await container.read(filteredEvidencesProvider.future);

      // Assert
      expect(result.length, 2);
      expect(result.every((e) => e.isReviewed), isTrue);
      expect(result.map((e) => e.id).toSet(), {1, 3});
    });

    test('should show all when filter is all', () async {
      // Arrange
      final evidences = createTestEvidences();
      when(mockGetAllEvidencesUseCase.call())
          .thenAnswer((_) async => evidences);

      final container = ProviderContainer(
        overrides: [
          getAllEvidencesUseCaseProvider
              .overrideWithValue(mockGetAllEvidencesUseCase),
          reviewStatusFilterProvider
              .overrideWith((ref) => ReviewStatusFilter.all),
          // Mock activeCourseProvider to return null
          activeCourseProvider.overrideWith((ref) => null),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final result = await container.read(filteredEvidencesProvider.future);

      // Assert
      expect(result.length, 6);
    });
  });

  group('filteredEvidencesProvider - Combined filters', () {
    test('should filter by subject + student', () async {
      // Arrange
      final evidences = createTestEvidences();
      when(mockGetAllEvidencesUseCase.call())
          .thenAnswer((_) async => evidences);

      final container = ProviderContainer(
        overrides: [
          getAllEvidencesUseCaseProvider
              .overrideWithValue(mockGetAllEvidencesUseCase),
          selectedSubjectFilterProvider.overrideWith((ref) => 1),
          selectedStudentFilterProvider.overrideWith((ref) => 2),
          // Mock activeCourseProvider to return null
          activeCourseProvider.overrideWith((ref) => null),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final result = await container.read(filteredEvidencesProvider.future);

      // Assert
      expect(result.length, 1);
      expect(result[0].id, 2);
      expect(result[0].subjectId, 1);
      expect(result[0].studentId, 2);
    });

    test('should filter by subject + review status', () async {
      // Arrange
      final evidences = createTestEvidences();
      when(mockGetAllEvidencesUseCase.call())
          .thenAnswer((_) async => evidences);

      final container = ProviderContainer(
        overrides: [
          getAllEvidencesUseCaseProvider
              .overrideWithValue(mockGetAllEvidencesUseCase),
          selectedSubjectFilterProvider.overrideWith((ref) => 1),
          reviewStatusFilterProvider
              .overrideWith((ref) => ReviewStatusFilter.pending),
          // Mock activeCourseProvider to return null
          activeCourseProvider.overrideWith((ref) => null),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final result = await container.read(filteredEvidencesProvider.future);

      // Assert
      expect(result.length, 2);
      expect(result.every((e) => e.subjectId == 1 && !e.isReviewed), isTrue);
      expect(result.map((e) => e.id).toSet(), {2, 5});
    });

    test('should filter by student + review status', () async {
      // Arrange
      final evidences = createTestEvidences();
      when(mockGetAllEvidencesUseCase.call())
          .thenAnswer((_) async => evidences);

      final container = ProviderContainer(
        overrides: [
          getAllEvidencesUseCaseProvider
              .overrideWithValue(mockGetAllEvidencesUseCase),
          selectedStudentFilterProvider.overrideWith((ref) => 1),
          reviewStatusFilterProvider
              .overrideWith((ref) => ReviewStatusFilter.reviewed),
          // Mock activeCourseProvider to return null
          activeCourseProvider.overrideWith((ref) => null),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final result = await container.read(filteredEvidencesProvider.future);

      // Assert
      expect(result.length, 2);
      expect(result.every((e) => e.studentId == 1 && e.isReviewed), isTrue);
      expect(result.map((e) => e.id).toSet(), {1, 3});
    });

    test('should filter by subject + student + review status', () async {
      // Arrange
      final evidences = createTestEvidences();
      when(mockGetAllEvidencesUseCase.call())
          .thenAnswer((_) async => evidences);

      final container = ProviderContainer(
        overrides: [
          getAllEvidencesUseCaseProvider
              .overrideWithValue(mockGetAllEvidencesUseCase),
          selectedSubjectFilterProvider.overrideWith((ref) => 2),
          selectedStudentFilterProvider.overrideWith((ref) => 2),
          reviewStatusFilterProvider
              .overrideWith((ref) => ReviewStatusFilter.pending),
          // Mock activeCourseProvider to return null
          activeCourseProvider.overrideWith((ref) => null),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final result = await container.read(filteredEvidencesProvider.future);

      // Assert
      expect(result.length, 1);
      expect(result[0].id, 4);
      expect(result[0].subjectId, 2);
      expect(result[0].studentId, 2);
      expect(result[0].isReviewed, false);
    });

    test('should return empty when combined filters match nothing', () async {
      // Arrange
      final evidences = createTestEvidences();
      when(mockGetAllEvidencesUseCase.call())
          .thenAnswer((_) async => evidences);

      final container = ProviderContainer(
        overrides: [
          getAllEvidencesUseCaseProvider
              .overrideWithValue(mockGetAllEvidencesUseCase),
          selectedSubjectFilterProvider.overrideWith((ref) => 1),
          selectedStudentFilterProvider.overrideWith((ref) => 1),
          reviewStatusFilterProvider
              .overrideWith((ref) => ReviewStatusFilter.pending),
          // Mock activeCourseProvider to return null
          activeCourseProvider.overrideWith((ref) => null),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final result = await container.read(filteredEvidencesProvider.future);

      // Assert - Subject 1, Student 1 is reviewed, not pending
      expect(result, isEmpty);
    });
  });

  group('evidenceByIdProvider', () {
    test('should return evidence when found', () async {
      // Arrange
      final evidence = Evidence(
        id: 1,
        subjectId: 1,
        studentId: 1,
        type: EvidenceType.image,
        filePath: '/test/1.jpg',
        isReviewed: true,
        captureDate: DateTime.now(),
        createdAt: DateTime.now(),
      );

      when(mockGetEvidenceByIdUseCase.call(1))
          .thenAnswer((_) async => evidence);

      final container = ProviderContainer(
        overrides: [
          getEvidenceByIdUseCaseProvider
              .overrideWithValue(mockGetEvidenceByIdUseCase),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final result = await container.read(evidenceByIdProvider(1).future);

      // Assert
      expect(result, isNotNull);
      expect(result?.id, 1);
      verify(mockGetEvidenceByIdUseCase.call(1)).called(1);
    });

    test('should return null when evidence not found', () async {
      // Arrange
      when(mockGetEvidenceByIdUseCase.call(999))
          .thenAnswer((_) async => null);

      final container = ProviderContainer(
        overrides: [
          getEvidenceByIdUseCaseProvider
              .overrideWithValue(mockGetEvidenceByIdUseCase),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final result = await container.read(evidenceByIdProvider(999).future);

      // Assert
      expect(result, isNull);
      verify(mockGetEvidenceByIdUseCase.call(999)).called(1);
    });

    test('should cache result for same ID', () async {
      // Arrange
      final evidence = Evidence(
        id: 1,
        subjectId: 1,
        studentId: 1,
        type: EvidenceType.image,
        filePath: '/test/1.jpg',
        isReviewed: true,
        captureDate: DateTime.now(),
        createdAt: DateTime.now(),
      );

      when(mockGetEvidenceByIdUseCase.call(1))
          .thenAnswer((_) async => evidence);

      final container = ProviderContainer(
        overrides: [
          getEvidenceByIdUseCaseProvider
              .overrideWithValue(mockGetEvidenceByIdUseCase),
        ],
      );
      addTearDown(container.dispose);

      // Act - Read twice
      final result1 = await container.read(evidenceByIdProvider(1).future);
      final result2 = await container.read(evidenceByIdProvider(1).future);

      // Assert - Should only call use case once (cached)
      expect(result1, isNotNull);
      expect(result2, isNotNull);
      verify(mockGetEvidenceByIdUseCase.call(1)).called(1);
    });

    test('should fetch separately for different IDs', () async {
      // Arrange
      final evidence1 = Evidence(
        id: 1,
        subjectId: 1,
        studentId: 1,
        type: EvidenceType.image,
        filePath: '/test/1.jpg',
        isReviewed: true,
        captureDate: DateTime.now(),
        createdAt: DateTime.now(),
      );

      final evidence2 = Evidence(
        id: 2,
        subjectId: 2,
        studentId: 2,
        type: EvidenceType.image,
        filePath: '/test/2.jpg',
        isReviewed: false,
        captureDate: DateTime.now(),
        createdAt: DateTime.now(),
      );

      when(mockGetEvidenceByIdUseCase.call(1))
          .thenAnswer((_) async => evidence1);
      when(mockGetEvidenceByIdUseCase.call(2))
          .thenAnswer((_) async => evidence2);

      final container = ProviderContainer(
        overrides: [
          getEvidenceByIdUseCaseProvider
              .overrideWithValue(mockGetEvidenceByIdUseCase),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final result1 = await container.read(evidenceByIdProvider(1).future);
      final result2 = await container.read(evidenceByIdProvider(2).future);

      // Assert
      expect(result1?.id, 1);
      expect(result2?.id, 2);
      verify(mockGetEvidenceByIdUseCase.call(1)).called(1);
      verify(mockGetEvidenceByIdUseCase.call(2)).called(1);
    });
  });
}
