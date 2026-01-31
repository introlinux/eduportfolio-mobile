import 'package:eduportfolio/core/data/datasources/subject_local_datasource.dart';
import 'package:eduportfolio/core/data/models/subject_model.dart';
import 'package:eduportfolio/core/database/database_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../helpers/database_test_helper.dart';

// Generate mocks
@GenerateMocks([DatabaseHelper])
import 'subject_local_datasource_test.mocks.dart';

void main() {
  late Database testDb;
  late MockDatabaseHelper mockDatabaseHelper;
  late SubjectLocalDataSource dataSource;
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
    dataSource = SubjectLocalDataSource(mockDatabaseHelper);
  });

  tearDown(() async {
    await closeTestDatabase(testDb);
  });

  group('SubjectLocalDataSource - getAllSubjects', () {
    test('should return all subjects ordered by name ASC', () async {
      // Arrange - la base de datos ya tiene 9 asignaturas por defecto
      // Añadimos algunas más para verificar el orden
      await testDataHelper.insertTestSubject(name: 'Zebra Subject');
      await testDataHelper.insertTestSubject(name: 'Alpha Subject');

      // Act
      final result = await dataSource.getAllSubjects();

      // Assert
      expect(result.length, greaterThan(9)); // Al menos las 9 por defecto + 2 nuevas

      // Verificar orden alfabético
      for (int i = 0; i < result.length - 1; i++) {
        expect(
          result[i].name.toLowerCase().compareTo(result[i + 1].name.toLowerCase()),
          lessThanOrEqualTo(0),
          reason: '${result[i].name} should come before ${result[i + 1].name}',
        );
      }
    });

    test('should return SubjectModel instances', () async {
      // Act
      final result = await dataSource.getAllSubjects();

      // Assert
      expect(result, isNotEmpty);
      expect(result.first, isA<SubjectModel>());
    });

    test('should include default subjects', () async {
      // Act
      final result = await dataSource.getAllSubjects();

      // Assert - verificar que existen las asignaturas por defecto
      final subjectNames = result.map((s) => s.name).toList();
      expect(subjectNames, contains('Sin asignar'));
      expect(subjectNames, contains('Matemáticas'));
      expect(subjectNames, contains('Lengua'));
    });
  });

  group('SubjectLocalDataSource - getDefaultSubjects', () {
    test('should return only subjects with is_default = 1', () async {
      // Arrange - añadir una asignatura personalizada (no default)
      await testDataHelper.insertTestSubject(
        name: 'Custom Subject',
        isDefault: false,
      );

      // Act
      final result = await dataSource.getDefaultSubjects();

      // Assert
      expect(result, hasLength(9)); // Solo las 9 por defecto
      expect(result.every((s) => s.isDefault), isTrue);
      expect(result.any((s) => s.name == 'Custom Subject'), isFalse);
    });

    test('should order by name ASC', () async {
      // Act
      final result = await dataSource.getDefaultSubjects();

      // Assert - verificar orden alfabético
      for (int i = 0; i < result.length - 1; i++) {
        expect(
          result[i].name.toLowerCase().compareTo(result[i + 1].name.toLowerCase()),
          lessThanOrEqualTo(0),
        );
      }
    });

    test('should return empty list if no default subjects exist', () async {
      // Arrange - eliminar todas las asignaturas por defecto
      await testDb.delete('subjects', where: 'is_default = ?', whereArgs: [1]);

      // Act
      final result = await dataSource.getDefaultSubjects();

      // Assert
      expect(result, isEmpty);
    });
  });

  group('SubjectLocalDataSource - getSubjectById', () {
    test('should return subject when ID exists', () async {
      // Arrange
      final subjectId = await testDataHelper.insertTestSubject(
        name: 'Test Subject',
        color: 'FF0000FF',
        icon: 'star',
      );

      // Act
      final result = await dataSource.getSubjectById(subjectId);

      // Assert
      expect(result, isNotNull);
      expect(result!.id, equals(subjectId));
      expect(result.name, equals('Test Subject'));
      expect(result.color, equals('FF0000FF'));
      expect(result.icon, equals('star'));
    });

    test('should return null when ID does not exist', () async {
      // Act
      final result = await dataSource.getSubjectById(9999);

      // Assert
      expect(result, isNull);
    });
  });

  group('SubjectLocalDataSource - getSubjectByName', () {
    test('should return subject when name exists', () async {
      // Arrange
      await testDataHelper.insertTestSubject(
        name: 'Unique Subject Name',
        color: 'FF00FF00',
      );

      // Act
      final result = await dataSource.getSubjectByName('Unique Subject Name');

      // Assert
      expect(result, isNotNull);
      expect(result!.name, equals('Unique Subject Name'));
      expect(result.color, equals('FF00FF00'));
    });

    test('should return null when name does not exist', () async {
      // Act
      final result = await dataSource.getSubjectByName('Non-existent Subject');

      // Assert
      expect(result, isNull);
    });

    test('should be case-sensitive', () async {
      // Arrange
      await testDataHelper.insertTestSubject(name: 'TestSubject');

      // Act
      final result = await dataSource.getSubjectByName('testsubject');

      // Assert
      expect(result, isNull); // SQLite es case-sensitive por defecto para LIKE
    });
  });

  group('SubjectLocalDataSource - insertSubject', () {
    test('should insert subject and return generated ID', () async {
      // Arrange
      final now = DateTime.now();
      final subject = SubjectModel(
        name: 'New Subject',
        color: 'FFFF0000',
        icon: 'bookmark',
        isDefault: false,
        createdAt: now,
      );

      // Act
      final insertedId = await dataSource.insertSubject(subject);

      // Assert
      expect(insertedId, greaterThan(0));

      // Verificar que se insertó correctamente
      final inserted = await dataSource.getSubjectById(insertedId);
      expect(inserted, isNotNull);
      expect(inserted!.name, equals('New Subject'));
      expect(inserted.color, equals('FFFF0000'));
      expect(inserted.icon, equals('bookmark'));
      expect(inserted.isDefault, isFalse);
    });

    test('should insert subject with minimal fields', () async {
      // Arrange - solo campos requeridos
      final subject = SubjectModel(
        name: 'Minimal Subject',
        isDefault: false,
        createdAt: DateTime.now(),
      );

      // Act
      final insertedId = await dataSource.insertSubject(subject);

      // Assert
      final inserted = await dataSource.getSubjectById(insertedId);
      expect(inserted, isNotNull);
      expect(inserted!.name, equals('Minimal Subject'));
      expect(inserted.color, isNull);
      expect(inserted.icon, isNull);
    });

    test('should replace on conflict (unique name constraint)', () async {
      // Arrange - insertar una asignatura
      final subject1 = SubjectModel(
        name: 'Duplicate Name',
        color: 'FF000000',
        isDefault: false,
        createdAt: DateTime.now(),
      );

      final id1 = await dataSource.insertSubject(subject1);

      // Insertar otra con el mismo nombre (debería reemplazar)
      final subject2 = SubjectModel(
        name: 'Duplicate Name',
        color: 'FFFFFFFF',
        isDefault: false,
        createdAt: DateTime.now(),
      );

      // Act
      final id2 = await dataSource.insertSubject(subject2);

      // Assert - REPLACE en SQLite elimina y reinserta, por lo que el ID cambia
      expect(id2, greaterThan(id1));

      // Verificar que la antigua ya no existe
      final oldResult = await dataSource.getSubjectById(id1);
      expect(oldResult, isNull);

      // Verificar que la nueva existe con los valores actualizados
      final newResult = await dataSource.getSubjectById(id2);
      expect(newResult, isNotNull);
      expect(newResult!.name, equals('Duplicate Name'));
      expect(newResult.color, equals('FFFFFFFF')); // Color actualizado

      // Verificar que solo hay una asignatura con ese nombre
      final byName = await dataSource.getSubjectByName('Duplicate Name');
      expect(byName!.id, equals(id2));
    });
  });

  group('SubjectLocalDataSource - updateSubject', () {
    test('should update subject fields correctly', () async {
      // Arrange
      final subjectId = await testDataHelper.insertTestSubject(
        name: 'Original Name',
        color: 'FF000000',
        icon: 'old_icon',
      );

      final original = await dataSource.getSubjectById(subjectId);
      expect(original, isNotNull);

      // Crear modelo actualizado
      final updated = SubjectModel(
        id: subjectId,
        name: 'Updated Name',
        color: 'FFFFFFFF',
        icon: 'new_icon',
        isDefault: false,
        createdAt: original!.createdAt,
      );

      // Act
      final rowsAffected = await dataSource.updateSubject(updated);

      // Assert
      expect(rowsAffected, equals(1));

      final result = await dataSource.getSubjectById(subjectId);
      expect(result!.name, equals('Updated Name'));
      expect(result.color, equals('FFFFFFFF'));
      expect(result.icon, equals('new_icon'));
    });

    test('should return 0 when updating non-existent subject', () async {
      // Arrange
      final subject = SubjectModel(
        id: 9999,
        name: 'Non-existent',
        isDefault: false,
        createdAt: DateTime.now(),
      );

      // Act
      final rowsAffected = await dataSource.updateSubject(subject);

      // Assert
      expect(rowsAffected, equals(0));
    });
  });

  group('SubjectLocalDataSource - deleteSubject', () {
    test('should delete subject when no evidences are associated', () async {
      // Arrange
      final subjectId = await testDataHelper.insertTestSubject(
        name: 'Subject to Delete',
      );

      // Verificar que existe
      final beforeDelete = await dataSource.getSubjectById(subjectId);
      expect(beforeDelete, isNotNull);

      // Act
      final rowsAffected = await dataSource.deleteSubject(subjectId);

      // Assert
      expect(rowsAffected, equals(1));

      final afterDelete = await dataSource.getSubjectById(subjectId);
      expect(afterDelete, isNull);
    });

    test('should return 0 when deleting non-existent subject', () async {
      // Act
      final rowsAffected = await dataSource.deleteSubject(9999);

      // Assert
      expect(rowsAffected, equals(0));
    });

    test(
        'should reassign evidences to "Sin asignar" and mark as not reviewed when deleting subject with evidences',
        () async {
      // Arrange
      final courseId = await testDataHelper.insertTestCourse();
      final studentId = await testDataHelper.insertTestStudent(
        courseId: courseId,
      );

      // Crear una asignatura personalizada
      final customSubjectId = await testDataHelper.insertTestSubject(
        name: 'Custom Subject',
        color: 'FFAABBCC',
      );

      // Crear evidencias asignadas a la asignatura personalizada
      final evidence1Id = await testDataHelper.insertTestEvidence(
        studentId: studentId,
        subjectId: customSubjectId,
        isReviewed: true, // Revisada
        filePath: '/path/evidence1.jpg',
      );

      final evidence2Id = await testDataHelper.insertTestEvidence(
        studentId: studentId,
        subjectId: customSubjectId,
        isReviewed: true, // Revisada
        filePath: '/path/evidence2.jpg',
      );

      // Verificar estado antes de eliminar
      final beforeEvidence1 = await testDb.query(
        'evidences',
        where: 'id = ?',
        whereArgs: [evidence1Id],
      );
      expect(beforeEvidence1.first['subject_id'], equals(customSubjectId));
      expect(beforeEvidence1.first['is_reviewed'], equals(1));

      // Act - eliminar la asignatura
      final rowsAffected = await dataSource.deleteSubject(customSubjectId);

      // Assert
      expect(rowsAffected, equals(1));

      // Verificar que la asignatura se eliminó
      final deletedSubject = await dataSource.getSubjectById(customSubjectId);
      expect(deletedSubject, isNull);

      // Verificar que las evidencias se reasignaron a "Sin asignar"
      final sinAsignarSubject = await dataSource.getSubjectByName('Sin asignar');
      expect(sinAsignarSubject, isNotNull);

      final afterEvidence1 = await testDb.query(
        'evidences',
        where: 'id = ?',
        whereArgs: [evidence1Id],
      );
      expect(afterEvidence1.first['subject_id'], equals(sinAsignarSubject!.id));
      expect(afterEvidence1.first['is_reviewed'], equals(0)); // Marcada como no revisada

      final afterEvidence2 = await testDb.query(
        'evidences',
        where: 'id = ?',
        whereArgs: [evidence2Id],
      );
      expect(afterEvidence2.first['subject_id'], equals(sinAsignarSubject.id));
      expect(afterEvidence2.first['is_reviewed'], equals(0));
    });

    test(
        'should create "Sin asignar" subject if it does not exist when deleting subject with evidences',
        () async {
      // Arrange
      final courseId = await testDataHelper.insertTestCourse();
      final studentId = await testDataHelper.insertTestStudent(
        courseId: courseId,
      );

      // Eliminar "Sin asignar" si existe
      await testDb.delete('subjects', where: 'name = ?', whereArgs: ['Sin asignar']);

      // Crear asignatura personalizada con evidencias
      final customSubjectId = await testDataHelper.insertTestSubject(
        name: 'Custom Subject',
      );

      await testDataHelper.insertTestEvidence(
        studentId: studentId,
        subjectId: customSubjectId,
        filePath: '/path/evidence.jpg',
      );

      // Verificar que "Sin asignar" no existe
      final beforeDelete = await dataSource.getSubjectByName('Sin asignar');
      expect(beforeDelete, isNull);

      // Act - eliminar la asignatura
      await dataSource.deleteSubject(customSubjectId);

      // Assert - "Sin asignar" debe haberse creado
      final afterDelete = await dataSource.getSubjectByName('Sin asignar');
      expect(afterDelete, isNotNull);
      expect(afterDelete!.name, equals('Sin asignar'));
      expect(afterDelete.color, equals('0xFF9E9E9E'));
      expect(afterDelete.icon, equals('help_outline'));
      expect(afterDelete.isDefault, isFalse); // Se crea como no-default
    });
  });

  group('SubjectLocalDataSource - countSubjects', () {
    test('should return total count of subjects', () async {
      // Act - ya hay 9 asignaturas por defecto
      final count = await dataSource.countSubjects();

      // Assert
      expect(count, equals(9));
    });

    test('should update count when subjects are added', () async {
      // Arrange
      await testDataHelper.insertTestSubject(name: 'New Subject 1');
      await testDataHelper.insertTestSubject(name: 'New Subject 2');

      // Act
      final count = await dataSource.countSubjects();

      // Assert
      expect(count, equals(11)); // 9 default + 2 nuevas
    });

    test('should return 0 when no subjects exist', () async {
      // Arrange - eliminar todas las asignaturas
      await testDb.delete('subjects');

      // Act
      final count = await dataSource.countSubjects();

      // Assert
      expect(count, equals(0));
    });
  });
}
