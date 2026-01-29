import 'package:eduportfolio/core/domain/entities/student.dart';
import 'package:eduportfolio/core/domain/repositories/student_repository.dart';
import 'package:eduportfolio/features/students/domain/usecases/create_student_usecase.dart';
import 'package:eduportfolio/features/students/domain/usecases/delete_student_usecase.dart';
import 'package:eduportfolio/features/students/domain/usecases/get_all_students_usecase.dart';
import 'package:eduportfolio/features/students/domain/usecases/get_student_by_id_usecase.dart';
import 'package:eduportfolio/features/students/domain/usecases/get_students_by_course_usecase.dart';
import 'package:eduportfolio/features/students/domain/usecases/update_student_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'student_usecases_test.mocks.dart';

@GenerateMocks([StudentRepository])
void main() {
  late MockStudentRepository mockRepository;

  setUp(() {
    mockRepository = MockStudentRepository();
  });

  group('GetAllStudentsUseCase', () {
    late GetAllStudentsUseCase useCase;

    setUp(() {
      useCase = GetAllStudentsUseCase(mockRepository);
    });

    test('should get all students ordered by name', () async {
      // Arrange
      final now = DateTime.now();
      final student1 = Student(
        id: 1,
        courseId: 1,
        name: 'Carlos García',
        createdAt: now,
        updatedAt: now,
      );
      final student2 = Student(
        id: 2,
        courseId: 1,
        name: 'Ana López',
        createdAt: now,
        updatedAt: now,
      );
      final student3 = Student(
        id: 3,
        courseId: 1,
        name: 'Beatriz Martínez',
        createdAt: now,
        updatedAt: now,
      );

      when(mockRepository.getAllStudents())
          .thenAnswer((_) async => [student1, student2, student3]);

      // Act
      final result = await useCase();

      // Assert
      expect(result.length, 3);
      // Should be ordered alphabetically by name
      expect(result[0].name, 'Ana López');
      expect(result[1].name, 'Beatriz Martínez');
      expect(result[2].name, 'Carlos García');
      verify(mockRepository.getAllStudents()).called(1);
    });

    test('should return empty list when no students', () async {
      // Arrange
      when(mockRepository.getAllStudents()).thenAnswer((_) async => []);

      // Act
      final result = await useCase();

      // Assert
      expect(result, isEmpty);
    });
  });

  group('GetStudentsByCourseUseCase', () {
    late GetStudentsByCourseUseCase useCase;

    setUp(() {
      useCase = GetStudentsByCourseUseCase(mockRepository);
    });

    test('should get students for specific course ordered by name', () async {
      // Arrange
      const courseId = 1;
      final now = DateTime.now();
      final student1 = Student(
        id: 1,
        courseId: courseId,
        name: 'Zoe Sánchez',
        createdAt: now,
        updatedAt: now,
      );
      final student2 = Student(
        id: 2,
        courseId: courseId,
        name: 'Alberto Ruiz',
        createdAt: now,
        updatedAt: now,
      );

      when(mockRepository.getStudentsByCourse(courseId))
          .thenAnswer((_) async => [student1, student2]);

      // Act
      final result = await useCase(courseId);

      // Assert
      expect(result.length, 2);
      // Should be ordered alphabetically by name
      expect(result[0].name, 'Alberto Ruiz');
      expect(result[1].name, 'Zoe Sánchez');
      verify(mockRepository.getStudentsByCourse(courseId)).called(1);
    });
  });

  group('GetStudentByIdUseCase', () {
    late GetStudentByIdUseCase useCase;

    setUp(() {
      useCase = GetStudentByIdUseCase(mockRepository);
    });

    test('should get student by ID', () async {
      // Arrange
      const studentId = 1;
      final student = Student(
        id: studentId,
        courseId: 1,
        name: 'Juan Pérez',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(mockRepository.getStudentById(studentId))
          .thenAnswer((_) async => student);

      // Act
      final result = await useCase(studentId);

      // Assert
      expect(result, student);
      verify(mockRepository.getStudentById(studentId)).called(1);
    });

    test('should return null when student not found', () async {
      // Arrange
      const studentId = 999;

      when(mockRepository.getStudentById(studentId))
          .thenAnswer((_) async => null);

      // Act
      final result = await useCase(studentId);

      // Assert
      expect(result, isNull);
    });
  });

  group('CreateStudentUseCase', () {
    late CreateStudentUseCase useCase;

    setUp(() {
      useCase = CreateStudentUseCase(mockRepository);
    });

    test('should create student with correct data and return ID', () async {
      // Arrange
      const courseId = 1;
      const name = 'María González';
      const newStudentId = 42;

      when(mockRepository.createStudent(any))
          .thenAnswer((_) async => newStudentId);

      // Act
      final result = await useCase(courseId: courseId, name: name);

      // Assert
      expect(result, newStudentId);

      // Verify the student was created with correct data
      final captured = verify(mockRepository.createStudent(captureAny))
          .captured
          .single as Student;

      expect(captured.courseId, courseId);
      expect(captured.name, name);
      expect(captured.id, isNull); // Should be null for new students
      expect(captured.faceEmbeddings, isNull); // No face data initially
      expect(captured.createdAt, isNotNull);
      expect(captured.updatedAt, isNotNull);
      // CreatedAt and updatedAt should be approximately now
      expect(
        captured.createdAt.difference(DateTime.now()).abs(),
        lessThan(const Duration(seconds: 1)),
      );
      expect(
        captured.updatedAt.difference(DateTime.now()).abs(),
        lessThan(const Duration(seconds: 1)),
      );
    });
  });

  group('UpdateStudentUseCase', () {
    late UpdateStudentUseCase useCase;

    setUp(() {
      useCase = UpdateStudentUseCase(mockRepository);
    });

    test('should update student with new data and updated timestamp',
        () async {
      // Arrange
      const studentId = 1;
      const courseId = 1;
      const newName = 'Juan Carlos Pérez';
      final createdAt = DateTime.now().subtract(const Duration(days: 7));

      when(mockRepository.updateStudent(any))
          .thenAnswer((_) async => Future<void>.value());

      // Act
      await useCase(
        id: studentId,
        courseId: courseId,
        name: newName,
        createdAt: createdAt,
      );

      // Assert
      final captured = verify(mockRepository.updateStudent(captureAny))
          .captured
          .single as Student;

      expect(captured.id, studentId);
      expect(captured.courseId, courseId);
      expect(captured.name, newName);
      expect(captured.createdAt, createdAt);
      // updatedAt should be approximately now
      expect(
        captured.updatedAt.difference(DateTime.now()).abs(),
        lessThan(const Duration(seconds: 1)),
      );
      // updatedAt should be after createdAt
      expect(captured.updatedAt.isAfter(captured.createdAt), isTrue);
    });
  });

  group('DeleteStudentUseCase', () {
    late DeleteStudentUseCase useCase;

    setUp(() {
      useCase = DeleteStudentUseCase(mockRepository);
    });

    test('should delete student by ID', () async {
      // Arrange
      const studentId = 1;

      when(mockRepository.deleteStudent(studentId))
          .thenAnswer((_) async => Future<void>.value());

      // Act
      await useCase(studentId);

      // Assert
      verify(mockRepository.deleteStudent(studentId)).called(1);
    });

    test('should propagate repository exceptions', () async {
      // Arrange
      const studentId = 999;
      final exception = Exception('Student not found');

      when(mockRepository.deleteStudent(studentId)).thenThrow(exception);

      // Act & Assert
      expect(
        () => useCase(studentId),
        throwsA(equals(exception)),
      );
    });
  });
}
