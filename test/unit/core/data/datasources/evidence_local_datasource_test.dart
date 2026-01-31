import 'package:eduportfolio/core/data/datasources/evidence_local_datasource.dart';
import 'package:eduportfolio/core/data/models/evidence_model.dart';
import 'package:eduportfolio/core/database/database_helper.dart';
import 'package:eduportfolio/core/domain/entities/evidence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../helpers/database_test_helper.dart';

// Generate mocks
@GenerateMocks([DatabaseHelper])
import 'evidence_local_datasource_test.mocks.dart';

void main() {
  late Database testDb;
  late MockDatabaseHelper mockDatabaseHelper;
  late EvidenceLocalDataSource dataSource;
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
    dataSource = EvidenceLocalDataSource(mockDatabaseHelper);
  });

  tearDown(() async {
    await closeTestDatabase(testDb);
  });

  group('EvidenceLocalDataSource - getAllEvidences', () {
    test('should return all evidences ordered by capture_date DESC', () async {
      // Arrange - insertar evidencias con diferentes fechas
      final now = DateTime.now();
      final evidence1Id = await testDataHelper.insertTestEvidence(
        filePath: '/path/evidence1.jpg',
        captureDate: now.subtract(const Duration(days: 2)),
      );
      final evidence2Id = await testDataHelper.insertTestEvidence(
        filePath: '/path/evidence2.jpg',
        captureDate: now.subtract(const Duration(days: 1)),
      );
      final evidence3Id = await testDataHelper.insertTestEvidence(
        filePath: '/path/evidence3.jpg',
        captureDate: now,
      );

      // Act
      final result = await dataSource.getAllEvidences();

      // Assert
      expect(result, hasLength(3));
      expect(result[0].id, equals(evidence3Id)); // Más reciente primero
      expect(result[1].id, equals(evidence2Id));
      expect(result[2].id, equals(evidence1Id));
    });

    test('should return empty list when no evidences exist', () async {
      // Act
      final result = await dataSource.getAllEvidences();

      // Assert
      expect(result, isEmpty);
    });

    test('should return EvidenceModel instances', () async {
      // Arrange
      await testDataHelper.insertTestEvidence(filePath: '/path/test.jpg');

      // Act
      final result = await dataSource.getAllEvidences();

      // Assert
      expect(result, isNotEmpty);
      expect(result.first, isA<EvidenceModel>());
    });
  });

  group('EvidenceLocalDataSource - getEvidencesByStudent', () {
    test('should return only evidences for specified student', () async {
      // Arrange - crear curso y estudiantes
      final courseId = await testDataHelper.insertTestCourse();
      final student1Id = await testDataHelper.insertTestStudent(
        courseId: courseId,
        name: 'Student 1',
      );
      final student2Id = await testDataHelper.insertTestStudent(
        courseId: courseId,
        name: 'Student 2',
      );

      // Insertar evidencias para diferentes estudiantes
      await testDataHelper.insertTestEvidence(
        studentId: student1Id,
        filePath: '/path/student1_evidence1.jpg',
      );
      await testDataHelper.insertTestEvidence(
        studentId: student1Id,
        filePath: '/path/student1_evidence2.jpg',
      );
      await testDataHelper.insertTestEvidence(
        studentId: student2Id,
        filePath: '/path/student2_evidence1.jpg',
      );

      // Act
      final result = await dataSource.getEvidencesByStudent(student1Id);

      // Assert
      expect(result, hasLength(2));
      expect(result.every((e) => e.studentId == student1Id), isTrue);
    });

    test('should return empty list when student has no evidences', () async {
      // Arrange
      final courseId = await testDataHelper.insertTestCourse();
      final studentId = await testDataHelper.insertTestStudent(
        courseId: courseId,
      );

      // Act
      final result = await dataSource.getEvidencesByStudent(studentId);

      // Assert
      expect(result, isEmpty);
    });

    test('should order by capture_date DESC', () async {
      // Arrange
      final courseId = await testDataHelper.insertTestCourse();
      final studentId = await testDataHelper.insertTestStudent(
        courseId: courseId,
      );

      final now = DateTime.now();
      final evidence1Id = await testDataHelper.insertTestEvidence(
        studentId: studentId,
        filePath: '/path/old.jpg',
        captureDate: now.subtract(const Duration(days: 1)),
      );
      final evidence2Id = await testDataHelper.insertTestEvidence(
        studentId: studentId,
        filePath: '/path/new.jpg',
        captureDate: now,
      );

      // Act
      final result = await dataSource.getEvidencesByStudent(studentId);

      // Assert
      expect(result, hasLength(2));
      expect(result[0].id, equals(evidence2Id)); // Más reciente primero
      expect(result[1].id, equals(evidence1Id));
    });
  });

  group('EvidenceLocalDataSource - getEvidencesBySubject', () {
    test('should return only evidences for specified subject', () async {
      // Arrange
      const mathSubjectId = 2; // Matemáticas
      const languageSubjectId = 3; // Lengua

      await testDataHelper.insertTestEvidence(
        subjectId: mathSubjectId,
        filePath: '/path/math1.jpg',
      );
      await testDataHelper.insertTestEvidence(
        subjectId: mathSubjectId,
        filePath: '/path/math2.jpg',
      );
      await testDataHelper.insertTestEvidence(
        subjectId: languageSubjectId,
        filePath: '/path/language1.jpg',
      );

      // Act
      final result = await dataSource.getEvidencesBySubject(mathSubjectId);

      // Assert
      expect(result, hasLength(2));
      expect(result.every((e) => e.subjectId == mathSubjectId), isTrue);
    });

    test('should return empty list when subject has no evidences', () async {
      // Act
      final result = await dataSource.getEvidencesBySubject(999);

      // Assert
      expect(result, isEmpty);
    });
  });

  group('EvidenceLocalDataSource - getEvidencesByStudentAndSubject', () {
    test('should return evidences matching both student and subject', () async {
      // Arrange
      final courseId = await testDataHelper.insertTestCourse();
      final student1Id = await testDataHelper.insertTestStudent(
        courseId: courseId,
        name: 'Student 1',
      );
      final student2Id = await testDataHelper.insertTestStudent(
        courseId: courseId,
        name: 'Student 2',
      );

      const mathSubjectId = 2;
      const languageSubjectId = 3;

      // Estudiante 1 - Matemáticas
      await testDataHelper.insertTestEvidence(
        studentId: student1Id,
        subjectId: mathSubjectId,
        filePath: '/path/student1_math1.jpg',
      );
      await testDataHelper.insertTestEvidence(
        studentId: student1Id,
        subjectId: mathSubjectId,
        filePath: '/path/student1_math2.jpg',
      );

      // Estudiante 1 - Lengua
      await testDataHelper.insertTestEvidence(
        studentId: student1Id,
        subjectId: languageSubjectId,
        filePath: '/path/student1_language1.jpg',
      );

      // Estudiante 2 - Matemáticas
      await testDataHelper.insertTestEvidence(
        studentId: student2Id,
        subjectId: mathSubjectId,
        filePath: '/path/student2_math1.jpg',
      );

      // Act
      final result = await dataSource.getEvidencesByStudentAndSubject(
        student1Id,
        mathSubjectId,
      );

      // Assert
      expect(result, hasLength(2));
      expect(
        result.every(
          (e) => e.studentId == student1Id && e.subjectId == mathSubjectId,
        ),
        isTrue,
      );
    });
  });

  group('EvidenceLocalDataSource - getEvidencesByType', () {
    test('should return only evidences of specified type', () async {
      // Arrange
      await testDataHelper.insertTestEvidence(
        type: 'IMG',
        filePath: '/path/image1.jpg',
      );
      await testDataHelper.insertTestEvidence(
        type: 'IMG',
        filePath: '/path/image2.jpg',
      );
      await testDataHelper.insertTestEvidence(
        type: 'VID',
        filePath: '/path/video1.mp4',
      );
      await testDataHelper.insertTestEvidence(
        type: 'AUD',
        filePath: '/path/audio1.mp3',
      );

      // Act
      final result = await dataSource.getEvidencesByType(EvidenceType.image);

      // Assert
      expect(result, hasLength(2));
      expect(result.every((e) => e.type == EvidenceType.image), isTrue);
    });
  });

  group('EvidenceLocalDataSource - getUnassignedEvidences', () {
    test('should return only evidences with student_id IS NULL', () async {
      // Arrange
      final courseId = await testDataHelper.insertTestCourse();
      final studentId = await testDataHelper.insertTestStudent(
        courseId: courseId,
      );

      // Evidencias sin asignar
      await testDataHelper.insertTestEvidence(
        studentId: null,
        filePath: '/path/unassigned1.jpg',
      );
      await testDataHelper.insertTestEvidence(
        studentId: null,
        filePath: '/path/unassigned2.jpg',
      );

      // Evidencia asignada
      await testDataHelper.insertTestEvidence(
        studentId: studentId,
        filePath: '/path/assigned1.jpg',
      );

      // Act
      final result = await dataSource.getUnassignedEvidences();

      // Assert
      expect(result, hasLength(2));
      expect(result.every((e) => e.studentId == null), isTrue);
    });

    test('should return empty list when all evidences are assigned', () async {
      // Arrange
      final courseId = await testDataHelper.insertTestCourse();
      final studentId = await testDataHelper.insertTestStudent(
        courseId: courseId,
      );

      await testDataHelper.insertTestEvidence(
        studentId: studentId,
        filePath: '/path/assigned1.jpg',
      );

      // Act
      final result = await dataSource.getUnassignedEvidences();

      // Assert
      expect(result, isEmpty);
    });
  });

  group('EvidenceLocalDataSource - getEvidencesNeedingReview', () {
    test('should return evidences with student_id IS NULL OR is_reviewed = 0',
        () async {
      // Arrange
      final courseId = await testDataHelper.insertTestCourse();
      final studentId = await testDataHelper.insertTestStudent(
        courseId: courseId,
      );

      // Sin asignar (necesita revisión)
      await testDataHelper.insertTestEvidence(
        studentId: null,
        isReviewed: false,
        filePath: '/path/unassigned.jpg',
      );

      // Asignada pero no revisada (necesita revisión)
      await testDataHelper.insertTestEvidence(
        studentId: studentId,
        isReviewed: false,
        filePath: '/path/not_reviewed.jpg',
      );

      // Asignada y revisada (NO necesita revisión)
      await testDataHelper.insertTestEvidence(
        studentId: studentId,
        isReviewed: true,
        filePath: '/path/reviewed.jpg',
      );

      // Act
      final result = await dataSource.getEvidencesNeedingReview();

      // Assert
      expect(result, hasLength(2));
      expect(
        result.every((e) => e.studentId == null || !e.isReviewed),
        isTrue,
      );
    });
  });

  group('EvidenceLocalDataSource - getEvidencesByDateRange', () {
    test('should return evidences within date range', () async {
      // Arrange
      final baseDate = DateTime(2024, 1, 15);

      await testDataHelper.insertTestEvidence(
        filePath: '/path/before.jpg',
        captureDate: DateTime(2024, 1, 1),
      );
      await testDataHelper.insertTestEvidence(
        filePath: '/path/inside1.jpg',
        captureDate: DateTime(2024, 1, 10),
      );
      await testDataHelper.insertTestEvidence(
        filePath: '/path/inside2.jpg',
        captureDate: DateTime(2024, 1, 20),
      );
      await testDataHelper.insertTestEvidence(
        filePath: '/path/after.jpg',
        captureDate: DateTime(2024, 1, 31),
      );

      // Act
      final result = await dataSource.getEvidencesByDateRange(
        DateTime(2024, 1, 10),
        DateTime(2024, 1, 20),
      );

      // Assert
      expect(result, hasLength(2));
      expect(result[0].filePath, contains('inside'));
      expect(result[1].filePath, contains('inside'));
    });
  });

  group('EvidenceLocalDataSource - getEvidenceById', () {
    test('should return evidence when ID exists', () async {
      // Arrange
      final evidenceId = await testDataHelper.insertTestEvidence(
        filePath: '/path/test.jpg',
      );

      // Act
      final result = await dataSource.getEvidenceById(evidenceId);

      // Assert
      expect(result, isNotNull);
      expect(result!.id, equals(evidenceId));
      expect(result.filePath, equals('/path/test.jpg'));
    });

    test('should return null when ID does not exist', () async {
      // Act
      final result = await dataSource.getEvidenceById(999);

      // Assert
      expect(result, isNull);
    });
  });

  group('EvidenceLocalDataSource - insertEvidence', () {
    test('should insert evidence and return generated ID', () async {
      // Arrange
      final now = DateTime.now();
      final evidence = EvidenceModel(
        subjectId: 1,
        type: EvidenceType.image,
        filePath: '/path/new_evidence.jpg',
        captureDate: now,
        isReviewed: false,
        createdAt: now,
      );

      // Act
      final insertedId = await dataSource.insertEvidence(evidence);

      // Assert
      expect(insertedId, greaterThan(0));

      // Verificar que se insertó correctamente
      final inserted = await dataSource.getEvidenceById(insertedId);
      expect(inserted, isNotNull);
      expect(inserted!.filePath, equals('/path/new_evidence.jpg'));
      expect(inserted.isReviewed, isFalse);
    });

    test('should insert evidence with all optional fields', () async {
      // Arrange
      final courseId = await testDataHelper.insertTestCourse();
      final studentId = await testDataHelper.insertTestStudent(
        courseId: courseId,
      );

      final now = DateTime.now();
      final evidence = EvidenceModel(
        studentId: studentId,
        subjectId: 2,
        type: EvidenceType.video,
        filePath: '/path/video.mp4',
        thumbnailPath: '/path/thumb.jpg',
        fileSize: 1024000,
        duration: 120,
        captureDate: now,
        isReviewed: true,
        notes: 'Test notes',
        createdAt: now,
      );

      // Act
      final insertedId = await dataSource.insertEvidence(evidence);

      // Assert
      final inserted = await dataSource.getEvidenceById(insertedId);
      expect(inserted, isNotNull);
      expect(inserted!.studentId, equals(studentId));
      expect(inserted.subjectId, equals(2));
      expect(inserted.type, equals(EvidenceType.video));
      expect(inserted.thumbnailPath, equals('/path/thumb.jpg'));
      expect(inserted.fileSize, equals(1024000));
      expect(inserted.duration, equals(120));
      expect(inserted.isReviewed, isTrue);
      expect(inserted.notes, equals('Test notes'));
    });
  });

  group('EvidenceLocalDataSource - updateEvidence', () {
    test('should update evidence fields correctly', () async {
      // Arrange
      final courseId = await testDataHelper.insertTestCourse();
      final studentId = await testDataHelper.insertTestStudent(
        courseId: courseId,
      );

      final evidenceId = await testDataHelper.insertTestEvidence(
        studentId: null,
        subjectId: 1,
        isReviewed: false,
        filePath: '/path/original.jpg',
        notes: 'Original notes',
      );

      final original = await dataSource.getEvidenceById(evidenceId);
      expect(original, isNotNull);

      // Crear modelo actualizado
      final updated = EvidenceModel(
        id: evidenceId,
        studentId: studentId,
        subjectId: 2,
        type: EvidenceType.image,
        filePath: '/path/original.jpg',
        captureDate: original!.captureDate,
        isReviewed: true,
        notes: 'Updated notes',
        createdAt: original.createdAt,
      );

      // Act
      final rowsAffected = await dataSource.updateEvidence(updated);

      // Assert
      expect(rowsAffected, equals(1));

      final result = await dataSource.getEvidenceById(evidenceId);
      expect(result!.studentId, equals(studentId));
      expect(result.subjectId, equals(2));
      expect(result.isReviewed, isTrue);
      expect(result.notes, equals('Updated notes'));
    });
  });

  group('EvidenceLocalDataSource - deleteEvidence', () {
    test('should delete evidence by ID', () async {
      // Arrange
      final evidenceId = await testDataHelper.insertTestEvidence(
        filePath: '/path/to_delete.jpg',
      );

      // Verificar que existe
      final beforeDelete = await dataSource.getEvidenceById(evidenceId);
      expect(beforeDelete, isNotNull);

      // Act
      final rowsAffected = await dataSource.deleteEvidence(evidenceId);

      // Assert
      expect(rowsAffected, equals(1));

      final afterDelete = await dataSource.getEvidenceById(evidenceId);
      expect(afterDelete, isNull);
    });

    test('should return 0 when deleting non-existent evidence', () async {
      // Act
      final rowsAffected = await dataSource.deleteEvidence(999);

      // Assert
      expect(rowsAffected, equals(0));
    });
  });

  group('EvidenceLocalDataSource - assignEvidenceToStudent', () {
    test('should assign evidence to student and mark as reviewed', () async {
      // Arrange
      final courseId = await testDataHelper.insertTestCourse();
      final studentId = await testDataHelper.insertTestStudent(
        courseId: courseId,
      );

      final evidenceId = await testDataHelper.insertTestEvidence(
        studentId: null,
        isReviewed: false,
        filePath: '/path/unassigned.jpg',
      );

      // Act
      final rowsAffected = await dataSource.assignEvidenceToStudent(
        evidenceId,
        studentId,
      );

      // Assert
      expect(rowsAffected, equals(1));

      final result = await dataSource.getEvidenceById(evidenceId);
      expect(result, isNotNull);
      expect(result!.studentId, equals(studentId));
      expect(result.isReviewed, isTrue); // CRÍTICO: debe marcarse como revisada
    });
  });

  group('EvidenceLocalDataSource - countEvidences', () {
    test('should return total count of evidences', () async {
      // Arrange
      await testDataHelper.insertTestEvidence(filePath: '/path/1.jpg');
      await testDataHelper.insertTestEvidence(filePath: '/path/2.jpg');
      await testDataHelper.insertTestEvidence(filePath: '/path/3.jpg');

      // Act
      final count = await dataSource.countEvidences();

      // Assert
      expect(count, equals(3));
    });

    test('should return 0 when no evidences exist', () async {
      // Act
      final count = await dataSource.countEvidences();

      // Assert
      expect(count, equals(0));
    });
  });

  group('EvidenceLocalDataSource - countEvidencesByStudent', () {
    test('should return count of evidences for specific student', () async {
      // Arrange
      final courseId = await testDataHelper.insertTestCourse();
      final student1Id = await testDataHelper.insertTestStudent(
        courseId: courseId,
        name: 'Student 1',
      );
      final student2Id = await testDataHelper.insertTestStudent(
        courseId: courseId,
        name: 'Student 2',
      );

      await testDataHelper.insertTestEvidence(
        studentId: student1Id,
        filePath: '/path/s1_1.jpg',
      );
      await testDataHelper.insertTestEvidence(
        studentId: student1Id,
        filePath: '/path/s1_2.jpg',
      );
      await testDataHelper.insertTestEvidence(
        studentId: student2Id,
        filePath: '/path/s2_1.jpg',
      );

      // Act
      final count = await dataSource.countEvidencesByStudent(student1Id);

      // Assert
      expect(count, equals(2));
    });
  });

  group('EvidenceLocalDataSource - countEvidencesNeedingReview', () {
    test('should return count of evidences needing review', () async {
      // Arrange
      final courseId = await testDataHelper.insertTestCourse();
      final studentId = await testDataHelper.insertTestStudent(
        courseId: courseId,
      );

      // Sin asignar (necesita revisión)
      await testDataHelper.insertTestEvidence(
        studentId: null,
        isReviewed: false,
        filePath: '/path/unassigned.jpg',
      );

      // Asignada pero no revisada (necesita revisión)
      await testDataHelper.insertTestEvidence(
        studentId: studentId,
        isReviewed: false,
        filePath: '/path/not_reviewed.jpg',
      );

      // Asignada y revisada (NO necesita revisión)
      await testDataHelper.insertTestEvidence(
        studentId: studentId,
        isReviewed: true,
        filePath: '/path/reviewed.jpg',
      );

      // Act
      final count = await dataSource.countEvidencesNeedingReview();

      // Assert
      expect(count, equals(2));
    });
  });

  group('EvidenceLocalDataSource - getTotalStorageSize', () {
    test('should return sum of file sizes', () async {
      // Arrange
      await testDataHelper.insertTestEvidence(
        filePath: '/path/1.jpg',
        fileSize: 1000,
      );
      await testDataHelper.insertTestEvidence(
        filePath: '/path/2.jpg',
        fileSize: 2000,
      );
      await testDataHelper.insertTestEvidence(
        filePath: '/path/3.jpg',
        fileSize: 3000,
      );

      // Act
      final totalSize = await dataSource.getTotalStorageSize();

      // Assert
      expect(totalSize, equals(6000));
    });

    test('should ignore evidences with NULL file_size', () async {
      // Arrange
      await testDataHelper.insertTestEvidence(
        filePath: '/path/1.jpg',
        fileSize: 1000,
      );
      await testDataHelper.insertTestEvidence(
        filePath: '/path/2.jpg',
        fileSize: null, // Sin tamaño
      );

      // Act
      final totalSize = await dataSource.getTotalStorageSize();

      // Assert
      expect(totalSize, equals(1000));
    });

    test('should return 0 when no evidences have file_size', () async {
      // Arrange
      await testDataHelper.insertTestEvidence(
        filePath: '/path/1.jpg',
        fileSize: null,
      );

      // Act
      final totalSize = await dataSource.getTotalStorageSize();

      // Assert
      expect(totalSize, equals(0));
    });
  });
}
