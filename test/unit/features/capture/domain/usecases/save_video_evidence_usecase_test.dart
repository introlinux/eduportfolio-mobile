import 'dart:io';

import 'package:eduportfolio/core/domain/entities/evidence.dart';
import 'package:eduportfolio/core/domain/entities/student.dart';
import 'package:eduportfolio/core/domain/entities/subject.dart';
import 'package:eduportfolio/core/domain/repositories/evidence_repository.dart';
import 'package:eduportfolio/core/domain/repositories/student_repository.dart';
import 'package:eduportfolio/core/domain/repositories/subject_repository.dart';
import 'package:eduportfolio/features/capture/domain/usecases/save_video_evidence_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'save_video_evidence_usecase_test.mocks.dart';

class FakePathProviderPlatform extends PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return Directory.systemTemp.path;
  }
}

@GenerateMocks([EvidenceRepository, SubjectRepository, StudentRepository])
void main() {
  late SaveVideoEvidenceUseCase useCase;
  late MockEvidenceRepository mockEvidenceRepository;
  late MockSubjectRepository mockSubjectRepository;
  late MockStudentRepository mockStudentRepository;
  late File tempVideoFile;

  setUpAll(() {
    PathProviderPlatform.instance = FakePathProviderPlatform();
  });

  setUp(() async {
    mockEvidenceRepository = MockEvidenceRepository();
    mockSubjectRepository = MockSubjectRepository();
    mockStudentRepository = MockStudentRepository();
    useCase = SaveVideoEvidenceUseCase(
      mockEvidenceRepository,
      mockSubjectRepository,
      mockStudentRepository,
    );

    // Create a fake video file with some bytes
    tempVideoFile = File('${Directory.systemTemp.path}/test_video.mp4');
    await tempVideoFile.writeAsBytes([0x00, 0x00, 0x00, 0x18]);
  });

  tearDown(() async {
    if (await tempVideoFile.exists()) {
      await tempVideoFile.delete();
    }
    final evidencesDir = Directory('${Directory.systemTemp.path}/evidences');
    if (await evidencesDir.exists()) {
      await evidencesDir.delete(recursive: true);
    }
  });

  group('SaveVideoEvidenceUseCase', () {
    const subjectId = 1;
    const studentId = 42;
    const durationMs = 30000;

    Subject buildSubject() => Subject(
          id: subjectId,
          name: 'Matemáticas',
          createdAt: DateTime.now(),
        );

    Student buildStudent() => Student(
          id: studentId,
          courseId: 1,
          name: 'Juan Garcia',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

    test('guarda vídeo con alumno → isReviewed=true y nombre de alumno en filename', () async {
      when(mockSubjectRepository.getSubjectById(subjectId))
          .thenAnswer((_) async => buildSubject());
      when(mockStudentRepository.getStudentById(studentId))
          .thenAnswer((_) async => buildStudent());
      when(mockEvidenceRepository.createEvidence(any))
          .thenAnswer((_) async => 1);

      await useCase(
        tempVideoPath: tempVideoFile.path,
        subjectId: subjectId,
        durationMs: durationMs,
        studentId: studentId,
      );

      final captured =
          verify(mockEvidenceRepository.createEvidence(captureAny)).captured.single as Evidence;
      expect(captured.isReviewed, isTrue);
      expect(captured.filePath, contains('Juan-Garcia'));
      expect(captured.studentId, studentId);
    });

    test('guarda vídeo sin alumno → isReviewed=false y SIN-ASIGNAR en filename', () async {
      when(mockSubjectRepository.getSubjectById(subjectId))
          .thenAnswer((_) async => buildSubject());
      when(mockEvidenceRepository.createEvidence(any))
          .thenAnswer((_) async => 1);

      await useCase(
        tempVideoPath: tempVideoFile.path,
        subjectId: subjectId,
        durationMs: durationMs,
      );

      final captured =
          verify(mockEvidenceRepository.createEvidence(captureAny)).captured.single as Evidence;
      expect(captured.isReviewed, isFalse);
      expect(captured.filePath, contains('SIN-ASIGNAR'));
      expect(captured.studentId, isNull);
    });

    test('filename empieza con VID_ y acaba con la extensión del archivo origen', () async {
      when(mockSubjectRepository.getSubjectById(subjectId))
          .thenAnswer((_) async => buildSubject());
      when(mockEvidenceRepository.createEvidence(any))
          .thenAnswer((_) async => 1);

      await useCase(
        tempVideoPath: tempVideoFile.path,
        subjectId: subjectId,
        durationMs: durationMs,
      );

      final captured =
          verify(mockEvidenceRepository.createEvidence(captureAny)).captured.single as Evidence;
      final filename = captured.filePath.split('/').last;
      expect(filename, startsWith('VID_'));
      expect(filename, endsWith('.mp4'));
    });

    test('duración almacenada en segundos (durationMs=30000 → duration=30)', () async {
      when(mockSubjectRepository.getSubjectById(subjectId))
          .thenAnswer((_) async => buildSubject());
      when(mockEvidenceRepository.createEvidence(any))
          .thenAnswer((_) async => 1);

      await useCase(
        tempVideoPath: tempVideoFile.path,
        subjectId: subjectId,
        durationMs: 30000,
      );

      final captured =
          verify(mockEvidenceRepository.createEvidence(captureAny)).captured.single as Evidence;
      expect(captured.duration, equals(30));
    });

    test('tipo de evidencia es EvidenceType.video', () async {
      when(mockSubjectRepository.getSubjectById(subjectId))
          .thenAnswer((_) async => buildSubject());
      when(mockEvidenceRepository.createEvidence(any))
          .thenAnswer((_) async => 1);

      await useCase(
        tempVideoPath: tempVideoFile.path,
        subjectId: subjectId,
        durationMs: durationMs,
      );

      final captured =
          verify(mockEvidenceRepository.createEvidence(captureAny)).captured.single as Evidence;
      expect(captured.type, EvidenceType.video);
    });

    test('evidencia se crea aunque falle la miniatura (thumbnailPath puede ser null)', () async {
      when(mockSubjectRepository.getSubjectById(subjectId))
          .thenAnswer((_) async => buildSubject());
      when(mockEvidenceRepository.createEvidence(any))
          .thenAnswer((_) async => 1);

      // VideoThumbnail.thumbnailFile() lanza MissingPluginException en tests,
      // que es capturada por el try/catch del usecase → se continúa sin miniatura
      await expectLater(
        useCase(
          tempVideoPath: tempVideoFile.path,
          subjectId: subjectId,
          durationMs: durationMs,
        ),
        completes,
      );

      final captured =
          verify(mockEvidenceRepository.createEvidence(captureAny)).captured.single as Evidence;
      // La evidencia se crea correctamente (thumbnailPath puede ser null)
      expect(captured.type, EvidenceType.video);
    });

    test('lanza excepción si getSubjectById retorna null', () async {
      when(mockSubjectRepository.getSubjectById(subjectId))
          .thenAnswer((_) async => null);

      expect(
        () => useCase(
          tempVideoPath: tempVideoFile.path,
          subjectId: subjectId,
          durationMs: durationMs,
        ),
        throwsException,
      );
    });

    test('llama a createEvidence exactamente una vez con los datos correctos', () async {
      when(mockSubjectRepository.getSubjectById(subjectId))
          .thenAnswer((_) async => buildSubject());
      when(mockEvidenceRepository.createEvidence(any))
          .thenAnswer((_) async => 99);

      final result = await useCase(
        tempVideoPath: tempVideoFile.path,
        subjectId: subjectId,
        durationMs: durationMs,
      );

      expect(result, 99);
      final captured =
          verify(mockEvidenceRepository.createEvidence(captureAny)).captured;
      expect(captured.length, equals(1));
      final evidence = captured.single as Evidence;
      expect(evidence.subjectId, subjectId);
      expect(evidence.type, EvidenceType.video);
    });
  });
}
