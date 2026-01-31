import 'package:eduportfolio/features/capture/presentation/providers/capture_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('State Providers', () {
    group('selectedImagePathProvider', () {
      test('should default to null', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final imagePath = container.read(selectedImagePathProvider);
        expect(imagePath, isNull);
      });

      test('should update with image path', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        container.read(selectedImagePathProvider.notifier).state =
            '/path/to/image.jpg';
        final imagePath = container.read(selectedImagePathProvider);
        expect(imagePath, '/path/to/image.jpg');
      });

      test('should allow reset to null', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        // Set a path
        container.read(selectedImagePathProvider.notifier).state =
            '/path/to/image.jpg';
        expect(container.read(selectedImagePathProvider), '/path/to/image.jpg');

        // Reset to null
        container.read(selectedImagePathProvider.notifier).state = null;
        expect(container.read(selectedImagePathProvider), isNull);
      });

      test('should handle multiple path updates', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        // First path
        container.read(selectedImagePathProvider.notifier).state =
            '/path/1.jpg';
        expect(container.read(selectedImagePathProvider), '/path/1.jpg');

        // Second path
        container.read(selectedImagePathProvider.notifier).state =
            '/path/2.jpg';
        expect(container.read(selectedImagePathProvider), '/path/2.jpg');
      });
    });

    group('selectedSubjectIdProvider', () {
      test('should default to null', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final subjectId = container.read(selectedSubjectIdProvider);
        expect(subjectId, isNull);
      });

      test('should update with subject ID', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        container.read(selectedSubjectIdProvider.notifier).state = 1;
        final subjectId = container.read(selectedSubjectIdProvider);
        expect(subjectId, 1);
      });

      test('should allow reset to null', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        // Set a subject
        container.read(selectedSubjectIdProvider.notifier).state = 1;
        expect(container.read(selectedSubjectIdProvider), 1);

        // Reset to null
        container.read(selectedSubjectIdProvider.notifier).state = null;
        expect(container.read(selectedSubjectIdProvider), isNull);
      });

      test('should handle subject changes', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        // First subject
        container.read(selectedSubjectIdProvider.notifier).state = 1;
        expect(container.read(selectedSubjectIdProvider), 1);

        // Change to different subject
        container.read(selectedSubjectIdProvider.notifier).state = 2;
        expect(container.read(selectedSubjectIdProvider), 2);
      });
    });

    group('isSavingProvider', () {
      test('should default to false', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final isSaving = container.read(isSavingProvider);
        expect(isSaving, false);
      });

      test('should update to true when saving starts', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        container.read(isSavingProvider.notifier).state = true;
        final isSaving = container.read(isSavingProvider);
        expect(isSaving, true);
      });

      test('should toggle between true and false', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        // Start saving
        container.read(isSavingProvider.notifier).state = true;
        expect(container.read(isSavingProvider), true);

        // Finish saving
        container.read(isSavingProvider.notifier).state = false;
        expect(container.read(isSavingProvider), false);
      });

      test('should reflect save operation lifecycle', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        // Initial state
        expect(container.read(isSavingProvider), false);

        // Simulate save start
        container.read(isSavingProvider.notifier).state = true;
        expect(container.read(isSavingProvider), true);

        // Simulate save complete
        container.read(isSavingProvider.notifier).state = false;
        expect(container.read(isSavingProvider), false);
      });
    });

    group('Combined state workflow', () {
      test('should handle complete capture workflow', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        // Initial state
        expect(container.read(selectedImagePathProvider), isNull);
        expect(container.read(selectedSubjectIdProvider), isNull);
        expect(container.read(isSavingProvider), false);

        // User selects subject
        container.read(selectedSubjectIdProvider.notifier).state = 1;
        expect(container.read(selectedSubjectIdProvider), 1);

        // User captures/picks image
        container.read(selectedImagePathProvider.notifier).state =
            '/temp/captured.jpg';
        expect(container.read(selectedImagePathProvider), '/temp/captured.jpg');

        // Start saving
        container.read(isSavingProvider.notifier).state = true;
        expect(container.read(isSavingProvider), true);

        // Save completes - reset state
        container.read(isSavingProvider.notifier).state = false;
        container.read(selectedImagePathProvider.notifier).state = null;
        expect(container.read(isSavingProvider), false);
        expect(container.read(selectedImagePathProvider), isNull);
        // Subject might stay selected for next capture
        expect(container.read(selectedSubjectIdProvider), 1);
      });

      test('should allow canceling capture', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        // Set up capture
        container.read(selectedSubjectIdProvider.notifier).state = 1;
        container.read(selectedImagePathProvider.notifier).state =
            '/temp/image.jpg';

        // Cancel - reset state
        container.read(selectedImagePathProvider.notifier).state = null;
        container.read(selectedSubjectIdProvider.notifier).state = null;

        expect(container.read(selectedImagePathProvider), isNull);
        expect(container.read(selectedSubjectIdProvider), isNull);
        expect(container.read(isSavingProvider), false);
      });
    });
  });
}
