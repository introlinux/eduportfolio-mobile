import 'package:eduportfolio/core/domain/entities/course.dart';
import 'package:eduportfolio/core/domain/repositories/course_repository.dart';
import 'package:eduportfolio/features/courses/domain/usecases/archive_course_usecase.dart';
import 'package:eduportfolio/features/courses/domain/usecases/create_course_usecase.dart';
import 'package:eduportfolio/features/courses/domain/usecases/get_active_course_usecase.dart';
import 'package:eduportfolio/features/courses/domain/usecases/get_all_courses_usecase.dart';
import 'package:eduportfolio/features/courses/domain/usecases/set_active_course_usecase.dart';
import 'package:eduportfolio/features/courses/domain/usecases/update_course_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'course_usecases_test.mocks.dart';

@GenerateMocks([CourseRepository])
void main() {
  late MockCourseRepository mockRepository;

  setUp(() {
    mockRepository = MockCourseRepository();
  });

  group('GetAllCoursesUseCase', () {
    late GetAllCoursesUseCase useCase;

    setUp(() {
      useCase = GetAllCoursesUseCase(mockRepository);
    });

    test('should get all courses ordered by start date desc', () async {
      // Arrange
      final now = DateTime.now();
      final course1 = Course(
        id: 1,
        name: 'Curso 2022-23',
        startDate: now.subtract(const Duration(days: 730)),
        isActive: false,
        createdAt: now.subtract(const Duration(days: 730)),
      );
      final course2 = Course(
        id: 2,
        name: 'Curso 2023-24',
        startDate: now.subtract(const Duration(days: 365)),
        isActive: false,
        createdAt: now.subtract(const Duration(days: 365)),
      );
      final course3 = Course(
        id: 3,
        name: 'Curso 2024-25',
        startDate: now,
        isActive: true,
        createdAt: now,
      );

      when(mockRepository.getAllCourses())
          .thenAnswer((_) async => [course1, course2, course3]);

      // Act
      final result = await useCase();

      // Assert
      expect(result.length, 3);
      // Should be ordered newest first (by start date)
      expect(result[0].name, 'Curso 2024-25');
      expect(result[1].name, 'Curso 2023-24');
      expect(result[2].name, 'Curso 2022-23');
      verify(mockRepository.getAllCourses()).called(1);
    });

    test('should return empty list when no courses', () async {
      // Arrange
      when(mockRepository.getAllCourses()).thenAnswer((_) async => []);

      // Act
      final result = await useCase();

      // Assert
      expect(result, isEmpty);
    });
  });

  group('GetActiveCourseUseCase', () {
    late GetActiveCourseUseCase useCase;

    setUp(() {
      useCase = GetActiveCourseUseCase(mockRepository);
    });

    test('should get active course', () async {
      // Arrange
      final now = DateTime.now();
      final activeCourse = Course(
        id: 1,
        name: 'Curso 2024-25',
        startDate: now,
        isActive: true,
        createdAt: now,
      );

      when(mockRepository.getActiveCourse())
          .thenAnswer((_) async => activeCourse);

      // Act
      final result = await useCase();

      // Assert
      expect(result, activeCourse);
      expect(result?.isActive, isTrue);
      verify(mockRepository.getActiveCourse()).called(1);
    });

    test('should return null when no active course', () async {
      // Arrange
      when(mockRepository.getActiveCourse()).thenAnswer((_) async => null);

      // Act
      final result = await useCase();

      // Assert
      expect(result, isNull);
    });
  });

  group('CreateCourseUseCase', () {
    late CreateCourseUseCase useCase;

    setUp(() {
      useCase = CreateCourseUseCase(mockRepository);
    });

    test('should create course with setAsActive true by default', () async {
      // Arrange
      const name = 'Curso 2024-25';
      final startDate = DateTime(2024, 9, 1);
      const newCourseId = 42;

      when(mockRepository.createCourse(any))
          .thenAnswer((_) async => newCourseId);

      // Act
      final result = await useCase(name: name, startDate: startDate);

      // Assert
      expect(result, newCourseId);

      final captured = verify(mockRepository.createCourse(captureAny))
          .captured
          .single as Course;

      expect(captured.name, name);
      expect(captured.startDate, startDate);
      expect(captured.isActive, isTrue); // Default is true
      expect(captured.id, isNull); // Should be null for new courses
      expect(captured.endDate, isNull);
    });

    test('should create course with setAsActive false when specified',
        () async {
      // Arrange
      const name = 'Curso 2023-24';
      final startDate = DateTime(2023, 9, 1);

      when(mockRepository.createCourse(any)).thenAnswer((_) async => 1);

      // Act
      await useCase(
        name: name,
        startDate: startDate,
        setAsActive: false,
      );

      // Assert
      final captured = verify(mockRepository.createCourse(captureAny))
          .captured
          .single as Course;

      expect(captured.isActive, isFalse);
    });
  });

  group('UpdateCourseUseCase', () {
    late UpdateCourseUseCase useCase;

    setUp(() {
      useCase = UpdateCourseUseCase(mockRepository);
    });

    test('should update course with new data', () async {
      // Arrange
      const courseId = 1;
      const newName = 'Curso 2024-25 (Actualizado)';
      final startDate = DateTime(2024, 9, 1);
      final createdAt = DateTime.now().subtract(const Duration(days: 30));

      when(mockRepository.updateCourse(any))
          .thenAnswer((_) async => Future<void>.value());

      // Act
      await useCase(
        id: courseId,
        name: newName,
        startDate: startDate,
        createdAt: createdAt,
        isActive: true,
      );

      // Assert
      final captured = verify(mockRepository.updateCourse(captureAny))
          .captured
          .single as Course;

      expect(captured.id, courseId);
      expect(captured.name, newName);
      expect(captured.startDate, startDate);
      expect(captured.createdAt, createdAt);
      expect(captured.isActive, isTrue);
    });
  });

  group('ArchiveCourseUseCase', () {
    late ArchiveCourseUseCase useCase;

    setUp(() {
      useCase = ArchiveCourseUseCase(mockRepository);
    });

    test('should archive course with specified end date', () async {
      // Arrange
      const courseId = 1;
      final endDate = DateTime(2024, 6, 30);

      when(mockRepository.archiveCourse(courseId, endDate))
          .thenAnswer((_) async => Future<void>.value());

      // Act
      await useCase(courseId, endDate: endDate);

      // Assert
      verify(mockRepository.archiveCourse(courseId, endDate)).called(1);
    });

    test('should archive course with current date when not specified',
        () async {
      // Arrange
      const courseId = 1;

      when(mockRepository.archiveCourse(any, any))
          .thenAnswer((_) async => Future<void>.value());

      // Act
      await useCase(courseId);

      // Assert
      final captured = verify(mockRepository.archiveCourse(courseId, captureAny))
          .captured
          .single as DateTime;

      // Should be approximately now
      expect(
        captured.difference(DateTime.now()).abs(),
        lessThan(const Duration(seconds: 1)),
      );
    });
  });

  group('SetActiveCourseUseCase', () {
    late SetActiveCourseUseCase useCase;

    setUp(() {
      useCase = SetActiveCourseUseCase(mockRepository);
    });

    test('should activate course and deactivate others', () async {
      // Arrange
      const targetCourseId = 2;
      final now = DateTime.now();

      final course1 = Course(
        id: 1,
        name: 'Curso 2023-24',
        startDate: now.subtract(const Duration(days: 365)),
        isActive: true, // Currently active
        createdAt: now.subtract(const Duration(days: 365)),
      );

      final course2 = Course(
        id: 2,
        name: 'Curso 2024-25',
        startDate: now,
        isActive: false, // To be activated
        createdAt: now,
      );

      when(mockRepository.getCourseById(targetCourseId))
          .thenAnswer((_) async => course2);
      when(mockRepository.getAllCourses())
          .thenAnswer((_) async => [course1, course2]);
      when(mockRepository.updateCourse(any))
          .thenAnswer((_) async => Future<void>.value());

      // Act
      await useCase(targetCourseId);

      // Assert
      // Should have been called twice: once to deactivate course1, once to activate course2
      verify(mockRepository.updateCourse(any)).called(2);

      // Verify course1 was deactivated
      final deactivateCall = verify(mockRepository.updateCourse(captureAny))
          .captured
          .first as Course;
      expect(deactivateCall.id, 1);
      expect(deactivateCall.isActive, isFalse);

      // Verify course2 was activated
      final activateCall = verify(mockRepository.updateCourse(captureAny))
          .captured
          .last as Course;
      expect(activateCall.id, 2);
      expect(activateCall.isActive, isTrue);
    });

    test('should throw exception when course not found', () async {
      // Arrange
      const courseId = 999;

      when(mockRepository.getCourseById(courseId))
          .thenAnswer((_) async => null);

      // Act & Assert
      expect(
        () => useCase(courseId),
        throwsA(isA<Exception>()),
      );
    });

    test('should only activate target course if no others are active',
        () async {
      // Arrange
      const targetCourseId = 1;
      final now = DateTime.now();

      final course1 = Course(
        id: 1,
        name: 'Curso 2024-25',
        startDate: now,
        isActive: false,
        createdAt: now,
      );

      when(mockRepository.getCourseById(targetCourseId))
          .thenAnswer((_) async => course1);
      when(mockRepository.getAllCourses())
          .thenAnswer((_) async => [course1]);
      when(mockRepository.updateCourse(any))
          .thenAnswer((_) async => Future<void>.value());

      // Act
      await useCase(targetCourseId);

      // Assert
      // Should only be called once to activate the target course
      verify(mockRepository.updateCourse(any)).called(1);
    });
  });
}
