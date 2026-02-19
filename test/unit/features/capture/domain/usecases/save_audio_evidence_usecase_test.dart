import 'dart:io';

import 'package:eduportfolio/core/domain/entities/evidence.dart';
import 'package:eduportfolio/core/domain/entities/student.dart';
import 'package:eduportfolio/core/domain/entities/subject.dart';
import 'package:eduportfolio/core/domain/repositories/evidence_repository.dart';
import 'package:eduportfolio/core/domain/repositories/student_repository.dart';
import 'package:eduportfolio/core/domain/repositories/subject_repository.dart';
import 'package:eduportfolio/features/capture/domain/usecases/save_audio_evidence_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'save_audio_evidence_usecase_test.mocks.dart';

class FakePathProviderPlatform extends PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return Directory.systemTemp.path;
  }
}

@GenerateMocks([EvidenceRepository, SubjectRepository, StudentRepository])
void main() {
  late SaveAudioEvidenceUseCase useCase;
  late MockEvidenceRepository mockEvidenceRepository;
  late MockSubjectRepository mockSubjectRepository;
  late MockStudentRepository mockStudentRepository;
  late File tempAudioFile;
  late File tempCoverFile;

  setUpAll(() {
    PathProviderPlatform.instance = FakePathProviderPlatform();
  });

  setUp(() async {
    mockEvidenceRepository = MockEvidenceRepository();
    mockSubjectRepository = MockSubjectRepository();
    mockStudentRepository = MockStudentRepository();
    useCase = SaveAudioEvidenceUseCase(
      mockEvidenceRepository,
      mockSubjectRepository,
      mockStudentRepository,
    );

    // Create fake audio and cover files
    tempAudioFile = File('${Directory.systemTemp.path}/test_audio.opus');
    await tempAudioFile.writeAsBytes([0x4F, 0x67, 0x67, 0x53]); // OGG magic bytes

    tempCoverFile = File('${Directory.systemTemp.path}/test_cover.jpg');
    await tempCoverFile.writeAsBytes([0xFF, 0xD8, 0xFF, 0xE0]); // JPEG magic bytes
  });

  tearDown(() async {
    if (await tempAudioFile.exists()) {
      await tempAudioFile.delete();
    }
    if (await tempCoverFile.exists()) {
      await tempCoverFile.delete();
    }
    final evidencesDir = Directory('${Directory.systemTemp.path}/evidences');
    if (await evidencesDir.exists()) {
      await evidencesDir.delete(recursive: true);
    }
  });

  group('SaveAudioEvidenceUseCase', () {
    const subjectId = 1;
    const studentId = 42;
    const durationMs = 15000;

    Subject buildSubject() => Subject(
          id: subjectId,
          name: 'Música',
          createdAt: DateTime.now(),
        );

    Student buildStudent() => Student(
          id: studentId,
          courseId: 1,
          name: 'Ana López',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

    test('guarda audio con alumno → isReviewed=true', () async {
      when(mockSubjectRepository.getSubjectById(subjectId))
          .thenAnswer((_) async => buildSubject());
      when(mockStudentRepository.getStudentById(studentId))
          .thenAnswer((_) async => buildStudent());
      when(mockEvidenceRepository.createEvidence(any))
          .thenAnswer((_) async => 1);

      await useCase(
        tempAudioPath: tempAudioFile.path,
        coverImagePath: tempCoverFile.path,
        subjectId: subjectId,
        durationMs: durationMs,
        studentId: studentId,
      );

      final captured =
          verify(mockEvidenceRepository.createEvidence(captureAny)).captured.single as Evidence;
      expect(captured.isReviewed, isTrue);
      expect(captured.studentId, studentId);
    });

    test('guarda audio sin alumno → isReviewed=false y SIN-ASIGNAR en filename', () async {
      when(mockSubjectRepository.getSubjectById(subjectId))
          .thenAnswer((_) async => buildSubject());
      when(mockEvidenceRepository.createEvidence(any))
          .thenAnswer((_) async => 1);

      await useCase(
        tempAudioPath: tempAudioFile.path,
        coverImagePath: tempCoverFile.path,
        subjectId: subjectId,
        durationMs: durationMs,
      );

      final captured =
          verify(mockEvidenceRepository.createEvidence(captureAny)).captured.single as Evidence;
      expect(captured.isReviewed, isFalse);
      expect(captured.filePath, contains('SIN-ASIGNAR'));
      expect(captured.studentId, isNull);
    });

    test('filename empieza con AUD_ y acaba en .opus', () async {
      when(mockSubjectRepository.getSubjectById(subjectId))
          .thenAnswer((_) async => buildSubject());
      when(mockEvidenceRepository.createEvidence(any))
          .thenAnswer((_) async => 1);

      await useCase(
        tempAudioPath: tempAudioFile.path,
        coverImagePath: tempCoverFile.path,
        subjectId: subjectId,
        durationMs: durationMs,
      );

      final captured =
          verify(mockEvidenceRepository.createEvidence(captureAny)).captured.single as Evidence;
      final filename = captured.filePath.split('/').last;
      expect(filename, startsWith('AUD_'));
      expect(filename, endsWith('.opus'));
    });

    test('duración almacenada en segundos (durationMs=15000 → duration=15)', () async {
      when(mockSubjectRepository.getSubjectById(subjectId))
          .thenAnswer((_) async => buildSubject());
      when(mockEvidenceRepository.createEvidence(any))
          .thenAnswer((_) async => 1);

      await useCase(
        tempAudioPath: tempAudioFile.path,
        coverImagePath: tempCoverFile.path,
        subjectId: subjectId,
        durationMs: 15000,
      );

      final captured =
          verify(mockEvidenceRepository.createEvidence(captureAny)).captured.single as Evidence;
      expect(captured.duration, equals(15));
    });

    test('tipo de evidencia es EvidenceType.audio', () async {
      when(mockSubjectRepository.getSubjectById(subjectId))
          .thenAnswer((_) async => buildSubject());
      when(mockEvidenceRepository.createEvidence(any))
          .thenAnswer((_) async => 1);

      await useCase(
        tempAudioPath: tempAudioFile.path,
        coverImagePath: tempCoverFile.path,
        subjectId: subjectId,
        durationMs: durationMs,
      );

      final captured =
          verify(mockEvidenceRepository.createEvidence(captureAny)).captured.single as Evidence;
      expect(captured.type, EvidenceType.audio);
    });

    test('evidencia se crea aunque falle la compresión de la portada', () async {
      when(mockSubjectRepository.getSubjectById(subjectId))
          .thenAnswer((_) async => buildSubject());
      when(mockEvidenceRepository.createEvidence(any))
          .thenAnswer((_) async => 1);

      // FlutterImageCompress.compressAndGetFile() lanza MissingPluginException en tests,
      // que es capturada por el try/catch del usecase → se continúa sin portada
      await expectLater(
        useCase(
          tempAudioPath: tempAudioFile.path,
          coverImagePath: tempCoverFile.path,
          subjectId: subjectId,
          durationMs: durationMs,
        ),
        completes,
      );

      final captured =
          verify(mockEvidenceRepository.createEvidence(captureAny)).captured.single as Evidence;
      expect(captured.type, EvidenceType.audio);
    });

    test('lanza excepción si la asignatura no existe', () async {
      when(mockSubjectRepository.getSubjectById(subjectId))
          .thenAnswer((_) async => null);

      expect(
        () => useCase(
          tempAudioPath: tempAudioFile.path,
          coverImagePath: tempCoverFile.path,
          subjectId: subjectId,
          durationMs: durationMs,
        ),
        throwsException,
      );
    });

    test('llama a createEvidence exactamente una vez', () async {
      when(mockSubjectRepository.getSubjectById(subjectId))
          .thenAnswer((_) async => buildSubject());
      when(mockEvidenceRepository.createEvidence(any))
          .thenAnswer((_) async => 77);

      final result = await useCase(
        tempAudioPath: tempAudioFile.path,
        coverImagePath: tempCoverFile.path,
        subjectId: subjectId,
        durationMs: durationMs,
      );

      expect(result, 77);
      final captured =
          verify(mockEvidenceRepository.createEvidence(captureAny)).captured;
      expect(captured.length, equals(1));
      final evidence = captured.single as Evidence;
      expect(evidence.subjectId, subjectId);
      expect(evidence.type, EvidenceType.audio);
    });
  });
}
