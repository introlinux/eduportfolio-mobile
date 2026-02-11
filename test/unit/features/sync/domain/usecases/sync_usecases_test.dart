import 'package:eduportfolio/features/sync/data/repositories/sync_repository.dart';
import 'package:eduportfolio/features/sync/domain/entities/sync_models.dart';
import 'package:eduportfolio/features/sync/domain/usecases/sync_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'sync_usecases_test.mocks.dart';

@GenerateMocks([SyncRepository])
void main() {
  late SyncAllDataUseCase useCase;
  late MockSyncRepository mockRepository;

  setUp(() {
    mockRepository = MockSyncRepository();
    useCase = SyncAllDataUseCase(mockRepository);
  });

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

  test(
    'should call syncAll on repository and return SyncResult',
    () async {
      // Arrange
      when(mockRepository.syncAll(tBaseUrl))
          .thenAnswer((_) async => tSyncResult);

      // Act
      final result = await useCase(tBaseUrl);

      // Assert
      expect(result, tSyncResult);
      verify(mockRepository.syncAll(tBaseUrl));
      verifyNoMoreInteractions(mockRepository);
    },
  );
}
