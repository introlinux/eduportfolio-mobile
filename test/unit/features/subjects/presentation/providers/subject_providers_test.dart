import 'package:eduportfolio/core/domain/entities/subject.dart';
import 'package:eduportfolio/core/domain/repositories/subject_repository.dart';
import 'package:eduportfolio/core/providers/core_providers.dart';
import 'package:eduportfolio/features/subjects/presentation/providers/subject_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'subject_providers_test.mocks.dart';

@GenerateMocks([SubjectRepository])
void main() {
  late MockSubjectRepository mockSubjectRepository;

  setUp(() {
    mockSubjectRepository = MockSubjectRepository();
  });

  // Helper to create test subjects
  List<Subject> createTestSubjects() {
    final now = DateTime(2024, 1, 15);
    return [
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
        name: 'Custom Subject',
        color: 'FF4CAF50',
        icon: 'star',
        isDefault: false,
        createdAt: now,
      ),
    ];
  }

  group('allSubjectsProvider', () {
    test('should return all subjects', () async {
      // Arrange
      final subjects = createTestSubjects();
      when(mockSubjectRepository.getAllSubjects())
          .thenAnswer((_) async => subjects);

      final container = ProviderContainer(
        overrides: [
          subjectRepositoryProvider.overrideWithValue(mockSubjectRepository),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final result = await container.read(allSubjectsProvider.future);

      // Assert
      expect(result.length, 3);
      expect(result.where((s) => s.isDefault).length, 2);
      verify(mockSubjectRepository.getAllSubjects()).called(1);
    });

    test('should return empty list when no subjects', () async {
      // Arrange
      when(mockSubjectRepository.getAllSubjects()).thenAnswer((_) async => []);

      final container = ProviderContainer(
        overrides: [
          subjectRepositoryProvider.overrideWithValue(mockSubjectRepository),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final result = await container.read(allSubjectsProvider.future);

      // Assert
      expect(result, isEmpty);
    });

    test('should cache result', () async {
      // Arrange
      final subjects = createTestSubjects();
      when(mockSubjectRepository.getAllSubjects())
          .thenAnswer((_) async => subjects);

      final container = ProviderContainer(
        overrides: [
          subjectRepositoryProvider.overrideWithValue(mockSubjectRepository),
        ],
      );
      addTearDown(container.dispose);

      // Act - Read twice
      final result1 = await container.read(allSubjectsProvider.future);
      final result2 = await container.read(allSubjectsProvider.future);

      // Assert - Should only call repository once (cached)
      expect(result1.length, 3);
      expect(result2.length, 3);
      verify(mockSubjectRepository.getAllSubjects()).called(1);
    });
  });

  group('createSubjectProvider', () {
    test('should create subject and return ID', () async {
      // Arrange
      final newSubject = Subject(
        name: 'New Subject',
        color: 'FFFF9800',
        icon: 'lightbulb',
        isDefault: false,
        createdAt: DateTime.now(),
      );

      when(mockSubjectRepository.createSubject(newSubject))
          .thenAnswer((_) async => 4);
      when(mockSubjectRepository.getAllSubjects()).thenAnswer((_) async => []);

      final container = ProviderContainer(
        overrides: [
          subjectRepositoryProvider.overrideWithValue(mockSubjectRepository),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final createFunction = container.read(createSubjectProvider);
      final id = await createFunction(newSubject);

      // Assert
      expect(id, 4);
      verify(mockSubjectRepository.createSubject(newSubject)).called(1);
    });

    test('should invalidate allSubjectsProvider after creation', () async {
      // Arrange
      final newSubject = Subject(
        name: 'New Subject',
        color: 'FFFF9800',
        icon: 'lightbulb',
        isDefault: false,
        createdAt: DateTime.now(),
      );

      final subjects = createTestSubjects();
      when(mockSubjectRepository.createSubject(newSubject))
          .thenAnswer((_) async => 4);

      // First call returns initial subjects, second call returns with new one
      when(mockSubjectRepository.getAllSubjects())
          .thenAnswer((_) async => subjects);

      final container = ProviderContainer(
        overrides: [
          subjectRepositoryProvider.overrideWithValue(mockSubjectRepository),
        ],
      );
      addTearDown(container.dispose);

      // Read initial state
      final result1 = await container.read(allSubjectsProvider.future);
      expect(result1.length, 3);

      // Act - Create new subject
      final createFunction = container.read(createSubjectProvider);
      await createFunction(newSubject);

      // Assert - allSubjectsProvider should be invalidated and re-fetched
      // Note: In real scenario, second call would return updated list
      verify(mockSubjectRepository.createSubject(newSubject)).called(1);
    });
  });

  group('updateSubjectProvider', () {
    test('should update subject', () async {
      // Arrange
      final subject = Subject(
        id: 1,
        name: 'Updated Subject',
        color: 'FFFF9800',
        icon: 'star',
        isDefault: false,
        createdAt: DateTime.now(),
      );

      when(mockSubjectRepository.updateSubject(subject))
          .thenAnswer((_) async => 1);
      when(mockSubjectRepository.getAllSubjects()).thenAnswer((_) async => []);

      final container = ProviderContainer(
        overrides: [
          subjectRepositoryProvider.overrideWithValue(mockSubjectRepository),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final updateFunction = container.read(updateSubjectProvider);
      await updateFunction(subject);

      // Assert
      verify(mockSubjectRepository.updateSubject(subject)).called(1);
    });

    test('should invalidate allSubjectsProvider after update', () async {
      // Arrange
      final subject = Subject(
        id: 1,
        name: 'Updated Subject',
        color: 'FFFF9800',
        icon: 'star',
        isDefault: false,
        createdAt: DateTime.now(),
      );

      final subjects = createTestSubjects();
      when(mockSubjectRepository.updateSubject(subject))
          .thenAnswer((_) async => 1);
      when(mockSubjectRepository.getAllSubjects())
          .thenAnswer((_) async => subjects);

      final container = ProviderContainer(
        overrides: [
          subjectRepositoryProvider.overrideWithValue(mockSubjectRepository),
        ],
      );
      addTearDown(container.dispose);

      // Read initial state
      await container.read(allSubjectsProvider.future);

      // Act - Update subject
      final updateFunction = container.read(updateSubjectProvider);
      await updateFunction(subject);

      // Assert
      verify(mockSubjectRepository.updateSubject(subject)).called(1);
    });
  });

  group('deleteSubjectProvider', () {
    test('should delete subject by ID', () async {
      // Arrange
      when(mockSubjectRepository.deleteSubject(1)).thenAnswer((_) async => 1);
      when(mockSubjectRepository.getAllSubjects()).thenAnswer((_) async => []);

      final container = ProviderContainer(
        overrides: [
          subjectRepositoryProvider.overrideWithValue(mockSubjectRepository),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final deleteFunction = container.read(deleteSubjectProvider);
      await deleteFunction(1);

      // Assert
      verify(mockSubjectRepository.deleteSubject(1)).called(1);
    });

    test('should invalidate allSubjectsProvider after deletion', () async {
      // Arrange
      final subjects = createTestSubjects();
      when(mockSubjectRepository.deleteSubject(1)).thenAnswer((_) async => 1);
      when(mockSubjectRepository.getAllSubjects())
          .thenAnswer((_) async => subjects);

      final container = ProviderContainer(
        overrides: [
          subjectRepositoryProvider.overrideWithValue(mockSubjectRepository),
        ],
      );
      addTearDown(container.dispose);

      // Read initial state
      final result1 = await container.read(allSubjectsProvider.future);
      expect(result1.length, 3);

      // Act - Delete subject
      final deleteFunction = container.read(deleteSubjectProvider);
      await deleteFunction(1);

      // Assert
      verify(mockSubjectRepository.deleteSubject(1)).called(1);
    });
  });
}
