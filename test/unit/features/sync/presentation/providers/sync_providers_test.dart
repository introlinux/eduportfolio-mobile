import 'package:eduportfolio/core/providers/core_providers.dart';
import 'package:eduportfolio/core/services/app_settings_service.dart';
import 'package:eduportfolio/core/services/sync_password_storage.dart';
import 'package:eduportfolio/features/sync/domain/entities/sync_models.dart';
import 'package:eduportfolio/features/sync/presentation/providers/sync_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'sync_providers_test.mocks.dart';

@GenerateMocks([AppSettingsService, SyncPasswordStorage])
void main() {
  late MockAppSettingsService mockSettingsService;
  late MockSyncPasswordStorage mockPasswordStorage;

  setUp(() {
    mockSettingsService = MockAppSettingsService();
    mockPasswordStorage = MockSyncPasswordStorage();
    // Stubs por defecto para _loadConfig() que se llama en build()
    when(mockSettingsService.getSyncServerUrl()).thenAnswer((_) async => null);
    when(mockSettingsService.getLastSyncTimestamp())
        .thenAnswer((_) async => null);
  });

  /// Crea un ProviderContainer con los mocks inyectados.
  ProviderContainer buildContainer() => ProviderContainer(
        overrides: [
          appSettingsServiceProvider.overrideWithValue(mockSettingsService),
          syncPasswordStorageProvider.overrideWithValue(mockPasswordStorage),
        ],
      );

  // ─────────────────────────────────────────────────────────────
  group('syncStatusProvider', () {
    test('estado inicial es SyncStatus.idle', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(syncStatusProvider), SyncStatus.idle);
    });

    test('setStatus cambia el estado', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(syncStatusProvider.notifier).setStatus(SyncStatus.syncing);

      expect(container.read(syncStatusProvider), SyncStatus.syncing);
    });

    test('reset vuelve a SyncStatus.idle desde cualquier estado', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(syncStatusProvider.notifier).setStatus(SyncStatus.error);
      container.read(syncStatusProvider.notifier).reset();

      expect(container.read(syncStatusProvider), SyncStatus.idle);
    });

    test('puede transitar por todos los valores del enum', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      for (final status in SyncStatus.values) {
        container.read(syncStatusProvider.notifier).setStatus(status);
        expect(container.read(syncStatusProvider), status);
      }
    });
  });

  // ─────────────────────────────────────────────────────────────
  group('lastSyncResultProvider', () {
    test('estado inicial es null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(lastSyncResultProvider), isNull);
    });

    test('asignar un resultado actualiza el estado', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = SyncResult.empty();
      container.read(lastSyncResultProvider.notifier).result = result;

      expect(container.read(lastSyncResultProvider), result);
    });

    test('asignar null limpia el estado', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(lastSyncResultProvider.notifier).result =
          SyncResult.empty();
      expect(container.read(lastSyncResultProvider), isNotNull);

      container.read(lastSyncResultProvider.notifier).result = null;
      expect(container.read(lastSyncResultProvider), isNull);
    });

    test('SyncResult con errores expone hasErrors=true', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final failedResult = SyncResult(
        studentsAdded: 0,
        studentsUpdated: 0,
        coursesAdded: 0,
        coursesUpdated: 0,
        subjectsAdded: 0,
        subjectsUpdated: 0,
        evidencesAdded: 0,
        evidencesUpdated: 0,
        filesTransferred: 0,
        errors: ['Network error: Connection refused'],
        timestamp: DateTime.now(),
      );

      container.read(lastSyncResultProvider.notifier).result = failedResult;

      expect(container.read(lastSyncResultProvider)!.hasErrors, isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────
  group('connectionTestResultProvider', () {
    test('estado inicial es null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(connectionTestResultProvider), isNull);
    });

    test('true indica conexión exitosa', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(connectionTestResultProvider.notifier).result = true;

      expect(container.read(connectionTestResultProvider), isTrue);
    });

    test('false indica conexión fallida', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(connectionTestResultProvider.notifier).result = false;

      expect(container.read(connectionTestResultProvider), isFalse);
    });

    test('asignar null limpia el resultado', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(connectionTestResultProvider.notifier).result = true;
      container.read(connectionTestResultProvider.notifier).result = null;

      expect(container.read(connectionTestResultProvider), isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────
  group('syncConfigProvider', () {
    test('estado inicial tiene serverUrl=null y lastSyncTimestamp=null', () {
      final container = buildContainer();
      addTearDown(container.dispose);

      // El estado síncrono antes de que _loadConfig() complete es SyncConfig()
      final state = container.read(syncConfigProvider);
      expect(state.serverUrl, isNull);
      expect(state.lastSyncTimestamp, isNull);
    });

    test('isConfigured es false en estado inicial', () {
      final container = buildContainer();
      addTearDown(container.dispose);

      expect(container.read(syncConfigProvider).isConfigured, isFalse);
    });

    test('_loadConfig carga serverUrl de la configuración guardada', () async {
      when(mockSettingsService.getSyncServerUrl())
          .thenAnswer((_) async => '192.168.1.100:3000');

      final container = buildContainer();
      addTearDown(container.dispose);

      container.read(syncConfigProvider); // dispara build() y _loadConfig()
      await Future<void>.delayed(Duration.zero); // deja completar las futures

      expect(
          container.read(syncConfigProvider).serverUrl, '192.168.1.100:3000');
    });

    test('_loadConfig carga lastSyncTimestamp de la configuración guardada',
        () async {
      final tTimestamp = DateTime(2024, 6, 15, 10, 30);
      when(mockSettingsService.getLastSyncTimestamp())
          .thenAnswer((_) async => tTimestamp);

      final container = buildContainer();
      addTearDown(container.dispose);

      container.read(syncConfigProvider);
      await Future<void>.delayed(Duration.zero);

      expect(
          container.read(syncConfigProvider).lastSyncTimestamp, tTimestamp);
    });

    test('setServerUrl guarda la URL en el servicio y actualiza el estado',
        () async {
      when(mockSettingsService.setSyncServerUrl(any))
          .thenAnswer((_) async {});

      final container = buildContainer();
      addTearDown(container.dispose);

      await container
          .read(syncConfigProvider.notifier)
          .setServerUrl('192.168.1.50:3000');

      expect(
          container.read(syncConfigProvider).serverUrl, '192.168.1.50:3000');
      verify(mockSettingsService.setSyncServerUrl('192.168.1.50:3000'))
          .called(1);
    });

    test('setServerUrl con URL válida activa isConfigured', () async {
      when(mockSettingsService.setSyncServerUrl(any))
          .thenAnswer((_) async {});

      final container = buildContainer();
      addTearDown(container.dispose);

      await container
          .read(syncConfigProvider.notifier)
          .setServerUrl('192.168.1.100:3000');

      expect(container.read(syncConfigProvider).isConfigured, isTrue);
    });

    test('clearServerUrl llama a clearSyncServerUrl en el servicio', () async {
      when(mockSettingsService.clearSyncServerUrl())
          .thenAnswer((_) async {});

      final container = buildContainer();
      addTearDown(container.dispose);

      container.read(syncConfigProvider);
      await container.read(syncConfigProvider.notifier).clearServerUrl();

      verify(mockSettingsService.clearSyncServerUrl()).called(1);
    });

    test('updateLastSync persiste el timestamp y actualiza el estado',
        () async {
      final tTimestamp = DateTime(2024, 1, 15, 10, 30);
      when(mockSettingsService.setLastSyncTimestamp(tTimestamp))
          .thenAnswer((_) async {});

      final container = buildContainer();
      addTearDown(container.dispose);

      await container
          .read(syncConfigProvider.notifier)
          .updateLastSync(tTimestamp);

      expect(
          container.read(syncConfigProvider).lastSyncTimestamp, tTimestamp);
      verify(mockSettingsService.setLastSyncTimestamp(tTimestamp)).called(1);
    });

    test('setPassword delega en SyncPasswordStorage y devuelve el resultado',
        () async {
      when(mockPasswordStorage.savePassword('secreto'))
          .thenAnswer((_) async => true);

      final container = buildContainer();
      addTearDown(container.dispose);

      final result = await container
          .read(syncConfigProvider.notifier)
          .setPassword('secreto');

      expect(result, isTrue);
      verify(mockPasswordStorage.savePassword('secreto')).called(1);
    });

    test('getPassword delega en SyncPasswordStorage', () async {
      when(mockPasswordStorage.getPassword())
          .thenAnswer((_) async => 'secreto');

      final container = buildContainer();
      addTearDown(container.dispose);

      final result =
          await container.read(syncConfigProvider.notifier).getPassword();

      expect(result, 'secreto');
      verify(mockPasswordStorage.getPassword()).called(1);
    });

    test('clearPassword delega en SyncPasswordStorage', () async {
      when(mockPasswordStorage.deletePassword())
          .thenAnswer((_) async => true);

      final container = buildContainer();
      addTearDown(container.dispose);

      final result =
          await container.read(syncConfigProvider.notifier).clearPassword();

      expect(result, isTrue);
      verify(mockPasswordStorage.deletePassword()).called(1);
    });

    test('hasPassword devuelve true cuando hay contraseña almacenada',
        () async {
      when(mockPasswordStorage.hasPassword()).thenAnswer((_) async => true);

      final container = buildContainer();
      addTearDown(container.dispose);

      final result =
          await container.read(syncConfigProvider.notifier).hasPassword();

      expect(result, isTrue);
      verify(mockPasswordStorage.hasPassword()).called(1);
    });

    test('hasPassword devuelve false cuando no hay contraseña', () async {
      when(mockPasswordStorage.hasPassword()).thenAnswer((_) async => false);

      final container = buildContainer();
      addTearDown(container.dispose);

      final result =
          await container.read(syncConfigProvider.notifier).hasPassword();

      expect(result, isFalse);
    });
  });
}
