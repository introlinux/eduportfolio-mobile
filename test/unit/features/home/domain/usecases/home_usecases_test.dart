import 'package:eduportfolio/core/domain/entities/subject.dart';
import 'package:eduportfolio/core/domain/repositories/evidence_repository.dart';
import 'package:eduportfolio/core/domain/repositories/subject_repository.dart';
import 'package:eduportfolio/features/home/domain/usecases/count_pending_evidences_usecase.dart';
import 'package:eduportfolio/features/home/domain/usecases/get_default_subjects_usecase.dart';
import 'package:eduportfolio/features/home/domain/usecases/get_storage_info_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'home_usecases_test.mocks.dart';

@GenerateMocks([EvidenceRepository, SubjectRepository])
void main() {
  late MockEvidenceRepository mockEvidenceRepository;
  late MockSubjectRepository mockSubjectRepository;

  setUp(() {
    mockEvidenceRepository = MockEvidenceRepository();
    mockSubjectRepository = MockSubjectRepository();
  });

  group('GetStorageInfoUseCase', () {
    late GetStorageInfoUseCase useCase;

    setUp(() {
      useCase = GetStorageInfoUseCase(mockEvidenceRepository);
    });

    test('should return storage info with correct size and count', () async {
      // Arrange
      const totalSize = 5242880; // 5 MB in bytes
      const evidenceCount = 42;

      when(mockEvidenceRepository.getTotalStorageSize())
          .thenAnswer((_) async => totalSize);
      when(mockEvidenceRepository.countEvidences())
          .thenAnswer((_) async => evidenceCount);

      // Act
      final result = await useCase();

      // Assert
      expect(result.totalSizeBytes, totalSize);
      expect(result.evidenceCount, evidenceCount);
      verify(mockEvidenceRepository.getTotalStorageSize()).called(1);
      verify(mockEvidenceRepository.countEvidences()).called(1);
    });

    test('should calculate size in MB correctly', () async {
      // Arrange
      const oneMB = 1024 * 1024; // 1 MB in bytes
      const totalSize = oneMB * 10; // 10 MB

      when(mockEvidenceRepository.getTotalStorageSize())
          .thenAnswer((_) async => totalSize);
      when(mockEvidenceRepository.countEvidences())
          .thenAnswer((_) async => 10);

      // Act
      final result = await useCase();

      // Assert
      expect(result.sizeMB, 10.0);
    });

    test('should calculate size in GB correctly', () async {
      // Arrange
      const oneGB = 1024 * 1024 * 1024; // 1 GB in bytes
      final totalSize = (oneGB * 2.5).toInt(); // 2.5 GB

      when(mockEvidenceRepository.getTotalStorageSize())
          .thenAnswer((_) async => totalSize);
      when(mockEvidenceRepository.countEvidences())
          .thenAnswer((_) async => 100);

      // Act
      final result = await useCase();

      // Assert
      expect(result.sizeGB, closeTo(2.5, 0.01));
    });

    test('should format size as GB when >= 1 GB', () async {
      // Arrange
      const oneGB = 1024 * 1024 * 1024;
      final totalSize = (oneGB * 1.5).toInt(); // 1.5 GB

      when(mockEvidenceRepository.getTotalStorageSize())
          .thenAnswer((_) async => totalSize);
      when(mockEvidenceRepository.countEvidences())
          .thenAnswer((_) async => 50);

      // Act
      final result = await useCase();

      // Assert
      expect(result.formattedSize, '1.50 GB');
    });

    test('should format size as MB when >= 1 MB and < 1 GB', () async {
      // Arrange
      const oneMB = 1024 * 1024;
      final totalSize = (oneMB * 500).toInt(); // 500 MB

      when(mockEvidenceRepository.getTotalStorageSize())
          .thenAnswer((_) async => totalSize);
      when(mockEvidenceRepository.countEvidences())
          .thenAnswer((_) async => 50);

      // Act
      final result = await useCase();

      // Assert
      expect(result.formattedSize, '500.0 MB');
    });

    test('should format size as KB when < 1 MB', () async {
      // Arrange
      const oneKB = 1024;
      const totalSize = oneKB * 512; // 512 KB

      when(mockEvidenceRepository.getTotalStorageSize())
          .thenAnswer((_) async => totalSize);
      when(mockEvidenceRepository.countEvidences())
          .thenAnswer((_) async => 10);

      // Act
      final result = await useCase();

      // Assert
      expect(result.formattedSize, '512 KB');
    });

    test('should handle zero storage size', () async {
      // Arrange
      when(mockEvidenceRepository.getTotalStorageSize())
          .thenAnswer((_) async => 0);
      when(mockEvidenceRepository.countEvidences())
          .thenAnswer((_) async => 0);

      // Act
      final result = await useCase();

      // Assert
      expect(result.totalSizeBytes, 0);
      expect(result.evidenceCount, 0);
      expect(result.sizeMB, 0.0);
      expect(result.sizeGB, 0.0);
      expect(result.formattedSize, '0 KB');
    });

    test('should handle large storage sizes', () async {
      // Arrange
      const oneGB = 1024 * 1024 * 1024;
      const totalSize = oneGB * 100; // 100 GB

      when(mockEvidenceRepository.getTotalStorageSize())
          .thenAnswer((_) async => totalSize);
      when(mockEvidenceRepository.countEvidences())
          .thenAnswer((_) async => 10000);

      // Act
      final result = await useCase();

      // Assert
      expect(result.sizeGB, 100.0);
      expect(result.formattedSize, '100.00 GB');
    });
  });

  group('CountPendingEvidencesUseCase', () {
    late CountPendingEvidencesUseCase useCase;

    setUp(() {
      useCase = CountPendingEvidencesUseCase(mockEvidenceRepository);
    });

    test('should return count of evidences needing review', () async {
      // Arrange
      const pendingCount = 15;

      when(mockEvidenceRepository.countEvidencesNeedingReview())
          .thenAnswer((_) async => pendingCount);

      // Act
      final result = await useCase();

      // Assert
      expect(result, pendingCount);
      verify(mockEvidenceRepository.countEvidencesNeedingReview()).called(1);
    });

    test('should return 0 when no pending evidences exist', () async {
      // Arrange
      when(mockEvidenceRepository.countEvidencesNeedingReview())
          .thenAnswer((_) async => 0);

      // Act
      final result = await useCase();

      // Assert
      expect(result, 0);
    });

    test('should handle large pending counts', () async {
      // Arrange
      const largePendingCount = 9999;

      when(mockEvidenceRepository.countEvidencesNeedingReview())
          .thenAnswer((_) async => largePendingCount);

      // Act
      final result = await useCase();

      // Assert
      expect(result, largePendingCount);
    });
  });

  group('GetDefaultSubjectsUseCase', () {
    late GetDefaultSubjectsUseCase useCase;

    setUp(() {
      useCase = GetDefaultSubjectsUseCase(mockSubjectRepository);
    });

    test('should return list of default subjects', () async {
      // Arrange
      final now = DateTime.now();
      final defaultSubjects = [
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
        Subject(
          id: 3,
          name: 'Ciencias',
          color: 'FF4CAF50',
          icon: 'science',
          isDefault: true,
          createdAt: now,
        ),
        Subject(
          id: 4,
          name: 'Inglés',
          color: 'FFFF9800',
          icon: 'language',
          isDefault: true,
          createdAt: now,
        ),
        Subject(
          id: 5,
          name: 'Plástica',
          color: 'FF9C27B0',
          icon: 'palette',
          isDefault: true,
          createdAt: now,
        ),
      ];

      when(mockSubjectRepository.getDefaultSubjects())
          .thenAnswer((_) async => defaultSubjects);

      // Act
      final result = await useCase();

      // Assert
      expect(result.length, 5);
      expect(result, defaultSubjects);
      expect(result.every((s) => s.isDefault), isTrue);
      verify(mockSubjectRepository.getDefaultSubjects()).called(1);
    });

    test('should return empty list when no default subjects exist', () async {
      // Arrange
      when(mockSubjectRepository.getDefaultSubjects())
          .thenAnswer((_) async => []);

      // Act
      final result = await useCase();

      // Assert
      expect(result, isEmpty);
    });

    test('should return subjects with correct properties', () async {
      // Arrange
      final now = DateTime.now();
      final mathSubject = Subject(
        id: 1,
        name: 'Matemáticas',
        color: 'FF2196F3',
        icon: 'calculate',
        isDefault: true,
        createdAt: now,
      );

      when(mockSubjectRepository.getDefaultSubjects())
          .thenAnswer((_) async => [mathSubject]);

      // Act
      final result = await useCase();

      // Assert
      expect(result.length, 1);
      expect(result.first.id, 1);
      expect(result.first.name, 'Matemáticas');
      expect(result.first.color, 'FF2196F3');
      expect(result.first.icon, 'calculate');
      expect(result.first.isDefault, isTrue);
    });
  });
}
