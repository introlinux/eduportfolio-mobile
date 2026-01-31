import 'package:eduportfolio/core/domain/entities/course.dart';
import 'package:eduportfolio/core/domain/repositories/student_repository.dart';
import 'package:eduportfolio/core/providers/core_providers.dart';
import 'package:eduportfolio/features/courses/domain/usecases/get_active_course_usecase.dart';
import 'package:eduportfolio/features/courses/domain/usecases/get_all_courses_usecase.dart';
import 'package:eduportfolio/features/courses/presentation/providers/course_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'course_providers_test.mocks.dart';

@GenerateMocks([
  GetAllCoursesUseCase,
  GetActiveCourseUseCase,
  StudentRepository,
])
void main() {
  late MockGetAllCoursesUseCase mockGetAllCoursesUseCase;
  late MockGetActiveCourseUseCase mockGetActiveCourseUseCase;
  late MockStudentRepository mockStudentRepository;

  setUp(() {
    mockGetAllCoursesUseCase = MockGetAllCoursesUseCase();
    mockGetActiveCourseUseCase = MockGetActiveCourseUseCase();
    mockStudentRepository = MockStudentRepository();
  });

  // Helper to create test courses
  List<Course> createTestCourses() {
    final now = DateTime(2024, 1, 15);
    return [
      Course(
        id: 1,
        name: 'Curso 2023-2024',
        startDate: DateTime(2023, 9, 1),
        endDate: DateTime(2024, 6, 30),
        isActive: true,
        createdAt: now,
      ),
      Course(
        id: 2,
        name: 'Curso 2022-2023',
        startDate: DateTime(2022, 9, 1),
        endDate: DateTime(2023, 6, 30),
        isActive: false,
        createdAt: now,
      ),
    ];
  }

  group('activeCourseProvider', () {
    test('should return active course when one exists', () async {
      // Arrange
      final activeCourse = Course(
        id: 1,
        name: 'Curso Activo',
        startDate: DateTime(2023, 9, 1),
        isActive: true,
        createdAt: DateTime.now(),
      );

      when(mockGetActiveCourseUseCase.call()).thenAnswer((_) async => activeCourse);

      final container = ProviderContainer(
        overrides: [
          getActiveCourseUseCaseProvider.overrideWithValue(mockGetActiveCourseUseCase),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final result = await container.read(activeCourseProvider.future);

      // Assert
      expect(result, isNotNull);
      expect(result?.id, 1);
      expect(result?.isActive, true);
      verify(mockGetActiveCourseUseCase.call()).called(1);
    });

    test('should return null when no active course exists', () async {
      // Arrange
      when(mockGetActiveCourseUseCase.call()).thenAnswer((_) async => null);

      final container = ProviderContainer(
        overrides: [
          getActiveCourseUseCaseProvider.overrideWithValue(mockGetActiveCourseUseCase),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final result = await container.read(activeCourseProvider.future);

      // Assert
      expect(result, isNull);
    });

    test('should cache result', () async {
      // Arrange
      final activeCourse = Course(
        id: 1,
        name: 'Curso Activo',
        startDate: DateTime(2023, 9, 1),
        isActive: true,
        createdAt: DateTime.now(),
      );

      when(mockGetActiveCourseUseCase.call()).thenAnswer((_) async => activeCourse);

      final container = ProviderContainer(
        overrides: [
          getActiveCourseUseCaseProvider.overrideWithValue(mockGetActiveCourseUseCase),
        ],
      );
      addTearDown(container.dispose);

      // Act - Read twice
      final result1 = await container.read(activeCourseProvider.future);
      final result2 = await container.read(activeCourseProvider.future);

      // Assert - Should only call use case once (cached)
      expect(result1, isNotNull);
      expect(result2, isNotNull);
      verify(mockGetActiveCourseUseCase.call()).called(1);
    });
  });

  group('allCoursesProvider', () {
    test('should return all courses', () async {
      // Arrange
      final courses = createTestCourses();
      when(mockGetAllCoursesUseCase.call()).thenAnswer((_) async => courses);

      final container = ProviderContainer(
        overrides: [
          getAllCoursesUseCaseProvider.overrideWithValue(mockGetAllCoursesUseCase),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final result = await container.read(allCoursesProvider.future);

      // Assert
      expect(result.length, 2);
      expect(result[0].isActive, true);
      expect(result[1].isActive, false);
      verify(mockGetAllCoursesUseCase.call()).called(1);
    });

    test('should return empty list when no courses', () async {
      // Arrange
      when(mockGetAllCoursesUseCase.call()).thenAnswer((_) async => []);

      final container = ProviderContainer(
        overrides: [
          getAllCoursesUseCaseProvider.overrideWithValue(mockGetAllCoursesUseCase),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final result = await container.read(allCoursesProvider.future);

      // Assert
      expect(result, isEmpty);
    });

    test('should cache result', () async {
      // Arrange
      final courses = createTestCourses();
      when(mockGetAllCoursesUseCase.call()).thenAnswer((_) async => courses);

      final container = ProviderContainer(
        overrides: [
          getAllCoursesUseCaseProvider.overrideWithValue(mockGetAllCoursesUseCase),
        ],
      );
      addTearDown(container.dispose);

      // Act - Read twice
      final result1 = await container.read(allCoursesProvider.future);
      final result2 = await container.read(allCoursesProvider.future);

      // Assert - Should only call use case once (cached)
      expect(result1.length, 2);
      expect(result2.length, 2);
      verify(mockGetAllCoursesUseCase.call()).called(1);
    });
  });

  group('courseStudentCountProvider', () {
    test('should return count of students in course', () async {
      // Arrange
      when(mockStudentRepository.countStudentsByCourse(1))
          .thenAnswer((_) async => 25);

      final container = ProviderContainer(
        overrides: [
          studentRepositoryProvider.overrideWithValue(mockStudentRepository),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final count = await container.read(courseStudentCountProvider(1).future);

      // Assert
      expect(count, 25);
      verify(mockStudentRepository.countStudentsByCourse(1)).called(1);
    });

    test('should return 0 when course has no students', () async {
      // Arrange
      when(mockStudentRepository.countStudentsByCourse(999))
          .thenAnswer((_) async => 0);

      final container = ProviderContainer(
        overrides: [
          studentRepositoryProvider.overrideWithValue(mockStudentRepository),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final count = await container.read(courseStudentCountProvider(999).future);

      // Assert
      expect(count, 0);
    });

    test('should cache count for same course ID', () async {
      // Arrange
      when(mockStudentRepository.countStudentsByCourse(1))
          .thenAnswer((_) async => 30);

      final container = ProviderContainer(
        overrides: [
          studentRepositoryProvider.overrideWithValue(mockStudentRepository),
        ],
      );
      addTearDown(container.dispose);

      // Act - Read twice
      final count1 = await container.read(courseStudentCountProvider(1).future);
      final count2 = await container.read(courseStudentCountProvider(1).future);

      // Assert - Should only call repository once (cached)
      expect(count1, 30);
      expect(count2, 30);
      verify(mockStudentRepository.countStudentsByCourse(1)).called(1);
    });

    test('should fetch separately for different course IDs', () async {
      // Arrange
      when(mockStudentRepository.countStudentsByCourse(1))
          .thenAnswer((_) async => 25);
      when(mockStudentRepository.countStudentsByCourse(2))
          .thenAnswer((_) async => 30);

      final container = ProviderContainer(
        overrides: [
          studentRepositoryProvider.overrideWithValue(mockStudentRepository),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final count1 = await container.read(courseStudentCountProvider(1).future);
      final count2 = await container.read(courseStudentCountProvider(2).future);

      // Assert
      expect(count1, 25);
      expect(count2, 30);
      verify(mockStudentRepository.countStudentsByCourse(1)).called(1);
      verify(mockStudentRepository.countStudentsByCourse(2)).called(1);
    });
  });
}
