import 'package:eduportfolio/core/domain/entities/evidence.dart';
import 'package:eduportfolio/features/review/domain/usecases/get_unassigned_evidences_usecase.dart';
import 'package:eduportfolio/features/review/presentation/providers/review_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'review_providers_test.mocks.dart';

@GenerateMocks([GetUnassignedEvidencesUseCase])
void main() {
  late MockGetUnassignedEvidencesUseCase mockGetUnassignedEvidencesUseCase;

  setUp(() {
    mockGetUnassignedEvidencesUseCase = MockGetUnassignedEvidencesUseCase();
  });

  // Helper to create test evidences
  List<Evidence> createTestUnassignedEvidences() {
    final now = DateTime(2024, 1, 15);
    return [
      Evidence(
        id: 1,
        subjectId: 1,
        studentId: null, // Unassigned
        type: EvidenceType.image,
        filePath: '/test/1.jpg',
        isReviewed: false,
        captureDate: now.subtract(const Duration(days: 3)),
        createdAt: now,
      ),
      Evidence(
        id: 2,
        subjectId: 2,
        studentId: null, // Unassigned
        type: EvidenceType.image,
        filePath: '/test/2.jpg',
        isReviewed: false,
        captureDate: now.subtract(const Duration(days: 2)),
        createdAt: now,
      ),
      Evidence(
        id: 3,
        subjectId: 1,
        studentId: null, // Unassigned
        type: EvidenceType.image,
        filePath: '/test/3.jpg',
        isReviewed: false,
        captureDate: now.subtract(const Duration(days: 1)),
        createdAt: now,
      ),
      Evidence(
        id: 4,
        subjectId: 2,
        studentId: null, // Unassigned
        type: EvidenceType.image,
        filePath: '/test/4.jpg',
        isReviewed: false,
        captureDate: now,
        createdAt: now,
      ),
    ];
  }

  group('State Providers', () {
    test('selectionModeProvider should default to false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final selectionMode = container.read(selectionModeProvider);
      expect(selectionMode, false);
    });

    test('selectionModeProvider should update value', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectionModeProvider.notifier).state = true;
      final selectionMode = container.read(selectionModeProvider);
      expect(selectionMode, true);
    });

    test('selectedEvidencesProvider should default to empty set', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final selected = container.read(selectedEvidencesProvider);
      expect(selected, isEmpty);
    });

    test('selectedEvidencesProvider should update with evidence IDs', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedEvidencesProvider.notifier).state = {1, 2, 3};
      final selected = container.read(selectedEvidencesProvider);
      expect(selected, {1, 2, 3});
    });

    test('selectedEvidencesProvider should support add/remove operations', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Add evidence IDs
      final notifier = container.read(selectedEvidencesProvider.notifier);
      notifier.state = {...notifier.state, 1};
      expect(container.read(selectedEvidencesProvider), {1});

      notifier.state = {...notifier.state, 2};
      expect(container.read(selectedEvidencesProvider), {1, 2});

      // Remove an ID
      notifier.state = {...notifier.state}..remove(1);
      expect(container.read(selectedEvidencesProvider), {2});
    });

    test('reviewSubjectFilterProvider should default to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final filter = container.read(reviewSubjectFilterProvider);
      expect(filter, isNull);
    });

    test('reviewSubjectFilterProvider should update value', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(reviewSubjectFilterProvider.notifier).state = 1;
      final filter = container.read(reviewSubjectFilterProvider);
      expect(filter, 1);
    });
  });

  group('unassignedEvidencesProvider', () {
    test('should return all unassigned evidences when no subject filter',
        () async {
      // Arrange
      final evidences = createTestUnassignedEvidences();
      when(mockGetUnassignedEvidencesUseCase.call(subjectId: null))
          .thenAnswer((_) async => evidences);

      final container = ProviderContainer(
        overrides: [
          getUnassignedEvidencesUseCaseProvider
              .overrideWithValue(mockGetUnassignedEvidencesUseCase),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final result = await container.read(unassignedEvidencesProvider.future);

      // Assert
      expect(result.length, 4);
      expect(result.every((e) => e.studentId == null), isTrue);
      verify(mockGetUnassignedEvidencesUseCase.call(subjectId: null)).called(1);
    });

    test('should filter by subject when subject filter is set', () async {
      // Arrange
      final evidences = createTestUnassignedEvidences()
          .where((e) => e.subjectId == 1)
          .toList();

      when(mockGetUnassignedEvidencesUseCase.call(subjectId: 1))
          .thenAnswer((_) async => evidences);

      final container = ProviderContainer(
        overrides: [
          getUnassignedEvidencesUseCaseProvider
              .overrideWithValue(mockGetUnassignedEvidencesUseCase),
          reviewSubjectFilterProvider.overrideWith((ref) => 1),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final result = await container.read(unassignedEvidencesProvider.future);

      // Assert
      expect(result.length, 2);
      expect(result.every((e) => e.subjectId == 1), isTrue);
      verify(mockGetUnassignedEvidencesUseCase.call(subjectId: 1)).called(1);
    });

    test('should return empty list when no unassigned evidences', () async {
      // Arrange
      when(mockGetUnassignedEvidencesUseCase.call(subjectId: null))
          .thenAnswer((_) async => []);

      final container = ProviderContainer(
        overrides: [
          getUnassignedEvidencesUseCaseProvider
              .overrideWithValue(mockGetUnassignedEvidencesUseCase),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final result = await container.read(unassignedEvidencesProvider.future);

      // Assert
      expect(result, isEmpty);
    });

    test('should update when subject filter changes', () async {
      // Arrange
      final allEvidences = createTestUnassignedEvidences();
      final subject1Evidences =
          allEvidences.where((e) => e.subjectId == 1).toList();

      when(mockGetUnassignedEvidencesUseCase.call(subjectId: null))
          .thenAnswer((_) async => allEvidences);
      when(mockGetUnassignedEvidencesUseCase.call(subjectId: 1))
          .thenAnswer((_) async => subject1Evidences);

      final container = ProviderContainer(
        overrides: [
          getUnassignedEvidencesUseCaseProvider
              .overrideWithValue(mockGetUnassignedEvidencesUseCase),
        ],
      );
      addTearDown(container.dispose);

      // Act 1 - No filter
      final result1 = await container.read(unassignedEvidencesProvider.future);
      expect(result1.length, 4);

      // Act 2 - Change filter to subject 1
      container.read(reviewSubjectFilterProvider.notifier).state = 1;
      // Need to invalidate to trigger refresh
      container.invalidate(unassignedEvidencesProvider);
      final result2 = await container.read(unassignedEvidencesProvider.future);

      // Assert
      expect(result2.length, 2);
      expect(result2.every((e) => e.subjectId == 1), isTrue);
    });
  });

  group('unassignedCountProvider', () {
    test('should return count of unassigned evidences', () async {
      // Arrange
      final evidences = createTestUnassignedEvidences();
      when(mockGetUnassignedEvidencesUseCase.call(subjectId: null))
          .thenAnswer((_) async => evidences);

      final container = ProviderContainer(
        overrides: [
          getUnassignedEvidencesUseCaseProvider
              .overrideWithValue(mockGetUnassignedEvidencesUseCase),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final count = await container.read(unassignedCountProvider.future);

      // Assert
      expect(count, 4);
    });

    test('should return 0 when no unassigned evidences', () async {
      // Arrange
      when(mockGetUnassignedEvidencesUseCase.call(subjectId: null))
          .thenAnswer((_) async => []);

      final container = ProviderContainer(
        overrides: [
          getUnassignedEvidencesUseCaseProvider
              .overrideWithValue(mockGetUnassignedEvidencesUseCase),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final count = await container.read(unassignedCountProvider.future);

      // Assert
      expect(count, 0);
    });

    test('should reflect filtered count when subject filter is active',
        () async {
      // Arrange
      final evidences = createTestUnassignedEvidences()
          .where((e) => e.subjectId == 1)
          .toList();

      when(mockGetUnassignedEvidencesUseCase.call(subjectId: 1))
          .thenAnswer((_) async => evidences);

      final container = ProviderContainer(
        overrides: [
          getUnassignedEvidencesUseCaseProvider
              .overrideWithValue(mockGetUnassignedEvidencesUseCase),
          reviewSubjectFilterProvider.overrideWith((ref) => 1),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final count = await container.read(unassignedCountProvider.future);

      // Assert
      expect(count, 2); // Only 2 evidences have subjectId = 1
    });

    test('should update when evidences are assigned', () async {
      // Arrange
      final evidences = createTestUnassignedEvidences();
      when(mockGetUnassignedEvidencesUseCase.call(subjectId: null))
          .thenAnswer((_) async => evidences);

      final container = ProviderContainer(
        overrides: [
          getUnassignedEvidencesUseCaseProvider
              .overrideWithValue(mockGetUnassignedEvidencesUseCase),
        ],
      );
      addTearDown(container.dispose);

      // Act 1 - Initial count
      final count1 = await container.read(unassignedCountProvider.future);
      expect(count1, 4);

      // Simulate assignment - now only 2 unassigned
      final updatedEvidences = evidences.take(2).toList();
      when(mockGetUnassignedEvidencesUseCase.call(subjectId: null))
          .thenAnswer((_) async => updatedEvidences);

      // Act 2 - Invalidate and re-read
      container.invalidate(unassignedEvidencesProvider);
      final count2 = await container.read(unassignedCountProvider.future);

      // Assert
      expect(count2, 2);
    });
  });
}
