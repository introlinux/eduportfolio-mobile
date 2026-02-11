import 'package:eduportfolio/core/utils/logger.dart';
import 'package:eduportfolio/features/sync/data/repositories/sync_repository.dart';
import 'package:eduportfolio/features/sync/domain/entities/sync_models.dart';

/// Use case for testing connection to desktop server
class TestConnectionUseCase {
  final SyncRepository _repository;

  TestConnectionUseCase(this._repository);

  Future<bool> call(String baseUrl) async {
    Logger.info('Testing connection to: $baseUrl');
    return await _repository.testConnection(baseUrl);
  }
}

/// Use case for getting system information from desktop server
class GetSystemInfoUseCase {
  final SyncRepository _repository;

  GetSystemInfoUseCase(this._repository);

  Future<SystemInfo> call(String baseUrl) async {
    Logger.info('Getting system info from: $baseUrl');
    return await _repository.getSystemInfo(baseUrl);
  }
}

/// Use case for performing full bidirectional synchronization
class SyncAllDataUseCase {
  final SyncRepository _repository;

  SyncAllDataUseCase(this._repository);

  Future<SyncResult> call(String baseUrl) async {
    Logger.info('Starting full synchronization with: $baseUrl');
    return await _repository.syncAll(baseUrl);
  }
}
