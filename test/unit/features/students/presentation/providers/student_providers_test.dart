import 'package:eduportfolio/core/domain/entities/student.dart';
import 'package:eduportfolio/features/students/domain/usecases/get_all_students_usecase.dart';
import 'package:eduportfolio/features/students/domain/usecases/get_student_by_id_usecase.dart';
import 'package:eduportfolio/features/students/domain/usecases/get_students_by_course_usecase.dart';
import 'package:eduportfolio/features/students/presentation/providers/student_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'student_providers_test.mocks.dart';

@GenerateMocks([
  GetAllStudentsUseCase,
  GetStudentsByCourseUseCase,
  GetStudentByIdUseCase,
])
void main() {
  late MockGetAllStudentsUseCase mockGetAllStudentsUseCase;
  late MockGetStudentsByCourseUseCase mockGetStudentsByCourseUseCase;
  late MockGetStudentByIdUseCase mockGetStudentByIdUseCase;

  setUp(() {
    mockGetAllStudentsUseCase = MockGetAllStudentsUseCase();
    mockGetStudentsByCourseUseCase = MockGetStudentsByCourseUseCase();
    mockGetStudentByIdUseCase = MockGetStudentByIdUseCase();
  });

  // Helper to create test students
  List<Student> createTestStudents() {
    final now = DateTime(2024, 1, 15);
    return [
      Student(
        id: 1,
        courseId: 1,
        name: 'Alice García',
        createdAt: now,
        updatedAt: now,
      ),
      Student(
        id: 2,
        courseId: 1,
        name: 'Bob Martínez',
        createdAt: now,
        updatedAt: now,
      ),
      Student(
        id: 3,
        courseId: 2,
        name: 'Carlos López',
        createdAt: now,
        updatedAt: now,
      ),
      Student(
        id: 4,
        courseId: 2,
        name: 'Diana Rodríguez',
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  group('State Providers', () {
    test('selectedCourseFilterProvider should default to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final selectedCourse = container.read(selectedCourseFilterProvider);
      expect(selectedCourse, isNull);
    });

    test('selectedCourseFilterProvider should update value', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedCourseFilterProvider.notifier).state = 1;
      final selectedCourse = container.read(selectedCourseFilterProvider);
      expect(selectedCourse, 1);
    });

    test('selectedCourseFilterProvider should allow reset to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Set to a value
      container.read(selectedCourseFilterProvider.notifier).state = 1;
      expect(container.read(selectedCourseFilterProvider), 1);

      // Reset to null
      container.read(selectedCourseFilterProvider.notifier).state = null;
      expect(container.read(selectedCourseFilterProvider), isNull);
    });
  });

  group('filteredStudentsProvider - No filter', () {
    test('should return all students when course filter is null', () async {
      // Arrange
      final students = createTestStudents();
      when(mockGetAllStudentsUseCase.call()).thenAnswer((_) async => students);

      final container = ProviderContainer(
        overrides: [
          getAllStudentsUseCaseProvider
              .overrideWithValue(mockGetAllStudentsUseCase),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final result = await container.read(filteredStudentsProvider.future);

      // Assert
      expect(result.length, 4);
      verify(mockGetAllStudentsUseCase.call()).called(1);
      verifyNever(mockGetStudentsByCourseUseCase.call(any));
    });

    test('should return empty list when no students', () async {
      // Arrange
      when(mockGetAllStudentsUseCase.call()).thenAnswer((_) async => []);

      final container = ProviderContainer(
        overrides: [
          getAllStudentsUseCaseProvider
              .overrideWithValue(mockGetAllStudentsUseCase),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final result = await container.read(filteredStudentsProvider.future);

      // Assert
      expect(result, isEmpty);
    });
  });

  group('filteredStudentsProvider - With course filter', () {
    test('should filter students by course ID', () async {
      // Arrange
      final students =
          createTestStudents().where((s) => s.courseId == 1).toList();
      when(mockGetStudentsByCourseUseCase.call(1))
          .thenAnswer((_) async => students);

      final container = ProviderContainer(
        overrides: [
          getStudentsByCourseUseCaseProvider
              .overrideWithValue(mockGetStudentsByCourseUseCase),
          selectedCourseFilterProvider.overrideWith((ref) => 1),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final result = await container.read(filteredStudentsProvider.future);

      // Assert
      expect(result.length, 2);
      expect(result.every((s) => s.courseId == 1), isTrue);
      verify(mockGetStudentsByCourseUseCase.call(1)).called(1);
      verifyNever(mockGetAllStudentsUseCase.call());
    });

    test('should return empty when course has no students', () async {
      // Arrange
      when(mockGetStudentsByCourseUseCase.call(999))
          .thenAnswer((_) async => []);

      final container = ProviderContainer(
        overrides: [
          getStudentsByCourseUseCaseProvider
              .overrideWithValue(mockGetStudentsByCourseUseCase),
          selectedCourseFilterProvider.overrideWith((ref) => 999),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final result = await container.read(filteredStudentsProvider.future);

      // Assert
      expect(result, isEmpty);
    });

    test('should update when course filter changes', () async {
      // Arrange
      final allStudents = createTestStudents();
      final course1Students =
          allStudents.where((s) => s.courseId == 1).toList();
      final course2Students =
          allStudents.where((s) => s.courseId == 2).toList();

      when(mockGetAllStudentsUseCase.call())
          .thenAnswer((_) async => allStudents);
      when(mockGetStudentsByCourseUseCase.call(1))
          .thenAnswer((_) async => course1Students);
      when(mockGetStudentsByCourseUseCase.call(2))
          .thenAnswer((_) async => course2Students);

      final container = ProviderContainer(
        overrides: [
          getAllStudentsUseCaseProvider
              .overrideWithValue(mockGetAllStudentsUseCase),
          getStudentsByCourseUseCaseProvider
              .overrideWithValue(mockGetStudentsByCourseUseCase),
        ],
      );
      addTearDown(container.dispose);

      // Act 1 - No filter (all students)
      final result1 = await container.read(filteredStudentsProvider.future);
      expect(result1.length, 4);

      // Act 2 - Filter by course 1
      container.read(selectedCourseFilterProvider.notifier).state = 1;
      container.invalidate(filteredStudentsProvider);
      final result2 = await container.read(filteredStudentsProvider.future);
      expect(result2.length, 2);
      expect(result2.every((s) => s.courseId == 1), isTrue);

      // Act 3 - Filter by course 2
      container.read(selectedCourseFilterProvider.notifier).state = 2;
      container.invalidate(filteredStudentsProvider);
      final result3 = await container.read(filteredStudentsProvider.future);
      expect(result3.length, 2);
      expect(result3.every((s) => s.courseId == 2), isTrue);
    });
  });

  group('studentByIdProvider', () {
    test('should return student when found', () async {
      // Arrange
      final student = Student(
        id: 1,
        courseId: 1,
        name: 'Test Student',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(mockGetStudentByIdUseCase.call(1))
          .thenAnswer((_) async => student);

      final container = ProviderContainer(
        overrides: [
          getStudentByIdUseCaseProvider
              .overrideWithValue(mockGetStudentByIdUseCase),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final result = await container.read(studentByIdProvider(1).future);

      // Assert
      expect(result, isNotNull);
      expect(result?.id, 1);
      expect(result?.name, 'Test Student');
      verify(mockGetStudentByIdUseCase.call(1)).called(1);
    });

    test('should return null when student not found', () async {
      // Arrange
      when(mockGetStudentByIdUseCase.call(999))
          .thenAnswer((_) async => null);

      final container = ProviderContainer(
        overrides: [
          getStudentByIdUseCaseProvider
              .overrideWithValue(mockGetStudentByIdUseCase),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final result = await container.read(studentByIdProvider(999).future);

      // Assert
      expect(result, isNull);
      verify(mockGetStudentByIdUseCase.call(999)).called(1);
    });

    test('should cache result for same ID', () async {
      // Arrange
      final student = Student(
        id: 1,
        courseId: 1,
        name: 'Test Student',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(mockGetStudentByIdUseCase.call(1))
          .thenAnswer((_) async => student);

      final container = ProviderContainer(
        overrides: [
          getStudentByIdUseCaseProvider
              .overrideWithValue(mockGetStudentByIdUseCase),
        ],
      );
      addTearDown(container.dispose);

      // Act - Read twice
      final result1 = await container.read(studentByIdProvider(1).future);
      final result2 = await container.read(studentByIdProvider(1).future);

      // Assert - Should only call use case once (cached)
      expect(result1, isNotNull);
      expect(result2, isNotNull);
      verify(mockGetStudentByIdUseCase.call(1)).called(1);
    });

    test('should fetch separately for different IDs', () async {
      // Arrange
      final student1 = Student(
        id: 1,
        courseId: 1,
        name: 'Student 1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final student2 = Student(
        id: 2,
        courseId: 1,
        name: 'Student 2',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(mockGetStudentByIdUseCase.call(1))
          .thenAnswer((_) async => student1);
      when(mockGetStudentByIdUseCase.call(2))
          .thenAnswer((_) async => student2);

      final container = ProviderContainer(
        overrides: [
          getStudentByIdUseCaseProvider
              .overrideWithValue(mockGetStudentByIdUseCase),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final result1 = await container.read(studentByIdProvider(1).future);
      final result2 = await container.read(studentByIdProvider(2).future);

      // Assert
      expect(result1?.id, 1);
      expect(result2?.id, 2);
      verify(mockGetStudentByIdUseCase.call(1)).called(1);
      verify(mockGetStudentByIdUseCase.call(2)).called(1);
    });
  });

  group('studentCountByCourseProvider', () {
    test('should return count of students for a course', () async {
      // Arrange
      final students = createTestStudents()
          .where((s) => s.courseId == 1)
          .toList();

      when(mockGetStudentsByCourseUseCase.call(1))
          .thenAnswer((_) async => students);

      final container = ProviderContainer(
        overrides: [
          getStudentsByCourseUseCaseProvider
              .overrideWithValue(mockGetStudentsByCourseUseCase),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final count = await container.read(studentCountByCourseProvider(1).future);

      // Assert
      expect(count, 2);
      verify(mockGetStudentsByCourseUseCase.call(1)).called(1);
    });

    test('should return 0 when course has no students', () async {
      // Arrange
      when(mockGetStudentsByCourseUseCase.call(999))
          .thenAnswer((_) async => []);

      final container = ProviderContainer(
        overrides: [
          getStudentsByCourseUseCaseProvider
              .overrideWithValue(mockGetStudentsByCourseUseCase),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final count = await container.read(studentCountByCourseProvider(999).future);

      // Assert
      expect(count, 0);
    });

    test('should cache count for same course ID', () async {
      // Arrange
      final students = createTestStudents()
          .where((s) => s.courseId == 1)
          .toList();

      when(mockGetStudentsByCourseUseCase.call(1))
          .thenAnswer((_) async => students);

      final container = ProviderContainer(
        overrides: [
          getStudentsByCourseUseCaseProvider
              .overrideWithValue(mockGetStudentsByCourseUseCase),
        ],
      );
      addTearDown(container.dispose);

      // Act - Read twice
      final count1 = await container.read(studentCountByCourseProvider(1).future);
      final count2 = await container.read(studentCountByCourseProvider(1).future);

      // Assert - Should only call use case once (cached)
      expect(count1, 2);
      expect(count2, 2);
      verify(mockGetStudentsByCourseUseCase.call(1)).called(1);
    });

    test('should fetch separately for different course IDs', () async {
      // Arrange
      final students1 = createTestStudents()
          .where((s) => s.courseId == 1)
          .toList();
      final students2 = createTestStudents()
          .where((s) => s.courseId == 2)
          .toList();

      when(mockGetStudentsByCourseUseCase.call(1))
          .thenAnswer((_) async => students1);
      when(mockGetStudentsByCourseUseCase.call(2))
          .thenAnswer((_) async => students2);

      final container = ProviderContainer(
        overrides: [
          getStudentsByCourseUseCaseProvider
              .overrideWithValue(mockGetStudentsByCourseUseCase),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final count1 = await container.read(studentCountByCourseProvider(1).future);
      final count2 = await container.read(studentCountByCourseProvider(2).future);

      // Assert
      expect(count1, 2);
      expect(count2, 2);
      verify(mockGetStudentsByCourseUseCase.call(1)).called(1);
      verify(mockGetStudentsByCourseUseCase.call(2)).called(1);
    });
  });
}
