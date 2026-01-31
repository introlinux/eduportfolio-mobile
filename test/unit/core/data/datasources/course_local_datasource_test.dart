import 'package:eduportfolio/core/data/datasources/course_local_datasource.dart';
import 'package:eduportfolio/core/data/models/course_model.dart';
import 'package:eduportfolio/core/database/database_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../helpers/database_test_helper.dart';

// Generate mocks
@GenerateMocks([DatabaseHelper])
import 'course_local_datasource_test.mocks.dart';

void main() {
  late Database testDb;
  late MockDatabaseHelper mockDatabaseHelper;
  late CourseLocalDataSource dataSource;
  late TestDataHelper testDataHelper;

  setUpAll(() {
    // Inicializar sqflite FFI para tests
    setupDatabaseForTests();
  });

  setUp(() async {
    // Crear base de datos de prueba en memoria
    testDb = await createTestDatabase();
    testDataHelper = TestDataHelper(testDb);

    // Configurar mock del DatabaseHelper
    mockDatabaseHelper = MockDatabaseHelper();
    when(mockDatabaseHelper.database).thenAnswer((_) async => testDb);

    // Crear datasource con el mock
    dataSource = CourseLocalDataSource(mockDatabaseHelper);
  });

  tearDown(() async {
    await closeTestDatabase(testDb);
  });

  group('CourseLocalDataSource - getAllCourses', () {
    test('should return all courses ordered by start_date DESC', () async {
      // Arrange - crear cursos con diferentes fechas de inicio
      final oldDate = DateTime(2022, 9, 1);
      final middleDate = DateTime(2023, 9, 1);
      final recentDate = DateTime(2024, 9, 1);

      final oldCourseId = await testDataHelper.insertTestCourse(
        name: 'Old Course',
        startDate: oldDate,
        isActive: false,
      );

      final recentCourseId = await testDataHelper.insertTestCourse(
        name: 'Recent Course',
        startDate: recentDate,
        isActive: true,
      );

      final middleCourseId = await testDataHelper.insertTestCourse(
        name: 'Middle Course',
        startDate: middleDate,
        isActive: false,
      );

      // Act
      final result = await dataSource.getAllCourses();

      // Assert
      expect(result, hasLength(3));
      expect(result[0].id, equals(recentCourseId)); // Más reciente primero
      expect(result[1].id, equals(middleCourseId));
      expect(result[2].id, equals(oldCourseId));
    });

    test('should return empty list when no courses exist', () async {
      // Act
      final result = await dataSource.getAllCourses();

      // Assert
      expect(result, isEmpty);
    });

    test('should return CourseModel instances', () async {
      // Arrange
      await testDataHelper.insertTestCourse(name: 'Test Course');

      // Act
      final result = await dataSource.getAllCourses();

      // Assert
      expect(result, isNotEmpty);
      expect(result.first, isA<CourseModel>());
    });
  });

  group('CourseLocalDataSource - getActiveCourse', () {
    test('should return the active course', () async {
      // Arrange - crear varios cursos, solo uno activo
      await testDataHelper.insertTestCourse(
        name: 'Inactive Course 1',
        isActive: false,
      );

      final activeCourseId = await testDataHelper.insertTestCourse(
        name: 'Active Course',
        isActive: true,
      );

      await testDataHelper.insertTestCourse(
        name: 'Inactive Course 2',
        isActive: false,
      );

      // Act
      final result = await dataSource.getActiveCourse();

      // Assert
      expect(result, isNotNull);
      expect(result!.id, equals(activeCourseId));
      expect(result.name, equals('Active Course'));
      expect(result.isActive, isTrue);
    });

    test('should return null when no active course exists', () async {
      // Arrange - solo cursos inactivos
      await testDataHelper.insertTestCourse(
        name: 'Inactive Course',
        isActive: false,
      );

      // Act
      final result = await dataSource.getActiveCourse();

      // Assert
      expect(result, isNull);
    });

    test('should return null when no courses exist', () async {
      // Act
      final result = await dataSource.getActiveCourse();

      // Assert
      expect(result, isNull);
    });
  });

  group('CourseLocalDataSource - getCourseById', () {
    test('should return course when ID exists', () async {
      // Arrange
      final startDate = DateTime(2024, 9, 1);
      final courseId = await testDataHelper.insertTestCourse(
        name: 'Test Course',
        startDate: startDate,
        isActive: true,
      );

      // Act
      final result = await dataSource.getCourseById(courseId);

      // Assert
      expect(result, isNotNull);
      expect(result!.id, equals(courseId));
      expect(result.name, equals('Test Course'));
      expect(result.isActive, isTrue);
    });

    test('should return null when ID does not exist', () async {
      // Act
      final result = await dataSource.getCourseById(9999);

      // Assert
      expect(result, isNull);
    });
  });

  group('CourseLocalDataSource - insertCourse', () {
    test('should insert course and return generated ID', () async {
      // Arrange
      final now = DateTime.now();
      final startDate = DateTime(2024, 9, 1);

      final course = CourseModel(
        name: 'New Course',
        startDate: startDate,
        isActive: false,
        createdAt: now,
      );

      // Act
      final insertedId = await dataSource.insertCourse(course);

      // Assert
      expect(insertedId, greaterThan(0));

      // Verificar que se insertó correctamente
      final inserted = await dataSource.getCourseById(insertedId);
      expect(inserted, isNotNull);
      expect(inserted!.name, equals('New Course'));
      expect(inserted.isActive, isFalse);
    });

    test('should deactivate other courses when inserting active course',
        () async {
      // Arrange - crear un curso activo existente
      final existingActiveCourseId = await testDataHelper.insertTestCourse(
        name: 'Existing Active',
        isActive: true,
      );

      // Verificar que está activo
      final beforeInsert = await dataSource.getCourseById(existingActiveCourseId);
      expect(beforeInsert!.isActive, isTrue);

      // Crear un nuevo curso activo
      final newActiveCourse = CourseModel(
        name: 'New Active Course',
        startDate: DateTime(2024, 9, 1),
        isActive: true,
        createdAt: DateTime.now(),
      );

      // Act - insertar el nuevo curso activo
      final newActiveCourseId = await dataSource.insertCourse(newActiveCourse);

      // Assert
      // El nuevo curso debe estar activo
      final newCourse = await dataSource.getCourseById(newActiveCourseId);
      expect(newCourse!.isActive, isTrue);

      // El curso anteriormente activo debe estar desactivado
      final oldCourse = await dataSource.getCourseById(existingActiveCourseId);
      expect(oldCourse!.isActive, isFalse);

      // Solo debe haber un curso activo
      final activeCourse = await dataSource.getActiveCourse();
      expect(activeCourse!.id, equals(newActiveCourseId));
    });

    test('should not deactivate other courses when inserting inactive course',
        () async {
      // Arrange - crear un curso activo existente
      final activeCourseId = await testDataHelper.insertTestCourse(
        name: 'Active Course',
        isActive: true,
      );

      // Crear un nuevo curso inactivo
      final inactiveCourse = CourseModel(
        name: 'Inactive Course',
        startDate: DateTime(2024, 9, 1),
        isActive: false,
        createdAt: DateTime.now(),
      );

      // Act - insertar el nuevo curso inactivo
      await dataSource.insertCourse(inactiveCourse);

      // Assert - el curso activo original debe seguir activo
      final stillActive = await dataSource.getCourseById(activeCourseId);
      expect(stillActive!.isActive, isTrue);
    });

    test('should insert course with end_date', () async {
      // Arrange
      final startDate = DateTime(2023, 9, 1);
      final endDate = DateTime(2024, 6, 30);

      final course = CourseModel(
        name: 'Completed Course',
        startDate: startDate,
        endDate: endDate,
        isActive: false,
        createdAt: DateTime.now(),
      );

      // Act
      final insertedId = await dataSource.insertCourse(course);

      // Assert
      final inserted = await dataSource.getCourseById(insertedId);
      expect(inserted, isNotNull);
      expect(inserted!.endDate, isNotNull);
      expect(
        inserted.endDate!.year,
        equals(2024),
      );
    });
  });

  group('CourseLocalDataSource - updateCourse', () {
    test('should update course fields correctly', () async {
      // Arrange
      final courseId = await testDataHelper.insertTestCourse(
        name: 'Original Name',
        startDate: DateTime(2023, 9, 1),
        isActive: false,
      );

      final original = await dataSource.getCourseById(courseId);
      expect(original, isNotNull);

      // Crear modelo actualizado
      final newStartDate = DateTime(2024, 9, 1);
      final updated = CourseModel(
        id: courseId,
        name: 'Updated Name',
        startDate: newStartDate,
        isActive: false,
        createdAt: original!.createdAt,
      );

      // Act
      final rowsAffected = await dataSource.updateCourse(updated);

      // Assert
      expect(rowsAffected, equals(1));

      final result = await dataSource.getCourseById(courseId);
      expect(result!.name, equals('Updated Name'));
      expect(result.startDate.year, equals(2024));
    });

    test('should deactivate other courses when activating a course', () async {
      // Arrange - crear dos cursos inactivos
      final course1Id = await testDataHelper.insertTestCourse(
        name: 'Course 1',
        isActive: true, // Este está activo
      );

      final course2Id = await testDataHelper.insertTestCourse(
        name: 'Course 2',
        isActive: false,
      );

      // Verificar estado inicial
      final course1Before = await dataSource.getCourseById(course1Id);
      expect(course1Before!.isActive, isTrue);

      // Activar el curso 2
      final course2 = await dataSource.getCourseById(course2Id);
      final updated = CourseModel(
        id: course2!.id,
        name: course2.name,
        startDate: course2.startDate,
        isActive: true, // Activar este curso
        createdAt: course2.createdAt,
      );

      // Act
      await dataSource.updateCourse(updated);

      // Assert
      // Curso 2 debe estar activo
      final course2After = await dataSource.getCourseById(course2Id);
      expect(course2After!.isActive, isTrue);

      // Curso 1 debe estar desactivado
      final course1After = await dataSource.getCourseById(course1Id);
      expect(course1After!.isActive, isFalse);

      // Solo debe haber un curso activo
      final activeCourse = await dataSource.getActiveCourse();
      expect(activeCourse!.id, equals(course2Id));
    });

    test('should not affect other courses when updating inactive course',
        () async {
      // Arrange
      final activeCourseId = await testDataHelper.insertTestCourse(
        name: 'Active Course',
        isActive: true,
      );

      final inactiveCourseId = await testDataHelper.insertTestCourse(
        name: 'Inactive Course',
        isActive: false,
      );

      // Actualizar el curso inactivo (pero mantenerlo inactivo)
      final inactiveCourse = await dataSource.getCourseById(inactiveCourseId);
      final updated = CourseModel(
        id: inactiveCourse!.id,
        name: 'Updated Inactive Course',
        startDate: inactiveCourse.startDate,
        isActive: false,
        createdAt: inactiveCourse.createdAt,
      );

      // Act
      await dataSource.updateCourse(updated);

      // Assert - el curso activo debe seguir activo
      final stillActive = await dataSource.getCourseById(activeCourseId);
      expect(stillActive!.isActive, isTrue);
    });
  });

  group('CourseLocalDataSource - deleteCourse', () {
    test('should delete course by ID', () async {
      // Arrange
      final courseId = await testDataHelper.insertTestCourse(
        name: 'Course to Delete',
      );

      // Verificar que existe
      final beforeDelete = await dataSource.getCourseById(courseId);
      expect(beforeDelete, isNotNull);

      // Act
      final rowsAffected = await dataSource.deleteCourse(courseId);

      // Assert
      expect(rowsAffected, equals(1));

      final afterDelete = await dataSource.getCourseById(courseId);
      expect(afterDelete, isNull);
    });

    test('should return 0 when deleting non-existent course', () async {
      // Act
      final rowsAffected = await dataSource.deleteCourse(9999);

      // Assert
      expect(rowsAffected, equals(0));
    });
  });

  group('CourseLocalDataSource - archiveCourse', () {
    test('should set end_date and deactivate course', () async {
      // Arrange
      final courseId = await testDataHelper.insertTestCourse(
        name: 'Course to Archive',
        isActive: true,
      );

      // Verificar estado inicial
      final beforeArchive = await dataSource.getCourseById(courseId);
      expect(beforeArchive!.isActive, isTrue);
      expect(beforeArchive.endDate, isNull);

      // Act
      final endDate = DateTime(2024, 6, 30);
      final rowsAffected = await dataSource.archiveCourse(courseId, endDate);

      // Assert
      expect(rowsAffected, equals(1));

      final afterArchive = await dataSource.getCourseById(courseId);
      expect(afterArchive!.isActive, isFalse);
      expect(afterArchive.endDate, isNotNull);
      expect(afterArchive.endDate!.year, equals(2024));
      expect(afterArchive.endDate!.month, equals(6));
    });

    test('should return 0 when archiving non-existent course', () async {
      // Act
      final rowsAffected = await dataSource.archiveCourse(
        9999,
        DateTime.now(),
      );

      // Assert
      expect(rowsAffected, equals(0));
    });
  });

  group('CourseLocalDataSource - countCourses', () {
    test('should return total count of courses', () async {
      // Arrange
      await testDataHelper.insertTestCourse(name: 'Course 1');
      await testDataHelper.insertTestCourse(name: 'Course 2');
      await testDataHelper.insertTestCourse(name: 'Course 3');

      // Act
      final count = await dataSource.countCourses();

      // Assert
      expect(count, equals(3));
    });

    test('should return 0 when no courses exist', () async {
      // Act
      final count = await dataSource.countCourses();

      // Assert
      expect(count, equals(0));
    });

    test('should count both active and inactive courses', () async {
      // Arrange
      await testDataHelper.insertTestCourse(name: 'Active', isActive: true);
      await testDataHelper.insertTestCourse(name: 'Inactive 1', isActive: false);
      await testDataHelper.insertTestCourse(name: 'Inactive 2', isActive: false);

      // Act
      final count = await dataSource.countCourses();

      // Assert
      expect(count, equals(3));
    });
  });
}
