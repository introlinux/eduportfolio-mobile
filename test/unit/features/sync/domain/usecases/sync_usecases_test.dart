import 'package:eduportfolio/features/sync/data/repositories/sync_repository.dart';
import 'package:eduportfolio/features/sync/domain/entities/sync_models.dart';
import 'package:eduportfolio/features/sync/domain/usecases/sync_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'sync_usecases_test.mocks.dart';

@GenerateMocks([SyncRepository])
void main() {
  late MockSyncRepository mockRepository;

  const tBaseUrl = 'http://192.168.1.100:3000';

  final tSyncResult = SyncResult(
    coursesAdded: 1,
    coursesUpdated: 0,
    subjectsAdded: 2,
    subjectsUpdated: 0,
    studentsAdded: 3,
    studentsUpdated: 0,
    evidencesAdded: 4,
    evidencesUpdated: 0,
    filesTransferred: 5,
    errors: [],
    timestamp: DateTime.now(),
  );

  setUp(() {
    mockRepository = MockSyncRepository();
  });

  group('TestConnectionUseCase', () {
    late TestConnectionUseCase useCase;

    setUp(() {
      useCase = TestConnectionUseCase(mockRepository);
    });

    test('delega en repository.testConnection y devuelve true cuando hay conexión', () async {
      when(mockRepository.testConnection(tBaseUrl))
          .thenAnswer((_) async => true);

      final result = await useCase(tBaseUrl);

      expect(result, isTrue);
      verify(mockRepository.testConnection(tBaseUrl));
      verifyNoMoreInteractions(mockRepository);
    });

    test('devuelve false cuando el repositorio devuelve false', () async {
      when(mockRepository.testConnection(tBaseUrl))
          .thenAnswer((_) async => false);

      final result = await useCase(tBaseUrl);

      expect(result, isFalse);
      verify(mockRepository.testConnection(tBaseUrl));
      verifyNoMoreInteractions(mockRepository);
    });
  });

  group('GetSystemInfoUseCase', () {
    late GetSystemInfoUseCase useCase;

    setUp(() {
      useCase = GetSystemInfoUseCase(mockRepository);
    });

    test('delega en repository.getSystemInfo y devuelve SystemInfo', () async {
      const tSystemInfo = SystemInfo(
        ip: '192.168.1.100',
        port: 3000,
        status: 'running',
      );
      when(mockRepository.getSystemInfo(tBaseUrl))
          .thenAnswer((_) async => tSystemInfo);

      final result = await useCase(tBaseUrl);

      expect(result.ip, '192.168.1.100');
      expect(result.port, 3000);
      expect(result.status, 'running');
      verify(mockRepository.getSystemInfo(tBaseUrl));
      verifyNoMoreInteractions(mockRepository);
    });
  });

  group('SyncAllDataUseCase', () {
    late SyncAllDataUseCase useCase;

    setUp(() {
      useCase = SyncAllDataUseCase(mockRepository);
    });

    test('should call syncAll on repository and return SyncResult', () async {
      when(mockRepository.syncAll(tBaseUrl))
          .thenAnswer((_) async => tSyncResult);

      final result = await useCase(tBaseUrl);

      expect(result, tSyncResult);
      verify(mockRepository.syncAll(tBaseUrl));
      verifyNoMoreInteractions(mockRepository);
    });

    test('propaga SyncResult con errores si la sincronización falla parcialmente', () async {
      final tFailedResult = SyncResult(
        coursesAdded: 0,
        coursesUpdated: 0,
        subjectsAdded: 0,
        subjectsUpdated: 0,
        studentsAdded: 0,
        studentsUpdated: 0,
        evidencesAdded: 0,
        evidencesUpdated: 0,
        filesTransferred: 0,
        errors: ['Network error: Connection refused'],
        timestamp: DateTime.now(),
      );

      when(mockRepository.syncAll(tBaseUrl))
          .thenAnswer((_) async => tFailedResult);

      final result = await useCase(tBaseUrl);

      expect(result.hasErrors, isTrue);
      expect(result.errors, isNotEmpty);
      expect(result.errors.first, contains('Network error'));
      verify(mockRepository.syncAll(tBaseUrl));
    });
  });
}
