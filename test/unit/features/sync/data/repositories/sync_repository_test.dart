import 'package:eduportfolio/core/domain/repositories/course_repository.dart';
import 'package:eduportfolio/core/domain/repositories/evidence_repository.dart';
import 'package:eduportfolio/core/domain/repositories/student_repository.dart';
import 'package:eduportfolio/core/domain/repositories/subject_repository.dart';
import 'package:eduportfolio/core/services/sync_password_storage.dart';
import 'package:eduportfolio/core/services/sync_service.dart';
import 'package:eduportfolio/features/sync/data/repositories/sync_repository.dart';
import 'package:eduportfolio/features/sync/domain/entities/sync_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'sync_repository_test.mocks.dart';

@GenerateMocks([
  SyncService,
  SyncPasswordStorage,
  StudentRepository,
  CourseRepository,
  SubjectRepository,
  EvidenceRepository,
])
void main() {
  late SyncRepository repository;
  late MockSyncService mockSyncService;
  late MockSyncPasswordStorage mockPasswordStorage;
  late MockStudentRepository mockStudentRepository;
  late MockCourseRepository mockCourseRepository;
  late MockSubjectRepository mockSubjectRepository;
  late MockEvidenceRepository mockEvidenceRepository;

  const tBaseUrl = 'http://192.168.1.100:3000';

  setUp(() {
    mockSyncService = MockSyncService();
    mockPasswordStorage = MockSyncPasswordStorage();
    mockStudentRepository = MockStudentRepository();
    mockCourseRepository = MockCourseRepository();
    mockSubjectRepository = MockSubjectRepository();
    mockEvidenceRepository = MockEvidenceRepository();

    repository = SyncRepository(
      syncService: mockSyncService,
      passwordStorage: mockPasswordStorage,
      studentRepository: mockStudentRepository,
      courseRepository: mockCourseRepository,
      subjectRepository: mockSubjectRepository,
      evidenceRepository: mockEvidenceRepository,
    );
  });

  group('testConnection', () {
    test('llama a syncService.testConnection con la URL correcta y devuelve true', () async {
      when(mockSyncService.testConnection(tBaseUrl))
          .thenAnswer((_) async => true);

      final result = await repository.testConnection(tBaseUrl);

      expect(result, isTrue);
      verify(mockSyncService.testConnection(tBaseUrl));
    });

    test('devuelve false si el servicio devuelve false (conexión fallida)', () async {
      when(mockSyncService.testConnection(tBaseUrl))
          .thenAnswer((_) async => false);

      final result = await repository.testConnection(tBaseUrl);

      expect(result, isFalse);
      verify(mockSyncService.testConnection(tBaseUrl));
    });
  });

  group('getSystemInfo', () {
    test('llama a syncService.getSystemInfo y devuelve SystemInfo', () async {
      const tSystemInfo = SystemInfo(
        ip: '192.168.1.100',
        port: 3000,
        status: 'running',
      );
      when(mockSyncService.getSystemInfo(tBaseUrl))
          .thenAnswer((_) async => tSystemInfo);

      final result = await repository.getSystemInfo(tBaseUrl);

      expect(result.ip, '192.168.1.100');
      expect(result.port, 3000);
      expect(result.status, 'running');
      verify(mockSyncService.getSystemInfo(tBaseUrl));
    });
  });

  group('syncAll', () {
    test('lanza SyncException cuando passwordStorage retorna null', () async {
      when(mockPasswordStorage.getPassword()).thenAnswer((_) async => null);

      expect(
        () => repository.syncAll(tBaseUrl),
        throwsA(isA<SyncException>()),
      );
    });

    test('lanza SyncException cuando passwordStorage retorna cadena vacía', () async {
      when(mockPasswordStorage.getPassword()).thenAnswer((_) async => '');

      expect(
        () => repository.syncAll(tBaseUrl),
        throwsA(isA<SyncException>()),
      );
    });

    test('retorna SyncResult con errors cuando el servicio de red falla', () async {
      when(mockPasswordStorage.getPassword())
          .thenAnswer((_) async => 'valid_password');
      when(mockSyncService.setPassword(any)).thenAnswer((_) {});
      when(mockSyncService.getMetadata(tBaseUrl))
          .thenThrow(SyncException('Network error: Connection refused'));

      final result = await repository.syncAll(tBaseUrl);

      expect(result.hasErrors, isTrue);
      expect(result.errors, isNotEmpty);
      expect(result.errors.first, contains('SyncException'));
    });
  });
}
