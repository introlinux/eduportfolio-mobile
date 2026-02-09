import 'package:eduportfolio/core/domain/entities/subject.dart';
import 'package:eduportfolio/features/courses/presentation/providers/course_providers.dart';
import 'package:eduportfolio/features/home/domain/usecases/count_pending_evidences_usecase.dart';
import 'package:eduportfolio/features/home/domain/usecases/get_default_subjects_usecase.dart';
import 'package:eduportfolio/features/home/domain/usecases/get_storage_info_usecase.dart';
import 'package:eduportfolio/features/home/presentation/providers/home_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'home_providers_test.mocks.dart';

@GenerateMocks([
  GetDefaultSubjectsUseCase,
  CountPendingEvidencesUseCase,
  GetStorageInfoUseCase,
])
void main() {
  late MockGetDefaultSubjectsUseCase mockGetDefaultSubjectsUseCase;
  late MockCountPendingEvidencesUseCase mockCountPendingEvidencesUseCase;
  late MockGetStorageInfoUseCase mockGetStorageInfoUseCase;

  setUp(() {
    mockGetDefaultSubjectsUseCase = MockGetDefaultSubjectsUseCase();
    mockCountPendingEvidencesUseCase = MockCountPendingEvidencesUseCase();
    mockGetStorageInfoUseCase = MockGetStorageInfoUseCase();
  });

  group('defaultSubjectsProvider', () {
    test('should return list of default subjects', () async {
      // Arrange
      final now = DateTime(2024, 1, 15);
      final subjects = [
        Subject(
          id: 1,
          name: 'Matemáticas',
          color: 'FF2196F3',
          icon: 'calculate',
          isDefault: true,
          createdAt: now,
        ),
        Subject(
          id: 2,
          name: 'Lengua',
          color: 'FFF44336',
          icon: 'menu_book',
          isDefault: true,
          createdAt: now,
        ),
      ];

      when(mockGetDefaultSubjectsUseCase.call())
          .thenAnswer((_) async => subjects);

      final container = ProviderContainer(
        overrides: [
          getDefaultSubjectsUseCaseProvider
              .overrideWithValue(mockGetDefaultSubjectsUseCase),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final result = await container.read(defaultSubjectsProvider.future);

      // Assert
      expect(result.length, 2);
      expect(result.every((s) => s.isDefault), isTrue);
      verify(mockGetDefaultSubjectsUseCase.call()).called(1);
    });

    test('should return empty list when no default subjects', () async {
      // Arrange
      when(mockGetDefaultSubjectsUseCase.call()).thenAnswer((_) async => []);

      final container = ProviderContainer(
        overrides: [
          getDefaultSubjectsUseCaseProvider
              .overrideWithValue(mockGetDefaultSubjectsUseCase),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final result = await container.read(defaultSubjectsProvider.future);

      // Assert
      expect(result, isEmpty);
    });

    test('should cache result', () async {
      // Arrange
      final now = DateTime(2024, 1, 15);
      final subjects = [
        Subject(
          id: 1,
          name: 'Matemáticas',
          color: 'FF2196F3',
          icon: 'calculate',
          isDefault: true,
          createdAt: now,
        ),
      ];

      when(mockGetDefaultSubjectsUseCase.call())
          .thenAnswer((_) async => subjects);

      final container = ProviderContainer(
        overrides: [
          getDefaultSubjectsUseCaseProvider
              .overrideWithValue(mockGetDefaultSubjectsUseCase),
        ],
      );
      addTearDown(container.dispose);

      // Act - Read twice
      final result1 = await container.read(defaultSubjectsProvider.future);
      final result2 = await container.read(defaultSubjectsProvider.future);

      // Assert - Should only call use case once (cached)
      expect(result1.length, 1);
      expect(result2.length, 1);
      verify(mockGetDefaultSubjectsUseCase.call()).called(1);
    });
  });

  group('pendingEvidencesCountProvider', () {
    test('should return count of pending evidences', () async {
      // Arrange
      when(mockCountPendingEvidencesUseCase.call(courseId: anyNamed('courseId')))
          .thenAnswer((_) async => 15);

      final container = ProviderContainer(
        overrides: [
          countPendingEvidencesUseCaseProvider
              .overrideWithValue(mockCountPendingEvidencesUseCase),
          // Mock activeCourseProvider to return null
          activeCourseProvider.overrideWith((ref) => null),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final count = await container.read(pendingEvidencesCountProvider.future);

      // Assert
      expect(count, 15);
      verify(mockCountPendingEvidencesUseCase.call()).called(1);
    });

    test('should return 0 when no pending evidences', () async {
      // Arrange
      when(mockCountPendingEvidencesUseCase.call(courseId: anyNamed('courseId')))
          .thenAnswer((_) async => 0);

      final container = ProviderContainer(
        overrides: [
          countPendingEvidencesUseCaseProvider
              .overrideWithValue(mockCountPendingEvidencesUseCase),
          // Mock activeCourseProvider to return null
          activeCourseProvider.overrideWith((ref) => null),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final count = await container.read(pendingEvidencesCountProvider.future);

      // Assert
      expect(count, 0);
    });

    test('should update when evidences are reviewed', () async {
      // Arrange
      when(mockCountPendingEvidencesUseCase.call(courseId: anyNamed('courseId')))
          .thenAnswer((_) async => 10);

      final container = ProviderContainer(
        overrides: [
          countPendingEvidencesUseCaseProvider
              .overrideWithValue(mockCountPendingEvidencesUseCase),
          // Mock activeCourseProvider to return null
          activeCourseProvider.overrideWith((ref) => null),
        ],
      );
      addTearDown(container.dispose);

      // Act 1 - Initial count
      final count1 = await container.read(pendingEvidencesCountProvider.future);
      expect(count1, 10);

      // Simulate some evidences reviewed
      when(mockCountPendingEvidencesUseCase.call()).thenAnswer((_) async => 5);

      // Act 2 - Invalidate and re-read
      container.invalidate(pendingEvidencesCountProvider);
      final count2 = await container.read(pendingEvidencesCountProvider.future);

      // Assert
      expect(count2, 5);
    });
  });

  group('storageInfoProvider', () {
    test('should return storage info', () async {
      // Arrange
      final storageInfo = StorageInfo(
        totalSizeBytes: 5242880, // 5 MB
        evidenceCount: 42,
      );

      when(mockGetStorageInfoUseCase.call())
          .thenAnswer((_) async => storageInfo);

      final container = ProviderContainer(
        overrides: [
          getStorageInfoUseCaseProvider
              .overrideWithValue(mockGetStorageInfoUseCase),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final result = await container.read(storageInfoProvider.future);

      // Assert
      expect(result.totalSizeBytes, 5242880);
      expect(result.evidenceCount, 42);
      expect(result.sizeMB, closeTo(5.0, 0.01));
      verify(mockGetStorageInfoUseCase.call()).called(1);
    });

    test('should handle zero storage', () async {
      // Arrange
      final storageInfo = StorageInfo(
        totalSizeBytes: 0,
        evidenceCount: 0,
      );

      when(mockGetStorageInfoUseCase.call())
          .thenAnswer((_) async => storageInfo);

      final container = ProviderContainer(
        overrides: [
          getStorageInfoUseCaseProvider
              .overrideWithValue(mockGetStorageInfoUseCase),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final result = await container.read(storageInfoProvider.future);

      // Assert
      expect(result.totalSizeBytes, 0);
      expect(result.evidenceCount, 0);
      expect(result.formattedSize, '0 KB');
    });

    test('should format large storage sizes correctly', () async {
      // Arrange
      const oneGB = 1024 * 1024 * 1024;
      final storageInfo = StorageInfo(
        totalSizeBytes: (oneGB * 1.5).toInt(), // 1.5 GB
        evidenceCount: 100,
      );

      when(mockGetStorageInfoUseCase.call())
          .thenAnswer((_) async => storageInfo);

      final container = ProviderContainer(
        overrides: [
          getStorageInfoUseCaseProvider
              .overrideWithValue(mockGetStorageInfoUseCase),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final result = await container.read(storageInfoProvider.future);

      // Assert
      expect(result.sizeGB, closeTo(1.5, 0.01));
      expect(result.formattedSize, '1.50 GB');
    });

    test('should update when new evidences are added', () async {
      // Arrange
      final storageInfo1 = StorageInfo(
        totalSizeBytes: 1024000,
        evidenceCount: 10,
      );
      final storageInfo2 = StorageInfo(
        totalSizeBytes: 2048000,
        evidenceCount: 20,
      );

      when(mockGetStorageInfoUseCase.call())
          .thenAnswer((_) async => storageInfo1);

      final container = ProviderContainer(
        overrides: [
          getStorageInfoUseCaseProvider
              .overrideWithValue(mockGetStorageInfoUseCase),
        ],
      );
      addTearDown(container.dispose);

      // Act 1 - Initial storage
      final result1 = await container.read(storageInfoProvider.future);
      expect(result1.evidenceCount, 10);

      // Simulate new evidences added
      when(mockGetStorageInfoUseCase.call())
          .thenAnswer((_) async => storageInfo2);

      // Act 2 - Invalidate and re-read
      container.invalidate(storageInfoProvider);
      final result2 = await container.read(storageInfoProvider.future);

      // Assert
      expect(result2.evidenceCount, 20);
      expect(result2.totalSizeBytes, 2048000);
    });
  });
}
