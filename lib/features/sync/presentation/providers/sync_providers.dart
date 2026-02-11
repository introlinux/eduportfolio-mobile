import 'package:eduportfolio/core/providers/core_providers.dart';
import 'package:eduportfolio/core/services/app_settings_service.dart';
import 'package:eduportfolio/core/services/sync_service.dart';
import 'package:eduportfolio/features/sync/data/repositories/sync_repository.dart';
import 'package:eduportfolio/features/sync/domain/entities/sync_models.dart';
import 'package:eduportfolio/features/sync/domain/usecases/sync_usecases.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for SharedPreferences instance
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

/// Provider for AppSettingsService
final appSettingsServiceProvider = Provider<AppSettingsService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).value;
  if (prefs == null) {
    throw Exception('SharedPreferences not initialized');
  }
  return AppSettingsService(prefs);
});

/// Provider for SyncService
final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService();
});

/// Provider for SyncRepository
final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  final studentRepository = ref.watch(studentRepositoryProvider);
  final courseRepository = ref.watch(courseRepositoryProvider);
  final subjectRepository = ref.watch(subjectRepositoryProvider);
  final evidenceRepository = ref.watch(evidenceRepositoryProvider);

  return SyncRepository(
    syncService: syncService,
    studentRepository: studentRepository,
    courseRepository: courseRepository,
    subjectRepository: subjectRepository,
    evidenceRepository: evidenceRepository,
  );
});

/// Provider for TestConnectionUseCase
final testConnectionUseCaseProvider = Provider<TestConnectionUseCase>((ref) {
  final repository = ref.watch(syncRepositoryProvider);
  return TestConnectionUseCase(repository);
});

/// Provider for GetSystemInfoUseCase
final getSystemInfoUseCaseProvider = Provider<GetSystemInfoUseCase>((ref) {
  final repository = ref.watch(syncRepositoryProvider);
  return GetSystemInfoUseCase(repository);
});

/// Provider for SyncAllDataUseCase
final syncAllDataUseCaseProvider = Provider<SyncAllDataUseCase>((ref) {
  final repository = ref.watch(syncRepositoryProvider);
  return SyncAllDataUseCase(repository);
});

/// Notifier for sync configuration
class SyncConfigNotifier extends Notifier<SyncConfig> {
  late final AppSettingsService _settingsService;

  @override
  SyncConfig build() {
    _settingsService = ref.watch(appSettingsServiceProvider);
    _loadConfig();
    return const SyncConfig();
  }

  Future<void> _loadConfig() async {
    final serverUrl = await _settingsService.getSyncServerUrl();
    final lastSync = await _settingsService.getLastSyncTimestamp();

    state = SyncConfig(
      serverUrl: serverUrl,
      lastSyncTimestamp: lastSync,
      autoSync: false,
    );
  }

  Future<void> setServerUrl(String url) async {
    await _settingsService.setSyncServerUrl(url);
    state = state.copyWith(serverUrl: url);
  }

  Future<void> clearServerUrl() async {
    await _settingsService.clearSyncServerUrl();
    state = state.copyWith(serverUrl: null);
  }

  Future<void> updateLastSync(DateTime timestamp) async {
    await _settingsService.setLastSyncTimestamp(timestamp);
    state = state.copyWith(lastSyncTimestamp: timestamp);
  }
}

/// Provider for sync configuration
final syncConfigProvider =
    NotifierProvider<SyncConfigNotifier, SyncConfig>(SyncConfigNotifier.new);

/// Notifier for sync status
class SyncStatusNotifier extends Notifier<SyncStatus> {
  @override
  SyncStatus build() {
    return SyncStatus.idle;
  }

  void setStatus(SyncStatus status) {
    state = status;
  }

  void reset() {
    state = SyncStatus.idle;
  }
}

/// Provider for sync status
final syncStatusProvider =
    NotifierProvider<SyncStatusNotifier, SyncStatus>(SyncStatusNotifier.new);

/// Notifier for last sync result
class LastSyncResultNotifier extends Notifier<SyncResult?> {
  @override
  SyncResult? build() => null;

  set result(SyncResult? value) => state = value;
}

/// Provider for last sync result
final lastSyncResultProvider =
    NotifierProvider<LastSyncResultNotifier, SyncResult?>(
        LastSyncResultNotifier.new);

/// Notifier for connection test result
class ConnectionTestResultNotifier extends Notifier<bool?> {
  @override
  bool? build() => null;

  set result(bool? value) => state = value;
}

/// Provider for connection test result
final connectionTestResultProvider =
    NotifierProvider<ConnectionTestResultNotifier, bool?>(
        ConnectionTestResultNotifier.new);
