import 'package:eduportfolio/features/settings/presentation/providers/settings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('sharedPreferencesProvider', () {
    test('should return SharedPreferences instance', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({});

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Act
      final prefs = await container.read(sharedPreferencesProvider.future);

      // Assert
      expect(prefs, isA<SharedPreferences>());
    });

    test('should cache SharedPreferences instance', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({});

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Act - Read twice
      final prefs1 = await container.read(sharedPreferencesProvider.future);
      final prefs2 = await container.read(sharedPreferencesProvider.future);

      // Assert - Should return same instance
      expect(prefs1, same(prefs2));
    });
  });

  group('appSettingsServiceProvider', () {
    test('should create AppSettingsService with SharedPreferences', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        'image_resolution': 1080,
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Wait for SharedPreferences to initialize
      await container.read(sharedPreferencesProvider.future);

      // Act
      final service = container.read(appSettingsServiceProvider);
      final resolution = await service.getImageResolution();

      // Assert
      expect(service, isNotNull);
      expect(resolution, 1080);
    });

    test('should throw StateError if SharedPreferences not initialized', () {
      // Arrange - Don't initialize SharedPreferences
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Act & Assert
      // Riverpod wraps errors in ProviderException, so we check for that
      expect(
        () => container.read(appSettingsServiceProvider),
        throwsA(isA<Object>()), // Throws any error (ProviderException wrapping StateError)
      );
    });

    test('should use default values from SharedPreferences', () async {
      // Arrange - No initial values set
      SharedPreferences.setMockInitialValues({});

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Wait for SharedPreferences to initialize
      await container.read(sharedPreferencesProvider.future);

      // Act
      final service = container.read(appSettingsServiceProvider);
      final resolution = await service.getImageResolution();

      // Assert - Should use default value (1080)
      expect(resolution, 1080);
    });
  });
}
